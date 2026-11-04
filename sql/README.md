# Invoice database setup

The numbered SQL files are bootstrap scripts for a new Supabase database; run
them in numeric order. They are not upgrade migrations for an existing database.

Invoice creation uses `execute_invoice_request(key, 'create', payload)` with
`currency` and `items`. It validates all items, snapshots prices and tax, computes
totals, assigns an invoice number, and saves an approved invoice and its items
atomically. There is no separate editing or approval operation. Reusing the same
key and payload returns the original invoice; a different payload is rejected.

Approved financial data and saved items are immutable. The existing `cancel`
operation remains available. Creation and cancellation helpers are private;
authenticated callers use the idempotent request function.

`tests/invoice_creation.sql` checks creation, totals, replay, unsupported
operations, immutability, permissions, and cancellation. Run it as the database
owner against a disposable Supabase database after setup; it rolls back fixtures.

The cancellation schema still uses `cancelled`, while the Flutter API expects
`deleted`. The API must translate this existing difference.

Changing these files does not update a deployed database or its API handlers.
An existing installation needs a separate migration that explicitly handles
legacy unfinished invoices, replaces the old functions and permissions, and
updates the status constraints. Do not rerun bootstrap scripts over live data.
