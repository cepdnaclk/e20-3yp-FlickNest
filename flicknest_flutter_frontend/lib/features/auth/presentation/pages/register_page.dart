// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flicknest_flutter_frontend/features/auth/providers/auth_providers.dart';
// import 'package:flicknest_flutter_frontend/features/auth/presentation/pages/login_page.dart';
//
// class RegisterPage extends ConsumerStatefulWidget {
//
//   static const String route = '/register';
//
//   const RegisterPage({super.key});
//
//   @override
//   ConsumerState<RegisterPage> createState() => _RegisterPageState();
// }
//
// class _RegisterPageState extends ConsumerState<RegisterPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   bool _isLoading = false;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _registerWithEmailAndPassword() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     if (_passwordController.text != _confirmPasswordController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Passwords do not match')),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//     try {
//       await ref.read(authRepositoryProvider).registerWithEmailAndPassword(
//             _emailController.text.trim(),
//             _passwordController.text.trim(),
//           );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'Register',
//                 style: Theme.of(context).textTheme.headlineMedium,
//               ),
//               const SizedBox(height: 32),
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your email';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: true,
//                 decoration: const InputDecoration(
//                   labelText: 'Password',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your password';
//                   }
//                   if (value.length < 6) {
//                     return 'Password must be at least 6 characters';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _confirmPasswordController,
//                 obscureText: true,
//                 decoration: const InputDecoration(
//                   labelText: 'Confirm Password',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please confirm your password';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _registerWithEmailAndPassword,
//                   child: _isLoading
//                       ? const CircularProgressIndicator()
//                       : const Text('Register'),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const LoginPage(),
//                     ),
//                   );
//                 },
//                 child: const Text('Already have an account? Login'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }