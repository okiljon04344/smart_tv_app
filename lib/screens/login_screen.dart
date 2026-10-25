import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'signup_screen.dart';
import '../services/auth_provider.dart';
import '../services/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tv_action.dart';

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
  final FocusNode _guestSignInFocus = FocusNode(debugLabel: 'login_guest_btn');
  final FocusNode _registerFocus = FocusNode(debugLabel: 'login_register_btn');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailSignInFocus.dispose();
    _googleSignInFocus.dispose();
    _guestSignInFocus.dispose();
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
          backgroundColor: context.colors.error,
        ),
      );
      auth.clearError();
      return;
    }

    if (auth.isSignedIn) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.t('login_success')),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }
  }

  void _openSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;

    return Scaffold(
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
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.outline),
                      ),
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
                                style: context.text.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l.t('login_subtitle'),
                                textAlign: TextAlign.center,
                                style: context.text.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(1),
                                child: TextFormField(
                                  autofocus: true,
                                  focusNode: _emailFocus,
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _passwordFocus.requestFocus(),
                                  decoration: InputDecoration(
                                    labelText: l.t('login_email'),
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
                              const SizedBox(height: 16),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(2),
                                child: TextFormField(
                                  focusNode: _passwordFocus,
                                  controller: _passwordCtrl,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) =>
                                      _submitEmail(auth, l),
                                  decoration: InputDecoration(
                                    labelText: l.t('login_password'),
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
                              const SizedBox(height: 24),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: TvAction(
                                  focusNode: _emailSignInFocus,
                                  enabled: !auth.isBusy,
                                  onActivate: () => _submitEmail(auth, l),
                                  child: ElevatedButton(
                                    onPressed: auth.isBusy
                                        ? null
                                        : () => _submitEmail(auth, l),
                                    child: Text(l.t('login_signin_with_email')),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(4),
                                child: TvAction(
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
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(5),
                                child: TvAction(
                                  focusNode: _guestSignInFocus,
                                  enabled: !auth.isBusy,
                                  onActivate: auth.signInAsGuest,
                                  child: OutlinedButton.icon(
                                    onPressed: auth.isBusy
                                        ? null
                                        : auth.signInAsGuest,
                                    icon: const Icon(
                                      Icons.tv_rounded,
                                      size: 22,
                                    ),
                                    label: const Text('TV Demo / Guest Mode'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(6),
                                child: TvAction(
                                  focusNode: _registerFocus,
                                  enabled: !auth.isBusy,
                                  onActivate: _openSignUp,
                                  child: TextButton(
                                    onPressed: auth.isBusy ? null : _openSignUp,
                                    child: Text(
                                      l.t('login_switch_to_register'),
                                    ),
                                  ),
                                ),
                              ),
                              if (auth.isBusy) ...[
                                const SizedBox(height: 12),
                                const Center(
                                  child: CircularProgressIndicator(),
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
            );
          },
        ),
      ),
    );
  }
}
