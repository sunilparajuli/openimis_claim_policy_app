import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';

class AboutOpenImisPage extends StatelessWidget {
  const AboutOpenImisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: const Text('About openIMIS')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/openimis-logo.png',
                  height: 64,
                  errorBuilder: (_, _, _) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CustomColors.BrandPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      size: 48,
                      color: CustomColors.BrandPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'openIMIS Mobile Suite',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: CustomColors.BrandPurple,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Unified Claims & Policies Management',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _infoRow('App Version', '2.1.0 (Build 2026.10)'),
                  const Divider(),
                  _infoRow('Release Date', 'October 2026'),
                  const Divider(),
                  _infoRow(
                    'Core Architecture',
                    'FHIR R4 • GraphQL • SQLite Offline',
                  ),
                  const Divider(),
                  _infoRow('License', 'GNU AGPL v3.0'),
                  const Divider(),
                  _infoRow('Initiative', 'openIMIS Global Initiative'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'About the Platform',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'openIMIS is an open-source insurance management information system that seamlessly integrates beneficiary enrollment, policy renewal, claim adjudication, and quality auditing into a unified digital ecosystem.\n\nOriginally developed with the support of the Swiss Agency for Development and Cooperation (SDC) and Deutsche Gesellschaft für Internationale Zusammenarbeit (GIZ), openIMIS empowers universal health coverage initiatives worldwide.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              '© 2016-2026 openIMIS Initiative\nSDC & GIZ Development Cooperation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
