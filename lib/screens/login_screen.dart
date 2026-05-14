import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'signup_screen.dart';
import '../services/auth_provider.dart';
import '../services/locale_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocus = FocusNode(debugLabel: 'login_email');
  final FocusNode _passwordFocus = FocusNode(debugLabel: 'login_password');
  final FocusNode _emailSignInFocus = FocusNode(debugLabel: 'login_email_btn');
  final FocusNode _googleSignInFocus = FocusNode(
    debugLabel: 'login_google_btn',
  );
  final FocusNode _registerFocus = FocusNode(debugLabel: 'login_register_btn');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailSignInFocus.dispose();
    _googleSignInFocus.dispose();
    _registerFocus.dispose();
    super.dispose();
  }

  Future<void> _submitEmail(AuthProvider auth, LocaleProvider l) async {
    if (!_formKey.currentState!.validate()) return;
    await auth.signInWithEmail(_emailCtrl.text, _passwordCtrl.text);

    if (!mounted) return;
    _showAuthResult(auth, l);
  }

  Future<void> _submitGoogle(AuthProvider auth, LocaleProvider l) async {
    await auth.signInWithGoogle();
    if (!mounted) return;
    _showAuthResult(auth, l);
  }

  void _showAuthResult(AuthProvider auth, LocaleProvider l) {
    final messenger = ScaffoldMessenger.of(context);
    final err = auth.error;
    if (err != null && err.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l.t('login_error')}: $err'),
          backgroundColor: Colors.red,
        ),
      );
      auth.clearError();
      return;
    }

    if (auth.isSignedIn) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.t('login_success')),
          backgroundColor: const Color(0xFF6C63FF),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF090A11),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      color: const Color(0xFF141624),
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: FocusTraversalGroup(
                          policy: OrderedTraversalPolicy(),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l.t('login_title'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l.t('login_subtitle'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(1),
                                  child: TextFormField(
                                    autofocus: true,
                                    focusNode: _emailFocus,
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    style: const TextStyle(color: Colors.white),
                                    onFieldSubmitted: (_) =>
                                        _passwordFocus.requestFocus(),
                                    decoration: InputDecoration(
                                      labelText: l.t('login_email'),
                                      labelStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF1B1D2D),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return l.t('login_email_required');
                                      }
                                      if (!v.contains('@')) {
                                        return l.t('login_email_invalid');
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(2),
                                  child: TextFormField(
                                    focusNode: _passwordFocus,
                                    controller: _passwordCtrl,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    style: const TextStyle(color: Colors.white),
                                    onFieldSubmitted: (_) =>
                                        _submitEmail(auth, l),
                                    decoration: InputDecoration(
                                      labelText: l.t('login_password'),
                                      labelStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF1B1D2D),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return l.t('login_password_required');
                                      }
                                      if (v.length < 6) {
                                        return l.t('login_password_short');
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(3),
                                  child: _TvAction(
                                    focusNode: _emailSignInFocus,
                                    enabled: !auth.isBusy,
                                    onActivate: () => _submitEmail(auth, l),
                                    child: ElevatedButton(
                                      onPressed: auth.isBusy
                                          ? null
                                          : () => _submitEmail(auth, l),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF6C63FF,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        l.t('login_signin_with_email'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(4),
                                  child: _TvAction(
                                    focusNode: _googleSignInFocus,
                                    enabled: !auth.isBusy,
                                    onActivate: () => _submitGoogle(auth, l),
                                    child: OutlinedButton.icon(
                                      onPressed: auth.isBusy
                                          ? null
                                          : () => _submitGoogle(auth, l),
                                      icon: const Icon(
                                        Icons.g_mobiledata,
                                        size: 28,
                                      ),
                                      label: Text(
                                        l.t('login_signin_with_google'),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(5),
                                  child: _TvAction(
                                    focusNode: _registerFocus,
                                    enabled: !auth.isBusy,
                                    onActivate: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpScreen(),
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed: auth.isBusy
                                          ? null
                                          : () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const SignUpScreen(),
                                              ),
                                            ),
                                      child: Text(
                                        l.t('login_switch_to_register'),
                                        style: const TextStyle(
                                          color: Color(0xFF9C97FF),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (auth.isBusy) ...[
                                  const SizedBox(height: 8),
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF6C63FF),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

bool _isTvActivateEvent(KeyEvent event) {
  final key = event.logicalKey;
  final isActivate =
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.gameButtonA;
  if (!isActivate) return false;
  if (key == LogicalKeyboardKey.select) {
    return event is KeyDownEvent || event is KeyUpEvent;
  }
  return event is KeyDownEvent;
}

class _TvAction extends StatelessWidget {
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onActivate;
  final Widget child;

  const _TvAction({
    required this.focusNode,
    required this.enabled,
    required this.onActivate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (enabled && _isTvActivateEvent(event)) {
          onActivate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
