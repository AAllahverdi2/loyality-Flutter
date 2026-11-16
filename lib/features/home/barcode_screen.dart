import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/network_monitor.dart';
import 'package:loyallig_flutter/core/widgets/network_error_view.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
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
  String? _barcode;
  bool _loading = true;
  bool _isNetworkError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initial = widget.barcode?.trim().isNotEmpty == true
        ? widget.barcode!.trim()
        : widget.cardNumber?.trim().isNotEmpty == true
            ? widget.cardNumber!.replaceAll(' ', '').trim()
            : null;
    _barcode = initial;
    _loading = _barcode == null;
    NetworkMonitor.instance.reconnectNotifier.addListener(_onReconnected);
    _loadBarcode();
  }

  @override
  void dispose() {
    NetworkMonitor.instance.reconnectNotifier.removeListener(_onReconnected);
    super.dispose();
  }

  void _onReconnected() {
    if (mounted) {
      _loadBarcode(forceRefresh: true);
    }
  }

  Future<void> _loadBarcode({bool forceRefresh = false}) async {
    if (mounted && _barcode == null) {
      setState(() {
        _loading = true;
        _errorMessage = null;
        _isNetworkError = false;
      });
    }

    // Serverdən (/api/Users/myBarcode) ən son barkodu çəkirik
    try {
      final barcode = await _profileService.getMyBarcode(
        forceRefresh: forceRefresh || _barcode == null,
      );
      if (!mounted) return;
      if (barcode != null && barcode.trim().isNotEmpty) {
        setState(() {
          _barcode = barcode.trim();
          _loading = false;
          _errorMessage = null;
          _isNetworkError = false;
        });
      } else {
        setState(() {
          _barcode = null;
          _loading = false;
          _errorMessage = tr('barcode_unavailable_desc');
          _isNetworkError = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [BARCODE YÜKLƏNMƏ XƏTASI]: $e');
      if (!mounted) return;
      setState(() {
        _barcode = null;
        _loading = false;
        _isNetworkError = NetworkMonitor.isNetworkError(e);
        _errorMessage = _isNetworkError
            ? tr('network_error_desc')
            : tr('barcode_unavailable_desc');
      });
    }
  }

  Widget _buildUnavailableState() {
    if (_isNetworkError) {
      return NetworkErrorView(
        onRetry: () async {
          await _loadBarcode(forceRefresh: true);
          return _barcode != null;
        },
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 42,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr('barcode_unavailable_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? tr('barcode_unavailable_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadBarcode(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.base,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                tr('common_retry'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final barcodeHeight = screenSize.height * 0.70;
    final barcodeWidth = (screenSize.width * 0.45).clamp(140.0, 220.0);

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.base),
                )
              else if (_barcode == null || _barcode!.isEmpty)
                _buildUnavailableState()
              else
                Center(
                  child: SizedBox(
                    height: barcodeHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              _barcode!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                        RotatedBox(
                          quarterTurns: 1,
                          child: BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: _barcode!,
                            width: barcodeHeight,
                            height: barcodeWidth,
                            drawText: false,
                            color: Colors.black,
                            errorBuilder: (context, error) =>
                                _buildUnavailableState(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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
            ],
          ),
        ),
      ),
    );
  }
}
