import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const AppBackButton() : null,
        title: const Text('Terms and Conditions'),
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
                  Text('VektorKite is a marketplace platform that connects customers with independent service providers in Namibia.'),
                  SizedBox(height: 12),
                  Text('Service providers are independent contractors and are not employees, agents, or representatives of VektorKite.'),
                  SizedBox(height: 12),
                  Text('By creating an account, you agree to these terms and the platform policies for bookings, payments, safety, and disputes.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
