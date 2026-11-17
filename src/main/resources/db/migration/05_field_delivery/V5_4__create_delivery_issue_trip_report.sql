
CREATE TABLE delivery_issue (
    issue_id      UUID         NOT NULL DEFAULT gen_random_uuid(),
    trip_id       UUID         NOT NULL,
    trip_stop_id  UUID,
    reported_by   UUID         NOT NULL,
    issue_type    VARCHAR(30)  NOT NULL,
    description   TEXT         NOT NULL,
    status        VARCHAR(20)  NOT NULL DEFAULT 'OPEN',
    reviewed_by   UUID,
    reported_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    resolved_at   TIMESTAMPTZ,

    CONSTRAINT pk_delivery_issue          PRIMARY KEY (issue_id),
    CONSTRAINT fk_delivery_issue_trip     FOREIGN KEY (trip_id)      REFERENCES delivery_trip (trip_id),
    CONSTRAINT fk_delivery_issue_stop     FOREIGN KEY (trip_stop_id) REFERENCES trip_stop (trip_stop_id),
    CONSTRAINT fk_delivery_issue_agent    FOREIGN KEY (reported_by)  REFERENCES agent (user_id),
    CONSTRAINT fk_delivery_issue_manager  FOREIGN KEY (reviewed_by)  REFERENCES agency_manager (user_id),
    CONSTRAINT ck_delivery_issue_type     CHECK (issue_type IN ('VEHICLE_BREAKDOWN','ROAD_BLOCKED','OUTLET_CLOSED',
                                                                'ACCIDENT','STOCK_SHORTAGE','OTHER')),
    CONSTRAINT ck_delivery_issue_status   CHECK (status IN ('OPEN','REVIEWED','RESOLVED')),
    CONSTRAINT ck_delivery_issue_resolved CHECK (status <> 'RESOLVED' OR resolved_at IS NOT NULL)
);
CREATE INDEX idx_delivery_issue_trip ON delivery_issue (trip_id);

CREATE TABLE trip_report (
    trip_report_id  UUID         NOT NULL DEFAULT gen_random_uuid(),
    trip_id         UUID         NOT NULL,
    submitted_by    UUID         NOT NULL,
    summary         TEXT,
    report_url      TEXT,
    submitted_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    reviewed_by     UUID,
    reviewed_at     TIMESTAMPTZ,

    CONSTRAINT pk_trip_report          PRIMARY KEY (trip_report_id),
    CONSTRAINT fk_trip_report_trip     FOREIGN KEY (trip_id)      REFERENCES delivery_trip (trip_id),
    CONSTRAINT fk_trip_report_agent    FOREIGN KEY (submitted_by) REFERENCES agent (user_id),
    CONSTRAINT fk_trip_report_manager  FOREIGN KEY (reviewed_by)  REFERENCES agency_manager (user_id),
    CONSTRAINT uq_trip_report_trip     UNIQUE (trip_id),
    CONSTRAINT ck_trip_report_content  CHECK (summary IS NOT NULL OR report_url IS NOT NULL),
    CONSTRAINT ck_trip_report_review   CHECK ((reviewed_by IS NULL) = (reviewed_at IS NULL))
);
