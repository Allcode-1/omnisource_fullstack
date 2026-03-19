import argparse
import sys
from collections.abc import Iterable
from datetime import datetime, timezone

from pymongo import ASCENDING, MongoClient, UpdateOne
from pymongo.collection import Collection

from app.core.config import settings
from app.core.content_keys import make_content_key


def _print_section(title: str) -> None:
    print(f"\n== {title} ==")


def _index_map(collection: Collection) -> dict[str, dict]:
    return {index["name"]: dict(index) for index in collection.list_indexes()}


def _find_duplicate_type_ext_ids(collection: Collection) -> list[dict]:
    pipeline = [
        {
            "$group": {
                "_id": {"type": "$type", "ext_id": "$ext_id"},
                "count": {"$sum": 1},
            }
        },
        {"$match": {"count": {"$gt": 1}}},
        {"$limit": 20},
    ]
    return list(collection.aggregate(pipeline))


def _find_duplicate_computed_content_keys(collection: Collection) -> list[dict]:
    pipeline = [
        {
            "$project": {
                "computed_content_key": {"$concat": ["$type", ":", "$ext_id"]},
            }
        },
        {
            "$group": {
                "_id": "$computed_content_key",
                "count": {"$sum": 1},
            }
        },
        {"$match": {"count": {"$gt": 1}}},
        {"$limit": 20},
    ]
    return list(collection.aggregate(pipeline))


def _prepare_metadata_updates(collection: Collection) -> list[UpdateOne]:
    operations: list[UpdateOne] = []
    cursor = collection.find(
        {},
        {"_id": 1, "type": 1, "ext_id": 1, "content_key": 1},
    )
    for doc in cursor:
        content_type = (doc.get("type") or "").strip()
        ext_id = (doc.get("ext_id") or "").strip()
        if not content_type or not ext_id:
            raise RuntimeError(
                f"content_metadata document {doc['_id']} is missing type/ext_id",
            )
        computed_key = make_content_key(content_type, ext_id)
        if doc.get("content_key") != computed_key:
            operations.append(
                UpdateOne(
                    {"_id": doc["_id"]},
                    {"$set": {"content_key": computed_key}},
                )
            )
    return operations


def _prepare_interaction_updates(
    interaction_collection: Collection,
    metadata_collection: Collection,
) -> list[UpdateOne]:
    type_by_ext_id: dict[str, str] = {}
    for doc in metadata_collection.find({}, {"_id": 0, "ext_id": 1, "type": 1}):
        ext_id = (doc.get("ext_id") or "").strip()
        content_type = (doc.get("type") or "").strip()
        if ext_id and content_type:
            type_by_ext_id[ext_id] = content_type

    operations: list[UpdateOne] = []
    cursor = interaction_collection.find(
        {},
        {"_id": 1, "ext_id": 1, "content_type": 1, "content_key": 1},
    )
    for doc in cursor:
        ext_id = (doc.get("ext_id") or "").strip()
        if not ext_id or ext_id == "app":
            continue

        content_type = (doc.get("content_type") or "").strip()
        if not content_type:
            content_type = type_by_ext_id.get(ext_id, "")

        if not content_type:
            continue

        computed_key = make_content_key(content_type, ext_id)
        update_fields: dict[str, str] = {}
        if doc.get("content_type") != content_type:
            update_fields["content_type"] = content_type
        if doc.get("content_key") != computed_key:
            update_fields["content_key"] = computed_key
        if update_fields:
            operations.append(
                UpdateOne(
                    {"_id": doc["_id"]},
                    {"$set": update_fields},
                )
            )
    return operations


def _apply_bulk(collection: Collection, operations: Iterable[UpdateOne], label: str) -> None:
    ops = list(operations)
    if not ops:
        print(f"{label}: no changes needed")
        return
    result = collection.bulk_write(ops, ordered=False)
    print(
        f"{label}: matched={result.matched_count} modified={result.modified_count}",
    )


def _ensure_content_metadata_indexes(collection: Collection) -> None:
    indexes = _index_map(collection)

    if "content_key_1" not in indexes:
        collection.create_index(
            [("content_key", ASCENDING)],
            name="content_key_1",
            unique=True,
            sparse=True,
        )
        print("content_metadata: created index content_key_1 (unique, sparse)")
    else:
        print("content_metadata: index content_key_1 already exists")

    ext_id_index = indexes.get("ext_id_1")
    if ext_id_index and ext_id_index.get("unique"):
        collection.drop_index("ext_id_1")
        collection.create_index([("ext_id", ASCENDING)], name="ext_id_1")
        print("content_metadata: recreated ext_id_1 as non-unique")
    elif ext_id_index:
        print("content_metadata: index ext_id_1 already non-unique")
    else:
        collection.create_index([("ext_id", ASCENDING)], name="ext_id_1")
        print("content_metadata: created index ext_id_1")

    if "type_1" not in indexes:
        collection.create_index([("type", ASCENDING)], name="type_1")
        print("content_metadata: created index type_1")
    else:
        print("content_metadata: index type_1 already exists")


def _ensure_interaction_indexes(collection: Collection) -> None:
    indexes = _index_map(collection)
    if "content_key_1" not in indexes:
        collection.create_index([("content_key", ASCENDING)], name="content_key_1")
        print("interactions: created index content_key_1")
    else:
        print("interactions: index content_key_1 already exists")


def _prepare_password_reset_cleanup(collection: Collection) -> tuple[int, int]:
    invalid_or_legacy = collection.count_documents(
        {
            "$or": [
                {"token_hash": {"$exists": False}},
                {"token_hash": None},
            ],
        }
    )
    expired_invalid_or_legacy = collection.count_documents(
        {
            "$or": [
                {"token_hash": {"$exists": False}},
                {"token_hash": None},
            ],
            "expires_at": {"$lt": datetime.now(timezone.utc)},
        }
    )
    return invalid_or_legacy, expired_invalid_or_legacy


def _cleanup_password_resets(collection: Collection) -> None:
    result = collection.delete_many(
        {
            "$or": [
                {"token_hash": {"$exists": False}},
                {"token_hash": None},
            ],
            "expires_at": {"$lt": datetime.now(timezone.utc)},
        }
    )
    print(f"password_resets cleanup: deleted={result.deleted_count}")


def _ensure_password_reset_indexes(collection: Collection) -> None:
    indexes = _index_map(collection)
    if "email_1" not in indexes:
        collection.create_index([("email", ASCENDING)], name="email_1")
        print("password_resets: created index email_1")
    else:
        print("password_resets: index email_1 already exists")

    if "token_hash_1" not in indexes:
        collection.create_index(
            [("token_hash", ASCENDING)],
            name="token_hash_1",
            unique=True,
        )
        print("password_resets: created index token_hash_1 (unique)")
    else:
        print("password_resets: index token_hash_1 already exists")

    if "expires_at_1" not in indexes:
        collection.create_index(
            [("expires_at", ASCENDING)],
            name="expires_at_1",
            expireAfterSeconds=0,
        )
        print("password_resets: created index expires_at_1 (ttl)")
    else:
        print("password_resets: index expires_at_1 already exists")


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Safely migrate OmniSource MongoDB indexes from unique ext_id "
            "to unique content_key."
        ),
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply changes. Without this flag the script only prints a dry-run summary.",
    )
    args = parser.parse_args()

    client = MongoClient(settings.MONGODB_URL)
    db = client.get_default_database()
    metadata_collection = db["content_metadata"]
    interaction_collection = db["interactions"]
    password_reset_collection = db["password_resets"]

    _print_section("Current State")
    metadata_indexes = _index_map(metadata_collection)
    print("content_metadata indexes:", ", ".join(metadata_indexes))
    print("content_metadata count:", metadata_collection.count_documents({}))
    print(
        "content_metadata without content_key:",
        metadata_collection.count_documents(
            {"$or": [{"content_key": {"$exists": False}}, {"content_key": None}]},
        ),
    )
    print("interactions count:", interaction_collection.count_documents({}))
    print(
        "interactions without content_key:",
        interaction_collection.count_documents(
            {"$or": [{"content_key": {"$exists": False}}, {"content_key": None}]},
        ),
    )
    invalid_resets, expired_invalid_resets = _prepare_password_reset_cleanup(
        password_reset_collection,
    )
    print("password_resets count:", password_reset_collection.count_documents({}))
    print("password_resets legacy or invalid:", invalid_resets)
    print("password_resets expired legacy or invalid:", expired_invalid_resets)

    _print_section("Validation")
    duplicate_type_ext_ids = _find_duplicate_type_ext_ids(metadata_collection)
    if duplicate_type_ext_ids:
        print("Found duplicate (type, ext_id) pairs. Migration aborted.")
        for row in duplicate_type_ext_ids:
            print(row)
        return 1
    print("No duplicate (type, ext_id) pairs found")

    duplicate_computed_content_keys = _find_duplicate_computed_content_keys(
        metadata_collection,
    )
    if duplicate_computed_content_keys:
        print("Found duplicate computed content_key values. Migration aborted.")
        for row in duplicate_computed_content_keys:
            print(row)
        return 1
    print("No duplicate computed content_key values found")

    metadata_updates = _prepare_metadata_updates(metadata_collection)
    interaction_updates = _prepare_interaction_updates(
        interaction_collection,
        metadata_collection,
    )

    _print_section("Planned Changes")
    print("content_metadata updates:", len(metadata_updates))
    print("interaction updates:", len(interaction_updates))
    ext_id_index = metadata_indexes.get("ext_id_1")
    if ext_id_index and ext_id_index.get("unique"):
        print("content_metadata ext_id_1 will be converted from unique to non-unique")
    else:
        print("content_metadata ext_id_1 is already compatible")
    if "content_key_1" not in metadata_indexes:
        print("content_metadata content_key_1 will be created")
    if "content_key_1" not in _index_map(interaction_collection):
        print("interactions content_key_1 will be created")
    reset_indexes = _index_map(password_reset_collection)
    if "token_hash_1" not in reset_indexes:
        print("password_resets token_hash_1 will be created")
    if "expires_at_1" not in reset_indexes:
        print("password_resets expires_at_1 will be created")
    if expired_invalid_resets:
        print("password_resets expired legacy records will be deleted")

    if not args.apply:
        _print_section("Dry Run")
        print("No changes were applied. Re-run with --apply to execute the migration.")
        return 0

    _print_section("Applying")
    _apply_bulk(metadata_collection, metadata_updates, "content_metadata backfill")
    _ensure_content_metadata_indexes(metadata_collection)
    _apply_bulk(interaction_collection, interaction_updates, "interactions backfill")
    _ensure_interaction_indexes(interaction_collection)
    _cleanup_password_resets(password_reset_collection)
    _ensure_password_reset_indexes(password_reset_collection)

    _print_section("Done")
    print("Migration completed successfully.")
    print("You can restart the API now.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
