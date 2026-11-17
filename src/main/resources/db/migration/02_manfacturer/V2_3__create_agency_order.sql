-- =====================================================================
-- V2_3  agency_order, agency_order_item
-- Owner : Bandara (manufacturer / distribution)
-- One order per agency per SAP report. Items hold requested vs the
-- quantity the manufacturer could actually allocate.
-- =====================================================================
CREATE TABLE agency_order (
    order_id    UUID         NOT NULL DEFAULT gen_random_uuid(),
    report_id   UUID         NOT NULL,
    agency_id   UUID         NOT NULL,
    created_by  UUID         NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'DRAFT',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_agency_order          PRIMARY KEY (order_id),
    CONSTRAINT fk_agency_order_report   FOREIGN KEY (report_id)  REFERENCES sap_report (report_id),
    CONSTRAINT fk_agency_order_agency   FOREIGN KEY (agency_id)  REFERENCES agency (agency_id),
    CONSTRAINT fk_agency_order_creator  FOREIGN KEY (created_by) REFERENCES manufacturing_admin (user_id),
    CONSTRAINT uq_agency_order_report_agency UNIQUE (report_id, agency_id),
    -- target for composite FK from dispatch_allocation (keeps agency consistent)
    CONSTRAINT uq_agency_order_id_agency     UNIQUE (order_id, agency_id),
    CONSTRAINT ck_agency_order_status   CHECK (status IN ('DRAFT','CONFIRMED','HANDED_OVER',
                                                          'DISPATCHED','CANCELLED'))
);
CREATE INDEX idx_agency_order_agency ON agency_order (agency_id);

CREATE TABLE agency_order_item (
    order_item_id   UUID     NOT NULL DEFAULT gen_random_uuid(),
    order_id        UUID     NOT NULL,
    product_id      UUID     NOT NULL,
    requested_qty   INTEGER  NOT NULL,
    allocated_qty   INTEGER  NOT NULL DEFAULT 0,

    CONSTRAINT pk_agency_order_item          PRIMARY KEY (order_item_id),
    CONSTRAINT fk_agency_order_item_order    FOREIGN KEY (order_id)
        REFERENCES agency_order (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_agency_order_item_product  FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT uq_agency_order_item_product  UNIQUE (order_id, product_id),
    CONSTRAINT ck_agency_order_item_qty      CHECK (requested_qty > 0
                                                    AND allocated_qty >= 0
                                                    AND allocated_qty <= requested_qty)
);
CREATE INDEX idx_agency_order_item_product ON agency_order_item (product_id);

CREATE TRIGGER trg_agency_order_updated_at BEFORE UPDATE ON agency_order
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
