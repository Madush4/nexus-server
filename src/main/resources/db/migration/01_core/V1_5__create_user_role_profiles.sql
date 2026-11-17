
CREATE TABLE manufacturing_admin (
    user_id  UUID        NOT NULL,
    role     VARCHAR(30) NOT NULL DEFAULT 'MANUFACTURING_ADMIN',

    CONSTRAINT pk_manufacturing_admin      PRIMARY KEY (user_id),
    CONSTRAINT ck_manufacturing_admin_role CHECK (role = 'MANUFACTURING_ADMIN'),
    CONSTRAINT fk_manufacturing_admin_user FOREIGN KEY (user_id, role)
        REFERENCES app_user (user_id, role) ON DELETE CASCADE
);

CREATE TABLE warehouse_admin (
    user_id       UUID        NOT NULL,
    role          VARCHAR(30) NOT NULL DEFAULT 'WAREHOUSE_ADMIN',
    warehouse_id  UUID        NOT NULL,

    CONSTRAINT pk_warehouse_admin           PRIMARY KEY (user_id),
    CONSTRAINT ck_warehouse_admin_role      CHECK (role = 'WAREHOUSE_ADMIN'),
    CONSTRAINT fk_warehouse_admin_user      FOREIGN KEY (user_id, role)
        REFERENCES app_user (user_id, role) ON DELETE CASCADE,
    CONSTRAINT fk_warehouse_admin_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id)
);
CREATE INDEX idx_warehouse_admin_warehouse ON warehouse_admin (warehouse_id);

CREATE TABLE warehouse_supervisor (
    user_id       UUID        NOT NULL,
    role          VARCHAR(30) NOT NULL DEFAULT 'WAREHOUSE_SUPERVISOR',
    warehouse_id  UUID        NOT NULL,

    CONSTRAINT pk_warehouse_supervisor           PRIMARY KEY (user_id),
    CONSTRAINT ck_warehouse_supervisor_role      CHECK (role = 'WAREHOUSE_SUPERVISOR'),
    CONSTRAINT fk_warehouse_supervisor_user      FOREIGN KEY (user_id, role)
        REFERENCES app_user (user_id, role) ON DELETE CASCADE,
    CONSTRAINT fk_warehouse_supervisor_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id)
);
CREATE INDEX idx_warehouse_supervisor_warehouse ON warehouse_supervisor (warehouse_id);

CREATE TABLE agency_manager (
    user_id    UUID        NOT NULL,
    role       VARCHAR(30) NOT NULL DEFAULT 'AGENCY_MANAGER',
    agency_id  UUID        NOT NULL,

    CONSTRAINT pk_agency_manager        PRIMARY KEY (user_id),
    CONSTRAINT ck_agency_manager_role   CHECK (role = 'AGENCY_MANAGER'),
    CONSTRAINT fk_agency_manager_user   FOREIGN KEY (user_id, role)
        REFERENCES app_user (user_id, role) ON DELETE CASCADE,
    CONSTRAINT fk_agency_manager_agency FOREIGN KEY (agency_id)
        REFERENCES agency (agency_id)
);
CREATE INDEX idx_agency_manager_agency ON agency_manager (agency_id);

CREATE TABLE agent (
    user_id        UUID        NOT NULL,
    role           VARCHAR(30) NOT NULL DEFAULT 'AGENT',
    agency_id      UUID        NOT NULL,
    employee_code  VARCHAR(20) NOT NULL,

    CONSTRAINT pk_agent          PRIMARY KEY (user_id),
    CONSTRAINT ck_agent_role     CHECK (role = 'AGENT'),
    CONSTRAINT fk_agent_user     FOREIGN KEY (user_id, role)
        REFERENCES app_user (user_id, role) ON DELETE CASCADE,
    CONSTRAINT fk_agent_agency   FOREIGN KEY (agency_id) REFERENCES agency (agency_id),
    CONSTRAINT uq_agent_employee_code UNIQUE (agency_id, employee_code)
);
CREATE INDEX idx_agent_agency ON agent (agency_id);
