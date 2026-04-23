import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/features/auth/presentation/providers/auth_provider.dart';
import 'package:kairo/features/auth/presentation/widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.toString()),
            backgroundColor: const Color(0xFF93000A),
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0C141B),
      body: Stack(
        children: [
          Positioned(
            top: -110,
            left: -70,
            child: _AmbientGlow(
              size: 320,
              color: const Color(0xFFA0C9FF).withValues(alpha: 0.20),
            ),
          ),
          Positioned(
            top: 180,
            right: -90,
            child: _AmbientGlow(
              size: 280,
              color: const Color(0xFF7AD5D7).withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: -90,
            left: 20,
            child: _AmbientGlow(
              size: 240,
              color: const Color(0xFF0F4C81).withValues(alpha: 0.22),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _BrandHeader(),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF131D26,
                            ).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(
                                0xFFDBE3ED,
                              ).withValues(alpha: 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 36,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _IntroPanel(),
                              SizedBox(height: 28),
                              GoogleSignInButton(),
                              SizedBox(height: 18),
                              _FooterNote(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _SecurityBadge(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF162330),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Icon(
                  Icons.note_add_rounded,
                  color: Color(0xFFA0C9FF),
                  size: 28,
                ),
              ),
            ),
            SizedBox(width: 14),
            Text(
              'Kairo',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Color(0xFFA0C9FF),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          'YOUR CLINICAL SANCTUARY',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFC2C7D1),
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF162636).withValues(alpha: 0.95),
            const Color(0xFF10202A).withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFA0C9FF).withValues(alpha: 0.08),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFFDBE3ED),
              height: 1.1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Sign in with your Google account to securely access your symptom history, documentation, and workspace.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              height: 1.55,
              color: Color(0xFFC2C7D1),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F171E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDBE3ED).withValues(alpha: 0.06),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF7AD5D7),
            size: 18,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'New users can also use Google sign-in to create their account',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.45,
                color: Color(0xFFB4BDC9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 1,
              width: 32,
              color: const Color(0xFFDBE3ED).withValues(alpha: 0.15),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.lock_rounded,
                size: 12,
                color: Color(0xFFDBE3ED),
              ),
            ),
            Container(
              height: 1,
              width: 32,
              color: const Color(0xFFDBE3ED).withValues(alpha: 0.15),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'END-TO-END ENCRYPTED HEALTH DATA',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: Color(0xFF8C919A),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
