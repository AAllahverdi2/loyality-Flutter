import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/models/lookup_item.dart';
import 'package:loyallig_flutter/features/history/services/transaction_service.dart';

class HistoryFilterResult {
  final String? partnerId;
  final String? partnerName;
  final String? status;
  final String? statusName;
  final String? statusValue;
  final String? transactionType;
  final String? transactionTypeName;
  final String? transactionTypeValue;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const HistoryFilterResult({
    this.partnerId,
    this.partnerName,
    this.status,
    this.statusName,
    this.statusValue,
    this.transactionType,
    this.transactionTypeName,
    this.transactionTypeValue,
    this.dateFrom,
    this.dateTo,
  });

  bool get hasActiveFilter =>
      (partnerId != null && partnerId!.isNotEmpty) ||
      (status != null && status!.isNotEmpty) ||
      (transactionType != null && transactionType!.isNotEmpty) ||
      dateFrom != null ||
      dateTo != null;
}

class HistoryFilterBottomSheet extends StatefulWidget {
  const HistoryFilterBottomSheet({
    this.initialPartnerId,
    this.initialStatus,
    this.initialStatusValue,
    this.initialTransactionType,
    this.initialTransactionTypeValue,
    this.initialDateFrom,
    this.initialDateTo,
    super.key,
  });

  final String? initialPartnerId;
  final dynamic initialStatus;
  final String? initialStatusValue;
  final dynamic initialTransactionType;
  final String? initialTransactionTypeValue;
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;

  static Future<HistoryFilterResult?> show(
    BuildContext context, {
    String? initialPartnerId,
    dynamic initialStatus,
    String? initialStatusValue,
    dynamic initialTransactionType,
    String? initialTransactionTypeValue,
    DateTime? initialDateFrom,
    DateTime? initialDateTo,
  }) {
    final effectiveStatus =
        initialStatus?.toString() ?? initialStatusValue;
    final effectiveType =
        initialTransactionType?.toString() ?? initialTransactionTypeValue;

    return showModalBottomSheet<HistoryFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryFilterBottomSheet(
        initialPartnerId: initialPartnerId,
        initialStatus: effectiveStatus,
        initialStatusValue: effectiveStatus,
        initialTransactionType: effectiveType,
        initialTransactionTypeValue: effectiveType,
        initialDateFrom: initialDateFrom,
        initialDateTo: initialDateTo,
      ),
    );
  }

  @override
  State<HistoryFilterBottomSheet> createState() =>
      _HistoryFilterBottomSheetState();
}

class _HistoryFilterBottomSheetState extends State<HistoryFilterBottomSheet> {
  final TransactionService _transactionService = TransactionService();

  List<LookupItem> _partners = [];
  List<LookupItem> _transactionTypes = [];
  List<LookupItem> _transactionStatuses = [];
  bool _loading = true;

  String? _selectedPartnerId;
  String? _selectedStatusValue;
  String? _selectedTransactionTypeValue;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  String _selectedDatePreset = 'all';

  @override
  void initState() {
    super.initState();
    _selectedPartnerId = widget.initialPartnerId;
    _selectedStatusValue =
        widget.initialStatus?.toString() ?? widget.initialStatusValue;
    _selectedTransactionTypeValue = widget.initialTransactionType?.toString() ??
        widget.initialTransactionTypeValue;
    _selectedDateFrom = widget.initialDateFrom;
    _selectedDateTo = widget.initialDateTo;
    if (_selectedDateFrom != null || _selectedDateTo != null) {
      _selectedDatePreset = 'custom';
    } else {
      _selectedDatePreset = 'all';
    }

    // Əgər keşdə məlumat varsa, dərhal göstəririk (təkrar şəbəkə sorğusu getmir)
    if (TransactionService.hasLookupsCache) {
      _transactionTypes = TransactionService.cachedTransactionTypes ?? [];
      _transactionStatuses =
          TransactionService.cachedTransactionStatuses ?? [];
      _partners = TransactionService.cachedPartners ?? [];
      _loading = false;
    } else {
      _loadLookups();
    }
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _transactionService.getLookupTransactionTypes(),
        _transactionService.getLookupTransactionStatuses(),
        _transactionService.getLookupPartners(),
      ]);

      if (mounted) {
        setState(() {
          _transactionTypes = results[0];
          _transactionStatuses = results[1];
          _partners = results[2];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedPartnerId = null;
      _selectedStatusValue = null;
      _selectedTransactionTypeValue = null;
      _selectedDateFrom = null;
      _selectedDateTo = null;
      _selectedDatePreset = 'all';
    });
  }

  void _applyFilters() {
    String? partnerName;
    if (_selectedPartnerId != null) {
      for (final p in _partners) {
        if (p.value == _selectedPartnerId) {
          partnerName = p.label;
          break;
        }
      }
    }

    String? statusName;
    if (_selectedStatusValue != null) {
      for (final s in _transactionStatuses) {
        if (s.value == _selectedStatusValue) {
          statusName = s.label;
          break;
        }
      }
    }

    String? typeName;
    if (_selectedTransactionTypeValue != null) {
      for (final t in _transactionTypes) {
        if (t.value == _selectedTransactionTypeValue) {
          typeName = t.label;
          break;
        }
      }
    }

    Navigator.of(context).pop(
      HistoryFilterResult(
        partnerId: _selectedPartnerId,
        partnerName: partnerName,
        status: _selectedStatusValue,
        statusName: statusName,
        statusValue: _selectedStatusValue,
        transactionType: _selectedTransactionTypeValue,
        transactionTypeName: typeName,
        transactionTypeValue: _selectedTransactionTypeValue,
        dateFrom: _selectedDateFrom,
        dateTo: _selectedDateTo,
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialDate = isFrom
        ? (_selectedDateFrom ?? DateTime.now())
        : (_selectedDateTo ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      confirmText: tr('filter_select'),
      cancelText: tr('common_cancel'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.base,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.base,
                    onPrimary: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDatePreset = 'custom';
        if (isFrom) {
          _selectedDateFrom = picked;
          if (_selectedDateTo != null && _selectedDateTo!.isBefore(picked)) {
            _selectedDateTo = picked;
          }
        } else {
          _selectedDateTo = picked;
          if (_selectedDateFrom != null && _selectedDateFrom!.isAfter(picked)) {
            _selectedDateFrom = picked;
          }
        }
      });
    }
  }

  void _setDatePreset(String preset) {
    if (_selectedDatePreset == preset && preset != 'all') {
      setState(() {
        _selectedDatePreset = 'all';
        _selectedDateFrom = null;
        _selectedDateTo = null;
      });
      return;
    }

    final now = DateTime.now();
    setState(() {
      _selectedDatePreset = preset;
      switch (preset) {
        case 'all':
          _selectedDateFrom = null;
          _selectedDateTo = null;
          break;
        case 'today':
          _selectedDateFrom = DateTime(now.year, now.month, now.day);
          _selectedDateTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'last7':
          _selectedDateFrom = now.subtract(const Duration(days: 7));
          _selectedDateTo = now;
          break;
        case 'month':
          _selectedDateFrom = DateTime(now.year, now.month, 1);
          _selectedDateTo = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
      }
    });
  }

  String _formatDateShort(DateTime? dt) {
    if (dt == null) return tr('filter_select_date');
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final chipBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final borderColor =
        isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final hasChanges = (_selectedPartnerId != null &&
            _selectedPartnerId!.isNotEmpty) ||
        _selectedStatusValue != null ||
        _selectedTransactionTypeValue != null ||
        _selectedDateFrom != null ||
        _selectedDateTo != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryTextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('history_filters_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                if (hasChanges)
                  GestureDetector(
                    onTap: _clearFilters,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        tr('filter_reset'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.base,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.base,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. TARİX ARALIĞI (LAP YUXARI HİSSƏDƏ)
                        Text(
                          tr('filter_date_range'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Tez seçim düymələri
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSelectableChip(
                              label: tr('filter_all'),
                              isSelected: _selectedDatePreset == 'all' &&
                                  _selectedDateFrom == null &&
                                  _selectedDateTo == null,
                              onTap: () => _setDatePreset('all'),
                              chipBg: chipBg,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                            _buildSelectableChip(
                              label: tr('history_today'),
                              isSelected: _selectedDatePreset == 'today',
                              onTap: () => _setDatePreset('today'),
                              chipBg: chipBg,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                            _buildSelectableChip(
                              label: tr('filter_last_7_days'),
                              isSelected: _selectedDatePreset == 'last7',
                              onTap: () => _setDatePreset('last7'),
                              chipBg: chipBg,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                            _buildSelectableChip(
                              label: tr('filter_this_month'),
                              isSelected: _selectedDatePreset == 'month',
                              onTap: () => _setDatePreset('month'),
                              chipBg: chipBg,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tarix qutuları (Başlanğıc və Bitmə)
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateBox(
                                label: tr('filter_start_date'),
                                value: _formatDateShort(_selectedDateFrom),
                                isSelected: _selectedDateFrom != null,
                                onTap: () => _pickDate(isFrom: true),
                                onClear: _selectedDateFrom != null
                                    ? () => setState(() {
                                        _selectedDateFrom = null;
                                        if (_selectedDateTo == null) {
                                          _selectedDatePreset = 'all';
                                        } else {
                                          _selectedDatePreset = 'custom';
                                        }
                                      })
                                    : null,
                                chipBg: chipBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateBox(
                                label: tr('filter_end_date'),
                                value: _formatDateShort(_selectedDateTo),
                                isSelected: _selectedDateTo != null,
                                onTap: () => _pickDate(isFrom: false),
                                onClear: _selectedDateTo != null
                                    ? () => setState(() {
                                        _selectedDateTo = null;
                                        if (_selectedDateFrom == null) {
                                          _selectedDatePreset = 'all';
                                        } else {
                                          _selectedDatePreset = 'custom';
                                        }
                                      })
                                    : null,
                                chipBg: chipBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 2. ƏMƏLİYYAT NÖVÜ
                        if (_transactionTypes.isNotEmpty) ...[
                          Text(
                            tr('history_transaction_type'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSelectableChip(
                                label: tr('filter_all'),
                                isSelected:
                                    _selectedTransactionTypeValue == null,
                                onTap: () => setState(() =>
                                    _selectedTransactionTypeValue = null),
                                chipBg: chipBg,
                                borderColor: borderColor,
                                textColor: textColor,
                              ),
                              ..._transactionTypes.map(
                                (item) {
                                  final isSelected =
                                      _selectedTransactionTypeValue ==
                                          item.value;
                                  return _buildSelectableChip(
                                    label: item.label,
                                    isSelected: isSelected,
                                    onTap: item.disabled
                                        ? null
                                        : () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedTransactionTypeValue =
                                                    null;
                                              } else {
                                                _selectedTransactionTypeValue =
                                                    item.value;
                                              }
                                            });
                                          },
                                    chipBg: chipBg,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 3. STATUSLAR
                        if (_transactionStatuses.isNotEmpty) ...[
                          Text(
                            tr('history_status'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSelectableChip(
                                label: tr('filter_all'),
                                isSelected: _selectedStatusValue == null,
                                onTap: () => setState(
                                    () => _selectedStatusValue = null),
                                chipBg: chipBg,
                                borderColor: borderColor,
                                textColor: textColor,
                              ),
                              ..._transactionStatuses.map(
                                (item) {
                                  final isSelected =
                                      _selectedStatusValue == item.value;
                                  return _buildSelectableChip(
                                    label: item.label,
                                    isSelected: isSelected,
                                    onTap: item.disabled
                                        ? null
                                        : () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedStatusValue = null;
                                              } else {
                                                _selectedStatusValue =
                                                    item.value;
                                              }
                                            });
                                          },
                                    chipBg: chipBg,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 4. TƏRƏFDAŞLAR
                        if (_partners.isNotEmpty) ...[
                          Text(
                            tr('history_filter_partner'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSelectableChip(
                                label: tr('filter_all'),
                                isSelected: _selectedPartnerId == null,
                                onTap: () =>
                                    setState(() => _selectedPartnerId = null),
                                chipBg: chipBg,
                                borderColor: borderColor,
                                textColor: textColor,
                              ),
                              ..._partners.map(
                                (item) {
                                  final isSelected =
                                      _selectedPartnerId == item.value;
                                  return _buildSelectableChip(
                                    label: item.label,
                                    isSelected: isSelected,
                                    onTap: item.disabled
                                        ? null
                                        : () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedPartnerId = null;
                                              } else {
                                                _selectedPartnerId =
                                                    item.value;
                                              }
                                            });
                                          },
                                    chipBg: chipBg,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
          ),

          // Bottom Button
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + (bottomInset > 0 ? bottomInset : 8),
            ),
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                top: BorderSide(
                  color: borderColor,
                  width: 0.5,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.base,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  tr('filter_apply'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
    required Color chipBg,
    required Color borderColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.base : chipBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.base : borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDateBox({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback? onClear,
    required Color chipBg,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.base.withValues(alpha: 0.08)
              : chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.base : borderColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.base : secondaryTextColor,
                  ),
                ),
                if (isSelected && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.base,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isSelected ? AppColors.base : secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.base : textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
