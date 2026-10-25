import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin_screen.dart';
import '../../services/auth_provider.dart';
import '../../services/locale_provider.dart';
import '../../services/favorites_provider.dart';
import '../../utils/tv_key_helper.dart';

// ─── Settings Screen ──────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  final VoidCallback onExitToSidebar;
  const SettingsScreen({super.key, required this.onExitToSidebar});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kBrightness = 'settings_brightness';
  static const _kContrast = 'settings_contrast';
  static const _kVolume = 'settings_volume';
  static const _kMuted = 'settings_muted';
  static const _kSoundEffects = 'settings_sound_effects';
  static const _kParentalControl = 'settings_parental_control';

  int _selectedIndex = 0;
  final FocusScopeNode _rightPanelScope = FocusScopeNode();
  late final List<FocusNode> _menuNodes;

  // Mutable state
  double _brightness = 0.7;
  double _contrast = 0.6;
  double _volume = 0.8;
  bool _muted = false;
  bool _soundEffects = true;
  bool _parentalControl = false;
  bool _historyCleared = false;

  @override
  void initState() {
    super.initState();
    _menuNodes = List.generate(
      7,
      (i) => FocusNode(debugLabel: 'settings_menu_$i'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusSelectedMenuItem();
    });
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _brightness = prefs.getDouble(_kBrightness) ?? 0.7;
      _contrast = prefs.getDouble(_kContrast) ?? 0.6;
      _volume = prefs.getDouble(_kVolume) ?? 0.8;
      _muted = prefs.getBool(_kMuted) ?? false;
      _soundEffects = prefs.getBool(_kSoundEffects) ?? true;
      _parentalControl = prefs.getBool(_kParentalControl) ?? false;
    });
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value.clamp(0.0, 1.0));
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _focusSelectedMenuItem() {
    if (!mounted) return;
    final i = _selectedIndex.clamp(0, _menuNodes.length - 1);
    _menuNodes[i].requestFocus();
  }

  void _openDetailsPanel(int i) {
    if (_selectedIndex != i) {
      setState(() => _selectedIndex = i);
    }
    _rightPanelScope.requestFocus();
  }

  @override
  void dispose() {
    _rightPanelScope.dispose();
    for (final n in _menuNodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context);
    final items = _buildItems(l);

    return Container(
      color: const Color(0xFF0A0A0F),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: settings list
          Container(
            width: 280,
            color: const Color(0xFF0D0D14),
            foregroundDecoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
                  child: Text(
                    l.t('settings_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return Focus(
                        focusNode: _menuNodes[i],
                        onFocusChange: (hasFocus) {
                          if (hasFocus && _selectedIndex != i) {
                            setState(() => _selectedIndex = i);
                          }
                        },
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent || event is KeyUpEvent) {
                            if (_isTvActivateEvent(event)) {
                              _openDetailsPanel(i);
                              return KeyEventResult.handled;
                            }
                            if (event is KeyDownEvent &&
                                event.logicalKey ==
                                    LogicalKeyboardKey.arrowRight) {
                              _openDetailsPanel(i);
                              return KeyEventResult.handled;
                            }
                            if (event is KeyDownEvent &&
                                event.logicalKey ==
                                    LogicalKeyboardKey.arrowLeft) {
                              widget.onExitToSidebar();
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(
                          builder: (bctx) {
                            final focused = Focus.of(bctx).hasFocus;
                            final selected = _selectedIndex == i;
                            return GestureDetector(
                              onTap: () => _openDetailsPanel(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: focused
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : selected
                                      ? const Color(
                                          0xFF6C63FF,
                                        ).withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: focused
                                        ? const Color(0xFF6C63FF)
                                        : selected
                                        ? const Color(
                                            0xFF6C63FF,
                                          ).withValues(alpha: 0.5)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.$1,
                                      color: focused || selected
                                          ? const Color(0xFF6C63FF)
                                          : Colors.white.withValues(alpha: 0.5),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      item.$2,
                                      style: TextStyle(
                                        color: focused || selected
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                        fontSize: 15,
                                        fontWeight: focused || selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (selected)
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF6C63FF),
                                        size: 18,
                                      ),
                                  ],
                                ),
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
          ),
          // Right: detail panel
          Expanded(
            child: FocusScope(
              node: _rightPanelScope,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  _focusSelectedMenuItem();
                  return KeyEventResult.handled;
                }
                if (isTvBackEvent(event)) {
                  _focusSelectedMenuItem();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: _buildDetailPanel(context, l),
            ),
          ),
        ],
      ),
    );
  }

  List<(IconData, String)> _buildItems(LocaleProvider l) => [
    (Icons.account_circle_outlined, l.t('settings_profile')),
    (Icons.display_settings_outlined, l.t('settings_display')),
    (Icons.volume_up_outlined, l.t('settings_sound')),
    (Icons.wifi_outlined, l.t('settings_network')),
    (Icons.language_outlined, l.t('settings_language')),
    (Icons.security_outlined, l.t('settings_privacy')),
    (Icons.info_outline, l.t('settings_about')),
  ];

  Widget _buildDetailPanel(BuildContext context, LocaleProvider l) {
    switch (_selectedIndex) {
      case 0:
        return _buildProfile(context, l);
      case 1:
        return _buildDisplay(context, l);
      case 2:
        return _buildSound(context, l);
      case 3:
        return _buildNetwork(l);
      case 4:
        return _buildLanguage(context, l);
      case 5:
        return _buildPrivacy(context, l);
      case 6:
        return _buildAbout(l);
      default:
        return const SizedBox();
    }
  }

  // ── Profile ──────────────────────────────────────────────────────────────────
  Widget _buildProfile(BuildContext context, LocaleProvider l) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : l.t('settings_profile_name_val');
    final email = user?.email ?? l.t('settings_profile_email_none');

    return _PanelScaffold(
      icon: Icons.account_circle_outlined,
      title: l.t('settings_profile'),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              border: Border.all(color: const Color(0xFF6C63FF), width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          _InfoRow(label: l.t('settings_profile_name'), value: displayName),
          _InfoRow(label: l.t('settings_profile_email'), value: email),
          _InfoRow(
            label: l.t('settings_profile_plan'),
            value: auth.isSignedIn
                ? l.t('settings_profile_plan_val')
                : l.t('settings_profile_plan_guest'),
          ),
          const SizedBox(height: 14),
          Focus(
            onKeyEvent: (node, event) {
              if (_isTvActivateEvent(event)) {
                _handleAuthAction(context, l, auth);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Builder(
              builder: (ctx) {
                final focused = Focus.of(ctx).hasFocus;
                return GestureDetector(
                  onTap: () => _handleAuthAction(context, l, auth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: focused
                          ? Colors.white
                          : const Color(0xFF6C63FF).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: focused
                            ? Colors.white
                            : const Color(0xFF6C63FF).withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          auth.isSignedIn ? Icons.logout : Icons.login,
                          color: focused
                              ? Colors.black
                              : const Color(0xFF6C63FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          auth.isBusy
                              ? l.t('settings_profile_login_busy')
                              : auth.isSignedIn
                              ? l.t('settings_profile_logout')
                              : l.t('settings_profile_login'),
                          style: TextStyle(
                            color: focused
                                ? Colors.black
                                : const Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (auth.isAdmin && isAdminSupportedPlatform(context)) ...[
            const SizedBox(height: 12),
            Focus(
              onKeyEvent: (node, event) {
                if (_isTvActivateEvent(event)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (ctx) {
                  final focused = Focus.of(ctx).hasFocus;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: focused
                            ? Colors.white
                            : const Color(0xFF00C853).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: focused
                              ? Colors.white
                              : const Color(0xFF00C853).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            color: focused
                                ? Colors.black
                                : const Color(0xFF00C853),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Panel',
                            style: TextStyle(
                              color: focused
                                  ? Colors.black
                                  : const Color(0xFF00C853),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAuthAction(
    BuildContext context,
    LocaleProvider l,
    AuthProvider auth,
  ) async {
    if (auth.isBusy) return;

    if (auth.isSignedIn) {
      await auth.signOut();
    } else {
      await auth.signIn();
    }

    if (!context.mounted) return;

    final err = auth.error;
    if (err != null && err.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.t('settings_profile_auth_error')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      auth.clearError();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          auth.isSignedIn
              ? l.t('settings_profile_signed_in')
              : l.t('settings_profile_signed_out'),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  // ── Display ───────────────────────────────────────────────────────────────────
  Widget _buildDisplay(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.display_settings_outlined,
      title: l.t('settings_display'),
      child: Column(
        children: [
          _SliderRow(
            label: l.t('settings_display_brightness'),
            icon: Icons.brightness_6_outlined,
            value: _brightness,
            onChanged: (v) => setState(() => _brightness = v),
            onSaved: () {
              unawaited(_saveDouble(_kBrightness, _brightness));
              _showSaved(context, l);
            },
          ),
          const SizedBox(height: 20),
          _SliderRow(
            label: l.t('settings_display_contrast'),
            icon: Icons.contrast,
            value: _contrast,
            onChanged: (v) => setState(() => _contrast = v),
            onSaved: () {
              unawaited(_saveDouble(_kContrast, _contrast));
              _showSaved(context, l);
            },
          ),
          const SizedBox(height: 20),
          _InfoRow(
            label: l.t('settings_display_theme'),
            value: l.t('settings_display_theme_dark'),
          ),
        ],
      ),
    );
  }

  // ── Sound ─────────────────────────────────────────────────────────────────────
  Widget _buildSound(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.volume_up_outlined,
      title: l.t('settings_sound'),
      child: Column(
        children: [
          _SliderRow(
            label: l.t('settings_sound_volume'),
            icon: _muted ? Icons.volume_off : Icons.volume_up,
            value: _muted ? 0 : _volume,
            onChanged: _muted ? null : (v) => setState(() => _volume = v),
            onSaved: () {
              unawaited(_saveDouble(_kVolume, _volume));
              _showSaved(context, l);
            },
          ),
          const SizedBox(height: 20),
          _ToggleRow(
            label: l.t('settings_sound_mute'),
            icon: Icons.volume_off_outlined,
            value: _muted,
            onChanged: (v) {
              setState(() => _muted = v);
              unawaited(_saveBool(_kMuted, v));
              _showSaved(context, l);
            },
          ),
          const SizedBox(height: 12),
          _ToggleRow(
            label: l.t('settings_sound_effects'),
            icon: Icons.music_note_outlined,
            value: _soundEffects,
            onChanged: (v) {
              setState(() => _soundEffects = v);
              unawaited(_saveBool(_kSoundEffects, v));
              _showSaved(context, l);
            },
          ),
        ],
      ),
    );
  }

  // ── Network ───────────────────────────────────────────────────────────────────
  Widget _buildNetwork(LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.wifi_outlined,
      title: l.t('settings_network'),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.wifi, color: Color(0xFF4CAF50), size: 28),
              const SizedBox(width: 12),
              Text(
                l.t('settings_network_connected'),
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(
            label: l.t('settings_network_type'),
            value: l.t('settings_network_type_val'),
          ),
          _InfoRow(
            label: l.t('settings_network_speed'),
            value: l.t('settings_network_speed_val'),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Color(0xFF2A2A3E),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '75%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Language ─────────────────────────────────────────────────────────────────
  Widget _buildLanguage(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.language_outlined,
      title: l.t('settings_language'),
      child: Column(
        children: [
          _LangTile(
            code: 'uz',
            label: l.t('lang_uz'),
            flag: '🇺🇿',
            current: l.locale,
          ),
          const SizedBox(height: 10),
          _LangTile(
            code: 'ru',
            label: l.t('lang_ru'),
            flag: '🇷🇺',
            current: l.locale,
          ),
          const SizedBox(height: 10),
          _LangTile(
            code: 'en',
            label: l.t('lang_en'),
            flag: '🇬🇧',
            current: l.locale,
          ),
        ],
      ),
    );
  }

  // ── Privacy ───────────────────────────────────────────────────────────────────
  Widget _buildPrivacy(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.security_outlined,
      title: l.t('settings_privacy'),
      child: Column(
        children: [
          _ToggleRow(
            label: l.t('settings_privacy_parental'),
            icon: Icons.child_care_outlined,
            value: _parentalControl,
            onChanged: (v) {
              setState(() => _parentalControl = v);
              unawaited(_saveBool(_kParentalControl, v));
              _showSaved(context, l);
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF6C63FF), size: 22),
              const SizedBox(width: 12),
              Text(
                l.t('settings_privacy_history'),
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const Spacer(),
              Focus(
                onKeyEvent: (node, event) {
                  if (_isTvActivateEvent(event)) {
                    _clearHistory(context, l);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (bctx) {
                    final focused = Focus.of(bctx).hasFocus;
                    return GestureDetector(
                      onTap: () => _clearHistory(context, l),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: focused
                              ? Colors.red
                              : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: focused
                                ? Colors.red
                                : Colors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _historyCleared
                              ? '✓'
                              : l.t('settings_privacy_history_clear'),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── About ─────────────────────────────────────────────────────────────────────
  Widget _buildAbout(LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.info_outline,
      title: l.t('settings_about'),
      child: Column(
        children: [
          const Center(
            child: Column(
              children: [
                Icon(Icons.tv, color: Color(0xFF6C63FF), size: 56),
                SizedBox(height: 8),
                Text(
                  'SMART TV',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _InfoRow(label: l.t('settings_about_version'), value: '1.0.0'),
          _InfoRow(label: l.t('settings_about_build'), value: '2026.05.12'),
          _InfoRow(
            label: l.t('settings_about_developer'),
            value: l.t('settings_about_developer_val'),
          ),
          _InfoRow(
            label: l.t('settings_about_license'),
            value: l.t('settings_about_license_val'),
          ),
        ],
      ),
    );
  }

  void _showSaved(BuildContext context, LocaleProvider l) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.t('settings_saved')),
        backgroundColor: const Color(0xFF6C63FF),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _clearHistory(BuildContext context, LocaleProvider l) {
    context.read<FavoritesProvider>().clearWatchHistory();
    setState(() => _historyCleared = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _historyCleared = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.t('settings_privacy_history_cleared')),
        backgroundColor: const Color(0xFF6C63FF),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Settings Helper Widgets ──────────────────────────────────────────────────

class _PanelScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _PanelScaffold({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(36, 36, 36, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6C63FF), size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

bool _isTvActivateEvent(KeyEvent event) => isTvActivateEvent(event);

class _SliderRow extends StatefulWidget {
  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double>? onChanged;
  final VoidCallback onSaved;
  const _SliderRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.onSaved,
  });

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  static const double _step = 0.05;
  bool _isEditing = false;

  bool get _isEnabled => widget.onChanged != null;

  void _setEditing(bool value, {bool save = false}) {
    if (_isEditing == value) return;
    setState(() => _isEditing = value);
    if (save) widget.onSaved();
  }

  void _changeBy(double delta) {
    if (!_isEnabled) return;
    final next = (widget.value + delta).clamp(0.0, 1.0);
    if (next != widget.value) {
      widget.onChanged?.call(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus && _isEditing) {
          _setEditing(false, save: true);
        }
      },
      onKeyEvent: (node, event) {
        if (_isTvActivateEvent(event)) {
          if (!_isEnabled) return KeyEventResult.handled;
          if (_isEditing) {
            _setEditing(false, save: true);
          } else {
            _setEditing(true);
          }
          return KeyEventResult.handled;
        }

        if (event is KeyDownEvent && _isEditing) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _changeBy(_step);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _changeBy(-_step);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _setEditing(false, save: true);
            return KeyEventResult.ignored;
          }
        }

        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          final active = focused || _isEditing;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isEditing
                    ? const Color(0xFF6C63FF)
                    : focused
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: const Color(0xFF6C63FF), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${(widget.value * 100).round()}%',
                      style: TextStyle(
                        color: _isEditing
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        fontWeight: _isEditing
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                ExcludeFocus(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF6C63FF),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                      thumbColor: const Color(0xFF6C63FF),
                      overlayColor: const Color(
                        0xFF6C63FF,
                      ).withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: widget.value,
                      onChanged: widget.onChanged,
                      onChangeEnd: (_) => widget.onSaved(),
                    ),
                  ),
                ),
                if (focused)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _isEditing ? 'ENTER - Save' : 'ENTER - Edit',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (_isTvActivateEvent(event)) {
          onChanged(!value);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: focused
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: focused
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: value
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  ExcludeFocus(
                    child: Switch(
                      value: value,
                      onChanged: onChanged,
                      activeThumbColor: const Color(0xFF6C63FF),
                      activeTrackColor: const Color(
                        0xFF6C63FF,
                      ).withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String code;
  final String label;
  final String flag;
  final String current;
  const _LangTile({
    required this.code,
    required this.label,
    required this.flag,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = code == current;
    return Focus(
      autofocus: isSelected,
      onKeyEvent: (node, event) {
        if (_isTvActivateEvent(event)) {
          _select(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return GestureDetector(
            onTap: () => _select(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.18)
                    : focused
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : focused
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF6C63FF),
                      size: 22,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _select(BuildContext context) {
    Provider.of<LocaleProvider>(context, listen: false).setLocale(code);
  }
}
