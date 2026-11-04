-- Run as the database owner in a disposable Supabase database after setup.
-- Fixtures and changes are rolled back.
BEGIN;
DO $test$
DECLARE
 uid uuid := gen_random_uuid(); pid uuid := gen_random_uuid();
 payload jsonb; response jsonb; replay jsonb; iid uuid;
BEGIN
 INSERT INTO auth.users(id) VALUES(uid);
 PERFORM set_config('request.jwt.claim.sub',uid::text,true);
 INSERT INTO public.products(id,name,price_jod,tax_rate,tax_inclusive)
 VALUES(pid,'Invoice lifecycle test',100,16,false);
 payload := jsonb_build_object('currency','JOD','items',jsonb_build_array(
  jsonb_build_object('product_id',pid,'quantity',2)));
 response := public.execute_invoice_request('test-create-001','create',payload);
 iid := (response->'invoice'->>'id')::uuid;
 IF response->'invoice'->>'status' IS DISTINCT FROM 'approved'
 OR response->'invoice'->>'invoice_number' IS NULL
 OR response->'invoice'->>'approved_at' IS NULL
 OR (response->'invoice'->>'subtotal')::numeric IS DISTINCT FROM 200
 OR (response->'invoice'->>'tax_total')::numeric IS DISTINCT FROM 32
 OR (response->'invoice'->>'grand_total')::numeric IS DISTINCT FROM 232
 OR jsonb_array_length(response->'invoice'->'items') IS DISTINCT FROM 1
 THEN RAISE EXCEPTION 'Invalid approved invoice'; END IF;

 replay := public.execute_invoice_request('test-create-001','create',payload);
 IF replay->'replayed' IS DISTINCT FROM 'true'::jsonb
 OR replay->'invoice' IS DISTINCT FROM response->'invoice'
 THEN RAISE EXCEPTION 'Idempotent replay changed the invoice'; END IF;

 BEGIN
  PERFORM public.execute_invoice_request('test-create-001','create',payload || '{"currency":"USD"}'::jsonb);
  RAISE EXCEPTION 'Expected idempotency conflict';
 EXCEPTION WHEN unique_violation THEN NULL;
 END;
 BEGIN
  PERFORM public.execute_invoice_request('test-approve-001','approve',jsonb_build_object('invoice_id',iid));
  RAISE EXCEPTION 'Expected unsupported operation';
 EXCEPTION WHEN invalid_parameter_value THEN NULL;
 END;
 BEGIN
  PERFORM public.execute_invoice_request('test-edit-001','edit',jsonb_build_object('invoice_id',iid));
  RAISE EXCEPTION 'Expected unsupported operation';
 EXCEPTION WHEN invalid_parameter_value THEN NULL;
 END;
 BEGIN
  UPDATE public.invoice_items SET quantity=3 WHERE invoice_id=iid;
  RAISE EXCEPTION 'Item mutation unexpectedly succeeded' USING ERRCODE='23514';
 EXCEPTION WHEN raise_exception THEN NULL;
 END;
 BEGIN
  UPDATE public.invoices SET subtotal=201,grand_total=233 WHERE id=iid;
  RAISE EXCEPTION 'Invoice mutation unexpectedly succeeded' USING ERRCODE='23514';
 EXCEPTION WHEN raise_exception THEN NULL;
 END;
 IF has_function_privilege('authenticated','public.create_invoice(character varying,jsonb)','EXECUTE')
 OR has_table_privilege('authenticated','public.invoice_items','INSERT')
 OR has_table_privilege('service_role','public.invoice_items','INSERT')
 OR has_table_privilege('service_role','public.invoices','INSERT')
 THEN RAISE EXCEPTION 'Creation helpers or tables are publicly writable'; END IF;

 response := public.execute_invoice_request('test-cancel-001','cancel',jsonb_build_object('invoice_id',iid));
 IF response->'invoice'->>'status' IS DISTINCT FROM 'cancelled'
 THEN RAISE EXCEPTION 'Cancellation failed'; END IF;
END $test$;
ROLLBACK;
