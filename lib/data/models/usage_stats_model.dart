import '../../domain/entities/usage_stats.dart';

class UsageStatsModel extends UsageStats {
  UsageStatsModel({
    required super.totalEvents,
    required super.countsByType,
    required super.ctr,
    required super.saveRate,
    required super.avgDwellSeconds,
    required super.topContentTypes,
    required super.abMetrics,
  });

  factory UsageStatsModel.fromJson(Map<String, dynamic> json) {
    final countsRaw = (json['counts_by_type'] as Map?)?.cast<String, dynamic>();
    final typesRaw = (json['top_content_types'] as Map?)
        ?.cast<String, dynamic>();
    final abRaw = (json['ab_metrics'] as Map?)?.cast<String, dynamic>();
    final abMetrics = <String, Map<String, double>>{};
    if (abRaw != null) {
      for (final entry in abRaw.entries) {
        if (entry.value is! Map) continue;
        final variantMap = Map<String, dynamic>.from(entry.value as Map);
        abMetrics[entry.key] = variantMap.map(
          (key, value) =>
              MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0.0),
        );
      }
    }

    return UsageStatsModel(
      totalEvents: (json['total_events'] as num?)?.toInt() ?? 0,
      countsByType:
          countsRaw?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ) ??
          const {},
      ctr: (json['ctr'] as num?)?.toDouble() ?? 0.0,
      saveRate: (json['save_rate'] as num?)?.toDouble() ?? 0.0,
      avgDwellSeconds: (json['avg_dwell_seconds'] as num?)?.toDouble() ?? 0.0,
      topContentTypes:
          typesRaw?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ) ??
          const {},
      abMetrics: abMetrics,
    );
  }
}
