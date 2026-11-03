BEGIN;
SET LOCAL search_path = public, pg_catalog;

INSERT INTO public.products(name,barcode,price_jod,tax_rate,tax_inclusive,is_active) VALUES
('Laptop','10000001',500,16,false,true),
('Mouse','10000002',15,16,true,true),
('Keyboard','10000003',30,0,false,true);
COMMIT;
