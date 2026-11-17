
CREATE TABLE warehouse_handover (
    handover_id         UUID          NOT NULL DEFAULT gen_random_uuid(),
    handover_reference  VARCHAR(50)   NOT NULL,
    report_id           UUID          NOT NULL,
    warehouse_id        UUID          NOT NULL,
    handed_over_by      UUID          NOT NULL,
    received_by         UUID,
    status              VARCHAR(20)   NOT NULL DEFAULT 'DRAFT',
    sent_at             TIMESTAMPTZ,
    received_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_warehouse_handover            PRIMARY KEY (handover_id),
    CONSTRAINT uq_warehouse_handover_reference  UNIQUE (handover_reference),
    CONSTRAINT uq_warehouse_handover_report     UNIQUE (report_id),
    CONSTRAINT fk_warehouse_handover_report     FOREIGN KEY (report_id)      REFERENCES sap_report (report_id),
    CONSTRAINT fk_warehouse_handover_warehouse  FOREIGN KEY (warehouse_id)   REFERENCES warehouse (warehouse_id),
    CONSTRAINT fk_warehouse_handover_sender     FOREIGN KEY (handed_over_by) REFERENCES manufacturing_admin (user_id),
    CONSTRAINT fk_warehouse_handover_receiver   FOREIGN KEY (received_by)    REFERENCES warehouse_admin (user_id),
    CONSTRAINT ck_warehouse_handover_status     CHECK (status IN ('DRAFT','SENT','RECEIVED','REJECTED')),
    CONSTRAINT ck_warehouse_handover_times      CHECK (received_at IS NULL OR sent_at IS NULL OR received_at >= sent_at)
);
CREATE INDEX idx_warehouse_handover_warehouse ON warehouse_handover (warehouse_id);

CREATE TABLE warehouse_handover_item (
    handover_item_id  UUID     NOT NULL DEFAULT gen_random_uuid(),
    handover_id       UUID     NOT NULL,
    order_item_id     UUID     NOT NULL,
    quantity          INTEGER  NOT NULL,

    CONSTRAINT pk_warehouse_handover_item            PRIMARY KEY (handover_item_id),
    CONSTRAINT fk_warehouse_handover_item_handover   FOREIGN KEY (handover_id)
        REFERENCES warehouse_handover (handover_id) ON DELETE CASCADE,
    CONSTRAINT fk_warehouse_handover_item_order_item FOREIGN KEY (order_item_id)
        REFERENCES agency_order_item (order_item_id),
    CONSTRAINT uq_warehouse_handover_item_line       UNIQUE (handover_id, order_item_id),
    CONSTRAINT ck_warehouse_handover_item_qty        CHECK (quantity > 0)
);
CREATE INDEX idx_warehouse_handover_item_order_item ON warehouse_handover_item (order_item_id);
