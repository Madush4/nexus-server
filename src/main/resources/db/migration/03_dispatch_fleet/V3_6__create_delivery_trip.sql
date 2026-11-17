
CREATE TABLE delivery_trip (
    trip_id       UUID         NOT NULL DEFAULT gen_random_uuid(),
    agency_id     UUID         NOT NULL,
    agent_id      UUID         NOT NULL,
    driver_id     UUID,
    vehicle_id    UUID         NOT NULL,
    scheduled_by  UUID         NOT NULL,
    trip_date     DATE         NOT NULL,
    status        VARCHAR(20)  NOT NULL DEFAULT 'PLANNED',
    started_at    TIMESTAMPTZ,
    ended_at      TIMESTAMPTZ,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_delivery_trip          PRIMARY KEY (trip_id),
    CONSTRAINT fk_delivery_trip_agency   FOREIGN KEY (agency_id)    REFERENCES agency (agency_id),
    CONSTRAINT fk_delivery_trip_agent    FOREIGN KEY (agent_id)     REFERENCES agent (user_id),
    CONSTRAINT fk_delivery_trip_driver   FOREIGN KEY (driver_id)    REFERENCES driver (driver_id),
    CONSTRAINT fk_delivery_trip_vehicle  FOREIGN KEY (vehicle_id)   REFERENCES vehicle (vehicle_id),
    CONSTRAINT fk_delivery_trip_manager  FOREIGN KEY (scheduled_by) REFERENCES agency_manager (user_id),
    CONSTRAINT ck_delivery_trip_status   CHECK (status IN ('PLANNED','IN_PROGRESS','COMPLETED','CANCELLED')),
    CONSTRAINT ck_delivery_trip_times    CHECK (ended_at IS NULL OR started_at IS NULL OR ended_at >= started_at)
);
CREATE INDEX idx_delivery_trip_agency_date ON delivery_trip (agency_id, trip_date);
CREATE INDEX idx_delivery_trip_agent       ON delivery_trip (agent_id, trip_date);
CREATE INDEX idx_delivery_trip_vehicle     ON delivery_trip (vehicle_id);

CREATE TABLE trip_stop (
    trip_stop_id        UUID         NOT NULL DEFAULT gen_random_uuid(),
    trip_id             UUID         NOT NULL,
    outlet_id           UUID         NOT NULL,
    stop_sequence       INTEGER      NOT NULL,
    planned_arrival_at  TIMESTAMPTZ,
    actual_arrival_at   TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    status              VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    failure_reason      TEXT,

    CONSTRAINT pk_trip_stop           PRIMARY KEY (trip_stop_id),
    CONSTRAINT fk_trip_stop_trip      FOREIGN KEY (trip_id)
        REFERENCES delivery_trip (trip_id) ON DELETE CASCADE,
    CONSTRAINT fk_trip_stop_outlet    FOREIGN KEY (outlet_id) REFERENCES retail_outlet (outlet_id),
    CONSTRAINT uq_trip_stop_sequence  UNIQUE (trip_id, stop_sequence),
    CONSTRAINT uq_trip_stop_outlet    UNIQUE (trip_id, outlet_id),
    -- target for composite FKs (stop + outlet must match)
    CONSTRAINT uq_trip_stop_id_outlet UNIQUE (trip_stop_id, outlet_id),
    CONSTRAINT ck_trip_stop_sequence  CHECK (stop_sequence > 0),
    CONSTRAINT ck_trip_stop_status    CHECK (status IN ('PENDING','ARRIVED','COMPLETED','SKIPPED','FAILED')),
    CONSTRAINT ck_trip_stop_failure   CHECK (status NOT IN ('FAILED','SKIPPED') OR failure_reason IS NOT NULL)
);
CREATE INDEX idx_trip_stop_outlet ON trip_stop (outlet_id);

CREATE TRIGGER trg_delivery_trip_updated_at BEFORE UPDATE ON delivery_trip
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
