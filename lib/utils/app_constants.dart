class AppConstants {
  static const String appName = 'মেস ম্যানেজমেন্ট';
  static const String adminRole = 'admin';
  static const String memberRole = 'member';

  static const List<String> expenseCategories = [
    'Rice', 'Fish', 'Meat', 'Vegetable', 'Dal', 'Oil', 'Salt',
    'Grocery', 'Gas', 'Water', 'Other',
  ];

  static const List<String> paymentMethods = [
    'Cash', 'bKash', 'Nagad', 'Bank', 'Other',
  ];

  static const List<String> cashInCategories = [
    'payment', 'other_income', 'opening', 'previous_balance',
  ];

  static const List<String> cashOutCategories = [
    'expense', 'gas', 'refund', 'other',
  ];

  static const List<String> mealOptions = ['0', '0.5', '1'];

  static const List<double> breakfastOptions = [0, 0.5, 1];
  static const List<double> lunchOptions = [0, 1];
  static const List<double> dinnerOptions = [0, 1];
}