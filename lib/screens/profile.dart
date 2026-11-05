import 'package:flutter/material.dart';
import 'package:nfc_app/services/auth_service.dart';
import 'package:nfc_app/services/dashboard_service.dart';

import 'auth/log_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await DashboardService.getProfile();

      if (!mounted) return;

      setState(() {
        _profile = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint('Profile loading error: $e');
    }
  }

  static const List<Map<String, dynamic>> _settingsItems = [
    {
      'section': 'Account',
      'items': [
        {
          'icon': Icons.person_outline,
          'label': 'Edit Profile',
          'color': Color(0xFF6C63FF),
        },
        {
          'icon': Icons.lock_outline,
          'label': 'Change Password',
          'color': Color(0xFF6C63FF),
        },
        {
          'icon': Icons.credit_card_outlined,
          'label': 'Linked Cards',
          'color': Color(0xFF6C63FF),
        },
      ],
    },
    {
      'section': 'Support',
      'items': [
        {
          'icon': Icons.help_outline,
          'label': 'Help & Support',
          'color': Color(0xFFFF9800),
        },
        {
          'icon': Icons.privacy_tip_outlined,
          'label': 'Privacy Policy',
          'color': Color(0xFFFF9800),
        },
        {
          'icon': Icons.info_outline,
          'label': 'About',
          'color': Color(0xFFFF9800),
        },
      ],
    },
  ];

  Future<void> _logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 48, 48, 48),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User info header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 48, 48, 48),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLoading
                        ? 'Loading...'
                        : _profile?['full_name'] ?? 'Unknown User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile?['email'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings sections
            ..._settingsItems.map((section) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        section['section'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: (section['items'] as List).map<Widget>((
                          item,
                        ) {
                          final isLast =
                              item == (section['items'] as List).last;
                          return Column(
                            children: [
                              ListTile(
                                onTap: () {},
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: (item['color'] as Color).withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: item['color'] as Color,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  item['label'] as String,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                              if (!isLast)
                                const Divider(
                                  height: 1,
                                  indent: 68,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Logout button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Color(0xFFE53935)),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
}
