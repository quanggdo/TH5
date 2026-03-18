import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  bool _obscure = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _authError;

  Future<void> _register() async {
    final auth = context.read<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    // Clear previous auth error
    setState(() => _authError = null);

    bool hasError = false;
    if (email.isEmpty) {
      _emailError = 'Vui lòng điền email';
      hasError = true;
    } else {
      // basic email format check
      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
      if (!emailRegex.hasMatch(email)) {
        _emailError = 'Email không hợp lệ';
        hasError = true;
      } else {
        _emailError = null;
      }
    }
    if (password.isEmpty) {
      _passwordError = 'Vui lòng nhập mật khẩu';
      hasError = true;
    } else if (password.length < 6) {
      _passwordError = 'Mật khẩu phải ít nhất 6 ký tự';
      hasError = true;
    } else {
      _passwordError = null;
    }
    if (confirm.isEmpty) {
      _confirmError = 'Vui lòng xác nhận mật khẩu';
      hasError = true;
    } else {
      _confirmError = null;
    }
    if (password.isNotEmpty && confirm.isNotEmpty && password != confirm) {
      _confirmError = 'Xác nhận mật khẩu không chính xác';
      hasError = true;
    }
    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);
    try {
      await auth.registerWithEmail(email, password);
      // registration succeeded: show success and return to root (home will rebuild to HomeScreen)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        setState(() {
          _authError = 'Tài khoản đã tồn tại';
          _emailError = null;
        });
      } else {
        setState(() {
          _authError = 'Lỗi đăng ký: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        setState(() {
          _emailError = null;
          _authError = null;
        });
        _emailController.clear();
      }
    });
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        setState(() {
          _passwordError = null;
          _authError = null;
        });
        if (_passwordError != null || _authError != null) {
          _passwordController.clear();
        }
      }
    });
    _confirmFocus.addListener(() {
      if (_confirmFocus.hasFocus) {
        setState(() {
          _confirmError = null;
          _authError = null;
        });
        if (_confirmError != null || _authError != null) {
          _confirmController.clear();
        }
      }
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(30.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Habit Tracker',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),

              if (_authError != null) ...[
                Text(
                  _authError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                focusNode: _emailFocus,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: borderRadius),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(
                      color: (_emailError != null || _authError != null)
                          ? Colors.red
                          : Colors.cyan.shade300,
                      width: 2,
                    ),
                  ),
                  errorText: _emailError,
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                focusNode: _passwordFocus,
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: borderRadius),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(
                      color: (_passwordError != null) ? Colors.red : Colors.grey.shade400,
                      width: 1.2,
                    ),
                  ),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              TextField(
                focusNode: _confirmFocus,
                controller: _confirmController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Xác nhận mật khẩu',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: borderRadius),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(
                      color: (_confirmError != null) ? Colors.red : Colors.grey.shade400,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              if (_confirmError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _confirmError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    shape: const StadiumBorder(),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đăng ký', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản? ', style: TextStyle(color: Colors.black54)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
