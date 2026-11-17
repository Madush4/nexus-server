
CREATE TABLE next_order (
    next_order_id            UUID         NOT NULL DEFAULT gen_random_uuid(),
    outlet_id                UUID         NOT NULL,
    recorded_by              UUID         NOT NULL,
    requested_delivery_date  DATE,
    status                   VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    notes                    TEXT,
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_next_order           PRIMARY KEY (next_order_id),
    CONSTRAINT fk_next_order_outlet    FOREIGN KEY (outlet_id)   REFERENCES retail_outlet (outlet_id),
    CONSTRAINT fk_next_order_agent     FOREIGN KEY (recorded_by) REFERENCES agent (user_id),
    -- target for composite FK from outlet_allocation
    CONSTRAINT uq_next_order_id_outlet UNIQUE (next_order_id, outlet_id),
    CONSTRAINT ck_next_order_status    CHECK (status IN ('PENDING','APPROVED','ALLOCATED',
                                                         'DELIVERED','CANCELLED'))
);
CREATE INDEX idx_next_order_outlet ON next_order (outlet_id);
CREATE INDEX idx_next_order_agent  ON next_order (recorded_by);

CREATE TABLE next_order_item (
    next_order_item_id  UUID     NOT NULL DEFAULT gen_random_uuid(),
    next_order_id       UUID     NOT NULL,
    product_id          UUID     NOT NULL,
    requested_qty       INTEGER  NOT NULL,

    CONSTRAINT pk_next_order_item          PRIMARY KEY (next_order_item_id),
    CONSTRAINT fk_next_order_item_order    FOREIGN KEY (next_order_id)
        REFERENCES next_order (next_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_next_order_item_product  FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT uq_next_order_item_product  UNIQUE (next_order_id, product_id),
    CONSTRAINT ck_next_order_item_qty      CHECK (requested_qty > 0)
);
CREATE INDEX idx_next_order_item_product ON next_order_item (product_id);

CREATE TRIGGER trg_next_order_updated_at BEFORE UPDATE ON next_order
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
