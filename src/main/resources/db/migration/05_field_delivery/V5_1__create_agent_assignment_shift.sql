
CREATE TABLE agent_area_assignment (
    assignment_id  UUID  NOT NULL DEFAULT gen_random_uuid(),
    agent_id       UUID  NOT NULL,
    area_id        UUID  NOT NULL,
    assigned_by    UUID  NOT NULL,
    assigned_from  DATE  NOT NULL DEFAULT CURRENT_DATE,
    assigned_to    DATE,                    -- NULL = still active

    CONSTRAINT pk_agent_area_assignment         PRIMARY KEY (assignment_id),
    CONSTRAINT fk_agent_area_assignment_agent   FOREIGN KEY (agent_id)    REFERENCES agent (user_id),
    CONSTRAINT fk_agent_area_assignment_area    FOREIGN KEY (area_id)     REFERENCES operational_area (area_id),
    CONSTRAINT fk_agent_area_assignment_manager FOREIGN KEY (assigned_by) REFERENCES agency_manager (user_id),
    CONSTRAINT ck_agent_area_assignment_dates   CHECK (assigned_to IS NULL OR assigned_to >= assigned_from)
);
-- only one ACTIVE assignment per agent + area (history rows allowed)
CREATE UNIQUE INDEX uq_agent_area_assignment_active
    ON agent_area_assignment (agent_id, area_id) WHERE assigned_to IS NULL;
CREATE INDEX idx_agent_area_assignment_area ON agent_area_assignment (area_id);

-- GPS: check-in / check-out position only (attendance proof).
-- Live position history is in location_log (V5_6), not here.
CREATE TABLE agent_day_shift (
    shift_id        UUID          NOT NULL DEFAULT gen_random_uuid(),
    agent_id        UUID          NOT NULL,
    shift_date      DATE          NOT NULL,
    check_in_at     TIMESTAMPTZ   NOT NULL,
    check_out_at    TIMESTAMPTZ,
    check_in_lat    NUMERIC(9,6),
    check_in_lng    NUMERIC(9,6),
    check_out_lat   NUMERIC(9,6),
    check_out_lng   NUMERIC(9,6),

    CONSTRAINT pk_agent_day_shift        PRIMARY KEY (shift_id),
    CONSTRAINT fk_agent_day_shift_agent  FOREIGN KEY (agent_id) REFERENCES agent (user_id),
    CONSTRAINT uq_agent_day_shift_date   UNIQUE (agent_id, shift_date),
    CONSTRAINT ck_agent_day_shift_times  CHECK (check_out_at IS NULL OR check_out_at >= check_in_at),
    CONSTRAINT ck_agent_day_shift_in     CHECK ((check_in_lat  IS NULL) = (check_in_lng  IS NULL)),
    CONSTRAINT ck_agent_day_shift_out    CHECK ((check_out_lat IS NULL) = (check_out_lng IS NULL))
);
