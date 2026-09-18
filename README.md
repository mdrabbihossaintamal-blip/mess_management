# মেস ম্যানেজমেন্ট (Mess Meal Management App)

A production-ready Android application for managing a small shared mess/hostel
(~10 members) with accurate meal, expense, payment and cash accounting.

Built with **Flutter + Firebase Authentication + Cloud Firestore**.

---

## 1. Features

- **Authentication** — Admin & Member login (username/phone + password/PIN).
  Passwords are stored only as SHA-256 hashes (never plain text).
- **Role-based access** — Admin has full control; Members are strictly
  read-only. Enforced both in UI **and** in Firestore security rules.
- **Member management** — add / edit / activate / deactivate / search members.
- **Daily meals** — grid entry for breakfast (default 0.5), lunch (1),
  dinner (1) with 0 / 0.5 / 1 / custom values, previous/next/today navigation,
  date picker and duplicate prevention.
- **Pika/Bazar expenses** — categories, amounts, paid-by, notes, edit/delete.
- **Payments** — member deposits with Cash/bKash/Nagad/Bank/Other, history.
- **Automatic accounting** — meal rate, per-member cost, due/advance,
  total collection, total expense, current cash.
- **Cash ledger** — opening cash + total cash in − total cash out
  = current cash balance.
- **Monthly life-cycle** — open a month, close/finalize it (freezes data),
  reopen with confirmation, start the next month without losing history.
- **Reports** — daily, monthly, per-member, expense-wise, payment-wise;
  exportable as **CSV** (Excel-compatible) and shareable.
- **Dashboard** — all key numbers on one screen for Admin and Member.
- **Optional notifications** — reminders for meals, payments, dues, closings.

---

## 2. Database Schema (Cloud Firestore)

```
users/{uid}                        (id == Firebase Auth uid)
  id, name, phone, email, username, passwordHash, role
     (role: 'admin' | 'member'), status ('active'|'inactive'), createdAt

lookup/{username}                  (public, used for username login)
  uid, role, name, email

members/{userId}                   (id == user document id)
  id, userId, name, phone, status, joinDate,
  currentMonthMeals, currentBalance

meals/{id}
  id, memberId, date (Timestamp), breakfast (double),
  lunch (double), dinner (double), totalMeal (double),
  createdBy, updatedAt, isDeleted (soft-delete)

expenses/{id}
  id, date, category (Rice/Fish/Meat/Vegetable/Dal/Oil/Salt/
     Grocery/Gas/Water/Other), description, amount (double),
     paidBy, note, createdBy, createdAt, isDeleted

payments/{id}
  id, memberId, date, amount (double), paymentMethod
     (Cash/bKash/Nagad/Bank/Other), note, createdBy, createdAt, isDeleted

cashTransactions/{id}
  id, date, type ('in'|'out'), category (payment/expense/opening/
     other_income/refund), amount, description, reference, createdBy,
     createdAt, isDeleted

monthlyAccounts/{year-month}       e.g. "2026-9"
  id, month, year, totalMeal, totalExpense, mealRate, totalCollection,
  openingCash, closingCash, otherIncome, totalCashIn, totalCashOut,
  status ('active'|'closed'|'reopened'), closedAt

monthlyMemberAccounts/{id}         (frozen per-member snapshot at close)
  id, monthlyAccountId, memberId, memberName, totalMeal, mealCost,
  totalPaid, due, advance

settings/main
  messId, messName, defaultBreakfast, defaultLunch, defaultDinner,
  openingCash, notificationsEnabled, createdAt

auditLogs/{id}                     (Admin action trail)
  action, targetType, targetId, changes, by, timestamp
```

Required composite indexes: see `firestore.indexes.json`.

---

## 3. Firebase Configuration Instructions

### 3.1 Create a Firebase project

1. Go to https://console.firebase.google.com and click **Add project**.
2. Name it (e.g. `mess-management`) and enable Google Analytics (optional).
3. Add an **Android app**:
   - Package name: `com.mess.management`
   - Download the generated **`google-services.json`**.
4. In **Build → Authentication → Sign-in method**, enable
   **Email/Password**.
5. In **Firestore Database**, click **Create database** and use test mode
   (Prod mode only after the rules below are deployed; a default mess must be
   created first).

### 3.2 Wire up the app

1. Copy `google-services.json` into `android/app/google-services.json`.
2. Edit the app's Firebase options in `lib/main.dart` — `Firebase.initializeApp()`
   will auto-read the Android config. (For other platforms add
   `DefaultFirebaseOptions` from `firebase_options.dart`.)

### 3.3 Deploy security rules & indexes

Install Firebase CLI, then from the project folder:

```bash
npm install -g firebase-tools
firebase login
firebase use --add            # select your project
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

> Important: do **not** run the app with a locked-down rules file before the
> first admin setup. Easiest path: temporarily set
> `allow read, write: if true;` on the `settings`, `users`, `lookup` and
> `members` rules, create the admin through the app UI, then restore the
> included `firestore.rules` and deploy. (Alternatively create the admin doc
> manually in the console with `role: 'admin'`.)

---

## 4. Admin Login / Setup Instructions

1. Install the APK and launch **মেস ম্যানেজমেন্ট**.
2. On **first launch** the app shows the **মেস সেটআপ** screen:
   - Mess name, Admin name, Phone, Username, Email (optional), Password
   - Initial cash balance
   - Default breakfast / lunch / dinner meal values
3. Tap **মেস তৈরি করুন**. The app:
   - creates the Admin Firebase Auth account + Firestore profile,
   - saves settings and opens the current month's account,
   - signs you in as Admin.

The Admin dashboard shows all statistics. Use the ✚ buttons to add
members, meals, bazar expenses and payments. Use the dashboard **report** and
**settings** icons for reports and monthly close/start operations.

Admin capabilities: manage members and their login credentials, enter meals,
add/edit/delete expenses & payments, view accounts, close/reopen months,
export reports, change settings.

---

## 5. Member Login Instructions

1. Admin adds a member from **সদস্য** tab. A default PIN `1234` (and a
   username derived from the name) is created — admin should note it.
2. Admin can change the member's username/PIN anytime via the member's
   **লগইন তথ্য** menu item.
3. The member logs in with **username or phone + PIN**.
4. Member sees only: own dashboard, own meals, own payments, own balance,
   and the mess monthly summary. **No** write access — blocked by both UI
   and Firestore rules.

---

## 6. Android APK Build Instructions

Prerequisites: Flutter SDK (>=3.1), Android Studio / Android SDK, Java 17.

Place `firebase_options.dart` / `google-services.json` as described in §3.

```bash
# 1. Get dependencies
flutter pub get

# 2. Build a release APK
flutter build apk --release

# 3. (Optional) split per-ABI APKs
flutter build apk --release --split-per-abi

# 4. Install on device
flutter install
```

Output APK: `build/app/outputs/flutter-apk/app-release.apk`.

Test debug build directly:

```bash
flutter run
```

---

## 7. Calculation Logic Explained

### Meal rate
```
MealRate = TotalBazarExpense / TotalMessMeal
```
Example: ৳25,000 / 250 meals = **৳100.00 per meal**.
The rate is computed with full double precision; only display rounds to 2 dp.

### Individual member account
```
MealCost   = MemberTotalMeal × MealRate
NetBalance = TotalPaid − MealCost
Due        = max(0, −NetBalance)      (NetBalance < 0)
Advance    = max(0,  NetBalance)      (NetBalance > 0)
```
Example — Rahim: 50 meals × ৳100 = ৳5,000 cost; paid ৳6,000
→ **Advance ৳1,000**.
Example — Karim: 50 meals × ৳100 = ৳5,000 cost; paid ৳4,000
→ **Due ৳1,000**.

### Cash accounting (separate from meal math)
```
CurrentCash = OpeningCash + TotalCashIn − TotalCashOut
```
Cash in: member payments, other income, previous balance.
Cash out: bazar expenses, gas, other expenses, refunds.
Total collection (sum of payments) is **not** the same as cash balance —
the two reconcile through this ledger.

### Monthly closing
On close, the app stores in `monthlyAccounts/YYYY-M`:
- final total meals, total expense, meal rate,
- member-wise meals, meal cost, payments, due/advance
  (in `monthlyMemberAccounts`),
- total collection, opening/closing cash.

The closing cash automatically becomes the **opening cash of the next month**.
Closed months are read-only; Admin may reopen them only with confirmation.

---

## 8. Environment Variables / Configuration

There are no runtime secrets in the app. Required configuration:

| Item | Where | Purpose |
|------|-------|---------|
| Firebase project | Firebase console | Auth + Firestore |
| `google-services.json` | `android/app/` | Android Firebase config |
| Firestore rules | `firestore.rules` | Backend security |
| Firestore indexes | `firestore.indexes.json` | Query performance |
| Flutter SDK | local env / `local.properties` | Build toolchain |

For Firebase CLI usage: `firebase.json` binds `firestore.rules`.

---

## 9. Security Rules

Full rules in **`firestore.rules`** (deploy with `firebase deploy`).

Summary:

| Collection            | Member                      | Admin            |
|-----------------------|-----------------------------|------------------|
| users                 | own doc read only           | read/write all   |
| lookup                | read only                   | read/write       |
| members               | own doc read only           | read/write       |
| meals                 | own records read only       | read/write       |
| expenses              | read only (mess summary)    | read/write       |
| payments              | own records read only       | read/write       |
| monthlyAccounts       | read only                   | read/write       |
| monthlyMemberAccounts | read only                   | read/write       |
| cashTransactions      | **no access**               | read/write       |
| settings              | read only                   | read/write       |
| auditLogs             | no access                   | read/create-only |

Members can **never** write to any collection from the backend. Admin writes
are the only writes allowed for the financial collections.

---

## 10. Sample Test Data

The app seeds realistic demo data automatically the first time it connects to
an **empty** Firestore database, so the dashboard/reports are immediately
testable:

- 10 members: Rahim, Karim, Hasan, Sakib, Nayeem, Rafi, Fahim, Imran,
  Tanvir, Arif (login: `{name}` e.g. `rahim`, PIN `1234` — create via
  Firestore Auth or re-create through the members screen).
- Last 5 days of meal entries (breakfast/lunch/dinner per member per day).
- Last 5 days of expenses (Rice, Fish, Meat, Vegetable, Dal …).
- 10 member payments (৳3,000–৳6,000 each).

Seeding runs automatically once (`_seeded` guard) and only when the
`members` collection is empty. See `lib/services/seed_service.dart`.
To disable, remove the `SeedService.maybeSeed(context)` call in `main.dart`.

---

## 11. Project Structure

```
lib/
  main.dart                  app bootstrap, routing, providers
  models/                    AppUser, Member, Meal, Expense, Payment,
                             CashTransaction, MonthlyAccount,
                             MonthlyMemberAccount, MessSettings
  services/
    auth_service.dart        Authentication + user/profile management
    firestore_service.dart   All Firestore CRUD + accounting queries
    mess_calculator.dart     Pure accounting formulas & summary builder
    report_service.dart      CSV export (Excel-compatible)
    notification_service.dart Local notifications
    seed_service.dart        Sample-data seeding
  providers/
    auth_provider.dart       Session/role state
    data_provider.dart       Admin data + derived summary
    member_data_provider.dart Member-scoped data
  screens/
    splash_screen.dart, home_shell.dart (bottom nav)
    auth/  login_screen.dart, setup_screen.dart
    admin/ dashboard, meals, bazar, payments, members, reports, settings,
           member_account_detail_screen.dart
    member/ dashboard, meals, payments, balance, reports
  widgets/  common_widgets.dart, meal_editor.dart
  utils/    app_utils.dart, app_constants.dart, theme.dart
firestore.rules, firestore.json, firestore.indexes.json
```

## 12. Code of Conduct / Accuracy guarantee

All financial math is computed from the source-of-truth collections
(`meals`, `expenses`, `payments`, `cashTransactions`) at read time through
`MessCalculator`, and snapshotted into `monthlyAccounts` at month close.
There are **no floating-point truncation** shortcuts in the formulas — Taka
amounts display to 2 decimal places, meal totals display with up to 1 d.p.