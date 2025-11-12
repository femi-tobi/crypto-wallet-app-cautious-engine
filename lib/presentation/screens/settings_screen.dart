import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo; // ← Now nullable
  bool _biometricEnabled = false;
  bool _pushNotifications = true;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadPackageInfo(); // ← Async, no problem
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _packageInfo = info);
    }
  }

  Future<void> _loadPrefs() async {
    final box = Hive.box('settings');
    setState(() {
      _biometricEnabled = box.get('biometric', defaultValue: false);
      _pushNotifications = box.get('push', defaultValue: true);
      _currency = box.get('currency', defaultValue: 'USD');
    });
  }

  Future<void> _save(String key, dynamic value) async {
    await Hive.box('settings').put(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _sectionHeader('Profile'),
          _profileTile(context),

          const Divider(height: 32),
          _sectionHeader('Security'),
          _switchTile(
            title: 'Biometric Unlock',
            subtitle: 'Use Face ID / Fingerprint',
            value: _biometricEnabled,
            onChanged: (v) => setState(() {
              _biometricEnabled = v;
              _save('biometric', v);
            }),
          ),
          _tile(
            icon: Icons.lock_outline,
            title: 'Change Passcode',
            onTap: () => _showPasscodeDialog(context),
          ),
          _tile(
            icon: Icons.phonelink_lock,
            title: 'Two‑Factor Authentication',
            trailing: const Text('Not set up', style: TextStyle(color: Colors.orange)),
            onTap: () => _show2FADialog(context),
          ),

          const Divider(height: 32),
          _sectionHeader('Preferences'),
          _switchTile(
            title: 'Push Notifications',
            subtitle: 'Price alerts, transactions, security',
            value: _pushNotifications,
            onChanged: (v) => setState(() {
              _pushNotifications = v;
              _save('push', v);
            }),
          ),
          _tile(
            icon: Icons.language,
            title: 'Display Currency',
            trailing: Text(_currency),
            onTap: () => _showCurrencyPicker(context),
          ),
          _tile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (v) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
            ),
          ),

          const Divider(height: 32),
          _sectionHeader('Support'),
          _tile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () => _launchURL('https://krypton.app/help'),
          ),
          _tile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            onTap: () => _launchURL('mailto:support@krypton.app'),
          ),
          _tile(
            icon: Icons.share_outlined,
            title: 'Share Krypton',
            onTap: () => Share.share('Check out Krypton – the safest crypto wallet! https://krypton.app'),
          ),

          const Divider(height: 32),
          _sectionHeader('Legal'),
          _tile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _launchURL('https://krypton.app/privacy'),
          ),
          _tile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _launchURL('https://krypton.app/terms'),
          ),

          const Divider(height: 32),
          _sectionHeader('About'),
          _tile(
            icon: Icons.info_outline,
            title: 'Version',
            trailing: Text(
              _packageInfo?.version ?? 'Loading...',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          _tile(
            icon: Icons.code,
            title: 'Open Source Licenses',
            onTap: () => showLicensePage(context: context),
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              'Made with love by Krypton Team',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8, top: 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.cyanAccent),
        ),
      );

  Widget _profileTile(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
        child: const Icon(Icons.person, size: 28, color: Colors.cyanAccent),
      ),
      title: const Text('Tobi Ade', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('tobi@example.com'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
    );
  }

  Widget _tile({required IconData icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyanAccent),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _switchTile({required String title, String? subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      secondary: const Icon(Icons.toggle_on, color: Colors.cyanAccent),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      value: value,
      onChanged: onChanged,
      activeColor: Colors.cyanAccent,
    );
  }

  void _showPasscodeDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Change Passcode'), content: Text('Coming soon!')));
  }

  void _show2FADialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AlertDialog(title: Text('2FA Setup'), content: Text('Scan QR code (coming soon)')));
  }

  void _showCurrencyPicker(BuildContext context) {
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'BTC'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: currencies.length,
        itemBuilder: (ctx, i) {
          final cur = currencies[i];
          return ListTile(
            title: Text(cur),
            trailing: _currency == cur ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
            onTap: () {
              setState(() => _currency = cur);
              _save('currency', cur);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }
}

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Edit Profile')), body: const Center(child: Text('Coming soon')));
}