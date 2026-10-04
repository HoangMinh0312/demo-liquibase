CREATE TABLE IF NOT EXISTS ${AppSchema}.order_status_history (
    id          BIGSERIAL    NOT NULL,
    order_id    UUID         NOT NULL,
    from_status VARCHAR(20)  NULL,
    to_status   VARCHAR(20)  NOT NULL,
    changed_by  VARCHAR(255) NOT NULL DEFAULT '',
    changed_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    note        TEXT         NULL,

    CONSTRAINT pk_order_status_history PRIMARY KEY (id),
    CONSTRAINT fk_order_status_history_order FOREIGN KEY (order_id) REFERENCES ${AppSchema}.orders (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_order_status_history_order_id ON ${AppSchema}.order_status_history (order_id, changed_at DESC);
