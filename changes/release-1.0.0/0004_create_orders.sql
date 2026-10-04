CREATE TABLE IF NOT EXISTS ${AppSchema}.orders (
    id           UUID           NOT NULL DEFAULT gen_random_uuid(),
    order_number VARCHAR(30)    NOT NULL,
    customer_id  UUID           NOT NULL,
    status       VARCHAR(20)    NOT NULL DEFAULT 'pending',
    total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
    currency     CHAR(3)        NOT NULL DEFAULT 'USD',
    ordered_at   TIMESTAMPTZ    NOT NULL DEFAULT now(),
    created_by   VARCHAR(255)   NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ    NOT NULL DEFAULT now(),
    modified_by  VARCHAR(255)   NOT NULL DEFAULT '',
    modified_at  TIMESTAMPTZ    NOT NULL DEFAULT now(),

    CONSTRAINT pk_orders PRIMARY KEY (id),
    CONSTRAINT uq_orders_order_number UNIQUE (order_number),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES ${AppSchema}.customers (id),
    CONSTRAINT ck_orders_status CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled'))
);

CREATE INDEX IF NOT EXISTS ix_orders_customer_id ON ${AppSchema}.orders (customer_id);
