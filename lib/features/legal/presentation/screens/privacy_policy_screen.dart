import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const AppBackButton() : null,
        title: const Text('Privacy Policy'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFDFE),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Effective date: 22/02/2026', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 14),
                  Text('VektorKite collects account, booking, location, and support information required to operate a marketplace for on-demand services in Namibia.'),
                  SizedBox(height: 12),
                  Text('We use this data to match requests, process bookings, support customer safety, and improve service quality.'),
                  SizedBox(height: 12),
                  Text('Providers listed on VektorKite are independent contractors. VektorKite is a marketplace facilitator and not the direct employer of providers.'),
                  SizedBox(height: 12),
                  Text('Your profile data is protected by authentication controls, and sensitive operations require signed-in access.'),
                  SizedBox(height: 12),
                  Text('You can request profile updates or account support through the Support section in the app.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
