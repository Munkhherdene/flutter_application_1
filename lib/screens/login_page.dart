import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  bool isLoading = false;
  String loadingMessage = 'Түр хүлээнэ үү...';

  @override
  void initState() {
    super.initState();
    autoLogin();
  }

  void autoLogin() async {
    setState(() {
      isLoading = true;
      loadingMessage = 'Өмнөх нэвтрэлтийг шалгаж байна...';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('loggedIn') ?? false;
      if (isLoggedIn) {
        // Add a small delay to show loading state
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void login() async {
    setState(() {
      isLoading = true;
      loadingMessage = 'Нэвтрэж байна...';
    });
    try {
      if (Firebase.apps.isEmpty) {
        // Firebase not initialized - use local storage
        final prefs = await SharedPreferences.getInstance();
        final savedEmail = prefs.getString('email') ?? '';
        final savedPassword = prefs.getString('password') ?? '';
        
        if (emailController.text.trim() == savedEmail && 
            passwordController.text.trim() == savedPassword) {
          await prefs.setBool('loggedIn', rememberMe);
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email or password incorrect')),
          );
        }
      } else {
        // Firebase initialized - use Firebase Auth
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', rememberMe);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void register() async {
    setState(() {
      isLoading = true;
      loadingMessage = 'Бүртгүүлж байна...';
    });
    try {
      if (Firebase.apps.isEmpty) {
        // Firebase not initialized - use local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', emailController.text.trim());
        await prefs.setString('password', passwordController.text.trim());
        await prefs.setBool('loggedIn', rememberMe);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful')),
        );
        
        emailController.clear();
        passwordController.clear();
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        // Firebase initialized - use Firebase Auth
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful')),
        );
        
        emailController.clear();
        passwordController.clear();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', rememberMe);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Microsoft login logic
  Future<void> loginWithMicrosoft() async {
    setState(() {
      isLoading = true;
      loadingMessage = 'Microsoft-д холбогдож байна...';
    });
    try {
      if (Firebase.apps.isEmpty) {
        // Firebase not initialized - show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microsoft login requires Firebase configuration')),
        );
        return;
      }

      // Firebase initialized - use Firebase Auth with timeout
      setState(() => loadingMessage = 'Нэвтрэх хуудсыг нээж байна...');
      final microsoftProvider = OAuthProvider("microsoft.com");

      // Add timeout to prevent infinite loading
      await FirebaseAuth.instance.signInWithProvider(microsoftProvider).timeout(
        const Duration(seconds: 30), // 30 second timeout
        onTimeout: () {
          throw TimeoutException('Microsoft login timed out. Please try again.');
        },
      );

      setState(() => loadingMessage = 'Нэвтрэлтийг баталгаажуулж байна...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('Microsoft login timeout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login timed out: ${e.message}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Microsoft login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microsoft login failed: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 60, color: Colors.deepPurple),
                      const SizedBox(height: 10),
                      const Text(
                        'Нэвтрэх',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            onChanged: (v) {
                              setState(() => rememberMe = v!);
                            },
                          ),
                          const Text('Remember me'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Microsoft login button
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.account_circle),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: isLoading ? null : loginWithMicrosoft,
                          label: const Text('Microsoft-ээр нэвтрэх'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Loading overlay with progress messages
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          loadingMessage,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() => isLoading = false);
                          },
                          child: const Text('Цуцлах'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}