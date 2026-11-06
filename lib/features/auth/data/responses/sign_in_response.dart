import 'package:neuro_app/core/services/api/responses/api_response.dart';
import 'package:neuro_app/features/auth/domain/entites/user_data.dart';
import 'package:neuro_app/features/auth/data/models/user_data_model.dart';

class SignInResponse {
  final String? message;
  final String token;
  final UserData user;

  SignInResponse({required this.message, required this.token, required this.user});
  factory SignInResponse.fromResponse(ApiResponse response) {
    return SignInResponse(
      message: response.message,
      token: response.data["token"],
      user: UserDataModel.fromJson(response.data["user"]),
    );
  }
}
