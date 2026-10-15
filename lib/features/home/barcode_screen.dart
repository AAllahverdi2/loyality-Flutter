import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/features/profile/services/profile_service.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({
    this.cardNumber,
    this.barcode,
    super.key,
  });

  final String? cardNumber;
  final String? barcode;

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final ProfileService _profileService = ProfileService();
  String _barcode = '076887053583';

  @override
  void initState() {
    super.initState();
    final initial = widget.barcode?.trim().isNotEmpty == true
        ? widget.barcode!.trim()
        : widget.cardNumber?.trim().isNotEmpty == true
            ? widget.cardNumber!.replaceAll(' ', '').trim()
            : '076887053583';
    _barcode = initial;
    _loadBarcode();
  }

  Future<void> _loadBarcode() async {
    // 1. Əvvəlcə yerli yaddaşda saxlanılmış barkod varsa, dərhal tətbiq edirik
    final cached = await TokenStorage.getBarcode();
    if (cached != null && cached.trim().isNotEmpty && mounted) {
      setState(() => _barcode = cached.trim());
    }

    // 2. Serverdən (/api/Users/myBarcode) ən son barkodu çəkirik
    try {
      final barcode = await _profileService.getMyBarcode();
      if (mounted && barcode != null && barcode.trim().isNotEmpty) {
        setState(() {
          _barcode = barcode.trim();
        });
      }
    } catch (e) {
      debugPrint('⚠️ [BARCODE YÜKLƏNMƏ XƏTASI]: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final barcodeHeight = screenSize.height * 0.70;
    final barcodeWidth = (screenSize.width * 0.45).clamp(140.0, 220.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Close Button: top right
            Positioned(
              top: 16,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ),

            // Center Content: Vertically rotated text + Real Barcode
            Center(
              child: SizedBox(
                height: barcodeHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Rotated text: 90 degrees clockwise matching RN
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          _barcode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),

                    // Real Vertical Barcode from string
                    RotatedBox(
                      quarterTurns: 1,
                      child: BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: _barcode,
                        width: barcodeHeight,
                        height: barcodeWidth,
                        drawText: false,
                        color: Colors.black,
                        errorBuilder: (context, error) => Image.asset(
                          'assets/barkod-vertical.png',
                          height: barcodeHeight,
                          width: barcodeWidth,
                          fit: BoxFit.contain,
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
    );
  }
}
