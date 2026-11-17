
CREATE TABLE location_log (
    log_id       BIGINT        GENERATED ALWAYS AS IDENTITY,
    agent_id     UUID          NOT NULL,
    trip_id      UUID,
    latitude     NUMERIC(9,6)  NOT NULL,
    longitude    NUMERIC(9,6)  NOT NULL,
    speed_kmh    NUMERIC(5,2),
    accuracy_m   NUMERIC(6,2),
    recorded_at  TIMESTAMPTZ   NOT NULL,

    CONSTRAINT pk_location_log        PRIMARY KEY (log_id),
    CONSTRAINT fk_location_log_agent  FOREIGN KEY (agent_id) REFERENCES agent (user_id),
    CONSTRAINT fk_location_log_trip   FOREIGN KEY (trip_id)  REFERENCES delivery_trip (trip_id),
    CONSTRAINT ck_location_log_lat    CHECK (latitude  BETWEEN  -90 AND  90),
    CONSTRAINT ck_location_log_lng    CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_location_log_speed  CHECK (speed_kmh  IS NULL OR speed_kmh  >= 0),
    CONSTRAINT ck_location_log_acc    CHECK (accuracy_m IS NULL OR accuracy_m >= 0)
);
CREATE INDEX idx_location_log_trip  ON location_log (trip_id, recorded_at);
CREATE INDEX idx_location_log_agent ON location_log (agent_id, recorded_at);
