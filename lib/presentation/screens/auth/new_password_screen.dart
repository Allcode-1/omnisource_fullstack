import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/custom_input.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _normalizeTokenInput(String raw) {
    var token = raw.trim();
    if (token.isEmpty) return '';

    final parsed = Uri.tryParse(token);
    final queryToken = parsed?.queryParameters['token'];
    if (queryToken != null && queryToken.isNotEmpty) {
      token = queryToken;
    }

    return token.replaceAll(RegExp(r'\s+'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 160),
                const Text(
                  'Set New Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paste the reset code or full reset link from email, then create a new secure password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),

                CustomInput(
                  label: 'Reset Code or Link',
                  icon: Icons.vpn_key_outlined,
                  controller: _tokenController,
                  validator: (val) {
                    final normalized = _normalizeTokenInput(val ?? '');
                    if (normalized.length < 8) return "Invalid reset code";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: 'New Password',
                  icon: Icons.lock_outline,
                  controller: _passController,
                  isPassword: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: 'Confirm New Password',
                  icon: Icons.lock_outline,
                  controller: _confirmPassController,
                  isPassword: true,
                  validator: (val) => val != _passController.text
                      ? "Passwords do not match"
                      : null,
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final authCubit = context.read<AuthCubit>();
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await authCubit.resetPassword(
                          _normalizeTokenInput(_tokenController.text),
                          _passController.text,
                        );
                        if (!mounted) return;
                        if (success) {
                          navigator.popUntil((route) => route.isFirst);
                        } else {
                          final authState = authCubit.state;
                          final message = authState is AuthError
                              ? authState.message
                              : 'Failed to reset password';
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Reset Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
