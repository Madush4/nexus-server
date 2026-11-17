
CREATE TABLE driver (
    driver_id            UUID          NOT NULL DEFAULT gen_random_uuid(),
    agency_id            UUID          NOT NULL,
    full_name            VARCHAR(150)  NOT NULL,
    nic                  VARCHAR(12)   NOT NULL,
    contact_number       VARCHAR(20)   NOT NULL,
    address              TEXT,
    licence_number       VARCHAR(20)   NOT NULL,
    licence_expiry_date  DATE          NOT NULL,
    is_active            BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_driver          PRIMARY KEY (driver_id),
    CONSTRAINT fk_driver_agency   FOREIGN KEY (agency_id) REFERENCES agency (agency_id),
    CONSTRAINT uq_driver_nic      UNIQUE (nic),
    CONSTRAINT uq_driver_licence  UNIQUE (licence_number),
    CONSTRAINT ck_driver_nic      CHECK (nic ~ '^([0-9]{9}[VvXx]|[0-9]{12})$')
);
CREATE INDEX idx_driver_agency ON driver (agency_id);

CREATE TABLE vehicle (
    vehicle_id           UUID           NOT NULL DEFAULT gen_random_uuid(),
    agency_id            UUID           NOT NULL,
    registration_number  VARCHAR(20)    NOT NULL,
    vehicle_type         VARCHAR(20)    NOT NULL,
    max_load_kg          NUMERIC(10,2)  NOT NULL,
    operational_status   VARCHAR(20)    NOT NULL DEFAULT 'AVAILABLE',
    is_active            BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ    NOT NULL DEFAULT now(),

    CONSTRAINT pk_vehicle               PRIMARY KEY (vehicle_id),
    CONSTRAINT fk_vehicle_agency        FOREIGN KEY (agency_id) REFERENCES agency (agency_id),
    CONSTRAINT uq_vehicle_registration  UNIQUE (registration_number),
    CONSTRAINT ck_vehicle_type          CHECK (vehicle_type IN ('LORRY','VAN','TRUCK','THREE_WHEELER','MOTORBIKE')),
    CONSTRAINT ck_vehicle_status        CHECK (operational_status IN ('AVAILABLE','ON_TRIP',
                                                                      'UNDER_MAINTENANCE','OUT_OF_SERVICE')),
    CONSTRAINT ck_vehicle_max_load      CHECK (max_load_kg > 0)
);
CREATE INDEX idx_vehicle_agency ON vehicle (agency_id);

CREATE TABLE vehicle_maintenance (
    maintenance_id    UUID           NOT NULL DEFAULT gen_random_uuid(),
    vehicle_id        UUID           NOT NULL,
    maintenance_type  VARCHAR(30)    NOT NULL,
    description       TEXT,
    service_date      DATE           NOT NULL,
    cost              NUMERIC(12,2),
    next_due_date     DATE,
    recorded_by       UUID           NOT NULL,
    created_at        TIMESTAMPTZ    NOT NULL DEFAULT now(),

    CONSTRAINT pk_vehicle_maintenance          PRIMARY KEY (maintenance_id),
    CONSTRAINT fk_vehicle_maintenance_vehicle  FOREIGN KEY (vehicle_id)  REFERENCES vehicle (vehicle_id),
    CONSTRAINT fk_vehicle_maintenance_manager  FOREIGN KEY (recorded_by) REFERENCES agency_manager (user_id),
    CONSTRAINT ck_vehicle_maintenance_type     CHECK (maintenance_type IN ('SERVICE','REPAIR','TYRE',
                                                                         'INSURANCE','REVENUE_LICENCE','OTHER')),
    CONSTRAINT ck_vehicle_maintenance_cost     CHECK (cost IS NULL OR cost >= 0),
    CONSTRAINT ck_vehicle_maintenance_due      CHECK (next_due_date IS NULL OR next_due_date >= service_date)
);
CREATE INDEX idx_vehicle_maintenance_vehicle ON vehicle_maintenance (vehicle_id, service_date);

CREATE TRIGGER trg_vehicle_updated_at BEFORE UPDATE ON vehicle
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
