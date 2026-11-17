
CREATE TABLE dispatch_discrepancy (
    discrepancy_id      UUID         NOT NULL DEFAULT gen_random_uuid(),
    shipment_trip_id    UUID         NOT NULL,
    allocation_item_id  UUID,
    reported_by         UUID         NOT NULL,
    issue_type          VARCHAR(20)  NOT NULL,
    quantity_affected   INTEGER,
    description         TEXT         NOT NULL,
    status              VARCHAR(20)  NOT NULL DEFAULT 'OPEN',
    resolved_by         UUID,
    resolution_note     TEXT,
    reported_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    resolved_at         TIMESTAMPTZ,

    CONSTRAINT pk_dispatch_discrepancy          PRIMARY KEY (discrepancy_id),
    CONSTRAINT fk_dispatch_discrepancy_trip     FOREIGN KEY (shipment_trip_id)
        REFERENCES shipment_trip (shipment_trip_id),
    CONSTRAINT fk_dispatch_discrepancy_item     FOREIGN KEY (allocation_item_id)
        REFERENCES dispatch_allocation_item (allocation_item_id),
    CONSTRAINT fk_dispatch_discrepancy_reporter FOREIGN KEY (reported_by) REFERENCES app_user (user_id),
    CONSTRAINT fk_dispatch_discrepancy_resolver FOREIGN KEY (resolved_by) REFERENCES warehouse_admin (user_id),
    CONSTRAINT ck_dispatch_discrepancy_type     CHECK (issue_type IN ('SHORTAGE','EXCESS','DAMAGED',
                                                                      'WRONG_ITEM','OTHER')),
    CONSTRAINT ck_dispatch_discrepancy_status   CHECK (status IN ('OPEN','UNDER_REVIEW','RESOLVED','REJECTED')),
    CONSTRAINT ck_dispatch_discrepancy_qty      CHECK (quantity_affected IS NULL OR quantity_affected > 0),
    CONSTRAINT ck_dispatch_discrepancy_resolved CHECK (status NOT IN ('RESOLVED','REJECTED')
                                                       OR (resolved_by IS NOT NULL AND resolved_at IS NOT NULL))
);
CREATE INDEX idx_dispatch_discrepancy_trip   ON dispatch_discrepancy (shipment_trip_id);
CREATE INDEX idx_dispatch_discrepancy_status ON dispatch_discrepancy (status);
