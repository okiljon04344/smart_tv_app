import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../services/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tv_action.dart';

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
          backgroundColor: context.colors.error,
        ),
      );
      auth.clearError();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.t('signup_success')),
        duration: const Duration(milliseconds: 900),
      ),
    );
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('signup_title'))),
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
                                l.t('signup_title'),
                                textAlign: TextAlign.center,
                                style: context.text.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l.t('signup_subtitle'),
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
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _confirmFocus.requestFocus(),
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
                              const SizedBox(height: 16),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: TextFormField(
                                  focusNode: _confirmFocus,
                                  controller: _confirmCtrl,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(auth, l),
                                  decoration: InputDecoration(
                                    labelText: l.t('signup_confirm_password'),
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
                              const SizedBox(height: 24),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(4),
                                child: TvAction(
                                  focusNode: _createBtnFocus,
                                  enabled: !auth.isBusy,
                                  onActivate: () => _submit(auth, l),
                                  child: ElevatedButton(
                                    onPressed: auth.isBusy
                                        ? null
                                        : () => _submit(auth, l),
                                    child: Text(l.t('signup_create_account')),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(5),
                                child: TvAction(
                                  focusNode: _backBtnFocus,
                                  enabled: !auth.isBusy,
                                  onActivate: () => Navigator.maybePop(context),
                                  child: TextButton(
                                    onPressed: auth.isBusy
                                        ? null
                                        : () => Navigator.maybePop(context),
                                    child: Text(l.t('signup_have_account')),
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
