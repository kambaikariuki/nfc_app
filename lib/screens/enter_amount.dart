import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_app/screens/nfc_read_screen.dart'; // adjust path

class EnterAmountScreen extends StatefulWidget {
  const EnterAmountScreen({super.key});

  @override
  State<EnterAmountScreen> createState() => _EnterAmountScreenState();
}

class _EnterAmountScreenState extends State<EnterAmountScreen>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  bool _isValid = false;

  late AnimationController _controller;
  late Animation<double> _titleFade;
  late Animation<double> _inputFade;
  late Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    _amountController.addListener(() {
      final text = _amountController.text.trim();
      final value = double.tryParse(text);
      setState(() => _isValid = value != null && value > 0);
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );
    _inputFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.6, curve: Curves.easeIn),
    );
    _buttonFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _proceed() {
    final amount = double.parse(_amountController.text.trim());
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NfcReadScreen(amount: amount),
      ),
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
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // Title block
                  FadeTransition(
                    opacity: _titleFade,
                    child: const Column(
                      children: [
                        Icon(
                          Icons.contactless_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Enter Amount',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Amount input
                  FadeTransition(
                    opacity: _inputFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount (KES)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16, top: 14),
                              child: Text(
                                'KES',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Colors.white, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                          ),
                          autofocus: true,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Proceed button
                  FadeTransition(
                    opacity: _buttonFade,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 48.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isValid ? _proceed : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            disabledForegroundColor:
                                Colors.white.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Proceed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }
}