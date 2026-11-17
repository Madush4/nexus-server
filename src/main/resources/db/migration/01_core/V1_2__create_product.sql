-- =====================================================================
-- V1_2  product  (single merged definition used by every module)
-- Owner : Bandara (product / agency / distribution)
-- =====================================================================
CREATE TABLE product (
    product_id      UUID          NOT NULL DEFAULT gen_random_uuid(),
    product_code    VARCHAR(50)   NOT NULL,
    product_name    VARCHAR(150)  NOT NULL,
    description     TEXT,
    unit_of_measure VARCHAR(20)   NOT NULL DEFAULT 'UNIT',
    unit_weight_kg  NUMERIC(10,3),
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_product         PRIMARY KEY (product_id),
    CONSTRAINT uq_product_code    UNIQUE (product_code),
    CONSTRAINT ck_product_uom     CHECK (unit_of_measure IN ('UNIT','PACK','BOX','CASE','KG','LITRE')),
    CONSTRAINT ck_product_weight  CHECK (unit_weight_kg IS NULL OR unit_weight_kg > 0)
);

CREATE TRIGGER trg_product_updated_at BEFORE UPDATE ON product
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
