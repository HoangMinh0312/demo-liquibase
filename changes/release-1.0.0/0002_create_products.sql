CREATE TABLE IF NOT EXISTS ${AppSchema}.products (
    id          UUID           NOT NULL DEFAULT gen_random_uuid(),
    sku         VARCHAR(50)    NOT NULL,
    name        VARCHAR(200)   NOT NULL,
    description TEXT           NULL,
    unit_price  NUMERIC(12, 2) NOT NULL DEFAULT 0,
    currency    CHAR(3)        NOT NULL DEFAULT 'USD',
    is_active   BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT now(),
    modified_at TIMESTAMPTZ    NOT NULL DEFAULT now(),

    CONSTRAINT pk_products PRIMARY KEY (id),
    CONSTRAINT uq_products_sku UNIQUE (sku),
    CONSTRAINT ck_products_unit_price CHECK (unit_price >= 0)
);
