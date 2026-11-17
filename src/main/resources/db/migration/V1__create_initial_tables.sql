-- ============================================================================
-- Manufacturer-Centric Distribution Management System
-- Consolidated PostgreSQL schema: V1 through V5
-- Designed for a NEW / EMPTY database, in dependency order.
-- PostgreSQL extensions: pgcrypto (gen_random_uuid)
--
-- IMPORTANT:
-- 1. This is a consolidated reference schema, not a replacement for already
--    applied Flyway migrations. If migrations have been applied, create NEW
--    forward-only migrations with ALTER TABLE / CREATE INDEX operations.
-- 2. Columns marked as additional are included to enforce cross-agency,
--    cross-report, and cross-order relationships at database level.
-- 3. Review business rules for report processing, handover quantities, and
--    role assignment before production deployment.
-- ============================================================================

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- V1_1: APP USER
-- ============================================================================
CREATE TABLE app_user (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    contact_number VARCHAR(20),
    nic VARCHAR(12) UNIQUE,
    password_hash TEXT NOT NULL,
    role VARCHAR(30) NOT NULL,
    account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_app_user_email_lower CHECK (email = LOWER(email)),
    CONSTRAINT ck_app_user_nic CHECK (
        nic IS NULL OR nic ~ '^([0-9]{9}[VvXx]|[0-9]{12})$'
    ),
    CONSTRAINT ck_app_user_role CHECK (role IN (
        'SUPER_ADMIN', 'MANUFACTURING_ADMIN', 'WAREHOUSE_ADMIN',
        'WAREHOUSE_SUPERVISOR', 'AGENCY_MANAGER', 'AGENT'
    )),
    CONSTRAINT ck_app_user_account_status CHECK (
        account_status IN ('ACTIVE', 'INACTIVE', 'LOCKED')
    ),
    -- Referenced by role-profile tables to validate both user and role.
    CONSTRAINT uq_app_user_id_role UNIQUE (user_id, role)
);

CREATE INDEX idx_app_user_role ON app_user(role);
CREATE INDEX idx_app_user_account_status ON app_user(account_status);

-- ============================================================================
-- V1_2: PRODUCT
-- ============================================================================
CREATE TABLE product (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_code VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(150) NOT NULL,
    description TEXT,
    unit_of_measure VARCHAR(20) NOT NULL DEFAULT 'UNIT',
    unit_weight_kg NUMERIC(10,3),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_product_unit CHECK (unit_of_measure IN (
        'UNIT', 'PACK', 'BOX', 'CASE', 'KG', 'LITRE'
    )),
    CONSTRAINT ck_product_unit_weight CHECK (
        unit_weight_kg IS NULL OR unit_weight_kg > 0
    ),
    CONSTRAINT ck_product_code_not_empty CHECK (LENGTH(TRIM(product_code)) > 0),
    CONSTRAINT ck_product_name_not_empty CHECK (LENGTH(TRIM(product_name)) > 0)
);

-- ============================================================================
-- V1_3: AGENCY, AREA, OUTLET
-- ============================================================================
CREATE TABLE agency (
    agency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_code VARCHAR(20) NOT NULL UNIQUE,
    agency_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE,
    contact_number VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_agency_latlng_pair CHECK (
        (latitude IS NULL) = (longitude IS NULL)
    ),
    CONSTRAINT ck_agency_latitude CHECK (
        latitude IS NULL OR latitude BETWEEN -90 AND 90
    ),
    CONSTRAINT ck_agency_longitude CHECK (
        longitude IS NULL OR longitude BETWEEN -180 AND 180
    ),
    CONSTRAINT ck_agency_email_lower CHECK (
        email IS NULL OR email = LOWER(email)
    )
);

CREATE TABLE operational_area (
    area_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    area_code VARCHAR(20) NOT NULL,
    area_name VARCHAR(150) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_operational_area_code UNIQUE (agency_id, area_code),
    -- Composite parent key used to validate the outlet's agency.
    CONSTRAINT uq_operational_area_id_agency UNIQUE (area_id, agency_id)
);

-- Additional agency_id is intentionally stored on the outlet so that
-- composite FKs can enforce outlet/agency consistency throughout V3-V5.
CREATE TABLE retail_outlet (
    outlet_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    area_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    outlet_code VARCHAR(20) NOT NULL UNIQUE,
    outlet_name VARCHAR(150) NOT NULL,
    owner_name VARCHAR(150),
    contact_number VARCHAR(20),
    address TEXT NOT NULL,
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_retail_outlet_area_agency
        FOREIGN KEY (area_id, agency_id)
        REFERENCES operational_area(area_id, agency_id),
    CONSTRAINT ck_retail_outlet_latlng_pair CHECK (
        (latitude IS NULL) = (longitude IS NULL)
    ),
    CONSTRAINT ck_retail_outlet_latitude CHECK (
        latitude IS NULL OR latitude BETWEEN -90 AND 90
    ),
    CONSTRAINT ck_retail_outlet_longitude CHECK (
        longitude IS NULL OR longitude BETWEEN -180 AND 180
    ),
    CONSTRAINT uq_retail_outlet_id_agency UNIQUE (outlet_id, agency_id),
    CONSTRAINT uq_retail_outlet_id_area_agency
        UNIQUE (outlet_id, area_id, agency_id)
);

CREATE INDEX idx_operational_area_agency ON operational_area(agency_id);
CREATE INDEX idx_retail_outlet_area ON retail_outlet(area_id);
CREATE INDEX idx_retail_outlet_agency ON retail_outlet(agency_id);
CREATE INDEX idx_retail_outlet_active ON retail_outlet(area_id, is_active);

-- ============================================================================
-- V1_4: WAREHOUSE
-- ============================================================================
CREATE TABLE warehouse (
    warehouse_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_code VARCHAR(20) NOT NULL UNIQUE,
    warehouse_name VARCHAR(150) NOT NULL,
    address TEXT NOT NULL,
    contact_number VARCHAR(20),
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_warehouse_latlng_pair CHECK (
        (latitude IS NULL) = (longitude IS NULL)
    ),
    CONSTRAINT ck_warehouse_latitude CHECK (
        latitude IS NULL OR latitude BETWEEN -90 AND 90
    ),
    CONSTRAINT ck_warehouse_longitude CHECK (
        longitude IS NULL OR longitude BETWEEN -180 AND 180
    )
);

-- ============================================================================
-- V1_5: ROLE PROFILES
-- ============================================================================
CREATE TABLE manufacturing_admin (
    user_id UUID PRIMARY KEY,
    role VARCHAR(30) NOT NULL DEFAULT 'MANUFACTURING_ADMIN',
    CONSTRAINT ck_manufacturing_admin_role CHECK (role = 'MANUFACTURING_ADMIN'),
    CONSTRAINT fk_manufacturing_admin_user
        FOREIGN KEY (user_id, role)
        REFERENCES app_user(user_id, role) ON DELETE CASCADE
);

CREATE TABLE warehouse_admin (
    user_id UUID PRIMARY KEY,
    role VARCHAR(30) NOT NULL DEFAULT 'WAREHOUSE_ADMIN',
    warehouse_id UUID NOT NULL REFERENCES warehouse(warehouse_id),
    CONSTRAINT ck_warehouse_admin_role CHECK (role = 'WAREHOUSE_ADMIN'),
    CONSTRAINT fk_warehouse_admin_user
        FOREIGN KEY (user_id, role)
        REFERENCES app_user(user_id, role) ON DELETE CASCADE,
    CONSTRAINT uq_warehouse_admin_user_warehouse UNIQUE (user_id, warehouse_id)
);

CREATE TABLE warehouse_supervisor (
    user_id UUID PRIMARY KEY,
    role VARCHAR(30) NOT NULL DEFAULT 'WAREHOUSE_SUPERVISOR',
    warehouse_id UUID NOT NULL REFERENCES warehouse(warehouse_id),
    CONSTRAINT ck_warehouse_supervisor_role CHECK (role = 'WAREHOUSE_SUPERVISOR'),
    CONSTRAINT fk_warehouse_supervisor_user
        FOREIGN KEY (user_id, role)
        REFERENCES app_user(user_id, role) ON DELETE CASCADE,
    CONSTRAINT uq_warehouse_supervisor_user_warehouse UNIQUE (user_id, warehouse_id)
);

CREATE TABLE agency_manager (
    user_id UUID PRIMARY KEY,
    role VARCHAR(30) NOT NULL DEFAULT 'AGENCY_MANAGER',
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    CONSTRAINT ck_agency_manager_role CHECK (role = 'AGENCY_MANAGER'),
    CONSTRAINT fk_agency_manager_user
        FOREIGN KEY (user_id, role)
        REFERENCES app_user(user_id, role) ON DELETE CASCADE,
    CONSTRAINT uq_agency_manager_user_agency UNIQUE (user_id, agency_id)
);

CREATE TABLE agent (
    user_id UUID PRIMARY KEY,
    role VARCHAR(30) NOT NULL DEFAULT 'AGENT',
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    employee_code VARCHAR(20) NOT NULL,
    CONSTRAINT ck_agent_role CHECK (role = 'AGENT'),
    CONSTRAINT fk_agent_user
        FOREIGN KEY (user_id, role)
        REFERENCES app_user(user_id, role) ON DELETE CASCADE,
    CONSTRAINT uq_agent_employee_code UNIQUE (agency_id, employee_code),
    CONSTRAINT uq_agent_user_agency UNIQUE (user_id, agency_id)
);

CREATE INDEX idx_warehouse_admin_warehouse ON warehouse_admin(warehouse_id);
CREATE INDEX idx_warehouse_supervisor_warehouse ON warehouse_supervisor(warehouse_id);
CREATE INDEX idx_agency_manager_agency ON agency_manager(agency_id);
CREATE INDEX idx_agent_agency ON agent(agency_id);

-- ============================================================================
-- V1_6: AUDIT LOG
-- ============================================================================
CREATE TABLE audit_log (
    log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES app_user(user_id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_log_user_created ON audit_log(user_id, created_at DESC);
CREATE INDEX idx_audit_log_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_log_action ON audit_log(action);

-- ============================================================================
-- V1_8: SUPER ADMIN PROFILE
-- ============================================================================
CREATE TABLE super_admin (
    user_id UUID PRIMARY KEY,
    role VARCHAR(30) NOT NULL DEFAULT 'SUPER_ADMIN',
    CONSTRAINT ck_super_admin_role CHECK (role = 'SUPER_ADMIN'),
    CONSTRAINT fk_super_admin_user
        FOREIGN KEY (user_id, role)
        REFERENCES app_user(user_id, role) ON DELETE CASCADE
);

-- ============================================================================
-- V2_1: SAP REPORTS
-- A report may contain many product lines for each agency. Therefore the
-- report/agency pair is represented by sap_report_agency, not made UNIQUE on
-- sap_report_item (which would incorrectly limit an agency to one product).
-- ============================================================================
CREATE TABLE sap_report (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    uploaded_by UUID NOT NULL REFERENCES manufacturing_admin(user_id),
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    report_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_sap_report_status CHECK (status IN (
        'PENDING', 'IN_PROGRESS', 'ACCEPTED', 'PARTIALLY_ACCEPTED', 'REJECTED'
    ))
);

CREATE TABLE sap_report_agency (
    report_id UUID NOT NULL REFERENCES sap_report(report_id) ON DELETE CASCADE,
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (report_id, agency_id)
);

CREATE TABLE sap_report_item (
    report_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    product_id UUID NOT NULL REFERENCES product(product_id),
    quantity INTEGER NOT NULL,
    due_payment NUMERIC(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT ck_sap_report_item_quantity CHECK (quantity > 0),
    CONSTRAINT ck_sap_report_item_due_payment CHECK (due_payment >= 0),
    CONSTRAINT fk_sap_report_item_report_agency
        FOREIGN KEY (report_id, agency_id)
        REFERENCES sap_report_agency(report_id, agency_id) ON DELETE CASCADE,
    CONSTRAINT uq_sap_report_item_line UNIQUE (report_id, agency_id, product_id),
    CONSTRAINT uq_sap_report_item_reference
        UNIQUE (report_item_id, report_id, agency_id, product_id)
);

CREATE INDEX idx_sap_report_date ON sap_report(report_date DESC);
CREATE INDEX idx_sap_report_status ON sap_report(status);
CREATE INDEX idx_sap_report_uploaded_by ON sap_report(uploaded_by);
CREATE INDEX idx_sap_report_item_product ON sap_report_item(product_id);
CREATE INDEX idx_sap_report_item_agency ON sap_report_item(agency_id);

-- ============================================================================
-- V2_2: MANUFACTURER INVENTORY AND MOVEMENTS
-- ============================================================================
CREATE TABLE manufacturer_inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL UNIQUE REFERENCES product(product_id),
    quantity_on_hand INTEGER NOT NULL DEFAULT 0,
    quantity_reserved INTEGER NOT NULL DEFAULT 0,
    minimum_stock_level INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_manufacturer_inventory_qty CHECK (
        quantity_on_hand >= 0
        AND quantity_reserved >= 0
        AND quantity_reserved <= quantity_on_hand
        AND minimum_stock_level >= 0
    ),
    CONSTRAINT uq_manufacturer_inventory_id_product UNIQUE (inventory_id, product_id)
);

CREATE TABLE manufacturer_stock_movement (
    movement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES manufacturer_inventory(product_id),
    report_id UUID REFERENCES sap_report(report_id),
    performed_by UUID NOT NULL REFERENCES manufacturing_admin(user_id),
    movement_type VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL,
    reference_type VARCHAR(30),
    reference_id UUID,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_manufacturer_stock_movement_type CHECK (movement_type IN (
        'STOCK_IN', 'STOCK_OUT', 'RESERVATION', 'RELEASE', 'ADJUSTMENT'
    )),
    CONSTRAINT ck_manufacturer_stock_movement_quantity CHECK (quantity > 0),
    CONSTRAINT ck_manufacturer_stock_movement_ref CHECK (
        (reference_type IS NULL) = (reference_id IS NULL)
    )
);

CREATE INDEX idx_manufacturer_stock_movement_product
    ON manufacturer_stock_movement(product_id, created_at DESC);
CREATE INDEX idx_manufacturer_stock_movement_report
    ON manufacturer_stock_movement(report_id);
CREATE INDEX idx_manufacturer_stock_movement_reference
    ON manufacturer_stock_movement(reference_type, reference_id)
    WHERE reference_id IS NOT NULL;

-- ============================================================================
-- V2_3: AGENCY ORDERS
-- report_id + agency_id identifies the SAP report segment for the order.
-- Each order line must match a product line in that exact report segment.
-- ============================================================================
CREATE TABLE agency_order (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    created_by UUID NOT NULL REFERENCES manufacturing_admin(user_id),
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_agency_order_report_agency
        FOREIGN KEY (report_id, agency_id)
        REFERENCES sap_report_agency(report_id, agency_id),
    CONSTRAINT ck_agency_order_status CHECK (status IN (
        'DRAFT', 'CONFIRMED', 'HANDED_OVER', 'DISPATCHED', 'CANCELLED'
    )),
    CONSTRAINT uq_agency_order_report_agency UNIQUE (report_id, agency_id),
    CONSTRAINT uq_agency_order_id_agency UNIQUE (order_id, agency_id),
    CONSTRAINT uq_agency_order_id_report UNIQUE (order_id, report_id),
    CONSTRAINT uq_agency_order_reference UNIQUE (order_id, report_id, agency_id)
);

CREATE TABLE agency_order_item (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    report_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    product_id UUID NOT NULL,
    requested_qty INTEGER NOT NULL,
    allocated_qty INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_agency_order_item_qty CHECK (
        requested_qty > 0 AND allocated_qty >= 0 AND allocated_qty <= requested_qty
    ),
    CONSTRAINT fk_agency_order_item_order
        FOREIGN KEY (order_id, report_id, agency_id)
        REFERENCES agency_order(order_id, report_id, agency_id) ON DELETE CASCADE,
    CONSTRAINT fk_agency_order_item_report_product
        FOREIGN KEY (report_id, agency_id, product_id)
        REFERENCES sap_report_item(report_id, agency_id, product_id),
    CONSTRAINT uq_agency_order_item_product UNIQUE (order_id, product_id),
    CONSTRAINT uq_agency_order_item_id_order UNIQUE (order_item_id, order_id)
);

CREATE INDEX idx_agency_order_agency ON agency_order(agency_id);
CREATE INDEX idx_agency_order_status ON agency_order(status);
CREATE INDEX idx_agency_order_report ON agency_order(report_id);
CREATE INDEX idx_agency_order_item_product ON agency_order_item(product_id);

-- ============================================================================
-- V2_4: WAREHOUSE HANDOVER
-- One handover per SAP report in this design. Handover lines can contain
-- multiple agency orders from that report.
-- ============================================================================
CREATE TABLE warehouse_handover (
    handover_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handover_reference VARCHAR(50) NOT NULL UNIQUE,
    report_id UUID NOT NULL UNIQUE REFERENCES sap_report(report_id),
    warehouse_id UUID NOT NULL REFERENCES warehouse(warehouse_id),
    handed_over_by UUID NOT NULL REFERENCES manufacturing_admin(user_id),
    received_by UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    sent_at TIMESTAMPTZ,
    received_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_warehouse_handover_receiver
        FOREIGN KEY (received_by, warehouse_id)
        REFERENCES warehouse_admin(user_id, warehouse_id),
    CONSTRAINT ck_warehouse_handover_status CHECK (status IN (
        'DRAFT', 'SENT', 'RECEIVED', 'REJECTED'
    )),
    CONSTRAINT ck_warehouse_handover_times CHECK (
        received_at IS NULL OR (sent_at IS NOT NULL AND received_at >= sent_at)
    ),
    CONSTRAINT ck_warehouse_handover_receiver CHECK (
        (received_by IS NULL) = (received_at IS NULL)
    ),
    CONSTRAINT ck_warehouse_handover_sent CHECK (
        status = 'DRAFT' OR sent_at IS NOT NULL
    ),
    CONSTRAINT ck_warehouse_handover_received CHECK (
        status <> 'RECEIVED' OR received_at IS NOT NULL
    ),
    CONSTRAINT uq_warehouse_handover_id_report UNIQUE (handover_id, report_id),
    CONSTRAINT uq_warehouse_handover_id_warehouse_report
        UNIQUE (handover_id, warehouse_id, report_id)
);

CREATE TABLE warehouse_handover_item (
    handover_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handover_id UUID NOT NULL,
    report_id UUID NOT NULL,
    order_id UUID NOT NULL,
    order_item_id UUID NOT NULL,
    quantity INTEGER NOT NULL,
    CONSTRAINT ck_warehouse_handover_item_quantity CHECK (quantity > 0),
    CONSTRAINT fk_handover_item_handover
        FOREIGN KEY (handover_id, report_id)
        REFERENCES warehouse_handover(handover_id, report_id) ON DELETE CASCADE,
    CONSTRAINT fk_handover_item_order
        FOREIGN KEY (order_id, report_id)
        REFERENCES agency_order(order_id, report_id),
    CONSTRAINT fk_handover_item_order_item
        FOREIGN KEY (order_item_id, order_id)
        REFERENCES agency_order_item(order_item_id, order_id),
    CONSTRAINT uq_warehouse_handover_item_line UNIQUE (handover_id, order_item_id)
);

CREATE INDEX idx_warehouse_handover_warehouse
    ON warehouse_handover(warehouse_id);
CREATE INDEX idx_warehouse_handover_status
    ON warehouse_handover(status);
CREATE INDEX idx_warehouse_handover_item_order
    ON warehouse_handover_item(order_id);

-- ============================================================================
-- V3_1: DRIVER, VEHICLE, VEHICLE MAINTENANCE
-- ============================================================================
CREATE TABLE driver (
    driver_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    full_name VARCHAR(150) NOT NULL,
    nic VARCHAR(12) NOT NULL UNIQUE,
    contact_number VARCHAR(20) NOT NULL,
    address TEXT,
    licence_number VARCHAR(20) NOT NULL UNIQUE,
    licence_expiry_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_driver_nic CHECK (nic ~ '^([0-9]{9}[VvXx]|[0-9]{12})$'),
    CONSTRAINT uq_driver_id_agency UNIQUE (driver_id, agency_id)
);

CREATE TABLE vehicle (
    vehicle_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    registration_number VARCHAR(20) NOT NULL UNIQUE,
    vehicle_type VARCHAR(20) NOT NULL,
    max_load_kg NUMERIC(10,2) NOT NULL,
    operational_status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_vehicle_type CHECK (vehicle_type IN (
        'LORRY', 'VAN', 'TRUCK', 'THREE_WHEELER', 'MOTORBIKE'
    )),
    CONSTRAINT ck_vehicle_max_load CHECK (max_load_kg > 0),
    CONSTRAINT ck_vehicle_operational_status CHECK (operational_status IN (
        'AVAILABLE', 'ON_TRIP', 'UNDER_MAINTENANCE', 'OUT_OF_SERVICE'
    )),
    CONSTRAINT uq_vehicle_id_agency UNIQUE (vehicle_id, agency_id)
);

CREATE TABLE vehicle_maintenance (
    maintenance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    maintenance_type VARCHAR(30) NOT NULL,
    description TEXT,
    service_date DATE NOT NULL,
    cost NUMERIC(12,2),
    next_due_date DATE,
    recorded_by UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_vehicle_maintenance_vehicle
        FOREIGN KEY (vehicle_id, agency_id)
        REFERENCES vehicle(vehicle_id, agency_id),
    CONSTRAINT fk_vehicle_maintenance_recorder
        FOREIGN KEY (recorded_by, agency_id)
        REFERENCES agency_manager(user_id, agency_id),
    CONSTRAINT ck_vehicle_maintenance_type CHECK (maintenance_type IN (
        'SERVICE', 'REPAIR', 'TYRE', 'INSURANCE', 'REVENUE_LICENCE', 'OTHER'
    )),
    CONSTRAINT ck_vehicle_maintenance_cost CHECK (cost IS NULL OR cost >= 0),
    CONSTRAINT ck_vehicle_maintenance_due CHECK (
        next_due_date IS NULL OR next_due_date >= service_date
    )
);

CREATE INDEX idx_driver_agency ON driver(agency_id);
CREATE INDEX idx_driver_active ON driver(agency_id, is_active);
CREATE INDEX idx_vehicle_agency ON vehicle(agency_id);
CREATE INDEX idx_vehicle_available ON vehicle(agency_id, operational_status)
    WHERE is_active = TRUE;
CREATE INDEX idx_vehicle_maintenance_vehicle
    ON vehicle_maintenance(vehicle_id, service_date DESC);
CREATE INDEX idx_vehicle_maintenance_due
    ON vehicle_maintenance(next_due_date) WHERE next_due_date IS NOT NULL;

-- ============================================================================
-- V3_2: DISPATCH SCHEDULE AND ALLOCATION
-- Schedule references the precise handover and warehouse. Each allocation
-- references an order from the same report as the schedule's handover.
-- ============================================================================
CREATE TABLE dispatch_schedule (
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handover_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    report_id UUID NOT NULL,
    scheduled_date DATE NOT NULL,
    pickup_scheduled_at TIMESTAMPTZ,
    created_by UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    loading_bay VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_dispatch_schedule_handover
        FOREIGN KEY (handover_id, warehouse_id, report_id)
        REFERENCES warehouse_handover(handover_id, warehouse_id, report_id),
    CONSTRAINT fk_dispatch_schedule_creator
        FOREIGN KEY (created_by, warehouse_id)
        REFERENCES warehouse_admin(user_id, warehouse_id),
    CONSTRAINT ck_dispatch_schedule_status CHECK (status IN (
        'DRAFT', 'PUBLISHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
    )),
    CONSTRAINT uq_dispatch_schedule_report_warehouse
        UNIQUE (schedule_id, report_id, warehouse_id)
);

CREATE TABLE dispatch_allocation (
    dispatch_allocation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID NOT NULL,
    report_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    order_id UUID NOT NULL UNIQUE,
    supervisor_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_dispatch_allocation_schedule
        FOREIGN KEY (schedule_id, report_id, warehouse_id)
        REFERENCES dispatch_schedule(schedule_id, report_id, warehouse_id),
    CONSTRAINT fk_dispatch_allocation_order
        FOREIGN KEY (order_id, report_id, agency_id)
        REFERENCES agency_order(order_id, report_id, agency_id),
    CONSTRAINT fk_dispatch_allocation_supervisor
        FOREIGN KEY (supervisor_id, warehouse_id)
        REFERENCES warehouse_supervisor(user_id, warehouse_id),
    CONSTRAINT ck_dispatch_allocation_status CHECK (status IN (
        'PENDING', 'ACCEPTED', 'REJECTED', 'READY_FOR_PICKUP',
        'PICKED_UP', 'DELIVERED', 'CANCELLED'
    )),
    CONSTRAINT uq_dispatch_allocation_id_order
        UNIQUE (dispatch_allocation_id, order_id),
    CONSTRAINT uq_dispatch_allocation_id_agency
        UNIQUE (dispatch_allocation_id, agency_id),
    CONSTRAINT uq_dispatch_allocation_id_agency_warehouse
        UNIQUE (dispatch_allocation_id, agency_id, warehouse_id)
);

CREATE TABLE dispatch_allocation_item (
    allocation_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispatch_allocation_id UUID NOT NULL,
    order_id UUID NOT NULL,
    order_item_id UUID NOT NULL,
    allocated_qty INTEGER NOT NULL,
    loaded_qty INTEGER,
    received_qty INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_dispatch_allocation_item_qty CHECK (
        allocated_qty > 0
        AND (loaded_qty IS NULL OR (loaded_qty >= 0 AND loaded_qty <= allocated_qty))
        AND (received_qty IS NULL OR (
            loaded_qty IS NOT NULL AND received_qty >= 0 AND received_qty <= loaded_qty
        ))
    ),
    CONSTRAINT fk_dispatch_allocation_item_parent
        FOREIGN KEY (dispatch_allocation_id, order_id)
        REFERENCES dispatch_allocation(dispatch_allocation_id, order_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_dispatch_allocation_item_order_item
        FOREIGN KEY (order_item_id, order_id)
        REFERENCES agency_order_item(order_item_id, order_id),
    CONSTRAINT uq_dispatch_allocation_item_line
        UNIQUE (dispatch_allocation_id, order_item_id),
    CONSTRAINT uq_dispatch_allocation_item_parent_reference
        UNIQUE (allocation_item_id, dispatch_allocation_id)
);

CREATE INDEX idx_dispatch_schedule_warehouse_date
    ON dispatch_schedule(warehouse_id, scheduled_date);
CREATE INDEX idx_dispatch_schedule_status ON dispatch_schedule(status);
CREATE INDEX idx_dispatch_allocation_agency ON dispatch_allocation(agency_id);
CREATE INDEX idx_dispatch_allocation_supervisor ON dispatch_allocation(supervisor_id);
CREATE INDEX idx_dispatch_allocation_item_order_item
    ON dispatch_allocation_item(order_item_id);

-- ============================================================================
-- V3_3: DISPATCH REVIEW
-- agency_id is included so the reviewer must belong to the order's agency.
-- ============================================================================
CREATE TABLE dispatch_review (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispatch_allocation_id UUID NOT NULL UNIQUE,
    agency_id UUID NOT NULL,
    reviewed_by UUID NOT NULL,
    outcome VARCHAR(20) NOT NULL,
    comments TEXT,
    reviewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_dispatch_review_allocation
        FOREIGN KEY (dispatch_allocation_id, agency_id)
        REFERENCES dispatch_allocation(dispatch_allocation_id, agency_id),
    CONSTRAINT fk_dispatch_review_reviewer
        FOREIGN KEY (reviewed_by, agency_id)
        REFERENCES agency_manager(user_id, agency_id),
    CONSTRAINT ck_dispatch_review_outcome CHECK (outcome IN (
        'ACCEPTED', 'REJECTED', 'CHANGE_REQUESTED'
    )),
    CONSTRAINT ck_dispatch_review_comment CHECK (
        outcome = 'ACCEPTED' OR NULLIF(TRIM(comments), '') IS NOT NULL
    )
);

CREATE INDEX idx_dispatch_review_reviewer ON dispatch_review(reviewed_by);

-- ============================================================================
-- V3_4: SHIPMENT TRIP, DOCUMENT, PICKUP CONFIRMATION
-- ============================================================================
CREATE TABLE shipment_trip (
    shipment_trip_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispatch_allocation_id UUID NOT NULL UNIQUE,
    agency_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    vehicle_id UUID NOT NULL,
    driver_id UUID NOT NULL,
    scheduled_by UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    expected_pickup_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    arrived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_shipment_trip_allocation
        FOREIGN KEY (dispatch_allocation_id, agency_id, warehouse_id)
        REFERENCES dispatch_allocation(
            dispatch_allocation_id, agency_id, warehouse_id
        ),
    CONSTRAINT fk_shipment_trip_vehicle
        FOREIGN KEY (vehicle_id, agency_id)
        REFERENCES vehicle(vehicle_id, agency_id),
    CONSTRAINT fk_shipment_trip_driver
        FOREIGN KEY (driver_id, agency_id)
        REFERENCES driver(driver_id, agency_id),
    CONSTRAINT fk_shipment_trip_scheduler
        FOREIGN KEY (scheduled_by, agency_id)
        REFERENCES agency_manager(user_id, agency_id),
    CONSTRAINT ck_shipment_trip_status CHECK (status IN (
        'SCHEDULED', 'AT_WAREHOUSE', 'LOADED', 'IN_TRANSIT', 'ARRIVED', 'CANCELLED'
    )),
    CONSTRAINT ck_shipment_trip_times CHECK (
        arrived_at IS NULL OR (picked_up_at IS NOT NULL AND arrived_at >= picked_up_at)
    ),
    CONSTRAINT uq_shipment_trip_id_allocation
        UNIQUE (shipment_trip_id, dispatch_allocation_id),
    CONSTRAINT uq_shipment_trip_id_warehouse
        UNIQUE (shipment_trip_id, warehouse_id)
);

CREATE TABLE shipment_document (
    document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_trip_id UUID NOT NULL
        REFERENCES shipment_trip(shipment_trip_id) ON DELETE CASCADE,
    document_type VARCHAR(20) NOT NULL,
    document_number VARCHAR(50),
    barcode VARCHAR(100) UNIQUE,
    file_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_shipment_document_type CHECK (document_type IN (
        'DELIVERY_NOTE', 'INVOICE', 'GATE_PASS', 'OTHER'
    ))
);

CREATE TABLE pickup_confirmation (
    pickup_confirmation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_trip_id UUID NOT NULL UNIQUE,
    warehouse_id UUID NOT NULL,
    confirmed_by UUID NOT NULL,
    confirmed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    signature_url TEXT,
    remarks TEXT,
    CONSTRAINT fk_pickup_confirmation_trip
        FOREIGN KEY (shipment_trip_id, warehouse_id)
        REFERENCES shipment_trip(shipment_trip_id, warehouse_id),
    CONSTRAINT fk_pickup_confirmation_supervisor
        FOREIGN KEY (confirmed_by, warehouse_id)
        REFERENCES warehouse_supervisor(user_id, warehouse_id),
    CONSTRAINT ck_pickup_confirmation_signature CHECK (
        signature_url IS NULL OR LENGTH(TRIM(signature_url)) > 0
    )
);

CREATE INDEX idx_shipment_trip_vehicle ON shipment_trip(vehicle_id);
CREATE INDEX idx_shipment_trip_driver ON shipment_trip(driver_id);
CREATE INDEX idx_shipment_trip_status ON shipment_trip(status);
CREATE INDEX idx_shipment_document_trip ON shipment_document(shipment_trip_id);

-- ============================================================================
-- V3_5: DISPATCH DISCREPANCY
-- Allocation and item references are constrained to the same shipment.
-- ============================================================================
CREATE TABLE dispatch_discrepancy (
    discrepancy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_trip_id UUID NOT NULL,
    dispatch_allocation_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    allocation_item_id UUID,
    reported_by UUID NOT NULL REFERENCES app_user(user_id),
    confirmed_by UUID NOT NULL,
    issue_type VARCHAR(20) NOT NULL,
    quantity_affected INTEGER,
    description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    resolved_by UUID,
    resolution_note TEXT,
    reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    CONSTRAINT fk_discrepancy_shipment_allocation
        FOREIGN KEY (shipment_trip_id, dispatch_allocation_id)
        REFERENCES shipment_trip(shipment_trip_id, dispatch_allocation_id),
    CONSTRAINT fk_discrepancy_warehouse
        FOREIGN KEY (shipment_trip_id, warehouse_id)
        REFERENCES shipment_trip(shipment_trip_id, warehouse_id),
    CONSTRAINT fk_discrepancy_confirming_supervisor
        FOREIGN KEY (confirmed_by, warehouse_id)
        REFERENCES warehouse_supervisor(user_id, warehouse_id),
    CONSTRAINT fk_discrepancy_resolver
        FOREIGN KEY (resolved_by, warehouse_id)
        REFERENCES warehouse_admin(user_id, warehouse_id),
    CONSTRAINT fk_discrepancy_allocation_item
        FOREIGN KEY (allocation_item_id, dispatch_allocation_id)
        REFERENCES dispatch_allocation_item(allocation_item_id, dispatch_allocation_id),
    CONSTRAINT ck_dispatch_discrepancy_type CHECK (issue_type IN (
        'SHORTAGE', 'EXCESS', 'DAMAGED', 'WRONG_ITEM', 'OTHER'
    )),
    CONSTRAINT ck_dispatch_discrepancy_quantity CHECK (
        quantity_affected IS NULL OR quantity_affected > 0
    ),
    CONSTRAINT ck_dispatch_discrepancy_status CHECK (status IN (
        'OPEN', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED'
    )),
    CONSTRAINT ck_dispatch_discrepancy_resolved CHECK (
        status NOT IN ('RESOLVED', 'REJECTED')
        OR (resolved_by IS NOT NULL AND resolved_at IS NOT NULL)
    )
);

CREATE INDEX idx_dispatch_discrepancy_shipment
    ON dispatch_discrepancy(shipment_trip_id);
CREATE INDEX idx_dispatch_discrepancy_item
    ON dispatch_discrepancy(allocation_item_id);
CREATE INDEX idx_dispatch_discrepancy_status
    ON dispatch_discrepancy(status);

-- ============================================================================
-- V3_6: DELIVERY TRIP AND TRIP STOP
-- agency_id is repeated in trip_stop and retail_outlet to enforce that each
-- stop belongs to an outlet of the delivery trip's agency.
-- ============================================================================
CREATE TABLE delivery_trip (
    trip_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    agent_id UUID NOT NULL,
    driver_id UUID,
    vehicle_id UUID NOT NULL,
    scheduled_by UUID NOT NULL,
    trip_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PLANNED',
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_delivery_trip_agent
        FOREIGN KEY (agent_id, agency_id)
        REFERENCES agent(user_id, agency_id),
    CONSTRAINT fk_delivery_trip_driver
        FOREIGN KEY (driver_id, agency_id)
        REFERENCES driver(driver_id, agency_id),
    CONSTRAINT fk_delivery_trip_vehicle
        FOREIGN KEY (vehicle_id, agency_id)
        REFERENCES vehicle(vehicle_id, agency_id),
    CONSTRAINT fk_delivery_trip_scheduler
        FOREIGN KEY (scheduled_by, agency_id)
        REFERENCES agency_manager(user_id, agency_id),
    CONSTRAINT ck_delivery_trip_status CHECK (status IN (
        'PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
    )),
    CONSTRAINT ck_delivery_trip_times CHECK (
        ended_at IS NULL OR (started_at IS NOT NULL AND ended_at >= started_at)
    ),
    CONSTRAINT ck_delivery_trip_started_status CHECK (
        status NOT IN ('IN_PROGRESS', 'COMPLETED') OR started_at IS NOT NULL
    ),
    CONSTRAINT ck_delivery_trip_completed_status CHECK (
        status <> 'COMPLETED' OR ended_at IS NOT NULL
    ),
    CONSTRAINT uq_delivery_trip_id_agency UNIQUE (trip_id, agency_id),
    CONSTRAINT uq_delivery_trip_agent_agency UNIQUE (trip_id, agent_id, agency_id)
);

CREATE TABLE trip_stop (
    trip_stop_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    outlet_id UUID NOT NULL,
    stop_sequence INTEGER NOT NULL,
    planned_arrival_at TIMESTAMPTZ,
    actual_arrival_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_trip_stop_trip_agency
        FOREIGN KEY (trip_id, agency_id)
        REFERENCES delivery_trip(trip_id, agency_id) ON DELETE CASCADE,
    CONSTRAINT fk_trip_stop_outlet_agency
        FOREIGN KEY (outlet_id, agency_id)
        REFERENCES retail_outlet(outlet_id, agency_id),
    CONSTRAINT ck_trip_stop_sequence CHECK (stop_sequence > 0),
    CONSTRAINT ck_trip_stop_status CHECK (status IN (
        'PENDING', 'ARRIVED', 'COMPLETED', 'SKIPPED', 'FAILED'
    )),
    CONSTRAINT ck_trip_stop_failure CHECK (
        status NOT IN ('FAILED', 'SKIPPED')
        OR NULLIF(TRIM(failure_reason), '') IS NOT NULL
    ),
    CONSTRAINT ck_trip_stop_arrived CHECK (
        status NOT IN ('ARRIVED', 'COMPLETED') OR actual_arrival_at IS NOT NULL
    ),
    CONSTRAINT ck_trip_stop_completed CHECK (
        status <> 'COMPLETED' OR completed_at IS NOT NULL
    ),
    CONSTRAINT ck_trip_stop_completion_time CHECK (
        completed_at IS NULL OR actual_arrival_at IS NULL
        OR completed_at >= actual_arrival_at
    ),
    CONSTRAINT uq_trip_stop_sequence UNIQUE (trip_id, stop_sequence),
    CONSTRAINT uq_trip_stop_outlet UNIQUE (trip_id, outlet_id),
    -- These keys are intentionally provided for V4/V5 composite FKs.
    CONSTRAINT uq_trip_stop_id_outlet UNIQUE (trip_stop_id, outlet_id),
    CONSTRAINT uq_trip_stop_id_trip UNIQUE (trip_stop_id, trip_id),
    CONSTRAINT uq_trip_stop_id_trip_outlet UNIQUE (trip_stop_id, trip_id, outlet_id),
    CONSTRAINT uq_trip_stop_id_trip_outlet_agency
        UNIQUE (trip_stop_id, trip_id, outlet_id, agency_id),
    CONSTRAINT uq_trip_stop_id_outlet_agency
        UNIQUE (trip_stop_id, outlet_id, agency_id),
    CONSTRAINT uq_trip_stop_id_trip_agency
        UNIQUE (trip_stop_id, trip_id, agency_id)
);

CREATE INDEX idx_delivery_trip_agency ON delivery_trip(agency_id);
CREATE INDEX idx_delivery_trip_agent ON delivery_trip(agent_id);
CREATE INDEX idx_delivery_trip_vehicle ON delivery_trip(vehicle_id);
CREATE INDEX idx_delivery_trip_driver ON delivery_trip(driver_id);
CREATE INDEX idx_delivery_trip_date_status ON delivery_trip(trip_date, status);
CREATE INDEX idx_trip_stop_trip ON trip_stop(trip_id);
CREATE INDEX idx_trip_stop_outlet ON trip_stop(outlet_id);
CREATE INDEX idx_trip_stop_status ON trip_stop(status);

-- ============================================================================
-- V4_1: AGENCY INVENTORY AND STOCK MOVEMENTS
-- ============================================================================
CREATE TABLE agency_inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    product_id UUID NOT NULL REFERENCES product(product_id),
    quantity_on_hand INTEGER NOT NULL DEFAULT 0,
    quantity_reserved INTEGER NOT NULL DEFAULT 0,
    reorder_level INTEGER NOT NULL DEFAULT 0,
    updated_by UUID REFERENCES app_user(user_id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_agency_inventory_qty CHECK (
        quantity_on_hand >= 0
        AND quantity_reserved >= 0
        AND quantity_reserved <= quantity_on_hand
        AND reorder_level >= 0
    ),
    CONSTRAINT uq_agency_inventory_agency_product UNIQUE (agency_id, product_id)
);

CREATE TABLE agency_stock_movement (
    movement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL,
    product_id UUID NOT NULL,
    movement_type VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL,
    reference_type VARCHAR(30),
    reference_id UUID,
    performed_by UUID NOT NULL REFERENCES app_user(user_id),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_agency_stock_movement_inventory
        FOREIGN KEY (agency_id, product_id)
        REFERENCES agency_inventory(agency_id, product_id),
    CONSTRAINT ck_agency_stock_movement_type CHECK (movement_type IN (
        'RECEIVED', 'DELIVERED', 'RETURNED', 'DAMAGED',
        'RESERVED', 'RELEASED', 'ADJUSTMENT'
    )),
    CONSTRAINT ck_agency_stock_movement_quantity CHECK (quantity > 0),
    CONSTRAINT ck_agency_stock_movement_ref CHECK (
        (reference_type IS NULL) = (reference_id IS NULL)
    )
);

CREATE INDEX idx_agency_inventory_product ON agency_inventory(product_id);
CREATE INDEX idx_agency_stock_movement_inventory
    ON agency_stock_movement(agency_id, product_id);
CREATE INDEX idx_agency_stock_movement_created
    ON agency_stock_movement(created_at DESC);
CREATE INDEX idx_agency_stock_movement_reference
    ON agency_stock_movement(reference_type, reference_id)
    WHERE reference_id IS NOT NULL;

-- ============================================================================
-- V4_2: WAREHOUSE REPORT
-- generated_by must belong to the same warehouse.
-- ============================================================================
CREATE TABLE warehouse_report (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID NOT NULL REFERENCES warehouse(warehouse_id),
    generated_by UUID NOT NULL,
    report_type VARCHAR(30) NOT NULL,
    title VARCHAR(200) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    file_url TEXT,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_warehouse_report_generator
        FOREIGN KEY (generated_by, warehouse_id)
        REFERENCES warehouse_admin(user_id, warehouse_id),
    CONSTRAINT ck_warehouse_report_type CHECK (report_type IN (
        'DAILY_DISPATCH', 'DISCREPANCY', 'STOCK_SUMMARY', 'MONTHLY'
    )),
    CONSTRAINT ck_warehouse_report_period CHECK (period_end >= period_start)
);

CREATE INDEX idx_warehouse_report_warehouse ON warehouse_report(warehouse_id);
CREATE INDEX idx_warehouse_report_type ON warehouse_report(report_type);
CREATE INDEX idx_warehouse_report_generated ON warehouse_report(generated_at DESC);

-- ============================================================================
-- V4_3: NEXT ORDER
-- Agency and outlet must match; recording agent must belong to that agency.
-- ============================================================================
CREATE TABLE next_order (
    next_order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outlet_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    recorded_by UUID NOT NULL,
    requested_delivery_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_next_order_outlet_agency
        FOREIGN KEY (outlet_id, agency_id)
        REFERENCES retail_outlet(outlet_id, agency_id),
    CONSTRAINT fk_next_order_agent
        FOREIGN KEY (recorded_by, agency_id)
        REFERENCES agent(user_id, agency_id),
    CONSTRAINT ck_next_order_status CHECK (status IN (
        'PENDING', 'APPROVED', 'ALLOCATED', 'DELIVERED', 'CANCELLED'
    )),
    CONSTRAINT uq_next_order_id_outlet UNIQUE (next_order_id, outlet_id),
    CONSTRAINT uq_next_order_id_outlet UNIQUE (next_order_id, outlet_id),
    CONSTRAINT uq_next_order_id_outlet_agency
        UNIQUE (next_order_id, outlet_id, agency_id)
);

CREATE TABLE next_order_item (
    next_order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    next_order_id UUID NOT NULL
        REFERENCES next_order(next_order_id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES product(product_id),
    requested_qty INTEGER NOT NULL,
    CONSTRAINT ck_next_order_item_qty CHECK (requested_qty > 0),
    CONSTRAINT uq_next_order_item_product UNIQUE (next_order_id, product_id)
);

CREATE INDEX idx_next_order_outlet ON next_order(outlet_id);
CREATE INDEX idx_next_order_agency ON next_order(agency_id);
CREATE INDEX idx_next_order_status ON next_order(status);
CREATE INDEX idx_next_order_delivery_date ON next_order(requested_delivery_date);
CREATE INDEX idx_next_order_item_product ON next_order_item(product_id);

-- ============================================================================
-- V4_4: OUTLET RETURNS
-- A collection stop must be for the same outlet and agency as the return.
-- ============================================================================
CREATE TABLE outlet_return (
    return_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outlet_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    recorded_by UUID NOT NULL,
    collected_stop_id UUID,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    collected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_outlet_return_outlet
        FOREIGN KEY (outlet_id, agency_id)
        REFERENCES retail_outlet(outlet_id, agency_id),
    CONSTRAINT fk_outlet_return_agent
        FOREIGN KEY (recorded_by, agency_id)
        REFERENCES agent(user_id, agency_id),
    CONSTRAINT fk_outlet_return_trip_stop
        FOREIGN KEY (collected_stop_id, outlet_id, agency_id)
        REFERENCES trip_stop(trip_stop_id, outlet_id, agency_id),
    CONSTRAINT ck_outlet_return_status CHECK (status IN (
        'REQUESTED', 'COLLECTED', 'ACCEPTED', 'REJECTED'
    )),
    CONSTRAINT ck_outlet_return_collection CHECK (
        (status = 'REQUESTED' AND collected_stop_id IS NULL AND collected_at IS NULL)
        OR (status <> 'REQUESTED' AND collected_stop_id IS NOT NULL AND collected_at IS NOT NULL)
    )
);

CREATE TABLE outlet_return_item (
    return_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    return_id UUID NOT NULL REFERENCES outlet_return(return_id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES product(product_id),
    quantity INTEGER NOT NULL,
    item_condition VARCHAR(20) NOT NULL,
    CONSTRAINT ck_outlet_return_item_quantity CHECK (quantity > 0),
    CONSTRAINT ck_outlet_return_item_condition CHECK (item_condition IN (
        'EXPIRED', 'DAMAGED', 'WRONG_ITEM', 'OTHER'
    )),
    CONSTRAINT uq_outlet_return_item_line UNIQUE (return_id, product_id, item_condition)
);

CREATE INDEX idx_outlet_return_outlet ON outlet_return(outlet_id);
CREATE INDEX idx_outlet_return_agent ON outlet_return(recorded_by);
CREATE INDEX idx_outlet_return_status ON outlet_return(status);
CREATE INDEX idx_outlet_return_item_product ON outlet_return_item(product_id);

-- ============================================================================
-- V4_5: COMPLAINT AND AGENCY FEEDBACK
-- Complaint context is checked against the same agency/outlet/trip/stop.
-- ============================================================================
CREATE TABLE complaint (
    complaint_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    outlet_id UUID,
    trip_id UUID,
    trip_stop_id UUID,
    raised_by UUID NOT NULL REFERENCES app_user(user_id),
    complaint_type VARCHAR(30) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    resolution_note TEXT,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_complaint_outlet_agency
        FOREIGN KEY (outlet_id, agency_id)
        REFERENCES retail_outlet(outlet_id, agency_id),
    CONSTRAINT fk_complaint_trip_agency
        FOREIGN KEY (trip_id, agency_id)
        REFERENCES delivery_trip(trip_id, agency_id),
    CONSTRAINT fk_complaint_trip_stop
        FOREIGN KEY (trip_stop_id, trip_id, outlet_id, agency_id)
        REFERENCES trip_stop(trip_stop_id, trip_id, outlet_id, agency_id),
    CONSTRAINT ck_complaint_type CHECK (complaint_type IN (
        'LATE_DELIVERY', 'SHORT_DELIVERY', 'DAMAGED_GOODS',
        'WRONG_ITEM', 'STAFF_BEHAVIOUR', 'OTHER'
    )),
    CONSTRAINT ck_complaint_status CHECK (status IN (
        'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'
    )),
    CONSTRAINT ck_complaint_stop_context CHECK (
        trip_stop_id IS NULL OR (trip_id IS NOT NULL AND outlet_id IS NOT NULL)
    ),
    CONSTRAINT ck_complaint_resolved CHECK (
        status NOT IN ('RESOLVED', 'CLOSED') OR resolved_at IS NOT NULL
    )
);

CREATE TABLE agency_feedback (
    feedback_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES agency(agency_id),
    submitted_by UUID NOT NULL,
    rating SMALLINT,
    feedback_text TEXT NOT NULL,
    admin_response TEXT,
    responded_by UUID REFERENCES manufacturing_admin(user_id),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    CONSTRAINT fk_agency_feedback_submitter
        FOREIGN KEY (submitted_by, agency_id)
        REFERENCES agency_manager(user_id, agency_id),
    CONSTRAINT ck_agency_feedback_rating CHECK (
        rating IS NULL OR rating BETWEEN 1 AND 5
    ),
    CONSTRAINT ck_agency_feedback_status CHECK (
        status IN ('PENDING', 'REVIEWED', 'RESPONDED')
    ),
    CONSTRAINT ck_agency_feedback_response_pair CHECK (
        (responded_by IS NULL) = (responded_at IS NULL)
    ),
    CONSTRAINT ck_agency_feedback_responded CHECK (
        status <> 'RESPONDED'
        OR (NULLIF(TRIM(admin_response), '') IS NOT NULL
            AND responded_by IS NOT NULL AND responded_at IS NOT NULL)
    )
);

CREATE INDEX idx_complaint_agency ON complaint(agency_id);
CREATE INDEX idx_complaint_outlet ON complaint(outlet_id);
CREATE INDEX idx_complaint_trip ON complaint(trip_id);
CREATE INDEX idx_complaint_status ON complaint(status);
CREATE INDEX idx_complaint_created ON complaint(created_at DESC);
CREATE INDEX idx_agency_feedback_agency ON agency_feedback(agency_id);
CREATE INDEX idx_agency_feedback_status ON agency_feedback(status);
CREATE INDEX idx_agency_feedback_created ON agency_feedback(created_at DESC);

-- ============================================================================
-- V5_1: AGENT AREA ASSIGNMENT AND DAY SHIFT
-- ============================================================================
CREATE TABLE agent_area_assignment (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    area_id UUID NOT NULL,
    assigned_by UUID NOT NULL,
    assigned_from DATE NOT NULL DEFAULT CURRENT_DATE,
    assigned_to DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_agent_area_assignment_agent
        FOREIGN KEY (agent_id, agency_id)
        REFERENCES agent(user_id, agency_id),
    CONSTRAINT fk_agent_area_assignment_area
        FOREIGN KEY (area_id, agency_id)
        REFERENCES operational_area(area_id, agency_id),
    CONSTRAINT fk_agent_area_assignment_manager
        FOREIGN KEY (assigned_by, agency_id)
        REFERENCES agency_manager(user_id, agency_id),
    CONSTRAINT ck_agent_area_assignment_dates CHECK (
        assigned_to IS NULL OR assigned_to >= assigned_from
    )
);

-- At most one current area assignment per agent.
CREATE UNIQUE INDEX uq_agent_area_assignment_active
    ON agent_area_assignment(agent_id) WHERE assigned_to IS NULL;
CREATE INDEX idx_agent_area_assignment_area
    ON agent_area_assignment(area_id, assigned_from DESC);

CREATE TABLE agent_day_shift (
    shift_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    shift_date DATE NOT NULL,
    shift_status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    check_in_at TIMESTAMPTZ,
    check_in_latitude NUMERIC(9,6),
    check_in_longitude NUMERIC(9,6),
    check_out_at TIMESTAMPTZ,
    check_out_latitude NUMERIC(9,6),
    check_out_longitude NUMERIC(9,6),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_agent_day_shift_agent
        FOREIGN KEY (agent_id, agency_id)
        REFERENCES agent(user_id, agency_id),
    CONSTRAINT ck_agent_day_shift_status CHECK (shift_status IN (
        'SCHEDULED', 'ACTIVE', 'COMPLETED', 'ABSENT', 'CANCELLED'
    )),
    CONSTRAINT ck_agent_day_shift_checkin_coords CHECK (
        (check_in_latitude IS NULL) = (check_in_longitude IS NULL)
        AND (check_in_latitude IS NULL OR check_in_latitude BETWEEN -90 AND 90)
        AND (check_in_longitude IS NULL OR check_in_longitude BETWEEN -180 AND 180)
    ),
    CONSTRAINT ck_agent_day_shift_checkout_coords CHECK (
        (check_out_latitude IS NULL) = (check_out_longitude IS NULL)
        AND (check_out_latitude IS NULL OR check_out_latitude BETWEEN -90 AND 90)
        AND (check_out_longitude IS NULL OR check_out_longitude BETWEEN -180 AND 180)
    ),
    CONSTRAINT ck_agent_day_shift_times CHECK (
        check_out_at IS NULL OR (check_in_at IS NOT NULL AND check_out_at >= check_in_at)
    ),
    CONSTRAINT ck_agent_day_shift_active CHECK (
        shift_status <> 'ACTIVE' OR check_in_at IS NOT NULL
    ),
    CONSTRAINT ck_agent_day_shift_completed CHECK (
        shift_status <> 'COMPLETED' OR check_out_at IS NOT NULL
    ),
    CONSTRAINT uq_agent_day_shift_agent_date UNIQUE (agent_id, shift_date)
);

CREATE INDEX idx_agent_day_shift_agency_date
    ON agent_day_shift(agency_id, shift_date);
CREATE INDEX idx_agent_day_shift_status
    ON agent_day_shift(shift_status);

-- ============================================================================
-- V5_2: OUTLET ALLOCATION AND ALLOCATION ITEMS
-- Allocation links an optional next order to a matching outlet and optionally
-- to the trip stop that will fulfil it. Allocation items can also be created
-- without a next order, so their product lines are linked to the allocation.
-- ============================================================================
CREATE TABLE outlet_allocation (
    allocation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outlet_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    next_order_id UUID,
    trip_stop_id UUID,
    created_by UUID NOT NULL,
    status VARCHAR(25) NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_outlet_allocation_outlet
        FOREIGN KEY (outlet_id, agency_id)
        REFERENCES retail_outlet(outlet_id, agency_id),
    CONSTRAINT fk_outlet_allocation_order
        FOREIGN KEY (next_order_id, outlet_id, agency_id)
        REFERENCES next_order(next_order_id, outlet_id, agency_id),
    CONSTRAINT fk_outlet_allocation_trip_stop
        FOREIGN KEY (trip_stop_id, outlet_id, agency_id)
        REFERENCES trip_stop(trip_stop_id, outlet_id, agency_id),
    CONSTRAINT fk_outlet_allocation_manager
        FOREIGN KEY (created_by, agency_id)
        REFERENCES agency_manager(user_id, agency_id),
    CONSTRAINT ck_outlet_allocation_status CHECK (status IN (
        'DRAFT', 'CONFIRMED', 'LOADED', 'DELIVERED',
        'PARTIALLY_DELIVERED', 'FAILED', 'CANCELLED'
    )),
    CONSTRAINT ck_outlet_allocation_stop_required CHECK (
        status IN ('DRAFT', 'CONFIRMED', 'CANCELLED') OR trip_stop_id IS NOT NULL
    ),
    CONSTRAINT uq_outlet_allocation_trip_stop UNIQUE (trip_stop_id),
    CONSTRAINT uq_outlet_allocation_id_trip_stop
        UNIQUE (allocation_id, trip_stop_id)
);

CREATE TABLE outlet_allocation_item (
    allocation_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    allocation_id UUID NOT NULL
        REFERENCES outlet_allocation(allocation_id) ON DELETE CASCADE,
    trip_stop_id UUID,
    product_id UUID NOT NULL REFERENCES product(product_id),
    allocated_qty INTEGER NOT NULL,
    delivered_qty INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- If an allocation is assigned to a trip stop, each of its item rows
    -- carries that same stop so POD item FKs can verify the relationship.
    CONSTRAINT fk_outlet_allocation_item_trip_stop
        FOREIGN KEY (allocation_id, trip_stop_id)
        REFERENCES outlet_allocation(allocation_id, trip_stop_id),
    CONSTRAINT ck_outlet_allocation_item_qty CHECK (
        allocated_qty > 0 AND delivered_qty >= 0 AND delivered_qty <= allocated_qty
    ),
    CONSTRAINT uq_outlet_allocation_item_product
        UNIQUE (allocation_id, product_id),
    CONSTRAINT uq_outlet_allocation_item_stop_reference
        UNIQUE (allocation_item_id, trip_stop_id)
);

CREATE INDEX idx_outlet_allocation_outlet ON outlet_allocation(outlet_id);
CREATE INDEX idx_outlet_allocation_agency_status
    ON outlet_allocation(agency_id, status);
CREATE INDEX idx_outlet_allocation_item_product
    ON outlet_allocation_item(product_id);

-- ============================================================================
-- V5_3: PROOF OF DELIVERY
-- One POD per trip stop; POD item lines must refer to allocation items for
-- exactly that same trip stop.
-- ============================================================================
CREATE TABLE proof_of_delivery (
    proof_of_delivery_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_stop_id UUID NOT NULL UNIQUE,
    trip_id UUID NOT NULL,
    outlet_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    captured_by UUID NOT NULL,
    receiver_name VARCHAR(150),
    signature_url TEXT,
    photo_url TEXT,
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    delivery_status VARCHAR(25) NOT NULL,
    delivered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_pod_trip_stop
        FOREIGN KEY (trip_stop_id, trip_id, outlet_id, agency_id)
        REFERENCES trip_stop(trip_stop_id, trip_id, outlet_id, agency_id),
    CONSTRAINT fk_pod_agent
        FOREIGN KEY (captured_by, agency_id)
        REFERENCES agent(user_id, agency_id),
    CONSTRAINT ck_pod_status CHECK (delivery_status IN (
        'DELIVERED', 'PARTIALLY_DELIVERED', 'REJECTED'
    )),
    CONSTRAINT ck_pod_latlng_pair CHECK (
        (latitude IS NULL) = (longitude IS NULL)
    ),
    CONSTRAINT ck_pod_latitude CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT ck_pod_longitude CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CONSTRAINT uq_pod_id_trip_stop UNIQUE (proof_of_delivery_id, trip_stop_id)
);

CREATE TABLE proof_of_delivery_item (
    pod_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proof_of_delivery_id UUID NOT NULL,
    trip_stop_id UUID NOT NULL,
    allocation_item_id UUID NOT NULL,
    delivered_qty INTEGER NOT NULL,
    CONSTRAINT fk_pod_item_pod
        FOREIGN KEY (proof_of_delivery_id, trip_stop_id)
        REFERENCES proof_of_delivery(proof_of_delivery_id, trip_stop_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_pod_item_allocation_item
        FOREIGN KEY (allocation_item_id, trip_stop_id)
        REFERENCES outlet_allocation_item(allocation_item_id, trip_stop_id),
    CONSTRAINT ck_pod_item_delivered_qty CHECK (delivered_qty >= 0),
    CONSTRAINT uq_pod_item_line UNIQUE (proof_of_delivery_id, allocation_item_id)
);

CREATE INDEX idx_pod_trip ON proof_of_delivery(trip_id);
CREATE INDEX idx_pod_outlet ON proof_of_delivery(outlet_id);
CREATE INDEX idx_pod_captured_by ON proof_of_delivery(captured_by);

-- ============================================================================
-- V5_4: DELIVERY ISSUE AND TRIP REPORT
-- ============================================================================
CREATE TABLE delivery_issue (
    issue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    trip_stop_id UUID,
    reported_by UUID NOT NULL,
    issue_type VARCHAR(30) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_delivery_issue_trip
        FOREIGN KEY (trip_id, agency_id)
        REFERENCES delivery_trip(trip_id, agency_id),
    CONSTRAINT fk_delivery_issue_stop
        FOREIGN KEY (trip_stop_id, trip_id, agency_id)
        REFERENCES trip_stop(trip_stop_id, trip_id, agency_id),
    CONSTRAINT fk_delivery_issue_agent
        FOREIGN KEY (reported_by, agency_id)
        REFERENCES agent(user_id, agency_id),
    CONSTRAINT fk_delivery_issue_reviewer
        FOREIGN KEY (reviewed_by, agency_id)
        REFERENCES agency_manager(user_id, agency_id),
    CONSTRAINT ck_delivery_issue_type CHECK (issue_type IN (
        'VEHICLE_BREAKDOWN', 'ROAD_BLOCKED', 'OUTLET_CLOSED', 'ACCIDENT',
        'STOCK_SHORTAGE', 'DAMAGED_GOODS', 'DELIVERY_FAILED',
        'RETURN_REQUESTED', 'OTHER'
    )),
    CONSTRAINT ck_delivery_issue_status CHECK (status IN (
        'OPEN', 'REVIEWED', 'RESOLVED'
    )),
    CONSTRAINT ck_delivery_issue_review_pair CHECK (
        (reviewed_by IS NULL) = (reviewed_at IS NULL)
    ),
    CONSTRAINT ck_delivery_issue_reviewed CHECK (
        status = 'OPEN' OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
    ),
    CONSTRAINT ck_delivery_issue_resolved CHECK (
        status <> 'RESOLVED' OR resolved_at IS NOT NULL
    ),
    CONSTRAINT ck_delivery_issue_latlng_pair CHECK (
        (latitude IS NULL) = (longitude IS NULL)
    ),
    CONSTRAINT ck_delivery_issue_latitude CHECK (
        latitude IS NULL OR latitude BETWEEN -90 AND 90
    ),
    CONSTRAINT ck_delivery_issue_longitude CHECK (
        longitude IS NULL OR longitude BETWEEN -180 AND 180
    )
);

CREATE TABLE trip_report (
    trip_report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL UNIQUE,
    agency_id UUID NOT NULL,
    submitted_by UUID NOT NULL,
    summary TEXT,
    report_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED',
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_trip_report_trip
        FOREIGN KEY (trip_id, agency_id)
        REFERENCES delivery_trip(trip_id, agency_id),
    CONSTRAINT fk_trip_report_submitter
        FOREIGN KEY (submitted_by, agency_id)
        REFERENCES agent(user_id, agency_id),
    CONSTRAINT fk_trip_report_reviewer
        FOREIGN KEY (reviewed_by, agency_id)
        REFERENCES agency_manager(user_id, agency_id),
    CONSTRAINT ck_trip_report_content CHECK (
        NULLIF(TRIM(summary), '') IS NOT NULL
        OR NULLIF(TRIM(report_url), '') IS NOT NULL
    ),
    CONSTRAINT ck_trip_report_status CHECK (status IN ('SUBMITTED', 'REVIEWED')),
    CONSTRAINT ck_trip_report_review_pair CHECK (
        (reviewed_by IS NULL) = (reviewed_at IS NULL)
    ),
    CONSTRAINT ck_trip_report_reviewed CHECK (
        status <> 'REVIEWED' OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
    )
);

CREATE INDEX idx_delivery_issue_trip ON delivery_issue(trip_id);
CREATE INDEX idx_delivery_issue_agency_status ON delivery_issue(agency_id, status);

-- ============================================================================
-- V5_5: RETAIL SHOP PROPOSAL
-- New outlet created from an approved proposal must belong to the same area
-- and agency for which the proposal was raised.
-- ============================================================================
CREATE TABLE retail_shop_proposal (
    proposal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL,
    area_id UUID NOT NULL,
    proposed_by UUID NOT NULL,
    shop_name VARCHAR(150) NOT NULL,
    owner_name VARCHAR(150),
    contact_number VARCHAR(20),
    address TEXT NOT NULL,
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    shop_type VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    created_outlet_id UUID UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_shop_proposal_area
        FOREIGN KEY (area_id, agency_id)
        REFERENCES operational_area(area_id, agency_id),
    CONSTRAINT fk_shop_proposal_agent
        FOREIGN KEY (proposed_by, agency_id)
        REFERENCES agent(user_id, agency_id),
    CONSTRAINT fk_shop_proposal_reviewer
        FOREIGN KEY (reviewed_by, agency_id)
        REFERENCES agency_manager(user_id, agency_id),
    CONSTRAINT fk_shop_proposal_created_outlet
        FOREIGN KEY (created_outlet_id, area_id, agency_id)
        REFERENCES retail_outlet(outlet_id, area_id, agency_id),
    CONSTRAINT ck_shop_proposal_type CHECK (shop_type IN (
        'GROCERY', 'SUPERMARKET', 'WHOLESALE', 'RETAIL', 'OTHER'
    )),
    CONSTRAINT ck_shop_proposal_status CHECK (status IN (
        'PENDING', 'APPROVED', 'REJECTED'
    )),
    CONSTRAINT ck_shop_proposal_latlng_pair CHECK (
        (latitude IS NULL) = (longitude IS NULL)
    ),
    CONSTRAINT ck_shop_proposal_latitude CHECK (
        latitude IS NULL OR latitude BETWEEN -90 AND 90
    ),
    CONSTRAINT ck_shop_proposal_longitude CHECK (
        longitude IS NULL OR longitude BETWEEN -180 AND 180
    ),
    CONSTRAINT ck_shop_proposal_review_pair CHECK (
        (reviewed_by IS NULL) = (reviewed_at IS NULL)
    ),
    CONSTRAINT ck_shop_proposal_decision CHECK (
        (status = 'PENDING' AND reviewed_by IS NULL AND created_outlet_id IS NULL)
        OR (status = 'REJECTED' AND reviewed_by IS NOT NULL AND created_outlet_id IS NULL)
        OR (status = 'APPROVED' AND reviewed_by IS NOT NULL AND created_outlet_id IS NOT NULL)
    )
);

CREATE INDEX idx_shop_proposal_agency_status
    ON retail_shop_proposal(agency_id, status);
CREATE INDEX idx_shop_proposal_area ON retail_shop_proposal(area_id);

-- ============================================================================
-- V5_6: LOCATION LOG
-- Optional trip reference must belong to the same agent and agency.
-- ============================================================================
CREATE TABLE location_log (
    location_log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id UUID NOT NULL,
    agency_id UUID NOT NULL,
    trip_id UUID,
    latitude NUMERIC(9,6) NOT NULL,
    longitude NUMERIC(9,6) NOT NULL,
    speed_kmh NUMERIC(8,2),
    accuracy_m NUMERIC(8,2),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_location_log_agent
        FOREIGN KEY (agent_id, agency_id)
        REFERENCES agent(user_id, agency_id),
    CONSTRAINT fk_location_log_trip_agent
        FOREIGN KEY (trip_id, agent_id, agency_id)
        REFERENCES delivery_trip(trip_id, agent_id, agency_id),
    CONSTRAINT ck_location_log_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT ck_location_log_longitude CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_location_log_speed CHECK (speed_kmh IS NULL OR speed_kmh >= 0),
    CONSTRAINT ck_location_log_accuracy CHECK (accuracy_m IS NULL OR accuracy_m >= 0)
);

CREATE INDEX idx_location_log_agent_recorded
    ON location_log(agent_id, recorded_at DESC);
CREATE INDEX idx_location_log_trip_recorded
    ON location_log(trip_id, recorded_at DESC) WHERE trip_id IS NOT NULL;

-- ============================================================================
-- V5_7: NOTIFICATION
-- user_id is recipient. sender_id is optional for system-generated messages.
-- ============================================================================
CREATE TABLE notification (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
    sender_id UUID REFERENCES app_user(user_id) ON DELETE SET NULL,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    reference_type VARCHAR(50),
    reference_id UUID,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_notification_reference_pair CHECK (
        (reference_type IS NULL) = (reference_id IS NULL)
    ),
    CONSTRAINT ck_notification_read_state CHECK (
        (is_read = FALSE AND read_at IS NULL)
        OR (is_read = TRUE AND read_at IS NOT NULL)
    )
);

CREATE INDEX idx_notification_user_created
    ON notification(user_id, created_at DESC);
CREATE INDEX idx_notification_user_unread
    ON notification(user_id, created_at DESC) WHERE is_read = FALSE;

COMMIT;

-- ============================================================================
-- ITEMS THAT CANNOT BE GUARANTEED BY THESE DECLARATIVE CONSTRAINTS ALONE
-- Implement in service transactions or database triggers:
-- 1. Inventory balance updates and stock-movement inserts must be atomic.
-- 2. Prevent aggregate delivered quantities across multiple PODs/items from
--    exceeding allocated quantities (row CHECK constraints only check one row).
-- 3. Validate that loaded/received/handover quantities do not exceed source
--    order quantities across multiple handover/allocation rows.
-- 4. Validate that an agent has an active area assignment covering a trip date.
-- 5. Validate state transitions (e.g. a CANCELLED trip cannot later complete).
-- 6. Validate reviewer roles and permissions beyond the profile FKs where a
--    workflow permits multiple privileged reviewer types.
-- ============================================================================
