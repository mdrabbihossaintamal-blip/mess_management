import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/meal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/meal_editor.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final date = data.selectedDate;

    return Scaffold(
      appBar: AppBar(title: const Text('দৈনিক মিল')),
      body: data.isLoading && data.monthMeals.isEmpty
          ? const LoadingView()
          : Column(
              children: [
                _dateNavigator(data, date),
                Expanded(child: _buildDateMealsGrid(data, date)),
              ],
            ),
    );
  }

  Widget _dateNavigator(DataProvider data, DateTime date) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                data.setSelectedDate(date.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) data.setSelectedDate(picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      AppUtils.formatDate(date),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      AppUtils.isSameDay(date, DateTime.now())
                          ? 'আজ'
                          : 'তারিখ নির্বাচন করুন',
                      style: const TextStyle(
                          color: primaryColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () =>
                data.setSelectedDate(date.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  Widget _buildDateMealsGrid(DataProvider data, DateTime date) {
    final members = data.activeMembers;
    final map = <String, Meal>{};
    for (final m in data.monthMeals) {
      if (AppUtils.isSameDay(m.date, date)) {
        map[m.memberId] = m;
      }
    }

    if (members.isEmpty) {
      return const EmptyState(message: 'কোনো সক্রিয় সদস্য নেই');
    }

    return MealEditorGrid(
      members: members,
      existingMeals: map,
      date: date,
      defaultBreakfast: data.settings?.defaultBreakfast ?? 0.5,
      defaultLunch: data.settings?.defaultLunch ?? 1,
      defaultDinner: data.settings?.defaultDinner ?? 1,
      onSave: (updated) async {
        try {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final batch = <String, Meal>{};
          for (final m in updated) {
            batch[m.memberId] = Meal(
              id: m.id,
              memberId: m.memberId,
              date: date,
              breakfast: m.breakfast,
              lunch: m.lunch,
              dinner: m.dinner,
              totalMeal: m.breakfast + m.lunch + m.dinner,
              createdBy: auth.uid,
            );
          }
          await data.updateMealsForDate(date, batch);
          if (context.mounted) {
            ConfirmDialog.showToast(context, 'মিল সংরক্ষিত হয়েছে');
          }
        } catch (e) {
          if (context.mounted) {
            ConfirmDialog.showToast(context, 'সংরক্ষণ ব্যর্থ হয়েছে', error: true);
          }
        }
      },
    );
  }
}