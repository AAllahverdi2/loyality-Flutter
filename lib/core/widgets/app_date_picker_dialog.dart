import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

/// GG/AA/İİİİ formatında daxil edilərkən 2-ci və 4-cü rəqəmdən sonra avtomatik '/' atan formatter
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // İstifadəçi simvol silirsə (backspace)
    if (newValue.text.length < oldValue.text.length) {
      // Əgər silinən simvol '/' idisə, onun qarşısındakı rəqəmi də silək ki, istifadəçi ilişib qalmasın
      if (oldValue.text.endsWith('/') && newValue.text.isNotEmpty) {
        final textWithoutPrevChar =
            newValue.text.substring(0, newValue.text.length - 1);
        return TextEditingValue(
          text: textWithoutPrevChar,
          selection:
              TextSelection.collapsed(offset: textWithoutPrevChar.length),
        );
      }
      return newValue;
    }

    // Yalnız rəqəmləri süzürük (maksimum 8 rəqəm: 2 gün, 2 ay, 4 il)
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 8) {
      return oldValue;
    }

    final buffer = StringBuffer();
    if (digits.length <= 2) {
      buffer.write(digits);
      // Əgər istifadəçi 06 yazıbsa, dərhal '/' atılır
      if (digits.length == 2) {
        buffer.write('/');
      }
    } else if (digits.length <= 4) {
      buffer.write(digits.substring(0, 2));
      buffer.write('/');
      buffer.write(digits.substring(2));
      // Əgər istifadəçi 20 yazıbsa, dərhal növbəti '/' atılır
      if (digits.length == 4) {
        buffer.write('/');
      }
    } else {
      buffer.write(digits.substring(0, 2));
      buffer.write('/');
      buffer.write(digits.substring(2, 4));
      buffer.write('/');
      buffer.write(digits.substring(4));
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  bool initialEntryModeInput = false,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AppDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialInputMode: initialEntryModeInput,
    ),
  );
}

class AppDatePickerDialog extends StatefulWidget {
  const AppDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.initialInputMode = false,
    super.key,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool initialInputMode;

  @override
  State<AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<AppDatePickerDialog> {
  late DateTime _selectedDate;
  late TextEditingController _textController;
  late bool _isInputMode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _isInputMode = widget.initialInputMode;
    final d = _selectedDate.day.toString().padLeft(2, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final y = _selectedDate.year.toString();
    _textController = TextEditingController(text: '$d/$m/$y');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _formatHeaderDate(DateTime dt) {
    const monthsAz = [
      'iyn', // 6
      'yan', 'fev', 'mar', 'apr', 'may', 'iyn',
      'iyl', 'avq', 'sen', 'okt', 'noy', 'dek'
    ];
    final realMonth = dt.month;
    final mName = monthsAz[realMonth];

    const weekdaysAz = [
      'B.e.', 'Ç.a.', 'Ç.', 'C.a.', 'C.', 'Ş.', 'B.'
    ];
    final wName = weekdaysAz[(dt.weekday - 1) % 7];

    return '${dt.day} $mName, $wName';
  }

  DateTime? _parseDateString(String text) {
    final clean = text.replaceAll('.', '/').replaceAll('-', '/');
    final parts = clean.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    if (y < 1920 || y > widget.lastDate.year) return null;
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;

    try {
      final dt = DateTime(y, m, d);
      if (dt.isAfter(widget.lastDate) || dt.isBefore(widget.firstDate)) {
        return null;
      }
      return dt;
    } catch (_) {
      return null;
    }
  }

  void _onConfirm() {
    if (_isInputMode) {
      final parsed = _parseDateString(_textController.text.trim());
      if (parsed == null) {
        setState(() {
          _errorText = 'Düzgün tarix daxil edin (GG/AA/İİİİ)';
        });
        return;
      }
      Navigator.of(context).pop(parsed);
    } else {
      Navigator.of(context).pop(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final activeColor = AppColors.base;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 330,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Label & Switch mode icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('personal_birth_date'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isInputMode
                        ? Icons.calendar_today_rounded
                        : Icons.edit_rounded,
                    size: 22,
                    color: textColor,
                  ),
                  tooltip: _isInputMode ? 'Təqvim rejimi' : 'Yazı rejimi',
                  onPressed: () {
                    setState(() {
                      _isInputMode = !_isInputMode;
                      _errorText = null;
                      if (!_isInputMode) {
                        final parsed =
                            _parseDateString(_textController.text.trim());
                        if (parsed != null) {
                          _selectedDate = parsed;
                        }
                      }
                    });
                  },
                ),
              ],
            ),

            // Big Date Header (məsələn: 7 iyn, Ç.)
            Text(
              _formatHeaderDate(_selectedDate),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
            ),
            const SizedBox(height: 16),

            // Main Body: Input Mode OR Calendar Mode
            if (_isInputMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _textController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        DateInputFormatter(),
                      ],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: 2,
                      ),
                      onChanged: (val) {
                        final parsed = _parseDateString(val);
                        if (parsed != null) {
                          setState(() {
                            _selectedDate = parsed;
                            _errorText = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: tr('personal_birth_date'),
                        labelStyle: TextStyle(
                          color: _errorText != null
                              ? AppColors.error
                              : activeColor,
                          fontSize: 14,
                        ),
                        hintText: 'GG/AA/İİİİ',
                        hintStyle: TextStyle(
                          color: secondaryTextColor.withValues(alpha: 0.5),
                          letterSpacing: 1,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: _errorText != null
                                ? AppColors.error
                                : (isDark
                                    ? const Color(0xFF3F3F46)
                                    : const Color(0xFFD1D5DB)),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: _errorText != null
                                ? AppColors.error
                                : activeColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                height: 310,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: isDark
                        ? ColorScheme.dark(
                            primary: activeColor,
                            onPrimary: Colors.white,
                            surface: bgColor,
                            onSurface: Colors.white,
                          )
                        : ColorScheme.light(
                            primary: activeColor,
                            onPrimary: Colors.white,
                            surface: bgColor,
                            onSurface: const Color(0xFF111827),
                          ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    initialCalendarMode: DatePickerMode.day,
                    onDateChanged: (newDate) {
                      setState(() {
                        _selectedDate = newDate;
                        final d =
                            newDate.day.toString().padLeft(2, '0');
                        final m =
                            newDate.month.toString().padLeft(2, '0');
                        final y = newDate.year.toString();
                        _textController.text = '$d/$m/$y';
                      });
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Bottom Buttons: Ləğv et & Təsdiqlə
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    tr('common_cancel'),
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _onConfirm,
                  child: Text(
                    tr('common_confirm'),
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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
