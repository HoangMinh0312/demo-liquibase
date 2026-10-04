ALTER TABLE ${AppSchema}.customers
    ADD COLUMN IF NOT EXISTS phone        VARCHAR(30)  NULL,
    ADD COLUMN IF NOT EXISTS address_line VARCHAR(500) NULL,
    ADD COLUMN IF NOT EXISTS city         VARCHAR(100) NULL,
    ADD COLUMN IF NOT EXISTS country_code CHAR(2)      NULL;

CREATE INDEX IF NOT EXISTS ix_customers_country_code ON ${AppSchema}.customers (country_code);
