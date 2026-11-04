BEGIN;
ALTER TABLE public.user_settings
 ADD COLUMN usd_rate_source text,
 ADD COLUMN usd_rate_effective_on date,
 ADD COLUMN eur_rate_source text,
 ADD COLUMN eur_rate_effective_on date;
GRANT INSERT(usd_rate_source,usd_rate_effective_on,eur_rate_source,eur_rate_effective_on),
 UPDATE(usd_rate_source,usd_rate_effective_on,eur_rate_source,eur_rate_effective_on)
 ON public.user_settings TO authenticated;

CREATE TABLE public.invoice_api_requests (
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 request_key text NOT NULL CHECK(length(request_key) BETWEEN 8 AND 128),
 operation text NOT NULL CHECK(operation IN ('create','cancel')),
 payload jsonb NOT NULL,
 result jsonb,
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(user_id,request_key)
);
ALTER TABLE public.invoice_api_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.invoice_api_requests FROM PUBLIC,anon,authenticated,service_role;
CREATE FUNCTION public.execute_invoice_request(p_key text,p_operation text,p_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $f$
DECLARE uid uuid:=auth.uid(); previous public.invoice_api_requests%ROWTYPE; iid uuid; response jsonb;
BEGIN
 IF uid IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
 IF p_key IS NULL OR p_key !~ '^[A-Za-z0-9._:-]{8,128}$' THEN RAISE EXCEPTION 'Invalid idempotency key' USING ERRCODE='22023'; END IF;
 IF p_operation IS NULL OR p_operation NOT IN ('create','cancel') OR jsonb_typeof(p_payload) IS DISTINCT FROM 'object' THEN RAISE EXCEPTION 'Invalid operation payload' USING ERRCODE='22023'; END IF;
 IF (p_operation='create' AND (p_payload-'currency'-'items')<>'{}'::jsonb)
 OR (p_operation='cancel' AND (p_payload-'invoice_id'-'reason')<>'{}'::jsonb)
 THEN RAISE EXCEPTION 'Unexpected payload fields' USING ERRCODE='22023'; END IF;
 INSERT INTO public.invoice_api_requests(user_id,request_key,operation,payload)
 VALUES(uid,p_key,p_operation,p_payload) ON CONFLICT(user_id,request_key) DO NOTHING;
 SELECT * INTO previous FROM public.invoice_api_requests WHERE user_id=uid AND request_key=p_key FOR UPDATE;
 IF previous.operation<>p_operation OR previous.payload<>p_payload THEN RAISE EXCEPTION 'Idempotency key reused with different request' USING ERRCODE='23505'; END IF;
 IF previous.result IS NOT NULL THEN RETURN jsonb_build_object('invoice',previous.result,'replayed',true); END IF;
 IF p_operation='create' THEN
  iid:=public.create_invoice((p_payload->>'currency')::varchar,p_payload->'items');
 ELSE
  iid:=(p_payload->>'invoice_id')::uuid;
  PERFORM public.cancel_invoice(iid,p_payload->>'reason');
 END IF;
 SELECT to_jsonb(i)||jsonb_build_object('items',coalesce((SELECT jsonb_agg(to_jsonb(x) ORDER BY x.created_at,x.id) FROM public.invoice_items x WHERE x.invoice_id=i.id),'[]'::jsonb)) INTO response
 FROM public.invoices i WHERE id=iid AND user_id=uid;
 UPDATE public.invoice_api_requests SET result=response WHERE user_id=uid AND request_key=p_key;
 RETURN jsonb_build_object('invoice',response,'replayed',false);
END $f$;
REVOKE ALL ON FUNCTION public.execute_invoice_request(text,text,jsonb) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.execute_invoice_request(text,text,jsonb) TO authenticated;
COMMIT;
