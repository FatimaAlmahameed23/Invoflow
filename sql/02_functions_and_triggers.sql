-- Final live InvoFlow export. Fresh-project migration; do not run on the existing project.
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

CREATE OR REPLACE FUNCTION public.recalculate_invoice_totals(p_invoice_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE
 v_status TEXT;
BEGIN
 SELECT status
 INTO v_status
 FROM public.invoices
 WHERE id = p_invoice_id
 FOR UPDATE;

 IF NOT FOUND THEN
 RAISE EXCEPTION 'Invoice not found';
 END IF;

 IF v_status <> 'draft' THEN
 RAISE EXCEPTION
 'Only draft invoices can be recalculated';
 END IF;

 UPDATE public.invoices
 SET
 subtotal = totals.subtotal,
 tax_total = totals.tax_total,
 grand_total = totals.grand_total
 FROM (
 SELECT
 COALESCE(SUM(subtotal), 0) AS subtotal,
 COALESCE(SUM(tax_amount), 0) AS tax_total,
 COALESCE(SUM(line_total), 0) AS grand_total
 FROM public.invoice_items
 WHERE invoice_id = p_invoice_id
 ) AS totals
 WHERE id = p_invoice_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.replace_draft_items(p_invoice_id uuid, p_items jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE i public.invoices%ROWTYPE; x jsonb; p public.products%ROWTYPE; q numeric; price numeric; c record; seen uuid[] := '{}'; pid uuid;
BEGIN
 SELECT * INTO i FROM public.invoices WHERE id=p_invoice_id FOR UPDATE;
 IF NOT FOUND OR i.status <> 'draft' THEN RAISE EXCEPTION 'Draft invoice required'; END IF;
 IF p_items IS NULL OR jsonb_typeof(p_items) IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Items must be an array'; END IF;
 IF jsonb_array_length(p_items) NOT BETWEEN 1 AND 500 THEN RAISE EXCEPTION 'Provide 1 to 500 items'; END IF;
 DELETE FROM public.invoice_items WHERE invoice_id=p_invoice_id;
 FOR x IN SELECT value FROM jsonb_array_elements(p_items) LOOP
 IF jsonb_typeof(x) IS DISTINCT FROM 'object' OR (x-'product_id'-'quantity') <> '{}'::jsonb OR jsonb_typeof(x->'product_id') IS DISTINCT FROM 'string' OR jsonb_typeof(x->'quantity') IS DISTINCT FROM 'number' THEN RAISE EXCEPTION 'Invalid item format'; END IF;
 pid := (x->>'product_id')::uuid; q := (x->>'quantity')::numeric;
 IF q<=0 OR q>999999 OR scale(q)>3 THEN RAISE EXCEPTION 'Invalid quantity'; END IF;
 IF pid=ANY(seen) THEN RAISE EXCEPTION 'Duplicate product'; END IF;
 seen := array_append(seen,pid);
 SELECT * INTO p FROM public.products WHERE id=pid AND is_active FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Product not found or inactive'; END IF;
 price := round(p.price_jod*i.exchange_rate,3);
 SELECT * INTO c FROM public.calculate_invoice_item(q,price,p.tax_rate,p.tax_inclusive);
 INSERT INTO public.invoice_items(invoice_id,product_id,product_name,quantity,unit_price,tax_rate,tax_inclusive,subtotal,tax_amount,line_total) VALUES(i.id,p.id,p.name,q,price,p.tax_rate,p.tax_inclusive,c.subtotal,c.tax_amount,c.line_total);
 END LOOP;
 PERFORM public.recalculate_invoice_totals(i.id);
END $function$;

CREATE OR REPLACE FUNCTION public.create_draft_invoice(p_currency character varying, p_items jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE uid uuid:=auth.uid(); rate numeric; iid uuid;
BEGIN
 IF uid IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
 IF p_currency IS NULL OR p_currency NOT IN ('JOD','USD','EUR') THEN RAISE EXCEPTION 'Unsupported currency'; END IF;
 IF p_currency='JOD' THEN rate:=1; ELSE
 SELECT CASE p_currency WHEN 'USD' THEN usd_per_jod ELSE eur_per_jod END INTO rate FROM public.user_settings WHERE user_id=uid;
 END IF;
 IF rate IS NULL OR rate<=0 OR rate>=1000000 THEN RAISE EXCEPTION 'Configure a valid rate for the selected currency'; END IF;
 INSERT INTO public.invoices(user_id,currency,exchange_rate) VALUES(uid,p_currency,rate) RETURNING id INTO iid;
 PERFORM public.replace_draft_items(iid,p_items);
 RETURN iid;
END $function$;

CREATE OR REPLACE FUNCTION public.edit_draft_invoice(p_invoice_id uuid, p_items jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE i public.invoices%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
 SELECT * INTO i FROM public.invoices WHERE id=p_invoice_id AND user_id=auth.uid() FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Invoice not found or unauthorized' USING ERRCODE='42501'; END IF;
 IF i.status<>'draft' THEN RAISE EXCEPTION 'Only draft invoices can be edited'; END IF;
 PERFORM public.replace_draft_items(i.id,p_items);
 RETURN i.id;
END $function$;

CREATE OR REPLACE FUNCTION public.approve_invoice(p_invoice_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE i public.invoices%ROWTYPE; num text;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
 SELECT * INTO i FROM public.invoices WHERE id=p_invoice_id AND user_id=auth.uid() FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Invoice not found or unauthorized' USING ERRCODE='42501'; END IF;
 IF i.status<>'draft' THEN RAISE EXCEPTION 'Only draft invoices can be approved'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.invoice_items WHERE invoice_id=i.id) THEN RAISE EXCEPTION 'At least one item required'; END IF;
 PERFORM public.recalculate_invoice_totals(i.id);
 num := 'INV-' || nextval('public.invoice_number_seq'::regclass)::text;
 UPDATE public.invoices SET status='approved',approved_at=clock_timestamp(),invoice_number=num WHERE id=i.id;
 RETURN num;
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
 IF OLD.status<>'draft' THEN RAISE EXCEPTION 'Finalized invoices cannot be deleted'; END IF; RETURN OLD;
 END IF;
 IF NEW.id<>OLD.id OR NEW.user_id<>OLD.user_id OR NEW.currency<>OLD.currency OR NEW.exchange_rate<>OLD.exchange_rate OR NEW.created_at<>OLD.created_at THEN RAISE EXCEPTION 'Invoice identity and currency snapshot are immutable'; END IF;
 IF OLD.status='cancelled' THEN RAISE EXCEPTION 'Cancelled invoices are immutable'; END IF;
 IF OLD.status='approved' THEN
 IF NEW.status<>'cancelled' OR (to_jsonb(NEW)-'status'-'cancelled_at'-'cancellation_reason'-'updated_at') IS DISTINCT FROM (to_jsonb(OLD)-'status'-'cancelled_at'-'cancellation_reason'-'updated_at') THEN RAISE EXCEPTION 'Approved financial data is immutable'; END IF;
 ELSIF NEW.status NOT IN ('draft','approved') THEN RAISE EXCEPTION 'Invalid transition'; END IF;
 RETURN NEW;
END $function$;

CREATE OR REPLACE FUNCTION public.guard_invoice_item_history()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE s text; iid uuid;
BEGIN
 IF TG_OP='UPDATE' AND NEW.invoice_id<>OLD.invoice_id THEN RAISE EXCEPTION 'Cannot move invoice items'; END IF;
 IF TG_OP='DELETE' THEN iid:=OLD.invoice_id; ELSE iid:=NEW.invoice_id; END IF;
 SELECT status INTO s FROM public.invoices WHERE id=iid FOR UPDATE;
 IF s IS DISTINCT FROM 'draft' THEN RAISE EXCEPTION 'Only draft invoice items may change'; END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END $function$;

CREATE TRIGGER guard_invoice_history BEFORE DELETE OR UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION guard_invoice_history();
CREATE TRIGGER guard_invoice_item_history BEFORE INSERT OR DELETE OR UPDATE ON public.invoice_items FOR EACH ROW EXECUTE FUNCTION guard_invoice_item_history();
CREATE TRIGGER trg_invoices_updated_at BEFORE UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_user_settings_updated_at BEFORE UPDATE ON public.user_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
COMMIT;
