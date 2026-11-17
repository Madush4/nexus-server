
CREATE TABLE warehouse_report (
    report_id     UUID          NOT NULL DEFAULT gen_random_uuid(),
    warehouse_id  UUID          NOT NULL,
    generated_by  UUID          NOT NULL,
    report_type   VARCHAR(30)   NOT NULL,
    title         VARCHAR(200)  NOT NULL,
    period_start  DATE          NOT NULL,
    period_end    DATE          NOT NULL,
    file_url      TEXT,
    generated_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_warehouse_report           PRIMARY KEY (report_id),
    CONSTRAINT fk_warehouse_report_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouse (warehouse_id),
    CONSTRAINT fk_warehouse_report_admin     FOREIGN KEY (generated_by) REFERENCES warehouse_admin (user_id),
    CONSTRAINT ck_warehouse_report_type      CHECK (report_type IN ('DAILY_DISPATCH','DISCREPANCY',
                                                                    'STOCK_SUMMARY','MONTHLY')),
    CONSTRAINT ck_warehouse_report_period    CHECK (period_end >= period_start)
);
CREATE INDEX idx_warehouse_report_warehouse ON warehouse_report (warehouse_id, generated_at);
