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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Tạo tài khoản mới',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bắt đầu hành trình thói quen của bạn',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),

              if (_authError != null) ...[
                Text(
                  _authError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error, fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                focusNode: _emailFocus,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _emailError,
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                focusNode: _passwordFocus,
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
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
                  labelText: 'Xác nhận mật khẩu',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                ),
              ),
              if (_confirmError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _confirmError!,
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Tạo tài khoản'),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
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
