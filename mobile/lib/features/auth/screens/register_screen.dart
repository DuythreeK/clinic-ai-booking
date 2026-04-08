import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    Key? key,
    required this.authService,
  }) : super(key: key);

  final AuthService authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final Logger logger = Logger();
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final fullNameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();

  bool obscurePassword = true;
  bool obscurePasswordConfirm = true;
  bool isLoading = false;
  String? errorMessage;
  String selectedRole = 'patient';

  Future<void> _handleRegister() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != passwordConfirmController.text) {
      setState(() => errorMessage = 'Mật khẩu không khớp');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await widget.authService.register(
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
        role: selectedRole,
      );

      if (mounted) {
        // Show success message and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đăng kí thành công! Vui lòng đăng nhập')),
        );
        context.go('/login');
      }
    } on AuthException catch (e) {
      setState(() => errorMessage = e.message);
      logger.e('❌ Register error: ${e.message}');
    } catch (e) {
      setState(() => errorMessage = 'Đăng kí thất bại. Vui lòng thử lại');
      logger.e('❌ Register error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6F1FB), Color(0xFFD8F4EA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 48),
                          const Text(
                            'Đăng kí',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tạo tài khoản mới để bắt đầu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF677389),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Full Name Field
                          _InputCard(
                            child: TextFormField(
                              controller: fullNameController,
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                hintText: 'Họ và tên',
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF8A93A5),
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'Vui lòng nhập họ và tên';
                                }
                                if (text.length < 2) {
                                  return 'Họ và tên phải có ít nhất 2 ký tự';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Email Field
                          _InputCard(
                            child: TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Nhập email của bạn',
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF8A93A5),
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!text.contains('@')) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Phone Field
                          _InputCard(
                            child: TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Nhập số điện thoại',
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: Icon(
                                  Icons.phone_outlined,
                                  color: Color(0xFF8A93A5),
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'Vui lòng nhập số điện thoại';
                                }
                                if (!RegExp(r'^[0-9]{9,}$').hasMatch(text)) {
                                  return 'Số điện thoại không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Role Selection Dropdown
                          Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.82),
                              border:
                                  Border.all(color: const Color(0xFFDCE4EE)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: selectedRole,
                              isExpanded: true,
                              underline: const SizedBox(),
                              style: const TextStyle(
                                color: Color(0xFF717C93),
                                fontSize: 14,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'patient',
                                  child: Text('Bệnh nhân'),
                                ),
                                DropdownMenuItem(
                                  value: 'doctor',
                                  child: Text('Bác sĩ'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => selectedRole = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Password Field
                          _InputCard(
                            child: TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Tạo mật khẩu',
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() =>
                                        obscurePassword = !obscurePassword);
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF8A93A5),
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                if ((value ?? '').length < 8) {
                                  return 'Mật khẩu phải có ít nhất 8 ký tự';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Confirm Password Field
                          _InputCard(
                            child: TextFormField(
                              controller: passwordConfirmController,
                              obscureText: obscurePasswordConfirm,
                              decoration: InputDecoration(
                                hintText: 'Nhập lại mật khẩu',
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(
                                      () => obscurePasswordConfirm =
                                          !obscurePasswordConfirm,
                                    );
                                  },
                                  icon: Icon(
                                    obscurePasswordConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF8A93A5),
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Vui lòng nhập lại mật khẩu';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                errorMessage!,
                                style:
                                    const TextStyle(color: Color(0xFFB71C1C)),
                              ),
                            ),
                          const SizedBox(height: 14),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF11C59B), Color(0xFF3A8DFF)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3300C5A5),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Đăng kí',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Đã có tài khoản? ',
                                style: TextStyle(
                                  color: Color(0xFF23BFB2),
                                  fontSize: 15,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    color: Color(0xFF0093FF),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    fullNameController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        border: Border.all(color: const Color(0xFFDCE4EE)),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
