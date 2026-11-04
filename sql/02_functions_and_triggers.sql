BEGIN;
SET LOCAL search_path = public, pg_catalog;
CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
BEGIN
 NEW.updated_at = NOW();
 RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_invoice_item(p_quantity numeric, p_unit_price numeric, p_tax_rate numeric, p_tax_inclusive boolean)
 RETURNS TABLE(subtotal numeric, tax_amount numeric, line_total numeric)
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE
 v_total NUMERIC;
 v_subtotal NUMERIC;
 v_tax NUMERIC;
BEGIN
 IF p_quantity IS NULL OR p_quantity <= 0
 OR p_unit_price IS NULL OR p_unit_price < 0
 OR p_tax_rate IS NULL OR p_tax_rate < 0 OR p_tax_rate > 100
 OR p_tax_inclusive IS NULL THEN
 RAISE EXCEPTION 'Invalid invoice item parameters';
 END IF;

 v_total := p_quantity * p_unit_price;

 IF p_tax_inclusive THEN
 v_subtotal := ROUND(
 v_total / (1 + p_tax_rate / 100), 3
 );
 v_tax := ROUND(v_total - v_subtotal, 3);
 ELSE
 v_subtotal := ROUND(v_total, 3);
 v_tax := ROUND(v_total * p_tax_rate / 100, 3);
 END IF;

 RETURN QUERY SELECT
 v_subtotal,
 v_tax,
 ROUND(v_subtotal + v_tax, 3);
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_invoice(p_currency character varying, p_items jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 uid uuid := auth.uid(); rate numeric; iid uuid; x jsonb;
 p public.products%ROWTYPE; q numeric; price numeric; c record;
 seen uuid[] := '{}'; pid uuid; snapshots jsonb := '[]'::jsonb;
 subtotal_sum numeric := 0; tax_sum numeric := 0; total_sum numeric := 0;
BEGIN
 IF uid IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
 IF p_currency IS NULL OR p_currency NOT IN ('JOD','USD','EUR') THEN RAISE EXCEPTION 'Unsupported currency'; END IF;
 IF p_currency='JOD' THEN rate:=1; ELSE
 SELECT CASE p_currency WHEN 'USD' THEN usd_per_jod ELSE eur_per_jod END INTO rate FROM public.user_settings WHERE user_id=uid;
 END IF;
 IF rate IS NULL OR rate<=0 OR rate>=1000000 THEN RAISE EXCEPTION 'Configure a valid rate for the selected currency'; END IF;
 IF p_items IS NULL OR jsonb_typeof(p_items) IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Items must be an array'; END IF;
 IF jsonb_array_length(p_items) NOT BETWEEN 1 AND 500 THEN RAISE EXCEPTION 'Provide 1 to 500 items'; END IF;

 -- Validate and price every item before inserting the approved invoice.
 FOR x IN SELECT value FROM jsonb_array_elements(p_items) LOOP
  IF jsonb_typeof(x) IS DISTINCT FROM 'object' OR (x-'product_id'-'quantity') <> '{}'::jsonb OR jsonb_typeof(x->'product_id') IS DISTINCT FROM 'string' OR jsonb_typeof(x->'quantity') IS DISTINCT FROM 'number' THEN RAISE EXCEPTION 'Invalid item format'; END IF;
  pid := (x->>'product_id')::uuid; q := (x->>'quantity')::numeric;
  IF q<=0 OR q>999999 OR scale(q)>3 THEN RAISE EXCEPTION 'Invalid quantity'; END IF;
  IF pid=ANY(seen) THEN RAISE EXCEPTION 'Duplicate product'; END IF;
  seen := array_append(seen,pid);
  SELECT * INTO p FROM public.products WHERE id=pid AND is_active FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Product not found or inactive'; END IF;
  price := round(p.price_jod*rate,3);
  SELECT * INTO c FROM public.calculate_invoice_item(q,price,p.tax_rate,p.tax_inclusive);
  snapshots := snapshots || jsonb_build_array(jsonb_build_object(
   'product_id',p.id,'product_name',p.name,'quantity',q,'unit_price',price,
   'tax_rate',p.tax_rate,'tax_inclusive',p.tax_inclusive,
   'subtotal',c.subtotal,'tax_amount',c.tax_amount,'line_total',c.line_total));
  subtotal_sum := subtotal_sum+c.subtotal;
  tax_sum := tax_sum+c.tax_amount;
  total_sum := total_sum+c.line_total;
 END LOOP;

 INSERT INTO public.invoices(user_id,currency,exchange_rate,status,invoice_number,approved_at,subtotal,tax_total,grand_total)
 VALUES(uid,p_currency,rate,'approved','INV-' || nextval('public.invoice_number_seq'::regclass)::text,clock_timestamp(),subtotal_sum,tax_sum,total_sum)
 RETURNING id INTO iid;
 INSERT INTO public.invoice_items(invoice_id,product_id,product_name,quantity,unit_price,tax_rate,tax_inclusive,subtotal,tax_amount,line_total)
 SELECT iid,t.product_id,t.product_name,t.quantity,t.unit_price,t.tax_rate,t.tax_inclusive,t.subtotal,t.tax_amount,t.line_total
 FROM jsonb_to_recordset(snapshots) AS t(product_id uuid,product_name text,quantity numeric,unit_price numeric,tax_rate numeric,tax_inclusive boolean,subtotal numeric,tax_amount numeric,line_total numeric);
 RETURN iid;
END $function$;

CREATE OR REPLACE FUNCTION public.cancel_invoice(p_invoice_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE i public.invoices%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
 IF length(p_reason)>1000 THEN RAISE EXCEPTION 'Cancellation reason exceeds 1000 characters'; END IF;
 SELECT * INTO i FROM public.invoices WHERE id=p_invoice_id AND user_id=auth.uid() FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Invoice not found or unauthorized' USING ERRCODE='42501'; END IF;
 IF i.status<>'approved' THEN RAISE EXCEPTION 'Only approved invoices can be cancelled'; END IF;
 UPDATE public.invoices SET status='cancelled',cancelled_at=clock_timestamp(),cancellation_reason=nullif(btrim(p_reason),'') WHERE id=i.id;
 RETURN i.id;
END $function$;

CREATE OR REPLACE FUNCTION public.guard_invoice_history()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
BEGIN
 IF TG_OP='DELETE' THEN
 RAISE EXCEPTION 'Finalized invoices cannot be deleted';
 END IF;
 IF NEW.id<>OLD.id OR NEW.user_id<>OLD.user_id OR NEW.currency<>OLD.currency OR NEW.exchange_rate<>OLD.exchange_rate OR NEW.created_at<>OLD.created_at THEN RAISE EXCEPTION 'Invoice identity and currency snapshot are immutable'; END IF;
 IF OLD.status='cancelled' THEN RAISE EXCEPTION 'Cancelled invoices are immutable'; END IF;
 IF OLD.status<>'approved' OR NEW.status<>'cancelled' OR (to_jsonb(NEW)-'status'-'cancelled_at'-'cancellation_reason'-'updated_at') IS DISTINCT FROM (to_jsonb(OLD)-'status'-'cancelled_at'-'cancellation_reason'-'updated_at') THEN RAISE EXCEPTION 'Approved financial data is immutable'; END IF;
 RETURN NEW;
END $function$;

CREATE OR REPLACE FUNCTION public.guard_invoice_item_history()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE invoice_status text;
BEGIN
 IF TG_OP<>'INSERT' THEN RAISE EXCEPTION 'Finalized invoice items are immutable'; END IF;
 SELECT status INTO invoice_status FROM public.invoices WHERE id=NEW.invoice_id FOR UPDATE;
 -- INSERT is restricted to the owner-only creation function by table permissions.
 IF NOT FOUND OR invoice_status<>'approved' THEN
  RAISE EXCEPTION 'Items can only be inserted while creating an invoice';
 END IF;
 RETURN NEW;
END $function$;

CREATE TRIGGER guard_invoice_history BEFORE DELETE OR UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION guard_invoice_history();
CREATE TRIGGER guard_invoice_item_history BEFORE INSERT OR DELETE OR UPDATE ON public.invoice_items FOR EACH ROW EXECUTE FUNCTION guard_invoice_item_history();
CREATE TRIGGER trg_invoices_updated_at BEFORE UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_user_settings_updated_at BEFORE UPDATE ON public.user_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
COMMIT;
