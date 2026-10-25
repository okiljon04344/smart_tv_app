import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_provider.dart';
import '../../services/favorites_provider.dart';
import '../../services/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/tv_key_helper.dart';
import '../../widgets/tv_button.dart';
import '../../widgets/tv_focusable.dart';
import '../admin_screen.dart';

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
    final colors = context.colors;
    final items = _buildItems(l);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            border: Border(right: BorderSide(color: colors.outline)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
                child: Text(
                  l.t('settings_title'),
                  style: context.text.headlineMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => _buildMenuItem(ctx, i, items[i]),
                ),
              ),
            ],
          ),
        ),
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
    );
  }

  Widget _buildMenuItem(BuildContext context, int i, (IconData, String) item) {
    final colors = context.colors;
    return Focus(
      focusNode: _menuNodes[i],
      onFocusChange: (hasFocus) {
        if (hasFocus && _selectedIndex != i) {
          setState(() => _selectedIndex = i);
        }
      },
      onKeyEvent: (node, event) {
        if (isTvActivateEvent(event)) {
          _openDetailsPanel(i);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _openDetailsPanel(i);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          widget.onExitToSidebar();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (bctx) {
          final focused = Focus.of(bctx).hasFocus;
          final selected = _selectedIndex == i;
          final emphasised = focused || selected;
          return GestureDetector(
            onTap: () => _openDetailsPanel(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              foregroundDecoration: focusRing(colors, focused),
              decoration: BoxDecoration(
                color: emphasised
                    ? colors.surfaceContainerHigh
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: Row(
                children: [
                  Icon(
                    item.$1,
                    color: emphasised
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: context.text.bodyLarge?.copyWith(
                        color: emphasised
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
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
        return _buildNetwork(context, l);
      case 4:
        return _buildLanguage(context, l);
      case 5:
        return _buildPrivacy(context, l);
      case 6:
        return _buildAbout(context, l);
      default:
        return const SizedBox();
    }
  }

  Widget _buildProfile(BuildContext context, LocaleProvider l) {
    final colors = context.colors;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?.displayName?.trim();
    final displayName = (name != null && name.isNotEmpty)
        ? name
        : l.t('settings_profile_name_val');
    final email = user?.email ?? l.t('settings_profile_email_none');

    return _PanelScaffold(
      title: l.t('settings_profile'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceContainerHigh,
              border: Border.all(color: colors.outline),
            ),
            child: Icon(
              Icons.person_outline,
              color: colors.onSurfaceVariant,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: l.t('settings_profile_name'), value: displayName),
          _InfoRow(label: l.t('settings_profile_email'), value: email),
          _InfoRow(
            label: l.t('settings_profile_plan'),
            value: auth.isSignedIn
                ? l.t('settings_profile_plan_val')
                : l.t('settings_profile_plan_guest'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TvButton(
                icon: auth.isSignedIn ? Icons.logout : Icons.login,
                label: auth.isBusy
                    ? l.t('settings_profile_login_busy')
                    : auth.isSignedIn
                    ? l.t('settings_profile_logout')
                    : l.t('settings_profile_login'),
                tone: auth.isSignedIn
                    ? TvButtonTone.secondary
                    : TvButtonTone.primary,
                onTap: () => _handleAuthAction(context, l, auth),
              ),
              if (auth.isAdmin && isAdminSupportedPlatform(context)) ...[
                const SizedBox(width: 12),
                TvButton(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin Panel',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  ),
                ),
              ],
            ],
          ),
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
          backgroundColor: context.colors.error,
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
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Widget _buildDisplay(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          _InfoRow(
            label: l.t('settings_display_theme'),
            value: l.t('settings_display_theme_dark'),
          ),
        ],
      ),
    );
  }

  Widget _buildSound(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
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
          const SizedBox(height: 16),
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

  Widget _buildNetwork(BuildContext context, LocaleProvider l) {
    final colors = context.colors;
    return _PanelScaffold(
      title: l.t('settings_network'),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.wifi, color: colors.onSurface, size: 28),
              const SizedBox(width: 12),
              Text(
                l.t('settings_network_connected'),
                style: context.text.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
            borderRadius: BorderRadius.circular(3),
            child: const LinearProgressIndicator(value: 0.75, minHeight: 6),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '75%',
              style: context.text.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguage(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
      title: l.t('settings_language'),
      child: Column(
        children: [
          _LangTile(code: 'uz', label: l.t('lang_uz'), current: l.locale),
          const SizedBox(height: 12),
          _LangTile(code: 'ru', label: l.t('lang_ru'), current: l.locale),
          const SizedBox(height: 12),
          _LangTile(code: 'en', label: l.t('lang_en'), current: l.locale),
        ],
      ),
    );
  }

  Widget _buildPrivacy(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
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
              Icon(Icons.history, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                l.t('settings_privacy_history'),
                style: context.text.bodyLarge,
              ),
              const Spacer(),
              TvButton(
                icon: _historyCleared ? Icons.check : null,
                label: l.t('settings_privacy_history_clear'),
                tone: TvButtonTone.danger,
                onTap: () => _clearHistory(context, l),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbout(BuildContext context, LocaleProvider l) {
    final colors = context.colors;
    return _PanelScaffold(
      title: l.t('settings_about'),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.tv, color: colors.onSurface, size: 48),
                const SizedBox(height: 8),
                Text(
                  'SMART TV',
                  style: context.text.titleMedium?.copyWith(letterSpacing: 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _PanelScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _PanelScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding + 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.headlineMedium),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.colors.outline),
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
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final colors = context.colors;
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus && _isEditing) {
          _setEditing(false, save: true);
        }
      },
      onKeyEvent: (node, event) {
        if (isTvActivateEvent(event)) {
          if (!_isEnabled) return KeyEventResult.handled;
          _setEditing(!_isEditing, save: _isEditing);
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
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            foregroundDecoration: focusRing(colors, focused || _isEditing),
            decoration: BoxDecoration(
              color: focused || _isEditing
                  ? colors.surfaceContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: colors.onSurfaceVariant, size: 22),
                    const SizedBox(width: 12),
                    Text(widget.label, style: context.text.bodyLarge),
                    const Spacer(),
                    Text(
                      '${(widget.value * 100).round()}%',
                      style: context.text.bodyMedium?.copyWith(
                        color: _isEditing
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        fontWeight: _isEditing
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                ExcludeFocus(
                  child: Slider(
                    value: widget.value,
                    onChanged: widget.onChanged,
                    onChangeEnd: (_) => widget.onSaved(),
                  ),
                ),
                if (focused)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _isEditing ? 'ENTER - Save' : 'ENTER - Edit',
                      style: context.text.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
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
    final colors = context.colors;
    return TvFocusable(
      onActivate: () => onChanged(!value),
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundDecoration: focusRing(colors, focused),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? colors.onSurface : colors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(label, style: context.text.bodyLarge),
            const Spacer(),
            ExcludeFocus(
              child: Switch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String code;
  final String label;
  final String current;
  const _LangTile({
    required this.code,
    required this.label,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSelected = code == current;
    return TvFocusable(
      autofocus: isSelected,
      onActivate: () =>
          Provider.of<LocaleProvider>(context, listen: false).setLocale(code),
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        foregroundDecoration: focusRing(colors, focused),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outline,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                code.toUpperCase(),
                style: context.text.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
            ),
            Text(label, style: context.text.bodyLarge),
            const Spacer(),
            if (isSelected) Icon(Icons.check, color: colors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
