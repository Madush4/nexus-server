
CREATE TABLE dispatch_schedule (
    schedule_id     UUID         NOT NULL DEFAULT gen_random_uuid(),
    handover_id     UUID         NOT NULL,
    warehouse_id    UUID         NOT NULL,
    scheduled_date  DATE         NOT NULL,
    created_by      UUID         NOT NULL,
    supervisor_id   UUID,
    status          VARCHAR(20)  NOT NULL DEFAULT 'DRAFT',
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_dispatch_schedule            PRIMARY KEY (schedule_id),
    CONSTRAINT fk_dispatch_schedule_handover   FOREIGN KEY (handover_id)   REFERENCES warehouse_handover (handover_id),
    CONSTRAINT fk_dispatch_schedule_warehouse  FOREIGN KEY (warehouse_id)  REFERENCES warehouse (warehouse_id),
    CONSTRAINT fk_dispatch_schedule_admin      FOREIGN KEY (created_by)    REFERENCES warehouse_admin (user_id),
    CONSTRAINT fk_dispatch_schedule_supervisor FOREIGN KEY (supervisor_id) REFERENCES warehouse_supervisor (user_id),
    CONSTRAINT ck_dispatch_schedule_status     CHECK (status IN ('DRAFT','PUBLISHED','IN_PROGRESS',
                                                                 'COMPLETED','CANCELLED'))
);
CREATE INDEX idx_dispatch_schedule_handover  ON dispatch_schedule (handover_id);
CREATE INDEX idx_dispatch_schedule_wh_date   ON dispatch_schedule (warehouse_id, scheduled_date);

CREATE TABLE dispatch_allocation (
    dispatch_allocation_id  UUID         NOT NULL DEFAULT gen_random_uuid(),
    schedule_id             UUID         NOT NULL,
    order_id                UUID         NOT NULL,
    agency_id               UUID         NOT NULL,
    pickup_scheduled_at     TIMESTAMPTZ,
    loading_bay             VARCHAR(20),
    status                  VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    notes                   TEXT,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_dispatch_allocation          PRIMARY KEY (dispatch_allocation_id),
    CONSTRAINT fk_dispatch_allocation_schedule FOREIGN KEY (schedule_id)
        REFERENCES dispatch_schedule (schedule_id) ON DELETE CASCADE,
    -- composite FK: agency_id must be the same agency as the order
    CONSTRAINT fk_dispatch_allocation_order    FOREIGN KEY (order_id, agency_id)
        REFERENCES agency_order (order_id, agency_id),
    CONSTRAINT uq_dispatch_allocation_order    UNIQUE (order_id),
    CONSTRAINT ck_dispatch_allocation_status   CHECK (status IN ('PENDING','ACCEPTED','REJECTED',
                                                                 'READY_FOR_PICKUP','PICKED_UP',
                                                                 'DELIVERED','CANCELLED'))
);
CREATE INDEX idx_dispatch_allocation_schedule ON dispatch_allocation (schedule_id);
CREATE INDEX idx_dispatch_allocation_agency   ON dispatch_allocation (agency_id);

CREATE TABLE dispatch_allocation_item (
    allocation_item_id      UUID     NOT NULL DEFAULT gen_random_uuid(),
    dispatch_allocation_id  UUID     NOT NULL,
    order_item_id           UUID     NOT NULL,
    allocated_qty           INTEGER  NOT NULL,
    loaded_qty              INTEGER,            -- filled at the warehouse
    received_qty            INTEGER,            -- filled by the agency

    CONSTRAINT pk_dispatch_allocation_item            PRIMARY KEY (allocation_item_id),
    CONSTRAINT fk_dispatch_allocation_item_allocation FOREIGN KEY (dispatch_allocation_id)
        REFERENCES dispatch_allocation (dispatch_allocation_id) ON DELETE CASCADE,
    CONSTRAINT fk_dispatch_allocation_item_order_item FOREIGN KEY (order_item_id)
        REFERENCES agency_order_item (order_item_id),
    CONSTRAINT uq_dispatch_allocation_item_line       UNIQUE (dispatch_allocation_id, order_item_id),
    CONSTRAINT ck_dispatch_allocation_item_qty        CHECK (
        allocated_qty > 0
        AND (loaded_qty   IS NULL OR (loaded_qty >= 0 AND loaded_qty <= allocated_qty))
        AND (received_qty IS NULL OR (loaded_qty IS NOT NULL AND received_qty >= 0
                                      AND received_qty <= loaded_qty)))
);
CREATE INDEX idx_dispatch_allocation_item_order_item ON dispatch_allocation_item (order_item_id);

CREATE TRIGGER trg_dispatch_schedule_updated_at BEFORE UPDATE ON dispatch_schedule
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_dispatch_allocation_updated_at BEFORE UPDATE ON dispatch_allocation
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
