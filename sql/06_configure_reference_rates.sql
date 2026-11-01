-- Run for the signed-in application user after applying migration 0005.
-- For Dashboard use, replace auth.uid() with the target test account's UUID.
-- CBJ latest available bulletin: 2026-10-29.
-- USD range: 708–710 fils/USD -> midpoint 0.709 JOD/USD -> 1.410437 USD/JOD.
-- EUR range: 787.58–792.43 fils/EUR -> midpoint 0.790005 JOD/EUR -> 1.265815 EUR/JOD.
-- These are reference midpoint-derived manual rates, not a bank's executable quote.
INSERT INTO public.user_settings(user_id,usd_per_jod,eur_per_jod,usd_rate_source,usd_rate_effective_on,eur_rate_source,eur_rate_effective_on)
VALUES(auth.uid(),1.410437,1.265815,
 'CBJ https://www.cbj.gov.jo/en/Pages/foreignexchangerates; 2026-10-29 USD 708-710 fils; reciprocal of midpoint 0.709 JOD/USD','2026-10-29',
 'CBJ https://www.cbj.gov.jo/en/Pages/foreignexchangerates; 2026-10-29 EUR 787.58-792.43 fils; reciprocal of midpoint 0.790005 JOD/EUR','2026-10-29')
ON CONFLICT(user_id) DO UPDATE SET
 usd_per_jod=EXCLUDED.usd_per_jod,eur_per_jod=EXCLUDED.eur_per_jod,
 usd_rate_source=EXCLUDED.usd_rate_source,usd_rate_effective_on=EXCLUDED.usd_rate_effective_on,
 eur_rate_source=EXCLUDED.eur_rate_source,eur_rate_effective_on=EXCLUDED.eur_rate_effective_on;
