CREATE TABLE IF NOT EXISTS ${AppSchema}.customers (
    id          UUID          NOT NULL DEFAULT gen_random_uuid(),
    code        VARCHAR(50)   NOT NULL,
    full_name   VARCHAR(200)  NOT NULL,
    email       VARCHAR(255)  NOT NULL,
    status      VARCHAR(20)   NOT NULL DEFAULT 'active',
    created_by  VARCHAR(255)  NOT NULL DEFAULT '',
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    modified_by VARCHAR(255)  NOT NULL DEFAULT '',
    modified_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
    is_deleted  BOOLEAN       NOT NULL DEFAULT FALSE,
    deleted_at  TIMESTAMPTZ   NULL,

    CONSTRAINT pk_customers PRIMARY KEY (id),
    CONSTRAINT uq_customers_code UNIQUE (code),
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT ck_customers_status CHECK (status IN ('active', 'inactive', 'blocked'))
);
