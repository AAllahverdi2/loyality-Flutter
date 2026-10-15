import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/features/history/history_detail_screen.dart';
import 'package:loyallig_flutter/features/history/models/user_transaction.dart';
import 'package:loyallig_flutter/features/history/services/transaction_service.dart';
import 'package:loyallig_flutter/features/history/widgets/history_filter_bottom_sheet.dart';
import 'package:loyallig_flutter/features/history/widgets/history_header.dart';
import 'package:loyallig_flutter/features/history/widgets/history_skeleton.dart';
import 'package:loyallig_flutter/features/history/widgets/transaction_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _loading = true;
  String? _errorMessage;
  List<UserTransaction> _items = [];

  // Filter parametrləri
  String? _selectedPartnerId;
  String? _selectedPartnerName;
  String? _selectedStatus;
  String? _selectedStatusName;
  String? _selectedTransactionType;
  String? _selectedTransactionTypeName;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;

  bool get _hasActiveFilters =>
      (_selectedPartnerId != null && _selectedPartnerId!.isNotEmpty) ||
      (_selectedStatus != null && _selectedStatus!.isNotEmpty) ||
      (_selectedTransactionType != null &&
          _selectedTransactionType!.isNotEmpty) ||
      _selectedDateFrom != null ||
      _selectedDateTo != null;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final futures = <Future<dynamic>>[
        _transactionService.getMyTransactions(
          partnerId: _selectedPartnerId,
          status: _selectedStatus,
          transactionType: _selectedTransactionType,
          dateFrom: _selectedDateFrom,
          dateTo: _selectedDateTo,
        ),
      ];

      // Əgər filter lookupları hələ keşdə yoxdursa, arxa planda gətirib keşləyirik
      if (!TransactionService.hasLookupsCache) {
        futures.add(_transactionService.fetchAllLookups());
      }

      final results = await Future.wait(futures);
      final items = results[0] as List<UserTransaction>;

      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Tarixçəni yükləmək mümkün olmadı';
          _loading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    try {
      // Keşi təmizləyirik və həm əməliyyatları, həm də filter lookuplarını yenidən gətiririk
      TransactionService.clearLookupsCache();

      final results = await Future.wait([
        _transactionService.getMyTransactions(
          partnerId: _selectedPartnerId,
          status: _selectedStatus,
          transactionType: _selectedTransactionType,
          dateFrom: _selectedDateFrom,
          dateTo: _selectedDateTo,
        ),
        _transactionService.fetchAllLookups(forceRefresh: true),
      ]);

      if (mounted) {
        setState(() {
          _items = results[0] as List<UserTransaction>;
          _errorMessage = null;
        });
      }
    } catch (_) {
      // Refresh zamanı xəta olarsa mövcud siyahını saxlayırıq
    }
  }

  Future<void> _openFilterSheet() async {
    final result = await HistoryFilterBottomSheet.show(
      context,
      initialPartnerId: _selectedPartnerId,
      initialStatus: _selectedStatus,
      initialTransactionType: _selectedTransactionType,
      initialDateFrom: _selectedDateFrom,
      initialDateTo: _selectedDateTo,
    );

    if (result != null) {
      setState(() {
        _selectedPartnerId = result.partnerId;
        _selectedPartnerName = result.partnerName;
        _selectedStatus = result.status;
        _selectedStatusName = result.statusName;
        _selectedTransactionType = result.transactionType;
        _selectedTransactionTypeName = result.transactionTypeName;
        _selectedDateFrom = result.dateFrom;
        _selectedDateTo = result.dateTo;
      });
      _fetchHistory(showLoading: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedPartnerId = null;
      _selectedPartnerName = null;
      _selectedStatus = null;
      _selectedStatusName = null;
      _selectedTransactionType = null;
      _selectedTransactionTypeName = null;
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
    _fetchHistory(showLoading: true);
  }

  void _onTransactionTap(String id) {
    UserTransaction? transaction;
    for (final item in _items) {
      if (item.id == id) {
        transaction = item;
        break;
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryDetailScreen(
          id: id,
          transaction: transaction,
        ),
      ),
    );
  }

  double get _monthlyEarned {
    final now = DateTime.now();
    double sum = 0;
    for (final item in _items) {
      if (item.earnedBonusAmount > 0) {
        if (item.transactionAt == null ||
            (item.transactionAt!.year == now.year &&
                item.transactionAt!.month == now.month)) {
          sum += item.earnedBonusAmount;
        }
      }
    }
    return sum;
  }

  double get _monthlySpent {
    final now = DateTime.now();
    double sum = 0;
    for (final item in _items) {
      final amount = item.spentBonusAmount > 0
          ? item.spentBonusAmount
          : (item.netAmount > 0 ? item.netAmount : item.grossAmount);
      if (amount > 0) {
        if (item.transactionAt == null ||
            (item.transactionAt!.year == now.year &&
                item.transactionAt!.month == now.month)) {
          sum += amount;
        }
      }
    }
    return sum;
  }

  Widget _buildActiveFilterBar(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('history_active_filters'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
              GestureDetector(
                onTap: _clearFilters,
                child: Text(
                  tr('history_clear_filters'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.base,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_selectedTransactionTypeName != null)
                  _buildFilterBadge(
                    label: '${tr('history_filter_type')}: $_selectedTransactionTypeName',
                    onDelete: () {
                      setState(() {
                        _selectedTransactionType = null;
                        _selectedTransactionTypeName = null;
                      });
                      _fetchHistory();
                    },
                  ),
                if (_selectedStatusName != null)
                  _buildFilterBadge(
                    label: '${tr('history_filter_status')}: $_selectedStatusName',
                    onDelete: () {
                      setState(() {
                        _selectedStatus = null;
                        _selectedStatusName = null;
                      });
                      _fetchHistory();
                    },
                  ),
                if (_selectedPartnerName != null)
                  _buildFilterBadge(
                    label: '${tr('history_filter_partner')}: $_selectedPartnerName',
                    onDelete: () {
                      setState(() {
                        _selectedPartnerId = null;
                        _selectedPartnerName = null;
                      });
                      _fetchHistory();
                    },
                  ),
                if (_selectedDateFrom != null || _selectedDateTo != null)
                  _buildFilterBadge(
                    label:
                        '${tr('history_filter_date')}: ${_selectedDateFrom != null ? "${_selectedDateFrom!.day}.${_selectedDateFrom!.month}" : tr('history_filter_before')} - ${_selectedDateTo != null ? "${_selectedDateTo!.day}.${_selectedDateTo!.month}" : tr('history_filter_now')}',
                    onDelete: () {
                      setState(() {
                        _selectedDateFrom = null;
                        _selectedDateTo = null;
                      });
                      _fetchHistory();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge({
    required String label,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 10, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.base.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.base.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.base,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.base,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    if (_loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
            child: HistorySkeleton(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.base,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          onRefresh: _onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 30,
            ),
            itemCount: _buildItemCount(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HistoryHeader(
                      monthlyEarned: _items.isNotEmpty ? _monthlyEarned : null,
                      monthlySpent: _items.isNotEmpty ? _monthlySpent : null,
                      hasActiveFilters: _hasActiveFilters,
                      onFilterTap: _openFilterSheet,
                    ),
                    if (_hasActiveFilters)
                      _buildActiveFilterBar(isDark, textColor, secondaryTextColor),
                  ],
                );
              }

              // Xəta halı
              if (_errorMessage != null && _items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 42,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: () => _fetchHistory(showLoading: true),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(tr('history_retry')),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.base,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Boş siyahı halı
              if (_items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 52,
                          color: secondaryTextColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _hasActiveFilters
                              ? tr('history_no_filtered_transactions')
                              : tr('history_empty_title'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _hasActiveFilters
                              ? tr('history_no_filtered_transactions_desc')
                              : tr('history_empty_desc'),
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                            label: Text(tr('discounts_reset_filters')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.base,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              final item = _items[index - 1];
              final transaction = item.toTransaction();

              return TransactionItem(
                item: transaction,
                onTap: _onTransactionTap,
              );
            },
          ),
        ),
      ),
    );
  }

  int _buildItemCount() {
    if (_items.isEmpty) {
      return 2; // Header + Error və ya Boş vəziyyət widget-ı
    }
    return _items.length + 1; // Header + Əməliyyatların sayı
  }
}

