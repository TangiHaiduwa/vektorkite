import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vektorkite/core/routing/route_paths.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFEAF4FF),
                              Color(0xFFE8FBF4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 22,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -18,
                      right: -20,
                      child: _Bubble(
                        size: 130,
                        color: const Color(0x330EA5A6),
                      ),
                    ),
                    Positioned(
                      bottom: -34,
                      left: -26,
                      child: _Bubble(
                        size: 120,
                        color: const Color(0x332563EB),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Namibia Service + Marketplace',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'VektorKite',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    color: const Color(0xFF0F172A),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Book trusted professionals, discover products, and manage everything in one clean experience.',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: const [
                                _MetricChip(
                                  label: 'Verified',
                                  value: 'Providers',
                                  color: Color(0xFFE0F2FE),
                                  textColor: Color(0xFF0C4A6E),
                                ),
                                SizedBox(width: 8),
                                _MetricChip(
                                  label: 'Auto',
                                  value: 'Matching',
                                  color: Color(0xFFDCFCE7),
                                  textColor: Color(0xFF14532D),
                                ),
                                SizedBox(width: 8),
                                _MetricChip(
                                  label: 'Live',
                                  value: 'Tracking',
                                  color: Color(0xFFF5F3FF),
                                  textColor: Color(0xFF4C1D95),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _FeatureTile(
                                    icon: Icons.verified_user_outlined,
                                    title: 'Trusted Pros',
                                    subtitle: 'Ratings and verified status',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _FeatureTile(
                                    icon: Icons.flash_on_outlined,
                                    title: 'Fast Flow',
                                    subtitle: 'Book now or schedule',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _FeatureTile(
                              icon: Icons.storefront_outlined,
                              title: 'Marketplace Built-in',
                              subtitle: 'Products from approved stores and providers',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => context.push(RoutePaths.signIn),
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => context.push(RoutePaths.signUp),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Powerd By Starkite Technologies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F4),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: const Color(0xFF0F766E)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
