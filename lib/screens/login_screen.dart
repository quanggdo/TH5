import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _authError;

  Future<void> _signIn() async {
    final auth = context.read<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Clear previous auth error
    setState(() => _authError = null);

    // Field validation
    bool hasError = false;
    if (email.isEmpty) {
      _emailError = 'Vui lòng điền email';
      hasError = true;
    } else {
      _emailError = null;
    }
    if (password.isEmpty) {
      _passwordError = 'Vui lòng nhập mật khẩu';
      hasError = true;
    } else {
      _passwordError = null;
    }
    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);
    try {
      await auth.signInWithEmail(email, password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Show inline auth error and mark both fields red
      setState(() {
        _authError = 'Tài khoản hoặc mật khẩu không chính xác';
        // keep specific field errors null so we show authError above
        _emailError = null;
        _passwordError = null;
      });
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
      }
    });
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        setState(() {
          _passwordError = null;
          _authError = null;
        });
        // Only clear existing input if there was a validation/auth error
        if (_passwordError != null || _authError != null) {
          _passwordController.clear();
        }
      }
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
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
                'Theo dõi thói quen',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đăng nhập để tiếp tục hành trình',
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

              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đăng nhập Google chưa được cấu hình'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Đăng nhập bằng Google'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/signup'),
                    child: const Text('Đăng ký ngay'),
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
