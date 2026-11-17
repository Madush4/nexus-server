
CREATE TABLE outlet_allocation (
    allocation_id  UUID         NOT NULL DEFAULT gen_random_uuid(),
    outlet_id      UUID         NOT NULL,
    next_order_id  UUID,
    trip_stop_id   UUID,
    created_by     UUID         NOT NULL,
    status         VARCHAR(20)  NOT NULL DEFAULT 'DRAFT',
    notes          TEXT,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_outlet_allocation            PRIMARY KEY (allocation_id),
    CONSTRAINT fk_outlet_allocation_outlet     FOREIGN KEY (outlet_id)  REFERENCES retail_outlet (outlet_id),
    CONSTRAINT fk_outlet_allocation_manager    FOREIGN KEY (created_by) REFERENCES agency_manager (user_id),
    CONSTRAINT fk_outlet_allocation_next_order FOREIGN KEY (next_order_id, outlet_id)
        REFERENCES next_order (next_order_id, outlet_id),
    CONSTRAINT fk_outlet_allocation_trip_stop  FOREIGN KEY (trip_stop_id, outlet_id)
        REFERENCES trip_stop (trip_stop_id, outlet_id),
    CONSTRAINT uq_outlet_allocation_stop       UNIQUE (trip_stop_id),
    CONSTRAINT ck_outlet_allocation_status     CHECK (status IN ('DRAFT','CONFIRMED','LOADED','DELIVERED',
                                                                 'PARTIALLY_DELIVERED','FAILED','CANCELLED')),
    CONSTRAINT ck_outlet_allocation_stop_set   CHECK (status IN ('DRAFT','CONFIRMED','CANCELLED')
                                                      OR trip_stop_id IS NOT NULL)
);
CREATE INDEX idx_outlet_allocation_outlet     ON outlet_allocation (outlet_id);
CREATE INDEX idx_outlet_allocation_next_order ON outlet_allocation (next_order_id);

CREATE TABLE outlet_allocation_item (
    allocation_item_id  UUID     NOT NULL DEFAULT gen_random_uuid(),
    allocation_id       UUID     NOT NULL,
    product_id          UUID     NOT NULL,
    allocated_qty       INTEGER  NOT NULL,
    delivered_qty       INTEGER  NOT NULL DEFAULT 0,

    CONSTRAINT pk_outlet_allocation_item            PRIMARY KEY (allocation_item_id),
    CONSTRAINT fk_outlet_allocation_item_allocation FOREIGN KEY (allocation_id)
        REFERENCES outlet_allocation (allocation_id) ON DELETE CASCADE,
    CONSTRAINT fk_outlet_allocation_item_product    FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT uq_outlet_allocation_item_product    UNIQUE (allocation_id, product_id),
    CONSTRAINT ck_outlet_allocation_item_qty        CHECK (allocated_qty > 0
                                                           AND delivered_qty >= 0
                                                           AND delivered_qty <= allocated_qty)
);
CREATE INDEX idx_outlet_allocation_item_product ON outlet_allocation_item (product_id);

CREATE TRIGGER trg_outlet_allocation_updated_at BEFORE UPDATE ON outlet_allocation
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
