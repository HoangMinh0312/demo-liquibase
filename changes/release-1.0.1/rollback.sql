DROP INDEX IF EXISTS ${AppSchema}.ix_customers_country_code;

ALTER TABLE ${AppSchema}.customers
    DROP COLUMN IF EXISTS country_code,
    DROP COLUMN IF EXISTS city,
    DROP COLUMN IF EXISTS address_line,
    DROP COLUMN IF EXISTS phone;
