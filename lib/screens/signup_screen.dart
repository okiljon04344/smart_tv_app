import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../services/locale_provider.dart';
import '../utils/tv_key_helper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocus = FocusNode(debugLabel: 'signup_email');
  final FocusNode _passwordFocus = FocusNode(debugLabel: 'signup_password');
  final FocusNode _confirmFocus = FocusNode(debugLabel: 'signup_confirm');
  final FocusNode _createBtnFocus = FocusNode(debugLabel: 'signup_create_btn');
  final FocusNode _backBtnFocus = FocusNode(debugLabel: 'signup_back_btn');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _createBtnFocus.dispose();
    _backBtnFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth, LocaleProvider l) async {
    if (!_formKey.currentState!.validate()) return;

    await auth.registerWithEmail(_emailCtrl.text, _passwordCtrl.text);

    if (!mounted) return;

    final err = auth.error;
    if (err != null && err.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.t('login_error')}: $err'),
          backgroundColor: Colors.red,
        ),
      );
      auth.clearError();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.t('signup_success')),
        backgroundColor: const Color(0xFF6C63FF),
        duration: const Duration(milliseconds: 900),
      ),
    );
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF090A11),
      appBar: AppBar(
        title: Text(l.t('signup_title')),
        backgroundColor: const Color(0xFF141624),
      ),
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
                                  l.t('signup_title'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l.t('signup_subtitle'),
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
                                    textInputAction: TextInputAction.next,
                                    style: const TextStyle(color: Colors.white),
                                    onFieldSubmitted: (_) =>
                                        _confirmFocus.requestFocus(),
                                    decoration: InputDecoration(
                                      labelText: l.t('login_password'),
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
                                const SizedBox(height: 12),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(3),
                                  child: TextFormField(
                                    focusNode: _confirmFocus,
                                    controller: _confirmCtrl,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    style: const TextStyle(color: Colors.white),
                                    onFieldSubmitted: (_) => _submit(auth, l),
                                    decoration: InputDecoration(
                                      labelText: l.t('signup_confirm_password'),
                                      filled: true,
                                      fillColor: const Color(0xFF1B1D2D),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return l.t('signup_confirm_required');
                                      }
                                      if (v != _passwordCtrl.text) {
                                        return l.t('signup_password_mismatch');
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(4),
                                  child: _TvAction(
                                    focusNode: _createBtnFocus,
                                    enabled: !auth.isBusy,
                                    onActivate: () => _submit(auth, l),
                                    child: ElevatedButton(
                                      onPressed: auth.isBusy
                                          ? null
                                          : () => _submit(auth, l),
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
                                        l.t('signup_create_account'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(5),
                                  child: _TvAction(
                                    focusNode: _backBtnFocus,
                                    enabled: !auth.isBusy,
                                    onActivate: () =>
                                        Navigator.maybePop(context),
                                    child: TextButton(
                                      onPressed: auth.isBusy
                                          ? null
                                          : () => Navigator.maybePop(context),
                                      child: Text(
                                        l.t('signup_have_account'),
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
        if (enabled && isTvActivateEvent(event)) {
          onActivate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: ExcludeFocus(child: child),
          );
        },
      ),
    );
  }
}
