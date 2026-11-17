-- =====================================================================
-- V1_3  agency, operational_area, retail_outlet
-- Owner : Bandara (product / agency / distribution)
--
-- GPS: latitude/longitude are stored (NUMERIC(9,6) ~ 0.1 m precision)
-- because route optimisation and the map need real coordinates.
-- A Google Maps link is NOT stored - the frontend builds it:
--   https://www.google.com/maps?q=<latitude>,<longitude>
-- =====================================================================
CREATE TABLE agency (
    agency_id       UUID          NOT NULL DEFAULT gen_random_uuid(),
    agency_code     VARCHAR(20)   NOT NULL,
    agency_name     VARCHAR(150)  NOT NULL,
    email           VARCHAR(150),
    contact_number  VARCHAR(20)   NOT NULL,
    address         TEXT          NOT NULL,
    latitude        NUMERIC(9,6),
    longitude       NUMERIC(9,6),
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_agency        PRIMARY KEY (agency_id),
    CONSTRAINT uq_agency_code   UNIQUE (agency_code),
    CONSTRAINT uq_agency_email  UNIQUE (email),
    CONSTRAINT ck_agency_lat    CHECK (latitude  BETWEEN  -90 AND  90),
    CONSTRAINT ck_agency_lng    CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_agency_latlng_pair CHECK ((latitude IS NULL) = (longitude IS NULL))
);

CREATE TABLE operational_area (
    area_id      UUID          NOT NULL DEFAULT gen_random_uuid(),
    agency_id    UUID          NOT NULL,
    area_code    VARCHAR(20)   NOT NULL,
    area_name    VARCHAR(150)  NOT NULL,
    description  TEXT,
    is_active    BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_operational_area       PRIMARY KEY (area_id),
    CONSTRAINT fk_operational_area_agency FOREIGN KEY (agency_id) REFERENCES agency (agency_id),
    CONSTRAINT uq_operational_area_code  UNIQUE (agency_id, area_code)
);
CREATE INDEX idx_operational_area_agency ON operational_area (agency_id);

CREATE TABLE retail_outlet (
    outlet_id       UUID          NOT NULL DEFAULT gen_random_uuid(),
    area_id         UUID          NOT NULL,
    outlet_code     VARCHAR(20)   NOT NULL,
    outlet_name     VARCHAR(150)  NOT NULL,
    owner_name      VARCHAR(150),
    contact_number  VARCHAR(20)   NOT NULL,
    address         TEXT          NOT NULL,
    latitude        NUMERIC(9,6),
    longitude       NUMERIC(9,6),
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_retail_outlet      PRIMARY KEY (outlet_id),
    CONSTRAINT fk_retail_outlet_area FOREIGN KEY (area_id) REFERENCES operational_area (area_id),
    CONSTRAINT uq_retail_outlet_code UNIQUE (outlet_code),
    CONSTRAINT ck_retail_outlet_lat  CHECK (latitude  BETWEEN  -90 AND  90),
    CONSTRAINT ck_retail_outlet_lng  CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_retail_outlet_latlng_pair CHECK ((latitude IS NULL) = (longitude IS NULL))
);
CREATE INDEX idx_retail_outlet_area ON retail_outlet (area_id);

CREATE TRIGGER trg_agency_updated_at BEFORE UPDATE ON agency
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_retail_outlet_updated_at BEFORE UPDATE ON retail_outlet
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
