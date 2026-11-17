
CREATE TABLE manufacturer_inventory (
    inventory_id         UUID         NOT NULL DEFAULT gen_random_uuid(),
    product_id           UUID         NOT NULL,
    quantity_on_hand     INTEGER      NOT NULL DEFAULT 0,
    quantity_reserved    INTEGER      NOT NULL DEFAULT 0,
    minimum_stock_level  INTEGER      NOT NULL DEFAULT 0,
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_manufacturer_inventory         PRIMARY KEY (inventory_id),
    CONSTRAINT fk_manufacturer_inventory_product FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT uq_manufacturer_inventory_product UNIQUE (product_id),
    CONSTRAINT ck_manufacturer_inventory_qty     CHECK (quantity_on_hand >= 0
                                                        AND quantity_reserved >= 0
                                                        AND quantity_reserved <= quantity_on_hand
                                                        AND minimum_stock_level >= 0)
);

CREATE TABLE manufacturer_stock_movement (
    movement_id     UUID         NOT NULL DEFAULT gen_random_uuid(),
    product_id      UUID         NOT NULL,
    performed_by    UUID         NOT NULL,
    movement_type   VARCHAR(20)  NOT NULL,
    quantity        INTEGER      NOT NULL,
    reference_type  VARCHAR(30),             -- e.g. SAP_REPORT, AGENCY_ORDER, HANDOVER
    reference_id    UUID,
    note            TEXT,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_manufacturer_stock_movement           PRIMARY KEY (movement_id),
    CONSTRAINT fk_manufacturer_stock_movement_inventory FOREIGN KEY (product_id)
        REFERENCES manufacturer_inventory (product_id),
    CONSTRAINT fk_manufacturer_stock_movement_admin     FOREIGN KEY (performed_by)
        REFERENCES manufacturing_admin (user_id),
    CONSTRAINT ck_manufacturer_stock_movement_type      CHECK (movement_type IN
        ('STOCK_IN','STOCK_OUT','RESERVATION','RELEASE','ADJUSTMENT')),
    CONSTRAINT ck_manufacturer_stock_movement_qty       CHECK (quantity > 0),
    CONSTRAINT ck_manufacturer_stock_movement_ref       CHECK ((reference_type IS NULL) = (reference_id IS NULL))
);
CREATE INDEX idx_manufacturer_stock_movement_product ON manufacturer_stock_movement (product_id, created_at);

CREATE TRIGGER trg_manufacturer_inventory_updated_at BEFORE UPDATE ON manufacturer_inventory
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
