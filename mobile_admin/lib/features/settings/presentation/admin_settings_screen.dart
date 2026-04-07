import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../../auth/domain/admin_session_user.dart';
import '../data/admin_settings_service.dart';
import '../domain/admin_notification_settings.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({
    super.key,
    required this.currentUser,
    this.onLogout,
    AdminSettingsService? settingsService,
  }) : _settingsService = settingsService;

  final AdminSessionUser currentUser;
  final Future<void> Function()? onLogout;
  final AdminSettingsService? _settingsService;

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late final AdminSettingsService _settingsService;

  AdminNotificationSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  static const _reminderOptions = [
    _ReminderOption(minutes: 30, label: '30 phút trước'),
    _ReminderOption(minutes: 1440, label: '1 ngày trước'),
    _ReminderOption(minutes: 2880, label: '2 ngày trước'),
  ];

  @override
  void initState() {
    super.initState();
    _settingsService = widget._settingsService ?? AdminSettingsService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await _settingsService.fetchNotificationSettings();
      if (!mounted) {
        return;
      }

      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error is AdminApiException
            ? error.message
            : 'Không thể tải cài đặt thông báo.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings(AdminNotificationSettings nextSettings) async {
    final previous = _settings;
    if (previous == null) {
      return;
    }

    setState(() {
      _settings = nextSettings;
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final saved = await _settingsService.updateNotificationSettings(
        nextSettings,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _settings = saved;
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _settings = previous;
        _isSaving = false;
        _errorMessage = error is AdminApiException
            ? error.message
            : 'Không thể cập nhật cài đặt.';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            color: AdminAppTheme.primary,
            onRefresh: _loadSettings,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cài đặt thông báo',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quản lý cách nhận thông báo',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null && _settings == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _SettingsErrorState(
                      message: _errorMessage!,
                      onRetry: _loadSettings,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SettingsCard(
                            child: Column(
                              children: [
                                _SettingTile(
                                  icon: Icons.notifications_none_rounded,
                                  title: 'Thông báo đẩy',
                                  subtitle: 'Nhận thông báo đẩy',
                                  value: _settings!.pushEnabled,
                                  onChanged: _isSaving
                                      ? null
                                      : (value) => _saveSettings(
                                          _settings!.copyWith(
                                            pushEnabled: value,
                                          ),
                                        ),
                                ),
                                _DividerLine(),
                                _SettingTile(
                                  icon: Icons.volume_up_outlined,
                                  title: 'Âm thanh',
                                  subtitle: 'Phát âm thanh khi có thông báo',
                                  value: _settings!.soundEnabled,
                                  onChanged: _isSaving
                                      ? null
                                      : (value) => _saveSettings(
                                          _settings!.copyWith(
                                            soundEnabled: value,
                                          ),
                                        ),
                                ),
                                _DividerLine(),
                                _SettingTile(
                                  icon: Icons.watch_later_outlined,
                                  title: 'Nhắc lịch',
                                  subtitle: 'Nhắc nhở trước lịch hẹn',
                                  value: _settings!.appointmentReminder,
                                  onChanged: _isSaving
                                      ? null
                                      : (value) => _saveSettings(
                                          _settings!.copyWith(
                                            appointmentReminder: value,
                                          ),
                                        ),
                                ),
                                _DividerLine(),
                                _SettingTile(
                                  icon: Icons.sync_rounded,
                                  title: 'Cập nhật trạng thái',
                                  subtitle: 'Thông báo khi trạng thái thay đổi',
                                  value: _settings!.statusUpdates,
                                  onChanged: _isSaving
                                      ? null
                                      : (value) => _saveSettings(
                                          _settings!.copyWith(
                                            statusUpdates: value,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'THỜI GIAN NHẮC NHỞ',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontSize: 13, letterSpacing: 0.4),
                          ),
                          const SizedBox(height: 10),
                          _SettingsCard(
                            child: Column(
                              children: _reminderOptions.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final option = entry.value;
                                final isLast =
                                    index == _reminderOptions.length - 1;

                                return Column(
                                  children: [
                                    RadioListTile<int>(
                                      value: option.minutes,
                                      groupValue:
                                          _settings!.reminderLeadMinutes,
                                      onChanged:
                                          (!_settings!.appointmentReminder ||
                                              _isSaving)
                                          ? null
                                          : (value) {
                                              if (value != null) {
                                                _saveSettings(
                                                  _settings!.copyWith(
                                                    reminderLeadMinutes: value,
                                                  ),
                                                );
                                              }
                                            },
                                      activeColor: AdminAppTheme.primary,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                      title: Text(
                                        option.label,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                    ),
                                    if (!isLast) _DividerLine(),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Thông báo sẽ được gửi qua ứng dụng và email. Bạn có thể tùy chỉnh từng loại thông báo riêng biệt.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AdminAppTheme.primary),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SettingsCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFEFF4FF),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        widget.currentUser.initials,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AdminAppTheme.primary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.currentUser.fullName,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            widget.currentUser.roleLabel,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: widget.onLogout == null
                                        ? null
                                        : () async {
                                            await widget.onLogout!.call();
                                          },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF676D),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    icon: const Icon(Icons.logout_rounded),
                                    label: const Text('Đăng xuất'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: const Color(0xFFE14D55)),
                            ),
                          ],
                        ],
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AdminAppTheme.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25344D).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEFF4FF),
            ),
            child: Icon(icon, size: 20, color: AdminAppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF1CCD8B),
          ),
        ],
      ),
    );
  }
}

class _SettingsErrorState extends StatelessWidget {
  const _SettingsErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AdminAppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Không tải được cài đặt',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminAppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: AdminAppTheme.border.withOpacity(0.95));
  }
}

class _ReminderOption {
  const _ReminderOption({required this.minutes, required this.label});

  final int minutes;
  final String label;
}
