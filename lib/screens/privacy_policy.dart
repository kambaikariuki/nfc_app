import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MatPay Privacy Policy',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: 13 November 2026',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 25),

            _section(
              '1. Introduction',
              'MatPay is an NFC-based cashless fare collection '
              'application designed to facilitate digital fare '
              'payments between passengers and transport operators. '
              'This policy explains how MatPay collects, uses, '
              'stores and protects personal information.',
            ),

            _section(
              '2. Information We Collect',
              'Personal information:\n'
              '• Full name\n'
              '• Email address\n'
              '• Hashed account passwords\n\n'
              'NFC card information:\n'
              '• NFC card unique identifier (UID)\n'
              '• Card registration and activation status\n\n'
              'Transaction information:\n'
              '• Passenger and operator wallet balances\n'
              '• Fare amounts\n'
              '• Transaction dates and timestamps\n'
              '• Transaction records and statuses',
            ),

            _section(
              '3. How We Use Your Information',
              'We use collected information to:\n'
              '• Create and manage user accounts.\n'
              '• Authenticate passengers and operators.\n'
              '• Register NFC cards.\n'
              '• Process digital fare payments.\n'
              '• Update wallet balances.\n'
              '• Maintain transaction histories.\n'
              '• Improve application functionality and security.',
            ),

            _section(
              '4. Data Storage and Security',
              'User information is stored in the MatPay backend '
              'database. Security measures include password hashing, '
              'token-based authentication, role-based access '
              'restrictions and database constraints designed to '
              'maintain transaction accuracy. No digital system '
              'can guarantee absolute security.',
            ),

            _section(
              '5. Sharing of Information',
              'MatPay does not intend to sell personal information. '
              'Information may be processed by infrastructure '
              'providers involved in hosting and operating the '
              'application. Information may also be disclosed '
              'where required by applicable law.',
            ),

            _section(
              '6. Data Retention',
              'Information is retained for as long as necessary '
              'to provide MatPay services, maintain transaction '
              'records, resolve disputes and meet applicable '
              'legal obligations. Users may request information '
              'about their stored data or request account deletion, '
              'subject to applicable requirements.',
            ),

            _section(
              '7. Your Privacy Rights',
              'Subject to applicable data protection laws, users '
              'may request access to their personal information, '
              'correction of inaccurate information, deletion '
              'where applicable and information about how their '
              'data is processed.',
            ),

            _section(
              '8. Changes to This Policy',
              'MatPay may update this Privacy Policy when its '
              'functionality, data practices or applicable legal '
              'requirements change. The latest version will be '
              'made available through the application.',
            ),

            _section(
              '9. Contact Us',
              'For questions or concerns regarding this Privacy '
              'Policy, please contact the MatPay support team '
              'through the official support email address:\n\n'
              'j.kariuki@alustudent.com\n'
              'Kenya',
            ),

            const Divider(),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '© 2026 MatPay. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
