import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../models/member.dart';
import '../utils/app_utils.dart';
import '../utils/theme.dart';

class MealEditorValues {
  final String id;
  final String memberId;
  final String memberName;
  double breakfast;
  double lunch;
  double dinner;

  MealEditorValues({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  double get total => breakfast + lunch + dinner;
}

class MealEditorGrid extends StatefulWidget {
  final List<Member> members;
  final Map<String, Meal> existingMeals;
  final DateTime date;
  final double defaultBreakfast;
  final double defaultLunch;
  final double defaultDinner;
  final Future<void> Function(List<Meal>) onSave;

  const MealEditorGrid({
    super.key,
    required this.members,
    required this.existingMeals,
    required this.date,
    required this.defaultBreakfast,
    required this.defaultLunch,
    required this.defaultDinner,
    required this.onSave,
  });

  @override
  State<MealEditorGrid> createState() => _MealEditorGridState();
}

class _MealEditorGridState extends State<MealEditorGrid> {
  late List<MealEditorValues> _rows;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initRows();
  }

  @override
  void didUpdateWidget(covariant MealEditorGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date.day != widget.date.day) {
      _initRows();
    }
  }

  void _initRows() {
    _rows = widget.members.map((m) {
      final existing = widget.existingMeals[m.id];
      return MealEditorValues(
        id: existing?.id ?? '',
        memberId: m.id,
        memberName: m.name,
        breakfast: existing?.breakfast ?? widget.defaultBreakfast,
        lunch: existing?.lunch ?? widget.defaultLunch,
        dinner: existing?.dinner ?? widget.defaultDinner,
      );
    }).toList();
  }

  void _setValue(int index, int mealType, double value) {
    setState(() {
      switch (mealType) {
        case 0:
          _rows[index].breakfast = value;
          break;
        case 1:
          _rows[index].lunch = value;
          break;
        case 2:
          _rows[index].dinner = value;
          break;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final meals = _rows.map((r) {
        return Meal(
          id: r.id,
          memberId: r.memberId,
          date: widget.date,
          breakfast: r.breakfast,
          lunch: r.lunch,
          dinner: r.dinner,
          totalMeal: r.breakfast + r.lunch + r.dinner,
        );
      }).toList();
      await widget.onSave(meals);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _headerRow(),
        Expanded(
          child: ListView.builder(
            itemCount: _rows.length,
            itemBuilder: (context, i) => _memberRow(i),
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _headerRow() {
    return Container(
      color: const Color(0xFFE8EEF6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('নাম', style: _h)),
          SizedBox(width: 40, child: Text('নাস্তা', textAlign: TextAlign.center, style: _h)),
          SizedBox(width: 40, child: Text('দুপুর', textAlign: TextAlign.center, style: _h)),
          SizedBox(width: 40, child: Text('রাত', textAlign: TextAlign.center, style: _h)),
          SizedBox(width: 46, child: Text('মোট', textAlign: TextAlign.center, style: _h)),
        ],
      ),
    );
  }

  static const _h = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary);

  Widget _memberRow(int index) {
    final r = _rows[index];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: bgColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              r.memberName,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _mealStepper(index, 0, r.breakfast),
          _mealStepper(index, 1, r.lunch),
          _mealStepper(index, 2, r.dinner),
          SizedBox(
            width: 46,
            child: Text(
              AppUtils.formatAmount(r.total),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealStepper(int index, int type, double value) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          InkWell(
            onTap: () => _picker(index, type),
            child: Container(
              width: 38,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value > 0
                    ? secondaryColor.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: value > 0 ? secondaryColor : Colors.grey),
              ),
              child: Text(
                AppUtils.formatAmount(value),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: value > 0 ? secondaryColor : textSecondary,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () =>
                    _setValue(index, type, (value - 0.5).clamp(0, 3)),
                child: const Icon(Icons.remove_circle_outline,
                    size: 16, color: textSecondary),
              ),
              InkWell(
                onTap: () =>
                    _setValue(index, type, (value + 0.5).clamp(0, 3)),
                child: const Icon(Icons.add_circle_outline,
                    size: 16, color: secondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _picker(int index, int type) async {
    final current = type == 0
        ? _rows[index].breakfast
        : type == 1
            ? _rows[index].lunch
            : _rows[index].dinner;
    final options = [0.0, 0.5, 1.0];
    final chosen = await showDialog<double>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('মিল মান নির্বাচন করুন'),
        children: [
          ...options.map(
            (o) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, o),
              child: Text(
                AppUtils.formatAmount(o),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: o == current ? FontWeight.w700 : FontWeight.w400,
                  color: o == current ? primaryColor : textPrimary,
                ),
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, current),
            child: Text(
              'ম্যানুয়াল ($current)',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textSecondary),
            ),
          ),
        ],
      ),
    );
    if (chosen != null) _setValue(index, type, chosen);
  }

  Widget _footer() {
    final total = _rows.fold(0.0, (s, r) => s + r.total);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'মোট মিল: ${AppUtils.formatAmount(total)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: primaryColor),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 130,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('সেভ করুন'),
            ),
          ),
        ],
      ),
    );
  }
}