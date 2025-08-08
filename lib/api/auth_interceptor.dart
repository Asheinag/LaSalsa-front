import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      handler.reject(
        DioException(
          requestOptions: options,
          message: 'User not authenticated',
        ),
      );
      return;
    }

    final token = await user.getIdToken();
    options.headers['Authorization'] = 'Bearer $token';
    super.onRequest(options, handler);
  }
}
