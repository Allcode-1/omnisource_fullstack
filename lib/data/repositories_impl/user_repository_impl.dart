import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class UserRepositoryImpl implements UserRepository {
  final ApiClient apiClient;

  UserRepositoryImpl(this.apiClient);

  @override
  Future<User> getMe() async {
    final response = await apiClient.dio.get(ApiConstants.userMe);
    return UserModel.fromJson(response.data);
  }

  @override
  Future<User> updateProfile({
    String? username,
    List<String>? interests,
  }) async {
    final response = await apiClient.dio.patch(
      ApiConstants.userUpdate,
      data: {
        if (username != null) 'username': username,
        if (interests != null) 'interests': interests,
      },
    );
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> deleteAccount() async {
    await apiClient.dio.delete(ApiConstants.userDelete);
  }
}
