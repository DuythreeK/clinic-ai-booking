import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../data/admin_auth_service.dart';
import '../domain/admin_session_user.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
    required this.authService,
    required this.onLoggedIn,
  });

  final AdminAuthService authService;
  final ValueChanged<AdminSessionUser> onLoggedIn;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await widget.authService.login(
        identifier: identifier,
        password: password,
      );

      if (!mounted) {
        return;
      }

      widget.onLoggedIn(user);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error is AdminApiException
            ? error.message
            : 'Không thể đăng nhập lúc này. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPlaceholderMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2FAFF),
              Color(0xFFFFFFFF),
              Color(0xFFF2FFFB),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -96,
              left: -104,
              child: _AmbientGlow(
                size: 280,
                colors: [Color(0x80D8F1FF), Color(0x00D8F1FF)],
              ),
            ),
            const Positioned(
              right: -112,
              bottom: -88,
              child: _AmbientGlow(
                size: 320,
                colors: [Color(0x85CFF8E8), Color(0x00CFF8E8)],
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Đăng nhập',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF12172A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Hãy chọn cách đăng nhập phù hợp phù hợp với bạn',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: const Color(0xFF7D86A4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 38),
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Google',
                                    leading: const _GoogleBadge(),
                                    onPressed: () => _showPlaceholderMessage(
                                      'Đăng nhập bằng Google sẽ được cập nhật sau.',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Facebook',
                                    leading: const _FacebookBadge(),
                                    onPressed: () => _showPlaceholderMessage(
                                      'Đăng nhập bằng Facebook sẽ được cập nhật sau.',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 34),
                            TextFormField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                                AutofillHints.telephoneNumber,
                              ],
                              onChanged: (_) => setState(() {}),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 18,
                                color: const Color(0xFF5C6582),
                              ),
                              decoration: _inputDecoration(
                                context,
                                hintText: 'Email hoặc số điện thoại',
                                suffix: _identifierController.text.trim().isEmpty
                                    ? null
                                    : const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(
                                          Icons.check_rounded,
                                          color: Color(0xFF19C89B),
                                          size: 22,
                                        ),
                                      ),
                              ),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Nhập email hoặc số điện thoại.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onChanged: (_) => setState(() {}),
                              onFieldSubmitted: (_) => _submit(),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 18,
                                color: const Color(0xFF5C6582),
                              ),
                              decoration: _inputDecoration(
                                context,
                                hintText: 'Nhập mật khẩu',
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  splashRadius: 18,
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF7E87A3),
                                    size: 22,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Nhập mật khẩu.';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEF1),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFFFD4DB),
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFFD6455D),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            _GradientActionButton(
                              label: 'Đăng nhập',
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _submit,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () => _showPlaceholderMessage(
                                  'Tính năng quên mật khẩu đang được cập nhật.',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF16C6AA),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Quên mật khẩu',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 94),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Chưa có tài khoản? ',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    color: const Color(0xFF5C6582),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _showPlaceholderMessage(
                                    'Đăng ký tài khoản đang được cập nhật.',
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF3798F6),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    'Đăng kí',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    Widget? suffix,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return InputDecoration(
      hintText: hintText,
      hintStyle: textTheme.bodyMedium?.copyWith(
        fontSize: 17,
        color: const Color(0xFF9AA3BF),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFEFEFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFDDE3F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF6DDCC2), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD6455D)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD6455D)),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.onPressed,
  });

  final String label;
  final Widget leading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFFEFEFF),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF294B73).withOpacity(0.08),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6D7593),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? const [Color(0xFF7ADFCC), Color(0xFF7AB8F5)]
                : const [Color(0xFF19C8A0), Color(0xFF3B92F4)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25B7B0).withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 56,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Text(
        'G',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFEA4335),
        ),
      ),
    );
  }
}

class _FacebookBadge extends StatelessWidget {
  const _FacebookBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF3B5998),
      ),
      child: Text(
        'f',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
