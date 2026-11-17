
CREATE TABLE shipment_trip (
    shipment_trip_id        UUID         NOT NULL DEFAULT gen_random_uuid(),
    dispatch_allocation_id  UUID         NOT NULL,
    vehicle_id              UUID         NOT NULL,
    driver_id               UUID         NOT NULL,
    scheduled_by            UUID         NOT NULL,
    status                  VARCHAR(20)  NOT NULL DEFAULT 'SCHEDULED',
    expected_pickup_at      TIMESTAMPTZ,
    picked_up_at            TIMESTAMPTZ,
    arrived_at              TIMESTAMPTZ,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_shipment_trip            PRIMARY KEY (shipment_trip_id),
    CONSTRAINT fk_shipment_trip_allocation FOREIGN KEY (dispatch_allocation_id)
        REFERENCES dispatch_allocation (dispatch_allocation_id),
    CONSTRAINT fk_shipment_trip_vehicle    FOREIGN KEY (vehicle_id)   REFERENCES vehicle (vehicle_id),
    CONSTRAINT fk_shipment_trip_driver     FOREIGN KEY (driver_id)    REFERENCES driver (driver_id),
    CONSTRAINT fk_shipment_trip_manager    FOREIGN KEY (scheduled_by) REFERENCES agency_manager (user_id),
    CONSTRAINT uq_shipment_trip_allocation UNIQUE (dispatch_allocation_id),
    CONSTRAINT ck_shipment_trip_status     CHECK (status IN ('SCHEDULED','AT_WAREHOUSE','LOADED',
                                                             'IN_TRANSIT','ARRIVED','CANCELLED')),
    CONSTRAINT ck_shipment_trip_times      CHECK (arrived_at IS NULL OR picked_up_at IS NULL
                                                  OR arrived_at >= picked_up_at)
);
CREATE INDEX idx_shipment_trip_vehicle ON shipment_trip (vehicle_id);
CREATE INDEX idx_shipment_trip_driver  ON shipment_trip (driver_id);

CREATE TABLE shipment_document (
    document_id       UUID          NOT NULL DEFAULT gen_random_uuid(),
    shipment_trip_id  UUID          NOT NULL,
    document_type     VARCHAR(20)   NOT NULL,
    document_number   VARCHAR(50),
    barcode           VARCHAR(100),
    file_url          TEXT          NOT NULL,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_shipment_document        PRIMARY KEY (document_id),
    CONSTRAINT fk_shipment_document_trip   FOREIGN KEY (shipment_trip_id)
        REFERENCES shipment_trip (shipment_trip_id) ON DELETE CASCADE,
    CONSTRAINT uq_shipment_document_barcode UNIQUE (barcode),
    CONSTRAINT ck_shipment_document_type   CHECK (document_type IN ('DELIVERY_NOTE','INVOICE',
                                                                    'GATE_PASS','OTHER'))
);
CREATE INDEX idx_shipment_document_trip ON shipment_document (shipment_trip_id);

CREATE TABLE pickup_confirmation (
    pickup_confirmation_id  UUID         NOT NULL DEFAULT gen_random_uuid(),
    shipment_trip_id        UUID         NOT NULL,
    confirmed_by            UUID         NOT NULL,
    confirmed_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    signature_url           TEXT,
    remarks                 TEXT,

    CONSTRAINT pk_pickup_confirmation            PRIMARY KEY (pickup_confirmation_id),
    CONSTRAINT fk_pickup_confirmation_trip       FOREIGN KEY (shipment_trip_id)
        REFERENCES shipment_trip (shipment_trip_id),
    CONSTRAINT fk_pickup_confirmation_supervisor FOREIGN KEY (confirmed_by)
        REFERENCES warehouse_supervisor (user_id),
    CONSTRAINT uq_pickup_confirmation_trip       UNIQUE (shipment_trip_id)
);

CREATE TRIGGER trg_shipment_trip_updated_at BEFORE UPDATE ON shipment_trip
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
