import 'package:flutter/material.dart';
import 'package:mixvy/presentation/screens/mixvy_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MixVyLoginScreen();
  }
}
              ElevatedButton(
                onPressed: authState.isLoading ? null : _login,
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              if (authState.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  authState.error ?? '',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    await controller.login(_emailController.text.trim(), _passwordController.text.trim());
  }
}
