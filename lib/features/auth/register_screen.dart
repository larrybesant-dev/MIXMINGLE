import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/user_provider.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Consumer(builder: (context, ref, _) {
              return ElevatedButton(
                onPressed: () {
                  // Placeholder: set userProvider with dummy user
                  ref.read(userProvider.notifier).state = UserModel(
                    id: 'dummy-id',
                    email: emailController.text,
                    username: emailController.text.split('@').first,
                    avatarUrl: '',
                    coinBalance: 0,
                    membershipLevel: 'Free',
                    followers: [],
                  ) as UserModel?;
                  Navigator.pop(context);
                },
                child: const Text('Register'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
