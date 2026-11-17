-- =====================================================================
-- V1_1  app_user  (EER superclass "User")
-- Owner : Bandara (auth & access)
-- One login table for every role. Role-specific data lives in the
-- subclass tables created in V1_5 (disjoint, total specialization).
-- ("user" is a reserved word in PostgreSQL, so the table is app_user.)
-- =====================================================================
CREATE TABLE app_user (
    user_id         UUID         NOT NULL DEFAULT gen_random_uuid(),
    full_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(150) NOT NULL,
    contact_number  VARCHAR(20),
    nic             VARCHAR(12),
    password_hash   TEXT         NOT NULL,
    role            VARCHAR(30)  NOT NULL,
    account_status  VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_app_user          PRIMARY KEY (user_id),
    CONSTRAINT uq_app_user_email    UNIQUE (email),
    CONSTRAINT uq_app_user_nic      UNIQUE (nic),
    -- lets subclass tables enforce "this user really has my role"
    CONSTRAINT uq_app_user_id_role  UNIQUE (user_id, role),
    CONSTRAINT ck_app_user_email_lower CHECK (email = lower(email)),
    CONSTRAINT ck_app_user_role     CHECK (role IN ('MANUFACTURING_ADMIN','WAREHOUSE_ADMIN',
                                                    'WAREHOUSE_SUPERVISOR','AGENCY_MANAGER','AGENT')),
    CONSTRAINT ck_app_user_status   CHECK (account_status IN ('ACTIVE','INACTIVE','LOCKED')),
    -- Sri Lankan NIC: old 9 digits + V/X, or new 12 digits
    CONSTRAINT ck_app_user_nic      CHECK (nic IS NULL OR nic ~ '^([0-9]{9}[VvXx]|[0-9]{12})$')
);

CREATE TRIGGER trg_app_user_updated_at BEFORE UPDATE ON app_user
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
