
CREATE TABLE agency_inventory (
    inventory_id       UUID         NOT NULL DEFAULT gen_random_uuid(),
    agency_id          UUID         NOT NULL,
    product_id         UUID         NOT NULL,
    quantity_on_hand   INTEGER      NOT NULL DEFAULT 0,
    quantity_reserved  INTEGER      NOT NULL DEFAULT 0,
    reorder_level      INTEGER      NOT NULL DEFAULT 0,
    updated_by         UUID,
    updated_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_agency_inventory          PRIMARY KEY (inventory_id),
    CONSTRAINT fk_agency_inventory_agency   FOREIGN KEY (agency_id)  REFERENCES agency (agency_id),
    CONSTRAINT fk_agency_inventory_product  FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT fk_agency_inventory_user     FOREIGN KEY (updated_by)
        REFERENCES app_user (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_agency_inventory_product  UNIQUE (agency_id, product_id),
    CONSTRAINT ck_agency_inventory_qty      CHECK (quantity_on_hand >= 0
                                                   AND quantity_reserved >= 0
                                                   AND quantity_reserved <= quantity_on_hand
                                                   AND reorder_level >= 0)
);
CREATE INDEX idx_agency_inventory_product ON agency_inventory (product_id);

CREATE TABLE agency_stock_movement (
    movement_id     UUID         NOT NULL DEFAULT gen_random_uuid(),
    agency_id       UUID         NOT NULL,
    product_id      UUID         NOT NULL,
    movement_type   VARCHAR(20)  NOT NULL,
    quantity        INTEGER      NOT NULL,
    reference_type  VARCHAR(30),             -- e.g. DISPATCH_ALLOCATION, OUTLET_ALLOCATION, OUTLET_RETURN
    reference_id    UUID,
    performed_by    UUID         NOT NULL,
    note            TEXT,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_agency_stock_movement           PRIMARY KEY (movement_id),
    -- composite FK: a movement can only exist for a stocked agency+product
    CONSTRAINT fk_agency_stock_movement_inventory FOREIGN KEY (agency_id, product_id)
        REFERENCES agency_inventory (agency_id, product_id),
    CONSTRAINT fk_agency_stock_movement_user      FOREIGN KEY (performed_by) REFERENCES app_user (user_id),
    CONSTRAINT ck_agency_stock_movement_type      CHECK (movement_type IN ('RECEIVED','DELIVERED','RETURNED',
                                                                         'DAMAGED','RESERVED','RELEASED',
                                                                         'ADJUSTMENT')),
    CONSTRAINT ck_agency_stock_movement_qty       CHECK (quantity > 0),
    CONSTRAINT ck_agency_stock_movement_ref       CHECK ((reference_type IS NULL) = (reference_id IS NULL))
);
CREATE INDEX idx_agency_stock_movement_lookup ON agency_stock_movement (agency_id, product_id, created_at);

CREATE TRIGGER trg_agency_inventory_updated_at BEFORE UPDATE ON agency_inventory
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
