import 'package:flutter/material.dart';

class LinkCardScreen extends StatefulWidget {
  const LinkCardScreen({super.key});

  @override
  State<LinkCardScreen> createState() => _LinkCardScreenState();
}

class _LinkCardScreenState extends State<LinkCardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _iconFade;
  late Animation<double> _hintFade;

  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  late Animation<double> _pulse3;

  @override
  void initState() {
    super.initState();

    // Staggered fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _titleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );
    _subtitleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.2, 0.5, curve: Curves.easeIn),
    );
    _iconFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
    );
    _hintFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
    );

    _fadeController.forward();

    // Repeating ripple pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulse1 = CurvedAnimation(
      parent: _pulseController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _pulse2 = CurvedAnimation(
      parent: _pulseController,
      curve: const Interval(0.33, 1.0, curve: Curves.easeOut),
    );
    _pulse3 = CurvedAnimation(
      parent: _pulseController,
      curve: const Interval(0.66, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildRing(Animation<double> animation, double maxRadius) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final radius = animation.value * maxRadius;
        final opacity = (1.0 - animation.value).clamp(0.0, 1.0);
        return Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: opacity * 0.5),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0A2E),
                  Color(0xFF1A1A4E),
                  Color(0xFF0D2137),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // Title
                  FadeTransition(
                    opacity: _titleFade,
                    child: const Text(
                      'Link a Card',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: const Text(
                      'This card will be linked to your account\nand used for future payments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.white60,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Pulsing card icon
                  FadeTransition(
                    opacity: _iconFade,
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildRing(_pulse1, 120),
                          _buildRing(_pulse2, 120),
                          _buildRing(_pulse3, 120),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                              border: Border.all(
                                color: Colors.white38,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.credit_card_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Hint text + cancel
                  FadeTransition(
                    opacity: _hintFade,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 48.0),
                      child: Column(
                        children: [
                          const Text(
                            'Waiting for card...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hold your NFC card or device\nclose to the back of this phone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white54,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white38,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}