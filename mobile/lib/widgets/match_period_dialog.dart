import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

typedef MatchPeriod = ({DateTime? from, DateTime? to});

/// 開始日・終了日をyyyyMMddで手入力するダイアログ。カレンダーでも選択できる。
class MatchPeriodDialog extends StatefulWidget {
  final DateTime? from;
  final DateTime? to;

  const MatchPeriodDialog({super.key, this.from, this.to});

  static Future<MatchPeriod?> show(
    BuildContext context, {
    DateTime? from,
    DateTime? to,
  }) {
    return showDialog<MatchPeriod>(
      context: context,
      builder: (_) => MatchPeriodDialog(from: from, to: to),
    );
  }

  static String format(DateTime d) => '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  /// 8桁のyyyyMMddを日付に変換する。実在しない日付はnull。
  static DateTime? parse(String text) {
    if (text.length != AppSizes.matchPeriodInputLength) return null;
    if (!RegExp(r'^\d{8}$').hasMatch(text)) return null;
    final year = int.parse(text.substring(0, 4));
    final month = int.parse(text.substring(4, 6));
    final day = int.parse(text.substring(6, 8));
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  @override
  State<MatchPeriodDialog> createState() => _MatchPeriodDialogState();
}

class _MatchPeriodDialogState extends State<MatchPeriodDialog> {
  DateTime get _firstDate => DateTime(AppSizes.matchSortPeriodFirstYear);
  DateTime get _lastDate => DateTime(DateTime.now().year + 1, 12, 31);

  bool _isInRange(DateTime date) =>
      !date.isBefore(_firstDate) && !date.isAfter(_lastDate);

  late final _fromController = TextEditingController(
    text: widget.from == null ? '' : MatchPeriodDialog.format(widget.from!),
  );
  late final _toController = TextEditingController(
    text: widget.to == null ? '' : MatchPeriodDialog.format(widget.to!),
  );
  String? _fromError;
  String? _toError;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCalendar(TextEditingController controller) async {
    final now = DateTime.now();
    final entered = MatchPeriodDialog.parse(controller.text);
    final initial = entered != null && _isInRange(entered) ? entered : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _firstDate,
      lastDate: _lastDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null && mounted) {
      setState(() => controller.text = MatchPeriodDialog.format(picked));
    }
  }

  void _submit() {
    DateTime? parseField(String text) =>
        text.isEmpty ? null : MatchPeriodDialog.parse(text);

    final from = parseField(_fromController.text);
    final to = parseField(_toController.text);
    final fromInvalid = _fromController.text.isNotEmpty && from == null;
    final toInvalid = _toController.text.isNotEmpty && to == null;
    final fromOutOfRange = from != null && !_isInRange(from);
    final toOutOfRange = to != null && !_isInRange(to);
    final reversed = from != null && to != null && from.isAfter(to);
    final rangeError = AppStrings.matchPeriodOutOfRange(
      MatchPeriodDialog.format(_firstDate),
      MatchPeriodDialog.format(_lastDate),
    );

    setState(() {
      _fromError = fromInvalid
          ? AppStrings.matchPeriodInvalidDate
          : (fromOutOfRange ? rangeError : null);
      _toError = toInvalid
          ? AppStrings.matchPeriodInvalidDate
          : (toOutOfRange
              ? rangeError
              : (reversed ? AppStrings.matchPeriodReversed : null));
    });
    if (fromInvalid ||
        toInvalid ||
        fromOutOfRange ||
        toOutOfRange ||
        reversed) {
      return;
    }

    Navigator.pop(context, (from: from, to: to));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String? error,
    required bool autofocus,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(AppSizes.matchPeriodInputLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: AppStrings.matchPeriodHint,
        errorText: error,
        errorMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: AppStrings.matchPeriodCalendar,
          icon: const Icon(Icons.calendar_month),
          onPressed: () => _pickFromCalendar(controller),
        ),
      ),
      onSubmitted: (_) => _submit(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.matchPeriodTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildField(
            controller: _fromController,
            label: AppStrings.matchSortPeriodFrom,
            error: _fromError,
            autofocus: true,
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          _buildField(
            controller: _toController,
            label: AppStrings.matchSortPeriodTo,
            error: _toError,
            autofocus: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.matchPeriodCancel),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(AppStrings.matchPeriodApply),
        ),
      ],
    );
  }
}
