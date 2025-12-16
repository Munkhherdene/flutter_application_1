import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Firebase initialization failed - continue without Firebase
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  // Sample customer data
  final List<Map<String, String>> customers = [
    {'name': 'Бат-Эрдэнэ', 'phone': '+976 99112233', 'company': 'Монгол Технологи ХХК'},
    {'name': 'Сараа', 'phone': '+976 88776655', 'company': 'Дэлхийн Худалдаа'},
    {'name': 'Дорж', 'phone': '+976 99445566', 'company': 'Төв Азийн Групп'},
    {'name': 'Нараа', 'phone': '+976 88997744', 'company': 'Оюу Толгой ХХК'},
    {'name': 'Болд', 'phone': '+976 99663322', 'company': 'Эрдэнэт Үйлдвэр'},
    {'name': 'Тэмүүжин', 'phone': '+976 88115577', 'company': 'Мобиком Корпораци'},
    {'name': 'Азжаргал', 'phone': '+976 99334455', 'company': 'Говь ХХК'},
    {'name': 'Энхжин', 'phone': '+976 88667788', 'company': 'Таван Богд Групп'},
  ];

  List<Map<String, String>> get filteredCustomers {
    if (searchQuery.isEmpty) {
      return customers;
    }
    return customers.where((customer) {
      final name = customer['name']!.toLowerCase();
      final company = customer['company']!.toLowerCase();
      final phone = customer['phone']!;
      final query = searchQuery.toLowerCase();

      return name.contains(query) ||
             company.contains(query) ||
             phone.contains(query);
    }).toList();
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Харилцагч хайх'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
            tooltip: 'Гарах',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Харилцагчын нэр, компани эсвэл утасны дугаар...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Нийт ${filteredCustomers.length} харилцагч',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                if (searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '("${searchQuery}" хайлтаар)',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Customer list
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Харилцагч олдсонгүй',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Өөр түлхүүр үгээр хайна уу',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            child: Text(
                              customer['name']![0],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          title: Text(
                            customer['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      customer['company']!,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    customer['phone']!,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.call),
                            color: Colors.green,
                            onPressed: () {
                              // Could implement phone call functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${customer['name']} руу залгах уу?'),
                                  action: SnackBarAction(
                                    label: 'Залгах',
                                    onPressed: () {
                                      // Implement phone call
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            // Could navigate to customer details
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${customer['name']} -ны дэлгэрэнгүй мэдээлэл'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Could add new customer functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Шинэ харилцагч нэмэх')),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
        tooltip: 'Шинэ харилцагч',
      ),
    );
  }
}
