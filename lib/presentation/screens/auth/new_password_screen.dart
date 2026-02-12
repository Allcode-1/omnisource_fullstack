import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../../core/utils/validators.dart';

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

  bool _obscurePass = true;
  bool _obscureConfirm = true;

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
                  'Paste the Google authentication token and create a new secure password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),

                const Text(
                  'Google Token',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                TextFormField(
                  controller: _tokenController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(helperText: ''),
                  validator: (val) =>
                      (val == null || val.length < 5) ? "Invalid token" : null,
                ),
                const SizedBox(height: 20),

                const Text(
                  'New Password',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                TextFormField(
                  controller: _passController,
                  obscureText: _obscurePass,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    helperText: '',
                    suffixIcon: InkWell(
                      onTap: () => setState(() => _obscurePass = !_obscurePass),
                      child: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Confirm New Password',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                TextFormField(
                  controller: _confirmPassController,
                  obscureText: _obscureConfirm,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    helperText: '',
                    suffixIcon: InkWell(
                      onTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      child: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: Colors.white54,
                      ),
                    ),
                  ),
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
                        await context.read<AuthCubit>().resetPassword(
                          _tokenController.text,
                          _passController.text,
                        );
                        if (mounted) {
                          Navigator.popUntil(context, (route) => route.isFirst);
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
