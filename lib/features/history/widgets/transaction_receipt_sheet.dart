import 'dart:async';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/services/biometric_service.dart';
import 'package:loyallig_flutter/features/history/models/user_transaction.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionReceiptSheet extends StatefulWidget {
  const TransactionReceiptSheet({
    required this.transaction,
    super.key,
  });

  final UserTransaction transaction;

  static Future<void> show(
    BuildContext context, {
    required UserTransaction transaction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionReceiptSheet(transaction: transaction),
    );
  }

  /// Qəbzi PNG şəkil kimi generasiya edib cihazın native paylaşım pəncərəsini
  /// (WhatsApp, Instagram, Telegram və s.) açır.
  static Future<void> shareReceipt(
    BuildContext context, {
    required UserTransaction transaction,
    GlobalKey? boundaryKey,
    Rect? shareOrigin,
  }) async {
    final origin = shareOrigin ?? _resolveShareOrigin(context);
    final summaryText = _buildReceiptSummaryText(transaction);
    final ref = _safeFileRef(transaction);
    final fileName = 'azera_qebz_$ref.png';

    Uint8List? pngBytes;
    if (boundaryKey != null) {
      pngBytes = await _captureBoundaryPng(boundaryKey);
    } else if (context.mounted) {
      pngBytes = await _renderOffscreenReceiptPng(context, transaction);
    }

    Future<ShareResult> invokeShare() {
      if (pngBytes != null && pngBytes.isNotEmpty) {
        return SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                pngBytes,
                mimeType: 'image/png',
                name: fileName,
              ),
            ],
            fileNameOverrides: [fileName],
            text: summaryText,
            subject: '${tr('history_receipt')} № $ref',
            sharePositionOrigin: origin,
            downloadFallbackEnabled: true,
          ),
        );
      }
      return SharePlus.instance.share(
        ShareParams(
          text: summaryText,
          subject: '${tr('history_receipt')} № $ref',
          sharePositionOrigin: origin,
          downloadFallbackEnabled: true,
        ),
      );
    }

    try {
      await BiometricService.instance.runWithSuppressedLock(invokeShare);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [RECEIPT_SHARE] Paylaşım xətası: $e');
      }
      if (context.mounted) {
        await Clipboard.setData(ClipboardData(text: summaryText));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('history_copied_info')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  static Rect? _resolveShareOrigin(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final offset = renderObject.localToGlobal(Offset.zero);
      if (renderObject.size.width > 0 && renderObject.size.height > 0) {
        return offset & renderObject.size;
      }
    }
    final size = MediaQuery.maybeSizeOf(context);
    if (size != null && size.width > 0 && size.height > 0) {
      return Rect.fromLTWH(size.width / 2 - 1, size.height / 2 - 1, 2, 2);
    }
    return null;
  }

  static Future<Uint8List?> _captureBoundaryPng(GlobalKey key) async {
    try {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;
      if (renderObject.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
      }
      final image = await renderObject.toImage(pixelRatio: 3.0);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [RECEIPT_SHARE] Şəkil çəkilərkən xəta: $e');
      }
      return null;
    }
  }

  static Future<Uint8List?> _renderOffscreenReceiptPng(
    BuildContext context,
    UserTransaction transaction,
  ) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;

    final tempKey = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: 0,
        width: 390,
        child: IgnorePointer(
          child: Material(
            type: MaterialType.transparency,
            child: RepaintBoundary(
              key: tempKey,
              child: Container(
                color: const Color(0xFFF3F4F6),
                padding: const EdgeInsets.all(16),
                child: TransactionReceiptPaper(transaction: transaction),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      return await _captureBoundaryPng(tempKey);
    } finally {
      entry.remove();
    }
  }

  static String _safeFileRef(UserTransaction transaction) {
    final raw = transaction.externalReference?.trim().isNotEmpty == true
        ? transaction.externalReference!.trim()
        : transaction.id.trim();
    final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    if (cleaned.isEmpty) return 'receipt';
    return cleaned.length > 24 ? cleaned.substring(0, 24) : cleaned;
  }

  static String _buildReceiptSummaryText(UserTransaction t) {
    final partner = t.partnerName.trim().isNotEmpty
        ? t.partnerName.trim()
        : 'Azera Loyallıq';
    final amount = t.netAmount > 0
        ? t.netAmount
        : (t.grossAmount > 0 ? t.grossAmount : t.spentBonusAmount);
    final lines = <String>[
      'Azera Loyallıq — $partner',
      '${tr('receipt_total')}: ${amount.toStringAsFixed(2)} ₼',
      if (t.fullFormattedDate != '—') '${tr('receipt_date')}: ${t.fullFormattedDate}',
      if (t.hasFiscalId) '${tr('receipt_fiscal_id')}: ${t.fiscalId!}',
      if (t.hasFiscalId && t.fiscalQrUrl != null) t.fiscalQrUrl!,
    ];
    return lines.join('\n');
  }

  @override
  State<TransactionReceiptSheet> createState() =>
      _TransactionReceiptSheetState();
}

class _TransactionReceiptSheetState extends State<TransactionReceiptSheet> {
  final GlobalKey _receiptBoundaryKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _isSharing = false;

  void _copyFiscalId() {
    final fiscalId = widget.transaction.fiscalId?.trim();
    if (fiscalId == null || fiscalId.isEmpty) return;
    Clipboard.setData(ClipboardData(text: fiscalId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('receipt_fiscal_copied')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openFiscalPortal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      Rect? origin;
      final box =
          _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
      await TransactionReceiptSheet.shareReceipt(
        context,
        transaction: widget.transaction,
        boundaryKey: _receiptBoundaryKey,
        shareOrigin: origin,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellBg = isDark ? const Color(0xFF141417) : const Color(0xFFF3F4F6);
    final headerText = isDark ? Colors.white : const Color(0xFF111827);
    final headerSub = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.90;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: shellBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: headerSub.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 20,
                    color: AppColors.base,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('history_receipt'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: headerText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: headerSub),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
                child: RepaintBoundary(
                  key: _receiptBoundaryKey,
                  child: Container(
                    color: shellBg,
                    padding: const EdgeInsets.all(6),
                    child: TransactionReceiptPaper(
                      transaction: widget.transaction,
                      onCopyFiscal: _copyFiscalId,
                      onOpenPortal: _openFiscalPortal,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                14 + (bottomInset > 0 ? bottomInset : 4),
              ),
              decoration: BoxDecoration(
                color: shellBg,
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: widget.transaction.hasFiscalId
                            ? _copyFiscalId
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: headerText,
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: Text(
                          widget.transaction.hasFiscalId
                              ? tr('receipt_copy_fiscal')
                              : tr('common_close'),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      key: _shareButtonKey,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _isSharing ? null : _handleShare,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.base,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.base.withValues(alpha: 0.65),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: _isSharing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share_rounded, size: 18),
                        label: Text(
                          tr('history_share'),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionReceiptPaper extends StatelessWidget {
  const TransactionReceiptPaper({
    required this.transaction,
    this.onCopyFiscal,
    this.onOpenPortal,
    super.key,
  });

  final UserTransaction transaction;
  final VoidCallback? onCopyFiscal;
  final ValueChanged<String>? onOpenPortal;

  String _formatDateOnly(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }

  String _formatTimeOnly(DateTime? dt) {
    if (dt == null) return '—';
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$min:$s';
  }

  String _receiptNumber() {
    final ext = transaction.externalReference?.trim();
    if (ext != null && ext.isNotEmpty) return ext;
    final id = transaction.id.trim();
    if (id.length <= 12) return id;
    return id.substring(0, 12).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const inkPrimary = Color(0xFF111827);
    const inkSecondary = Color(0xFF4B5563);
    const inkMuted = Color(0xFF6B7280);

    final t = transaction;
    final partnerName = t.partnerName.trim().isNotEmpty
        ? t.partnerName.trim()
        : 'Azera Loyallıq';
    final txType = t.displayTransactionType;
    final statusText = t.statusName?.trim().isNotEmpty == true
        ? t.statusName!.trim()
        : (t.status?.trim().isNotEmpty == true
              ? t.status!.trim()
              : tr('history_completed'));
    final paymentLabel = t.paymentMethodTypeName?.trim().isNotEmpty == true
        ? t.paymentMethodTypeName!.trim()
        : (t.paymentMethodType?.trim().isNotEmpty == true
              ? t.paymentMethodType!.trim()
              : tr('history_wallet'));

    final displayTotal = t.netAmount > 0
        ? t.netAmount
        : (t.grossAmount > 0 ? t.grossAmount : t.spentBonusAmount);

    final lowerPay = (t.paymentMethodType ?? t.paymentMethodTypeName ?? '')
        .trim()
        .toLowerCase();
    final isPureWallet =
        lowerPay.contains('wallet') ||
        lowerPay.contains('cüzdan') ||
        lowerPay.contains('bonus');
    final nonBonusPaid = (displayTotal - t.spentBonusAmount).clamp(
      0.0,
      double.infinity,
    );

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const _ReceiptPaperClipper(toothWidth: 12, toothHeight: 6),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: inkPrimary,
              fontSize: 12.5,
              height: 1.4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Obyekt / Tərəfdaş başlığı
                Text(
                  partnerName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: inkPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Azera Loyallıq',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: inkSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Qəbz başlığı № ...
                Text(
                  '${t.receiptTitle} № ${_receiptNumber()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: inkPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Tarix / Saat / Növ / Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${tr('history_transaction_type')}: ',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: inkMuted,
                                  ),
                                ),
                                TextSpan(
                                  text: txType,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: inkPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${tr('history_status')}: ',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: inkMuted,
                                  ),
                                ),
                                TextSpan(
                                  text: statusText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: inkPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${tr('receipt_date')}:  ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: inkMuted,
                              ),
                            ),
                            Text(
                              _formatDateOnly(t.transactionAt),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: inkPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${tr('receipt_time')}:  ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: inkMuted,
                              ),
                            ),
                            Text(
                              _formatTimeOnly(t.transactionAt),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: inkPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const _ReceiptSeparator.asterisk(),

                // 4. Məhsullar cədvəli
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        tr('receipt_product'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: inkPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        tr('receipt_quantity'),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: inkPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        tr('receipt_price'),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: inkPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        tr('receipt_total'),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: inkPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (t.items.isNotEmpty)
                  ...t.items.map((item) {
                    final lineTotal = item.total > 0
                        ? item.total
                        : (item.unitPrice * item.exactQuantity);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: inkPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.exactQuantity.toStringAsFixed(3),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: inkSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.unitPrice.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: inkSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              lineTotal.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: inkPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            txType,
                            style: const TextStyle(
                              fontSize: 12,
                              color: inkPrimary,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            '1.000',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: inkSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            displayTotal.toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: inkSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            displayTotal.toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: inkPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const _ReceiptSeparator.dashed(),

                // 5. Cəmi / Endirim
                if (t.discountAmount > 0) ...[
                  _ReceiptAmountRow(
                    label: tr('history_gross_amount'),
                    value: '${t.grossAmount.toStringAsFixed(2)} ₼',
                  ),
                  _ReceiptAmountRow(
                    label: tr('history_discount_amount'),
                    value: '-${t.discountAmount.toStringAsFixed(2)} ₼',
                  ),
                ],
                _ReceiptAmountRow(
                  label: tr('receipt_total'),
                  value: '${displayTotal.toStringAsFixed(2)} ₼',
                  isBold: true,
                  fontSize: 14,
                ),

                const _ReceiptSeparator.asterisk(),

                // 6. Ödəniş növü
                Text(
                  tr('receipt_payment_type'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: inkPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                if (!isPureWallet || nonBonusPaid > 0)
                  _ReceiptAmountRow(
                    label: '$paymentLabel:',
                    value:
                        '${(nonBonusPaid > 0 ? nonBonusPaid : displayTotal).toStringAsFixed(2)} ₼',
                  ),
                if (t.spentBonusAmount > 0 || isPureWallet)
                  _ReceiptAmountRow(
                    label: '${tr('receipt_bonus_paid')}:',
                    value: '${t.spentBonusAmount.toStringAsFixed(2)} ₼',
                  ),
                if (t.earnedBonusAmount > 0)
                  _ReceiptAmountRow(
                    label: '${tr('history_earned_bonus')}:',
                    value: '+${t.earnedBonusAmount.toStringAsFixed(2)} ₼',
                  ),

                if (t.notes != null && t.notes!.trim().isNotEmpty) ...[
                  const _ReceiptSeparator.dashed(),
                  Text(
                    '${tr('history_notes')}: ${t.notes!.trim()}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: inkSecondary,
                    ),
                  ),
                ],

                // 7. Fiskal ID & ƏDV QR kodu — YALNIZ fiscalId dolu olduqda!
                if (t.hasFiscalId && t.fiscalQrUrl != null) ...[
                  const _ReceiptSeparator.asterisk(),
                  GestureDetector(
                    onTap: onCopyFiscal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '${tr('receipt_fiscal_id')}: ${t.fiscalId!}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: inkPrimary,
                            ),
                          ),
                        ),
                        if (onCopyFiscal != null) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: inkMuted,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: BarcodeWidget(
                        barcode: Barcode.qrCode(
                          errorCorrectLevel: BarcodeQRCorrectionLevel.medium,
                        ),
                        data: t.fiscalQrUrl!,
                        width: 152,
                        height: 152,
                        color: Colors.black,
                        backgroundColor: Colors.white,
                        drawText: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onOpenPortal != null
                        ? () => onOpenPortal!(t.fiscalQrUrl!)
                        : null,
                    child: const Text(
                      'www.e-kassa.gov.az',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: inkPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const _ReceiptSeparator.dashed(),
                  Text(
                    tr('receipt_vat_refund'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('receipt_vat_scan_hint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: inkSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptAmountRow extends StatelessWidget {
  const _ReceiptAmountRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize = 12.5,
  });

  final String label;
  final String value;
  final bool isBold;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      color: isBold ? const Color(0xFF111827) : const Color(0xFF374151),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ReceiptSeparator extends StatelessWidget {
  const _ReceiptSeparator.asterisk() : _char = '*';
  const _ReceiptSeparator.dashed() : _char = '-';

  final String _char;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 7.2).floor().clamp(12, 80);
          return Text(
            List.filled(count, _char).join(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              color: Color(0xFF9CA3AF),
              height: 1.0,
            ),
          );
        },
      ),
    );
  }
}

class _ReceiptPaperClipper extends CustomClipper<Path> {
  const _ReceiptPaperClipper({
    required this.toothWidth,
    required this.toothHeight,
  });

  final double toothWidth;
  final double toothHeight;

  @override
  Path getClip(Size size) {
    final path = Path();
    final teethCount = (size.width / toothWidth).floor().clamp(4, 120);
    final actualToothW = size.width / teethCount;

    path.moveTo(0, toothHeight);
    for (int i = 0; i < teethCount; i++) {
      final startX = i * actualToothW;
      path.lineTo(startX + actualToothW / 2, 0);
      path.lineTo(startX + actualToothW, toothHeight);
    }

    path.lineTo(size.width, size.height - toothHeight);
    for (int i = teethCount - 1; i >= 0; i--) {
      final startX = i * actualToothW;
      path.lineTo(startX + actualToothW / 2, size.height);
      path.lineTo(startX, size.height - toothHeight);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ReceiptPaperClipper oldClipper) {
    return oldClipper.toothWidth != toothWidth ||
        oldClipper.toothHeight != toothHeight;
  }
}
