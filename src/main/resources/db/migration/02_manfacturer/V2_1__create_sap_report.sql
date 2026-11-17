-- =====================================================================
-- V2_1  sap_report, sap_report_item
-- Owner : Bandara (manufacturer / ERP integration)
-- A manufacturing admin uploads an ERP (SAP-style) report; each line
-- says how much of a product an agency should receive.
-- =====================================================================
CREATE TABLE sap_report (
    report_id    UUID          NOT NULL DEFAULT gen_random_uuid(),
    uploaded_by  UUID          NOT NULL,
    file_name    VARCHAR(255)  NOT NULL,
    file_path    TEXT          NOT NULL,
    report_date  DATE          NOT NULL,
    status       VARCHAR(30)   NOT NULL DEFAULT 'PENDING',
    uploaded_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_sap_report          PRIMARY KEY (report_id),
    CONSTRAINT fk_sap_report_uploader FOREIGN KEY (uploaded_by)
        REFERENCES manufacturing_admin (user_id),
    CONSTRAINT ck_sap_report_status   CHECK (status IN ('PENDING','IN_PROGRESS','ACCEPTED',
                                                        'PARTIALLY_ACCEPTED','REJECTED'))
);
CREATE INDEX idx_sap_report_uploader ON sap_report (uploaded_by);

CREATE TABLE sap_report_item (
    report_item_id  UUID           NOT NULL DEFAULT gen_random_uuid(),
    report_id       UUID           NOT NULL,
    product_id      UUID           NOT NULL,
    agency_id       UUID           NOT NULL,
    quantity        INTEGER        NOT NULL,
    due_payment     NUMERIC(12,2)  NOT NULL DEFAULT 0,

    CONSTRAINT pk_sap_report_item         PRIMARY KEY (report_item_id),
    CONSTRAINT fk_sap_report_item_report  FOREIGN KEY (report_id)
        REFERENCES sap_report (report_id) ON DELETE CASCADE,
    CONSTRAINT fk_sap_report_item_product FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT fk_sap_report_item_agency  FOREIGN KEY (agency_id)  REFERENCES agency (agency_id),
    CONSTRAINT uq_sap_report_item_line    UNIQUE (report_id, agency_id, product_id),
    CONSTRAINT ck_sap_report_item_qty     CHECK (quantity > 0),
    CONSTRAINT ck_sap_report_item_due     CHECK (due_payment >= 0)
);
CREATE INDEX idx_sap_report_item_product ON sap_report_item (product_id);
CREATE INDEX idx_sap_report_item_agency  ON sap_report_item (agency_id);

CREATE TRIGGER trg_sap_report_updated_at BEFORE UPDATE ON sap_report
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
