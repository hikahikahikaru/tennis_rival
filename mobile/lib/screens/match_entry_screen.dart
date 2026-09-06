import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/match_format.dart';
import '../widgets/selection_field.dart';
import '../widgets/match_date_picker.dart';
import '../widgets/opponent_picker_sheet.dart';

class MatchEntryScreen extends StatefulWidget {
  const MatchEntryScreen({super.key});

  @override
  State<MatchEntryScreen> createState() => _MatchEntryScreenState();
}

//TODO リファクタリング必要
class _MatchEntryScreenState extends State<MatchEntryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedOpponent = '未選択';
  MatchFormat _selectedFormat = MatchFormat.threeSets;

  // カレンダー部品を呼び出す処理
  Future<void> _handleDateSelection() async {
    final picked = await MatchDatePicker.show(context, _selectedDate);
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('yyyy年M月d日').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('試合結果を記録'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.matchInfo,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SelectionField(
              title: AppStrings.matchDate,
              value: formattedDate,
              icon: Icons.calendar_today,
              onTap: _handleDateSelection, // 切り出した処理を呼ぶだけ
            ),
            const SizedBox(height: 16),
            SelectionField(
              title: AppStrings.opponent,
              value: _selectedOpponent,
              icon: Icons.person_search,
              // シートを呼び出すだけ（setStateは将来、相手を選んでから実装）
              onTap: () => OpponentPickerSheet.show(context),
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.matchFormat,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<MatchFormat>(
                segments: [
                  ButtonSegment(
                    value: MatchFormat.oneSet,
                    label: Text(MatchFormat.oneSet.label),
                  ),
                  ButtonSegment(
                    value: MatchFormat.threeSets,
                    label: Text(MatchFormat.threeSets.label),
                  ),
                ],
                selected: {_selectedFormat},
                onSelectionChanged: (Set<MatchFormat> newSelection) {
                  setState(() {
                    _selectedFormat = newSelection.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                ),
                showSelectedIcon: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
