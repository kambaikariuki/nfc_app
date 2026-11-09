import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import 'package:nfc_app/services/card_service.dart';

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

  bool _checkingNfc = true;
  bool _nfcEnabled = false;
  bool _sessionStarted = false;
  bool _processing = false;
  bool _cardLinked = false;

  String _statusMessage = 'Checking NFC...';
  String _hintMessage = 'Please wait.';

  String? _cardUid;
  String? _errorMessage;

  Future<void> _checkAndStartNfc() async {
    if (!mounted) return;

    setState(() {
      _checkingNfc = true;
      _nfcEnabled = false;
      _processing = false;
      _cardLinked = false;
      _cardUid = null;
      _errorMessage = null;
      _statusMessage = 'Checking NFC...';
      _hintMessage = 'Please wait.';
    });

    try {
      final available = await NfcManager.instance.isAvailable();

      if (!mounted) return;

      if (!available) {
        setState(() {
          _checkingNfc = false;
          _statusMessage = 'NFC unavailable';
          _hintMessage = 'Please enable NFC in your phone settings.';
        });
        return;
      }

      setState(() {
        _checkingNfc = false;
        _nfcEnabled = true;
        _statusMessage = 'Waiting for card...';
        _hintMessage =
            'Hold your NTAG213 card close to the back of this phone.';
      });

      await _startNfcSession();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _checkingNfc = false;
        _statusMessage = 'Unable to start NFC';
        _hintMessage = 'Please check your device and try again.';
      });
    }
  }

  Future<void> _startNfcSession() async {
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag tag) async {
          if (!mounted || _cardUid != null) return;

          // Read Android NFC tag UID.
          final androidTag = NfcTagAndroid.from(tag);

          if (androidTag == null) {
            await NfcManager.instance.stopSession();
            _sessionStarted = false;

            if (!mounted) return;

            setState(() {
              _nfcEnabled = false;
              _statusMessage = 'Unable to read card';
              _hintMessage = 'Please try another card.';
              _errorMessage = 'Unsupported NFC card.';
            });

            return;
          }

          final uid = androidTag.id
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join()
              .toUpperCase();

          if (!mounted) return;

          setState(() {
            _cardUid = uid;
            _statusMessage = 'Card detected!';
            _hintMessage = 'Registering your NFC card...';
          });

          await NfcManager.instance.stopSession();
          _sessionStarted = false;

          await _linkCard(uid);
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

  Future<void> _linkCard(String uid) async {
    if (_processing) return;

    setState(() {
      _processing = true;
      _statusMessage = 'Linking card...';
      _hintMessage = 'Please wait while we register your card.';
    });

    try {
      final response = await CardService.linkCard(uid: uid);

      if (!mounted) return;

      if (response['status'] != 'active') {
        throw Exception('Unexpected response from server.');
      }

      setState(() {
        _processing = false;
        _cardLinked = true;
        _statusMessage = 'Card linked successfully!';
        _hintMessage = 'Your NFC card is now ready for payments.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _statusMessage = 'Unable to link card';
        _hintMessage = _errorMessage!;
      });
    }
  }

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
    _checkAndStartNfc();
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
                          if (_nfcEnabled &&
                              !_processing &&
                              !_cardLinked &&
                              _errorMessage == null) ...[
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
                            child: _checkingNfc || _processing
                                ? const Padding(
                                    padding: EdgeInsets.all(28),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _cardLinked
                                        ? Icons.check_circle_outline
                                        : _errorMessage != null
                                        ? Icons.error_outline
                                        : Icons.credit_card_rounded,
                                    color: _cardLinked
                                        ? Colors.greenAccent
                                        : _errorMessage != null
                                        ? Colors.orangeAccent
                                        : Colors.white,
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
                          Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _cardLinked
                                  ? Colors.greenAccent
                                  : _errorMessage != null
                                  ? Colors.orangeAccent
                                  : Colors.white,
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
                          const SizedBox(height: 28),

                          if (!_checkingNfc && !_processing) ...[
                            if (_cardLinked)
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Done',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            else if (!_nfcEnabled || _errorMessage != null)
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton(
                                  onPressed: _retryScanning,
                                  child: const Text('Try again'),
                                ),
                              ),

                            if (!_cardLinked)
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white38,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
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
