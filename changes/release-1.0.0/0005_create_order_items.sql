CREATE TABLE IF NOT EXISTS ${AppSchema}.order_items (
    id         UUID           NOT NULL DEFAULT gen_random_uuid(),
    order_id   UUID           NOT NULL,
    product_id UUID           NOT NULL,
    quantity   INTEGER        NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    line_total NUMERIC(14, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,

    CONSTRAINT pk_order_items PRIMARY KEY (id),
    CONSTRAINT fk_order_items_order   FOREIGN KEY (order_id)   REFERENCES ${AppSchema}.orders (id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES ${AppSchema}.products (id),
    CONSTRAINT uq_order_items_order_product UNIQUE (order_id, product_id),
    CONSTRAINT ck_order_items_quantity CHECK (quantity > 0)
);

CREATE INDEX IF NOT EXISTS ix_order_items_order_id   ON ${AppSchema}.order_items (order_id);
CREATE INDEX IF NOT EXISTS ix_order_items_product_id ON ${AppSchema}.order_items (product_id);
