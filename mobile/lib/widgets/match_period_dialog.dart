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
    final y = int.parse(text.substring(0, 4));
    final m = int.parse(text.substring(4, 6));
    final d = int.parse(text.substring(6, 8));
    final date = DateTime(y, m, d);
    return date.year == y && date.month == m && date.day == d ? date : null;
  }

  @override
  State<MatchPeriodDialog> createState() => _MatchPeriodDialogState();
}

class _MatchPeriodDialogState extends State<MatchPeriodDialog> {
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
    final initial = MatchPeriodDialog.parse(controller.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(AppSizes.matchSortPeriodFirstYear),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
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
    final reversed = from != null && to != null && from.isAfter(to);

    setState(() {
      _fromError = fromInvalid ? AppStrings.matchPeriodInvalidDate : null;
      _toError = toInvalid
          ? AppStrings.matchPeriodInvalidDate
          : (reversed ? AppStrings.matchPeriodReversed : null);
    });
    if (fromInvalid || toInvalid || reversed) return;

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
