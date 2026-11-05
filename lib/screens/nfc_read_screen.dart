import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';


class NfcReadScreen extends StatefulWidget {
  final double amount;

  const NfcReadScreen({
    super.key,
    required this.amount,
  });

  @override
  State<NfcReadScreen> createState() => _NfcReadScreenState();
}

class _NfcReadScreenState extends State<NfcReadScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _titleFade;
  late Animation<double> _amountFade;
  late Animation<double> _iconFade;
  late Animation<double> _hintFade;

  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  late Animation<double> _pulse3;

  bool _checkingNfc = true;
  bool _nfcEnabled = false;
  bool _sessionStarted = false;
  bool _cardDetected = false;

  String _statusMessage = 'Checking NFC...';
  String _hintMessage = 'Please wait.';

  String? _cardUid;

  // Check NFC availability
  Future<void> _checkAndStartNfc() async {
    if (!mounted) return;

    setState(() {
      _checkingNfc = true;
      _nfcEnabled = false;
      _cardDetected = false;
      _cardUid = null;
      _statusMessage = 'Checking NFC...';
      _hintMessage = 'Please wait.';
    });

    try {
      final available = await NfcManager.instance.isAvailable();

      if (!mounted) return;

      if (!available) {
        setState(() {
          _checkingNfc = false;
          _nfcEnabled = false;
          _statusMessage = 'NFC unavailable';
          _hintMessage =
              'This device does not have NFC available or it is turned off.\nPlease check your phone settings.';
        });

        return;
      }

      setState(() {
        _checkingNfc = false;
        _nfcEnabled = true;
        _statusMessage = 'Waiting for card...';
        _hintMessage =
            'Ask the passenger to tap their NTAG213 card here.';
      });

      await _startNfcSession();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _checkingNfc = false;
        _nfcEnabled = false;
        _statusMessage = 'Unable to check NFC';
        _hintMessage = 'Please check your device settings and try again.';
      });
    }
  }

  // Start NFC scanning
  Future<void> _startNfcSession() async {
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
        },
        onDiscovered: (NfcTag tag) async {
          if (!mounted || _cardDetected) return;

          // NTAG213 uses NFC-A / ISO 14443 Type A
          final androidTag = NfcTagAndroid.from(tag);

if (androidTag == null) {
  setState(() {
    _statusMessage = 'Unable to read this NFC card.';
  });
  return;
}

final cardUid = androidTag.id
    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    .join()
    .toUpperCase();

setState(() {
  _cardUid = cardUid;
  _cardDetected = true;
  _statusMessage = 'Card detected successfully!';
});

await NfcManager.instance.stopSession();
          _sessionStarted = false;
        },
      );

      _sessionStarted = true;
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _nfcEnabled = false;
        _statusMessage = 'NFC scanning failed';
        _hintMessage = 'Unable to start scanning. Please try again.';
      });
    }
  }

  // Retry NFC scanning
  Future<void> _retryScanning() async {
    if (_sessionStarted) {
      await NfcManager.instance.stopSession();
      _sessionStarted = false;
    }

    await _checkAndStartNfc();
  }

  @override
  void initState() {
    super.initState();

    // Fade-in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _titleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    _amountFade = CurvedAnimation(
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

    // Ripple animation
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

    // Check NFC when screen opens
    _checkAndStartNfc();
  }

  @override
  void dispose() {
    if (_sessionStarted) {
      NfcManager.instance.stopSession();
    }

    _fadeController.dispose();
    _pulseController.dispose();

    super.dispose();
  }

  // Build expanding NFC rings
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
    final formattedAmount =
        'KES ${widget.amount.toStringAsFixed(2)}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
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
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // Title
                  FadeTransition(
                    opacity: _titleFade,
                    child: const Text(
                      'Ready to Collect',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Amount
                  FadeTransition(
                    opacity: _amountFade,
                    child: Text(
                      formattedAmount,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // NFC animation
                  FadeTransition(
                    opacity: _iconFade,
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_nfcEnabled && !_cardDetected) ...[
                            _buildRing(_pulse1, 120),
                            _buildRing(_pulse2, 120),
                            _buildRing(_pulse3, 120),
                          ],

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
                            child: _checkingNfc
                                ? const Padding(
                                    padding: EdgeInsets.all(28),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _cardDetected
                                        ? Icons.check_circle_outline
                                        : _nfcEnabled
                                            ? Icons.contactless_rounded
                                            : Icons.nfc_rounded,
                                    color: _cardDetected
                                        ? Colors.greenAccent
                                        : Colors.white,
                                    size: 48,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // NFC status and instructions
                  FadeTransition(
                    opacity: _hintFade,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        children: [
                          Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _cardDetected
                                  ? Colors.greenAccent
                                  : _nfcEnabled
                                      ? Colors.white
                                      : Colors.orangeAccent,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            _hintMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white54,
                              height: 1.6,
                            ),
                          ),

                          // Retry button
                          if (!_checkingNfc &&
                              (!_nfcEnabled || _cardDetected)) ...[
                            const SizedBox(height: 20),

                            OutlinedButton.icon(
                              onPressed: _retryScanning,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                _cardDetected
                                    ? 'Scan another card'
                                    : 'Try again',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white54,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
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
        ],
      ),
    );
  }
}