import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  static const String route = "/login";
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  bool _isLoading = false;
  
  // @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentUser();
    });
  }

  Future<void> _checkCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Current user check: ${user?.email ?? 'No user'}');
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Error checking current user: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    print('Starting Google Sign-in process...');
    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        print('Google Sign-in was cancelled or failed with null result');
        _showMessage('Sign-in was cancelled');
        return;
      }
      if (mounted) {
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'This account exists with a different sign-in method';
          break;
        case 'invalid-credential':
          errorMessage = 'The sign-in credentials are invalid';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'user-not-found':
          errorMessage = 'No account found with these credentials';
          break;
        case 'network-request-failed':
          errorMessage = 'Please check your internet connection';
          break;
        case 'sign_in_canceled':
          errorMessage = 'Sign-in was cancelled';
          break;
        case 'invalid_token':
          errorMessage = 'Authentication failed. Please try again';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign in';
      }
      _showMessage(errorMessage);
    } on PlatformException catch (e) {
      print('Platform error: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'network_error':
          errorMessage = 'Please check your internet connection';
          break;
        case 'sign_in_failed':
          errorMessage = 'Sign-in failed. Please try again';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign in';
      }
      _showMessage(errorMessage);
    } catch (e) {
      print('Unexpected error during sign-in: $e');
      _showMessage('An unexpected error occurred. Please try again');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    print('Showing message to user: $message');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C3E50).withOpacity(0.95),
              const Color(0xFF3498DB).withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and App Name
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.waving_hand,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'FlickNest',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your Smart Home Entertainment Hub',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Sign In Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_isLoading)
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: SignInButton(
                                Buttons.Google,
                                onPressed: _handleGoogleSignIn,
                                text: "Continue with Google",
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Footer Text
                    Text(
                      '© ${DateTime.now().year} FlickNest. All rights reserved.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
