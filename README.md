# InvoFlow – Flutter Technical Assessment

A Sales Invoice Management application developed using **Flutter, Supabase REST APIs, and PostgreSQL** for the Triosuite technical assessment.

## 1. How to Run the Project

**Requirements:** Flutter SDK, Android device/emulator, and Supabase credentials.

Clone the repository and install dependencies:

```bash
git clone https://github.com/FatimaAlmahameed23/Invoflow.git
cd Invoflow
flutter pub get
```

Create a `supabase.local.json` file in the project root containing the required Supabase configuration.

Run the application:

```bash
flutter run --dart-define-from-file=supabase.local.json
```

A pre-created test account is required to log in.

## 2. SQL Source Code

All SQL scripts are located in the [`sql/`](sql/) folder.

| File                                       | Description                                     |
| ------------------------------------------ | ----------------------------------------------- |
| `01_tables_constraints_indexes.sql`        | Database tables, constraints, and indexes       |
| `02_functions_and_triggers.sql`            | PostgreSQL functions and triggers               |
| `03_rls_and_permissions.sql`               | Row Level Security and permissions              |
| `04_product_catalog.sql`                   | Initial product data                            |
| `05_api_idempotency_and_rate_metadata.sql` | API idempotency and exchange-rate configuration |

## 3. Database Screenshots

Screenshots of all five database tables are available in:

[`docs/screenshots/database/`](docs/screenshots/database/)

Tables included: `invoices`, `invoice_items`, `products`, `user_settings`, and `invoice_api_requests`.

## 4. Application Screenshots

Screenshots of the five application screens are available in:

[`docs/screenshots/app/`](docs/screenshots/app/)

Screens included: Login, Invoice List, Create Invoice, Invoice Details, and Settings.

## 5. APK

The APK is provided separately with the submission.

To build the release APK:

```bash
flutter build apk --release --dart-define-from-file=supabase.local.json
```
