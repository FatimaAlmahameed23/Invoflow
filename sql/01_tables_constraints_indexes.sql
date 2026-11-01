-- Final live InvoFlow export. Fresh-project migration; do not run on the existing project.
BEGIN;
SET LOCAL search_path = public, pg_catalog;
CREATE SEQUENCE public."invoice_number_seq" AS bigint INCREMENT BY 1 MINVALUE 1 NO MAXVALUE START WITH 1 CACHE 1 NO CYCLE;

CREATE TABLE public."user_settings" (
  "user_id" uuid NOT NULL,
  "default_currency" character varying(3) DEFAULT 'JOD'::character varying NOT NULL,
  "exchange_rate" numeric(18,6) DEFAULT 1.0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "usd_per_jod" numeric(18,6),
  "eur_per_jod" numeric(18,6)
);

CREATE TABLE public."products" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "name" text NOT NULL,
  "barcode" text,
  "price_jod" numeric(18,3) NOT NULL,
  "tax_rate" numeric(5,2) DEFAULT 0 NOT NULL,
  "tax_inclusive" boolean DEFAULT false NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public."invoices" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "invoice_number" text,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "currency" character varying(3) DEFAULT 'JOD'::character varying NOT NULL,
  "exchange_rate" numeric(18,6) DEFAULT 1 NOT NULL,
  "subtotal" numeric(18,3) DEFAULT 0 NOT NULL,
  "tax_total" numeric(18,3) DEFAULT 0 NOT NULL,
  "grand_total" numeric(18,3) DEFAULT 0 NOT NULL,
  "cancellation_reason" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "approved_at" timestamp with time zone,
  "cancelled_at" timestamp with time zone
);

CREATE TABLE public."invoice_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "invoice_id" uuid NOT NULL,
  "product_id" uuid NOT NULL,
  "product_name" text NOT NULL,
  "quantity" numeric(18,3) NOT NULL,
  "unit_price" numeric(18,3) NOT NULL,
  "tax_rate" numeric(5,2) DEFAULT 0 NOT NULL,
  "tax_inclusive" boolean DEFAULT false NOT NULL,
  "subtotal" numeric(18,3) DEFAULT 0 NOT NULL,
  "tax_amount" numeric(18,3) DEFAULT 0 NOT NULL,
  "line_total" numeric(18,3) DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public."invoices" ADD CONSTRAINT "cancellation_reason_length" CHECK ((length(cancellation_reason) <= 1000));

ALTER TABLE public."invoice_items" ADD CONSTRAINT "invoice_items_line_total_check" CHECK ((line_total >= (0)::numeric));

ALTER TABLE public."invoice_items" ADD CONSTRAINT "invoice_items_pkey" PRIMARY KEY (id);

ALTER TABLE public."invoice_items" ADD CONSTRAINT "invoice_items_product_name_check" CHECK ((length(TRIM(BOTH FROM product_name)) > 0));

ALTER TABLE public."invoice_items" ADD CONSTRAINT "invoice_items_quantity_check" CHECK ((quantity > (0)::numeric));

ALTER TABLE public."invoice_items" ADD CONSTRAINT "invoice_items_subtotal_check" CHECK ((subtotal >= (0)::numeric));

ALTER TABLE public."invoice_items" ADD CONSTRAINT "invoice_items_tax_amount_check" CHECK ((tax_amount >= (0)::numeric));

ALTER TABLE public."invoice_items" ADD CONSTRAINT "invoice_items_tax_rate_check" CHECK (((tax_rate >= (0)::numeric) AND (tax_rate <= (100)::numeric)));

ALTER TABLE public."invoice_items" ADD CONSTRAINT "invoice_items_unit_price_check" CHECK ((unit_price >= (0)::numeric));

ALTER TABLE public."invoices" ADD CONSTRAINT "invoice_lifecycle" CHECK ((((status = 'draft'::text) AND (invoice_number IS NULL) AND (approved_at IS NULL) AND (cancelled_at IS NULL) AND (cancellation_reason IS NULL)) OR ((status = 'approved'::text) AND (invoice_number IS NOT NULL) AND (approved_at IS NOT NULL) AND (cancelled_at IS NULL) AND (cancellation_reason IS NULL)) OR ((status = 'cancelled'::text) AND (invoice_number IS NOT NULL) AND (approved_at IS NOT NULL) AND (cancelled_at IS NOT NULL))));

ALTER TABLE public."invoices" ADD CONSTRAINT "invoice_rate_finite" CHECK (((exchange_rate < (1000000)::numeric) AND (((currency)::text <> 'JOD'::text) OR (exchange_rate = (1)::numeric))));

ALTER TABLE public."invoices" ADD CONSTRAINT "invoice_total_identity" CHECK ((grand_total = (subtotal + tax_total)));

ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_currency_check" CHECK (((currency)::text = ANY ((ARRAY['JOD'::character varying, 'USD'::character varying, 'EUR'::character varying])::text[])));

ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_exchange_rate_check" CHECK ((exchange_rate > (0)::numeric));

ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_grand_total_check" CHECK ((grand_total >= (0)::numeric));

ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_invoice_number_key" UNIQUE (invoice_number);

ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_pkey" PRIMARY KEY (id);

ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_status_check" CHECK ((status = ANY (ARRAY['draft'::text, 'approved'::text, 'cancelled'::text])));

ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_subtotal_check" CHECK ((subtotal >= (0)::numeric));

ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_tax_total_check" CHECK ((tax_total >= (0)::numeric));

ALTER TABLE public."invoice_items" ADD CONSTRAINT "item_price_finite" CHECK ((unit_price < ('1000000000000000'::bigint)::numeric));

ALTER TABLE public."invoice_items" ADD CONSTRAINT "item_quantity_bounded" CHECK ((quantity <= (999999)::numeric));

ALTER TABLE public."invoice_items" ADD CONSTRAINT "item_total_identity" CHECK ((line_total = (subtotal + tax_amount)));

ALTER TABLE public."products" ADD CONSTRAINT "product_price_finite" CHECK ((price_jod < ('1000000000000000'::bigint)::numeric));

ALTER TABLE public."products" ADD CONSTRAINT "products_barcode_key" UNIQUE (barcode);

ALTER TABLE public."products" ADD CONSTRAINT "products_name_check" CHECK ((length(TRIM(BOTH FROM name)) > 0));

ALTER TABLE public."products" ADD CONSTRAINT "products_pkey" PRIMARY KEY (id);

ALTER TABLE public."products" ADD CONSTRAINT "products_price_jod_check" CHECK ((price_jod >= (0)::numeric));

ALTER TABLE public."products" ADD CONSTRAINT "products_tax_rate_check" CHECK (((tax_rate >= (0)::numeric) AND (tax_rate <= (100)::numeric)));

ALTER TABLE public."user_settings" ADD CONSTRAINT "settings_currency_valid" CHECK (((default_currency)::text = ANY ((ARRAY['JOD'::character varying, 'USD'::character varying, 'EUR'::character varying])::text[])));

ALTER TABLE public."user_settings" ADD CONSTRAINT "settings_eur_valid" CHECK (((eur_per_jod > (0)::numeric) AND (eur_per_jod < (1000000)::numeric)));

ALTER TABLE public."user_settings" ADD CONSTRAINT "settings_usd_valid" CHECK (((usd_per_jod > (0)::numeric) AND (usd_per_jod < (1000000)::numeric)));

ALTER TABLE public."user_settings" ADD CONSTRAINT "user_settings_exchange_rate_check" CHECK ((exchange_rate > (0)::numeric));

ALTER TABLE public."user_settings" ADD CONSTRAINT "user_settings_pkey" PRIMARY KEY (user_id);

ALTER TABLE public."invoice_items" ADD CONSTRAINT "invoice_items_invoice_id_fkey" FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE;

ALTER TABLE public."invoice_items" ADD CONSTRAINT "invoice_items_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id);

ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public."user_settings" ADD CONSTRAINT "user_settings_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

CREATE INDEX invoice_items_invoice_idx ON public.invoice_items USING btree (invoice_id);

CREATE INDEX invoice_items_product_idx ON public.invoice_items USING btree (product_id);

CREATE INDEX invoices_user_created_idx ON public.invoices USING btree (user_id, created_at DESC);

COMMENT ON COLUMN public."invoices"."exchange_rate" IS 'Immutable snapshot: invoice currency units per 1 JOD. Converted unit prices rounded to 3 decimals.';

COMMENT ON COLUMN public."user_settings"."exchange_rate" IS 'Deprecated ambiguous legacy field. Unused by invoice operations. Use usd_per_jod and eur_per_jod.';

COMMENT ON COLUMN public."user_settings"."usd_per_jod" IS 'Manually configured USD units per 1 JOD. NULL means not configured.';

COMMENT ON COLUMN public."user_settings"."eur_per_jod" IS 'Manually configured EUR units per 1 JOD. NULL means not configured.';
COMMIT;
