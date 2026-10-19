import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/chat/chat_topics_screen.dart';
import 'package:loyallig_flutter/features/history/models/user_transaction.dart';
import 'package:loyallig_flutter/features/history/services/transaction_service.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({
    required this.id,
    this.transaction,
    super.key,
  });

  final String id;
  final UserTransaction? transaction;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final TransactionService _transactionService = TransactionService();

  bool _loading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  UserTransaction? _transaction;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails({bool isRefresh = false}) async {
    if (!isRefresh && _transaction == null) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    } else if (isRefresh) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final detail = await _transactionService.getTransactionById(widget.id);
      if (!mounted) return;

      if (detail != null) {
        setState(() {
          _transaction = detail;
          _loading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      } else {
        if (_transaction == null) {
          setState(() {
            _errorMessage = tr('history_detail_not_found');
            _loading = false;
            _isRefreshing = false;
          });
        } else {
          setState(() {
            _isRefreshing = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (_transaction == null) {
        setState(() {
          _errorMessage = tr('history_detail_error');
          _loading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  IconData _getCategoryIcon(String? type) {
    if (type == null) return Icons.shopping_bag_outlined;
    final lower = type.toLowerCase();
    if (lower.contains('alış') || lower.contains('purchase')) {
      return Icons.shopping_cart_outlined;
    }
    if (lower.contains('qazan') || lower.contains('bonus') || lower.contains('earn')) {
      return Icons.card_giftcard_rounded;
    }
    if (lower.contains('redemption') || lower.contains('istifadə')) {
      return Icons.toll_rounded;
    }
    if (lower.contains('cüzdan') || lower.contains('wallet')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (lower.contains('endirim') || lower.contains('discount')) {
      return Icons.local_offer_outlined;
    }
    return Icons.storefront_rounded;
  }

  Color _getStatusColor(String? status, bool isDark) {
    if (status == null) return const Color(0xFF16A34A);
    final lower = status.toLowerCase();
    if (lower.contains('tamam') || lower.contains('completed') || lower.contains('uğurlu')) {
      return const Color(0xFF16A34A);
    }
    if (lower.contains('gözlə') || lower.contains('pending')) {
      return const Color(0xFFD97706);
    }
    if (lower.contains('ləğv') || lower.contains('cancel') || lower.contains('fail')) {
      return const Color(0xFFDC2626);
    }
    return const Color(0xFF16A34A);
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.check_circle_rounded;
    final lower = status.toLowerCase();
    if (lower.contains('tamam') || lower.contains('completed') || lower.contains('uğurlu')) {
      return Icons.check_circle_rounded;
    }
    if (lower.contains('gözlə') || lower.contains('pending')) {
      return Icons.access_time_filled_rounded;
    }
    if (lower.contains('ləğv') || lower.contains('cancel') || lower.contains('fail')) {
      return Icons.cancel_rounded;
    }
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final secondaryBg =
        isDark ? const Color(0xFF141414) : const Color(0xFFF8F9FA);

    if (_loading && _transaction == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.base,
          ),
        ),
      );
    }

    if (_errorMessage != null && _transaction == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: textColor,
            ),
          ),
          title: Text(
            tr('history_detail_title'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _fetchDetails(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.base,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(tr('history_retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final t = _transaction!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Yuxarıda əsas məbləğ (Net amount həmişə əsas prioritetdir)
    final topAmount = t.netAmount > 0
        ? '${t.netAmount.toStringAsFixed(2)} ₼'
        : (t.grossAmount > 0
            ? '${t.grossAmount.toStringAsFixed(2)} ₼'
            : (t.spentBonusAmount > 0
                ? '${t.spentBonusAmount.toStringAsFixed(2)} ₼'
                : (t.earnedBonusAmount > 0
                    ? '+${t.earnedBonusAmount.toStringAsFixed(2)} ₼'
                    : '0.00 ₼')));

    final logoUrl = (t.fileId != null && t.fileId!.trim().isNotEmpty)
        ? '${ApiEndpoints.baseUrl}${ApiEndpoints.fileDownload(t.fileId!.trim())}'
        : null;

    final partnerDisplay = t.partnerName.trim().isNotEmpty
        ? t.partnerName.trim()
        : (t.transactionTypeName?.trim().isNotEmpty == true
            ? t.transactionTypeName!.trim()
            : tr('partner_default_name'));

    final categoryDisplay = t.transactionTypeName?.trim().isNotEmpty == true
        ? t.transactionTypeName!.trim()
        : (t.transactionType?.trim().isNotEmpty == true
            ? t.transactionType!.trim()
            : tr('history_purchase'));

    final statusDisplay = t.statusName?.trim().isNotEmpty == true
        ? t.statusName!.trim()
        : (t.status?.trim().isNotEmpty == true ? t.status!.trim() : tr('history_completed'));

    final statusColor = _getStatusColor(statusDisplay, isDark);
    final statusIcon = _getStatusIcon(statusDisplay);
    final categoryIcon = _getCategoryIcon(categoryDisplay);

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: textColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tr('history_detail_title'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isRefreshing ? null : () => _fetchDetails(isRefresh: true),
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.base,
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            size: 22,
                            color: textColor,
                          ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.base,
                onRefresh: () => _fetchDetails(isRefresh: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    24 + (bottomInset > 0 ? bottomInset : 24),
                  ),
                  child: Column(
                    children: [
                      // 1. Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: logoUrl != null
                                      ? Image.network(
                                          logoUrl,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              _buildAvatarFallback(
                                            partnerDisplay,
                                            categoryIcon,
                                            isDark,
                                            borderColor,
                                            secondaryTextColor,
                                          ),
                                        )
                                      : _buildAvatarFallback(
                                          partnerDisplay,
                                          categoryIcon,
                                          isDark,
                                          borderColor,
                                          secondaryTextColor,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        partnerDisplay,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            categoryIcon,
                                            size: 14,
                                            color: secondaryTextColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            categoryDisplay,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  topAmount,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusDisplay,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Bonusla ödəniş qutusu (Balansdan istifadə olunubsa)
                      if (t.spentBonusAmount > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.toll_rounded,
                                  size: 20,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('history_bonus_payment'),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tr('history_bonus_deducted'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-${t.spentBonusAmount.toStringAsFixed(2)} ₼',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 3. Qazanılan bonus qutusu (Cashback / Bonus gəliri)
                      if (t.earnedBonusAmount > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF059669).withValues(alpha: 0.15)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF059669).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.card_giftcard_rounded,
                                  size: 20,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('history_earned_bonus_income'),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tr('history_added_to_balance'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+${t.earnedBonusAmount.toStringAsFixed(2)} ₼',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 4. Ətraflı məlumat (API-dən gələn dəyərlər)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('history_details_info'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: tr('history_transaction_id'),
                              value: '#${t.externalReference?.isNotEmpty == true ? t.externalReference! : t.id}',
                              textColor: textColor,
                              labelColor: secondaryTextColor,
                              icon: Icons.copy_rounded,
                              onIconTap: () {
                                final copyText = t.externalReference?.isNotEmpty == true
                                    ? t.externalReference!
                                    : t.id;
                                Clipboard.setData(ClipboardData(text: copyText));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr('history_id_copied')),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                            _InfoRow(
                              label: tr('history_date_time'),
                              value: t.fullFormattedDate,
                              textColor: textColor,
                              labelColor: secondaryTextColor,
                            ),
                            _InfoRow(
                              label: tr('history_payment_method'),
                              value: t.paymentMethodTypeName ??
                                  t.paymentMethodType ??
                                  tr('history_wallet'),
                              textColor: textColor,
                              labelColor: secondaryTextColor,
                              icon: Icons.credit_card_rounded,
                            ),
                            _InfoRow(
                              label: tr('history_transaction_type'),
                              value: categoryDisplay,
                              textColor: textColor,
                              labelColor: secondaryTextColor,
                              icon: categoryIcon,
                            ),
                            _InfoRow(
                              label: tr('history_status'),
                              value: statusDisplay,
                              textColor: statusColor,
                              labelColor: secondaryTextColor,
                              icon: statusIcon,
                            ),
                            if (t.grossAmount > 0 &&
                                (t.grossAmount != t.netAmount || t.discountAmount > 0))
                              _InfoRow(
                                label: tr('history_gross_amount'),
                                value: '${t.grossAmount.toStringAsFixed(2)} ₼',
                                textColor: textColor,
                                labelColor: secondaryTextColor,
                              ),
                            if (t.discountAmount > 0)
                              _InfoRow(
                                label: tr('history_discount_amount'),
                                value: '- ${t.discountAmount.toStringAsFixed(2)} ₼',
                                textColor: const Color(0xFFDC2626),
                                labelColor: secondaryTextColor,
                              ),
                            _InfoRow(
                              label: tr('history_net_amount'),
                              value: '${t.netAmount.toStringAsFixed(2)} ₼',
                              textColor: textColor,
                              labelColor: secondaryTextColor,
                            ),
                            if (t.spentBonusAmount > 0)
                              _InfoRow(
                                label: tr('history_spent_bonus'),
                                value: '- ${t.spentBonusAmount.toStringAsFixed(2)} ₼',
                                textColor: const Color(0xFFDC2626),
                                labelColor: secondaryTextColor,
                                icon: Icons.toll_rounded,
                              ),
                            if (t.earnedBonusAmount > 0)
                              _InfoRow(
                                label: tr('history_earned_bonus'),
                                value: '+ ${t.earnedBonusAmount.toStringAsFixed(2)} ₼',
                                textColor: const Color(0xFF059669),
                                labelColor: secondaryTextColor,
                                icon: Icons.card_giftcard_rounded,
                              ),
                            if (t.notes != null && t.notes!.trim().isNotEmpty)
                              _InfoRow(
                                label: tr('history_notes'),
                                value: t.notes!.trim(),
                                textColor: textColor,
                                labelColor: secondaryTextColor,
                                icon: Icons.description_outlined,
                              ),
                          ],
                        ),
                      ),

                      // 5. Alınan məhsullar (items)
                      if (t.items.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tr('history_purchased_products'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: secondaryBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: borderColor, width: 0.5),
                                    ),
                                    child: Text(
                                      '${t.items.length} ${tr('history_items_count')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ...t.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: secondaryBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${item.quantity}x',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.itemName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: textColor,
                                              ),
                                            ),
                                            if (item.quantity > 1 && item.unitPrice > 0)
                                              Text(
                                                '${item.unitPrice.toStringAsFixed(2)} ₼ / ${tr('history_items_count')}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(item.total > 0 ? item.total : (item.unitPrice * item.quantity)).toStringAsFixed(2)} ₼',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(color: borderColor, height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tr('history_total'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    topAmount,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 6. Cüzdan hərəkətləri (walletHistories)
                      if (t.walletHistories.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 18,
                                    color: AppColors.base,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('history_wallet_movements'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ...t.walletHistories.asMap().entries.map((entry) {
                                final index = entry.key;
                                final history = entry.value;
                                final isNegative = history.amount < 0;
                                final amountColor = isNegative
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF059669);

                                return Column(
                                  children: [
                                    if (index > 0)
                                      Divider(color: borderColor, height: 20),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: amountColor.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isNegative
                                                ? Icons.arrow_downward_rounded
                                                : Icons.arrow_upward_rounded,
                                            size: 14,
                                            color: amountColor,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                history.sourceTypeName ??
                                                    history.sourceType ??
                                                    tr('history_wallet_tx'),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                              if (history.description != null &&
                                                  history.description!.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  history.description!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: secondaryTextColor,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: secondaryBg,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${tr('history_balance_prefix')}: ${history.balanceBefore.toStringAsFixed(2)} ₼ ➔ ${history.balanceAfter.toStringAsFixed(2)} ₼',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: secondaryTextColor,
                                                  ),
                                                ),
                                              ),
                                              if (history.formattedDate.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  history.formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: secondaryTextColor,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          history.amount > 0
                                              ? '+ ${history.amount.toStringAsFixed(2)} ₼'
                                              : '${history.amount.toStringAsFixed(2)} ₼',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: amountColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ],

                      // 7. Qəbz & Paylaş Düymələri
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${tr('history_receipt')}: #${t.externalReference?.isNotEmpty == true ? t.externalReference! : t.id}',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.download_rounded,
                                      size: 20,
                                      color: textColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      tr('history_receipt'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                final text =
                                    'Loyallig: $partnerDisplay - $topAmount (${t.fullFormattedDate})';
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr('history_copied_info')),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.share_outlined,
                                      size: 20,
                                      color: textColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      tr('history_share'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 8. Dəstək / Sual düyməsi
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ChatTopicsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: secondaryBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr('history_have_question'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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

  Widget _buildAvatarFallback(
    String name,
    IconData fallbackIcon,
    bool isDark,
    Color borderColor,
    Color secondaryTextColor,
  ) {
    final initial = name.trim().isNotEmpty ? name.trim().characters.first.toUpperCase() : '';
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
        border: Border.all(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: initial.isNotEmpty
          ? Text(
              initial,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.base,
              ),
            )
          : Icon(fallbackIcon, size: 24, color: secondaryTextColor),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.labelColor,
    this.icon,
    this.onIconTap,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color labelColor;
  final IconData? icon;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: labelColor),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onIconTap,
                    child: Icon(icon, size: 16, color: textColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
