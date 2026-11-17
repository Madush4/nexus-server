# Nexus — Database Schema Reference

Generated from a live PostgreSQL database after applying every Flyway migration, so the keys and constraints below are exactly what the migrations create. The team runs PostgreSQL 18 in Docker (port 5433).

**Key:** 🔑 PK = primary key · 🔗 FK = foreign key · UQ = unique · ✔ CHECK = rule the value must satisfy · NN = NOT NULL

**Totals:** 53 tables · 3 views · 32 migration files (V1\_\_init_common.sql + 31 in module folders)

---

## 01_core — Core: users, roles & master data

### `app_user`

<sub>File: `01_core/V1_1__create_app_user.sql` · `created_by`, `deactivated_at`, `deactivated_by` added in `V1_7` · `SUPER_ADMIN` role added in `V1_8`</sub>

| Column           | Type         | Key                      | Null | Default             |
| ---------------- | ------------ | ------------------------ | ---- | ------------------- |
| `user_id`        | uuid         | 🔑 PK                    | NN   | `gen_random_uuid()` |
| `full_name`      | varchar(150) |                          | NN   |                     |
| `email`          | varchar(150) | UQ                       | NN   |                     |
| `contact_number` | varchar(20)  |                          | null |                     |
| `nic`            | varchar(12)  | UQ                       | null |                     |
| `password_hash`  | text         |                          | NN   |                     |
| `role`           | varchar(30)  |                          | NN   |                     |
| `account_status` | varchar(20)  |                          | NN   | `'ACTIVE'`          |
| `last_login_at`  | timestamptz  |                          | null |                     |
| `created_at`     | timestamptz  |                          | NN   | `now()`             |
| `updated_at`     | timestamptz  |                          | NN   | `now()`             |
| `created_by`     | uuid         | 🔗 FK → app_user.user_id | null |                     |
| `deactivated_at` | timestamptz  |                          | null |                     |
| `deactivated_by` | uuid         | 🔗 FK → app_user.user_id | null |                     |

**Constraints**

- `pk_app_user` — PRIMARY KEY (user_id)
- `fk_app_user_created_by` — FOREIGN KEY (created_by) REFERENCES app_user(user_id)
- `fk_app_user_deactivated_by` — FOREIGN KEY (deactivated_by) REFERENCES app_user(user_id)
- `uq_app_user_email` — UNIQUE (email)
- `uq_app_user_id_role` — UNIQUE (user_id, role)
- `uq_app_user_nic` — UNIQUE (nic)
- `ck_app_user_deactivation` — CHECK ((((account_status = 'INACTIVE') = (deactivated_at IS NOT NULL)) AND ((deactivated_at IS NULL) = (deactivated_by IS NULL))))
- `ck_app_user_email_lower` — CHECK ((email = lower(email)))
- `ck_app_user_nic` — CHECK (((nic IS NULL) OR (nic ~ '^([0-9]{9}[VvXx]|[0-9]{12})$')))
- `ck_app_user_not_self_created` — CHECK (((created_by IS NULL) OR (created_by <> user_id)))
- `ck_app_user_role` — CHECK (role IN ('SUPER_ADMIN', 'MANUFACTURING_ADMIN', 'WAREHOUSE_ADMIN', 'WAREHOUSE_SUPERVISOR', 'AGENCY_MANAGER', 'AGENT'))
- `ck_app_user_status` — CHECK (account_status IN ('ACTIVE', 'INACTIVE', 'LOCKED'))
- `uq_app_user_one_active_super_admin` — UNIQUE INDEX (role) WHERE ((role = 'SUPER_ADMIN') AND (account_status = 'ACTIVE')) — only one active super admin

### `product`

<sub>File: `01_core/V1_2__create_product.sql`</sub>

| Column            | Type          | Key   | Null | Default             |
| ----------------- | ------------- | ----- | ---- | ------------------- |
| `product_id`      | uuid          | 🔑 PK | NN   | `gen_random_uuid()` |
| `product_code`    | varchar(50)   | UQ    | NN   |                     |
| `product_name`    | varchar(150)  |       | NN   |                     |
| `description`     | text          |       | null |                     |
| `unit_of_measure` | varchar(20)   |       | NN   | `'UNIT'`            |
| `unit_weight_kg`  | numeric(10,3) |       | null |                     |
| `is_active`       | boolean       |       | NN   | `true`              |
| `created_at`      | timestamptz   |       | NN   | `now()`             |
| `updated_at`      | timestamptz   |       | NN   | `now()`             |

**Constraints**

- `pk_product` — PRIMARY KEY (product_id)
- `uq_product_code` — UNIQUE (product_code)
- `ck_product_uom` — CHECK (unit_of_measure IN ('UNIT', 'PACK', 'BOX', 'CASE', 'KG', 'LITRE'))
- `ck_product_weight` — CHECK (((unit_weight_kg IS NULL) OR (unit_weight_kg > 0)))

### `agency`

<sub>File: `01_core/V1_3__create_agency_area_outlet.sql` · `created_by`, `deactivated_at`, `deactivated_by` added in `V1_7`</sub>

| Column           | Type         | Key                                 | Null | Default             |
| ---------------- | ------------ | ----------------------------------- | ---- | ------------------- |
| `agency_id`      | uuid         | 🔑 PK                               | NN   | `gen_random_uuid()` |
| `agency_code`    | varchar(20)  | UQ                                  | NN   |                     |
| `agency_name`    | varchar(150) |                                     | NN   |                     |
| `email`          | varchar(150) | UQ                                  | null |                     |
| `contact_number` | varchar(20)  |                                     | NN   |                     |
| `address`        | text         |                                     | NN   |                     |
| `latitude`       | numeric(9,6) |                                     | null |                     |
| `longitude`      | numeric(9,6) |                                     | null |                     |
| `is_active`      | boolean      |                                     | NN   | `true`              |
| `created_at`     | timestamptz  |                                     | NN   | `now()`             |
| `updated_at`     | timestamptz  |                                     | NN   | `now()`             |
| `created_by`     | uuid         | 🔗 FK → manufacturing_admin.user_id | null |                     |
| `deactivated_at` | timestamptz  |                                     | null |                     |
| `deactivated_by` | uuid         | 🔗 FK → manufacturing_admin.user_id | null |                     |

**Constraints**

- `pk_agency` — PRIMARY KEY (agency_id)
- `fk_agency_created_by` — FOREIGN KEY (created_by) REFERENCES manufacturing_admin(user_id)
- `fk_agency_deactivated_by` — FOREIGN KEY (deactivated_by) REFERENCES manufacturing_admin(user_id)
- `uq_agency_code` — UNIQUE (agency_code)
- `uq_agency_email` — UNIQUE (email)
- `ck_agency_deactivation` — CHECK (((is_active = (deactivated_at IS NULL)) AND ((deactivated_at IS NULL) = (deactivated_by IS NULL))))
- `ck_agency_lat` — CHECK (((latitude >= -90) AND (latitude <= 90)))
- `ck_agency_latlng_pair` — CHECK (((latitude IS NULL) = (longitude IS NULL)))
- `ck_agency_lng` — CHECK (((longitude >= -180) AND (longitude <= 180)))

### `operational_area`

<sub>File: `01_core/V1_3__create_agency_area_outlet.sql`</sub>

| Column        | Type         | Key                      | Null | Default             |
| ------------- | ------------ | ------------------------ | ---- | ------------------- |
| `area_id`     | uuid         | 🔑 PK                    | NN   | `gen_random_uuid()` |
| `agency_id`   | uuid         | 🔗 FK → agency.agency_id | NN   |                     |
| `area_code`   | varchar(20)  |                          | NN   |                     |
| `area_name`   | varchar(150) |                          | NN   |                     |
| `description` | text         |                          | null |                     |
| `is_active`   | boolean      |                          | NN   | `true`              |

**Constraints**

- `pk_operational_area` — PRIMARY KEY (area_id)
- `fk_operational_area_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `uq_operational_area_code` — UNIQUE (agency_id, area_code)

### `retail_outlet`

<sub>File: `01_core/V1_3__create_agency_area_outlet.sql`</sub>

| Column           | Type         | Key                              | Null | Default             |
| ---------------- | ------------ | -------------------------------- | ---- | ------------------- |
| `outlet_id`      | uuid         | 🔑 PK                            | NN   | `gen_random_uuid()` |
| `area_id`        | uuid         | 🔗 FK → operational_area.area_id | NN   |                     |
| `outlet_code`    | varchar(20)  | UQ                               | NN   |                     |
| `outlet_name`    | varchar(150) |                                  | NN   |                     |
| `owner_name`     | varchar(150) |                                  | null |                     |
| `contact_number` | varchar(20)  |                                  | NN   |                     |
| `address`        | text         |                                  | NN   |                     |
| `latitude`       | numeric(9,6) |                                  | null |                     |
| `longitude`      | numeric(9,6) |                                  | null |                     |
| `is_active`      | boolean      |                                  | NN   | `true`              |
| `created_at`     | timestamptz  |                                  | NN   | `now()`             |
| `updated_at`     | timestamptz  |                                  | NN   | `now()`             |

**Constraints**

- `pk_retail_outlet` — PRIMARY KEY (outlet_id)
- `fk_retail_outlet_area` — FOREIGN KEY (area_id) REFERENCES operational_area(area_id)
- `uq_retail_outlet_code` — UNIQUE (outlet_code)
- `ck_retail_outlet_lat` — CHECK (((latitude >= -90) AND (latitude <= 90)))
- `ck_retail_outlet_latlng_pair` — CHECK (((latitude IS NULL) = (longitude IS NULL)))
- `ck_retail_outlet_lng` — CHECK (((longitude >= -180) AND (longitude <= 180)))

### `warehouse`

<sub>File: `01_core/V1_4__create_warehouse.sql` · `created_by`, `updated_at`, `deactivated_at`, `deactivated_by` added in `V1_7`</sub>

| Column           | Type         | Key                                 | Null | Default             |
| ---------------- | ------------ | ----------------------------------- | ---- | ------------------- |
| `warehouse_id`   | uuid         | 🔑 PK                               | NN   | `gen_random_uuid()` |
| `warehouse_code` | varchar(20)  | UQ                                  | NN   |                     |
| `warehouse_name` | varchar(150) |                                     | NN   |                     |
| `address`        | text         |                                     | NN   |                     |
| `contact_number` | varchar(20)  |                                     | null |                     |
| `latitude`       | numeric(9,6) |                                     | null |                     |
| `longitude`      | numeric(9,6) |                                     | null |                     |
| `is_active`      | boolean      |                                     | NN   | `true`              |
| `created_at`     | timestamptz  |                                     | NN   | `now()`             |
| `created_by`     | uuid         | 🔗 FK → manufacturing_admin.user_id | null |                     |
| `updated_at`     | timestamptz  |                                     | NN   | `now()`             |
| `deactivated_at` | timestamptz  |                                     | null |                     |
| `deactivated_by` | uuid         | 🔗 FK → manufacturing_admin.user_id | null |                     |

**Constraints**

- `pk_warehouse` — PRIMARY KEY (warehouse_id)
- `fk_warehouse_created_by` — FOREIGN KEY (created_by) REFERENCES manufacturing_admin(user_id)
- `fk_warehouse_deactivated_by` — FOREIGN KEY (deactivated_by) REFERENCES manufacturing_admin(user_id)
- `uq_warehouse_code` — UNIQUE (warehouse_code)
- `ck_warehouse_deactivation` — CHECK (((is_active = (deactivated_at IS NULL)) AND ((deactivated_at IS NULL) = (deactivated_by IS NULL))))
- `ck_warehouse_lat` — CHECK (((latitude >= -90) AND (latitude <= 90)))
- `ck_warehouse_latlng_pair` — CHECK (((latitude IS NULL) = (longitude IS NULL)))
- `ck_warehouse_lng` — CHECK (((longitude >= -180) AND (longitude <= 180)))

### `manufacturing_admin`

<sub>File: `01_core/V1_5__create_user_role_profiles.sql` · `created_by` added in `V1_8`</sub>

| Column       | Type        | Key                              | Null | Default                 |
| ------------ | ----------- | -------------------------------- | ---- | ----------------------- |
| `user_id`    | uuid        | 🔑 PK · 🔗 FK → app_user.user_id | NN   |                         |
| `role`       | varchar(30) | 🔗 FK → app_user.role            | NN   | `'MANUFACTURING_ADMIN'` |
| `created_by` | uuid        | 🔗 FK → super_admin.user_id      | NN   |                         |

**Constraints**

- `pk_manufacturing_admin` — PRIMARY KEY (user_id)
- `fk_manufacturing_admin_created_by` — FOREIGN KEY (created_by) REFERENCES super_admin(user_id)
- `fk_manufacturing_admin_user` — FOREIGN KEY (user_id, role) REFERENCES app_user(user_id, role) ON DELETE CASCADE
- `ck_manufacturing_admin_role` — CHECK ((role = 'MANUFACTURING_ADMIN'))

### `warehouse_admin`

<sub>File: `01_core/V1_5__create_user_role_profiles.sql`</sub>

| Column         | Type        | Key                              | Null | Default             |
| -------------- | ----------- | -------------------------------- | ---- | ------------------- |
| `user_id`      | uuid        | 🔑 PK · 🔗 FK → app_user.user_id | NN   |                     |
| `role`         | varchar(30) | 🔗 FK → app_user.role            | NN   | `'WAREHOUSE_ADMIN'` |
| `warehouse_id` | uuid        | 🔗 FK → warehouse.warehouse_id   | NN   |                     |

**Constraints**

- `pk_warehouse_admin` — PRIMARY KEY (user_id)
- `fk_warehouse_admin_user` — FOREIGN KEY (user_id, role) REFERENCES app_user(user_id, role) ON DELETE CASCADE
- `fk_warehouse_admin_warehouse` — FOREIGN KEY (warehouse_id) REFERENCES warehouse(warehouse_id)
- `ck_warehouse_admin_role` — CHECK ((role = 'WAREHOUSE_ADMIN'))

### `warehouse_supervisor`

<sub>File: `01_core/V1_5__create_user_role_profiles.sql`</sub>

| Column         | Type        | Key                              | Null | Default                  |
| -------------- | ----------- | -------------------------------- | ---- | ------------------------ |
| `user_id`      | uuid        | 🔑 PK · 🔗 FK → app_user.user_id | NN   |                          |
| `role`         | varchar(30) | 🔗 FK → app_user.role            | NN   | `'WAREHOUSE_SUPERVISOR'` |
| `warehouse_id` | uuid        | 🔗 FK → warehouse.warehouse_id   | NN   |                          |

**Constraints**

- `pk_warehouse_supervisor` — PRIMARY KEY (user_id)
- `fk_warehouse_supervisor_user` — FOREIGN KEY (user_id, role) REFERENCES app_user(user_id, role) ON DELETE CASCADE
- `fk_warehouse_supervisor_warehouse` — FOREIGN KEY (warehouse_id) REFERENCES warehouse(warehouse_id)
- `ck_warehouse_supervisor_role` — CHECK ((role = 'WAREHOUSE_SUPERVISOR'))

### `agency_manager`

<sub>File: `01_core/V1_5__create_user_role_profiles.sql`</sub>

| Column      | Type        | Key                              | Null | Default            |
| ----------- | ----------- | -------------------------------- | ---- | ------------------ |
| `user_id`   | uuid        | 🔑 PK · 🔗 FK → app_user.user_id | NN   |                    |
| `role`      | varchar(30) | 🔗 FK → app_user.role            | NN   | `'AGENCY_MANAGER'` |
| `agency_id` | uuid        | 🔗 FK → agency.agency_id         | NN   |                    |

**Constraints**

- `pk_agency_manager` — PRIMARY KEY (user_id)
- `fk_agency_manager_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `fk_agency_manager_user` — FOREIGN KEY (user_id, role) REFERENCES app_user(user_id, role) ON DELETE CASCADE
- `ck_agency_manager_role` — CHECK ((role = 'AGENCY_MANAGER'))

### `agent`

<sub>File: `01_core/V1_5__create_user_role_profiles.sql`</sub>

| Column          | Type        | Key                              | Null | Default   |
| --------------- | ----------- | -------------------------------- | ---- | --------- |
| `user_id`       | uuid        | 🔑 PK · 🔗 FK → app_user.user_id | NN   |           |
| `role`          | varchar(30) | 🔗 FK → app_user.role            | NN   | `'AGENT'` |
| `agency_id`     | uuid        | 🔗 FK → agency.agency_id         | NN   |           |
| `employee_code` | varchar(20) |                                  | NN   |           |

**Constraints**

- `pk_agent` — PRIMARY KEY (user_id)
- `fk_agent_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `fk_agent_user` — FOREIGN KEY (user_id, role) REFERENCES app_user(user_id, role) ON DELETE CASCADE
- `uq_agent_employee_code` — UNIQUE (agency_id, employee_code)
- `ck_agent_role` — CHECK ((role = 'AGENT'))

### `audit_log`

<sub>File: `01_core/V1_6__create_audit_log.sql`</sub>

| Column        | Type        | Key                      | Null | Default                        |
| ------------- | ----------- | ------------------------ | ---- | ------------------------------ |
| `log_id`      | bigint      | 🔑 PK                    | NN   | `GENERATED ALWAYS AS IDENTITY` |
| `user_id`     | uuid        | 🔗 FK → app_user.user_id | null |                                |
| `action`      | varchar(50) |                          | NN   |                                |
| `entity_type` | varchar(50) |                          | NN   |                                |
| `entity_id`   | uuid        |                          | null |                                |
| `details`     | jsonb       |                          | null |                                |
| `created_at`  | timestamptz |                          | NN   | `now()`                        |

**Constraints**

- `pk_audit_log` — PRIMARY KEY (log_id)
- `fk_audit_log_user` — FOREIGN KEY (user_id) REFERENCES app_user(user_id) ON DELETE SET NULL

### `super_admin`

<sub>File: `01_core/V1_8__add_super_admin.sql`</sub>

| Column    | Type        | Key                              | Null | Default         |
| --------- | ----------- | -------------------------------- | ---- | --------------- |
| `user_id` | uuid        | 🔑 PK · 🔗 FK → app_user.user_id | NN   |                 |
| `role`    | varchar(30) | 🔗 FK → app_user.role            | NN   | `'SUPER_ADMIN'` |

**Constraints**

- `pk_super_admin` — PRIMARY KEY (user_id)
- `fk_super_admin_user` — FOREIGN KEY (user_id, role) REFERENCES app_user(user_id, role) ON DELETE CASCADE
- `ck_super_admin_role` — CHECK ((role = 'SUPER_ADMIN'))

---

## 02_manufacturer — Manufacturer & ERP integration

### `sap_report`

<sub>File: `02_manufacturer/V2_1__create_sap_report.sql`</sub>

| Column        | Type         | Key                                 | Null | Default             |
| ------------- | ------------ | ----------------------------------- | ---- | ------------------- |
| `report_id`   | uuid         | 🔑 PK                               | NN   | `gen_random_uuid()` |
| `uploaded_by` | uuid         | 🔗 FK → manufacturing_admin.user_id | NN   |                     |
| `file_name`   | varchar(255) |                                     | NN   |                     |
| `file_path`   | text         |                                     | NN   |                     |
| `report_date` | date         |                                     | NN   |                     |
| `status`      | varchar(30)  |                                     | NN   | `'PENDING'`         |
| `uploaded_at` | timestamptz  |                                     | NN   | `now()`             |
| `updated_at`  | timestamptz  |                                     | NN   | `now()`             |

**Constraints**

- `pk_sap_report` — PRIMARY KEY (report_id)
- `fk_sap_report_uploader` — FOREIGN KEY (uploaded_by) REFERENCES manufacturing_admin(user_id)
- `ck_sap_report_status` — CHECK (status IN ('PENDING', 'IN_PROGRESS', 'ACCEPTED', 'PARTIALLY_ACCEPTED', 'REJECTED'))

### `sap_report_item`

<sub>File: `02_manufacturer/V2_1__create_sap_report.sql`</sub>

| Column           | Type          | Key                          | Null | Default             |
| ---------------- | ------------- | ---------------------------- | ---- | ------------------- |
| `report_item_id` | uuid          | 🔑 PK                        | NN   | `gen_random_uuid()` |
| `report_id`      | uuid          | 🔗 FK → sap_report.report_id | NN   |                     |
| `product_id`     | uuid          | 🔗 FK → product.product_id   | NN   |                     |
| `agency_id`      | uuid          | 🔗 FK → agency.agency_id     | NN   |                     |
| `quantity`       | integer       |                              | NN   |                     |
| `due_payment`    | numeric(12,2) |                              | NN   | `0`                 |

**Constraints**

- `pk_sap_report_item` — PRIMARY KEY (report_item_id)
- `fk_sap_report_item_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `fk_sap_report_item_product` — FOREIGN KEY (product_id) REFERENCES product(product_id)
- `fk_sap_report_item_report` — FOREIGN KEY (report_id) REFERENCES sap_report(report_id) ON DELETE CASCADE
- `uq_sap_report_item_line` — UNIQUE (report_id, agency_id, product_id)
- `ck_sap_report_item_due` — CHECK ((due_payment >= 0))
- `ck_sap_report_item_qty` — CHECK ((quantity > 0))

### `manufacturer_inventory`

<sub>File: `02_manufacturer/V2_2__create_manufacturer_inventory.sql`</sub>

| Column                | Type        | Key                             | Null | Default             |
| --------------------- | ----------- | ------------------------------- | ---- | ------------------- |
| `inventory_id`        | uuid        | 🔑 PK                           | NN   | `gen_random_uuid()` |
| `product_id`          | uuid        | 🔗 FK → product.product_id · UQ | NN   |                     |
| `quantity_on_hand`    | integer     |                                 | NN   | `0`                 |
| `quantity_reserved`   | integer     |                                 | NN   | `0`                 |
| `minimum_stock_level` | integer     |                                 | NN   | `0`                 |
| `updated_at`          | timestamptz |                                 | NN   | `now()`             |

**Constraints**

- `pk_manufacturer_inventory` — PRIMARY KEY (inventory_id)
- `fk_manufacturer_inventory_product` — FOREIGN KEY (product_id) REFERENCES product(product_id)
- `uq_manufacturer_inventory_product` — UNIQUE (product_id)
- `ck_manufacturer_inventory_qty` — CHECK (((quantity_on_hand >= 0) AND (quantity_reserved >= 0) AND (quantity_reserved <= quantity_on_hand) AND (minimum_stock_level >= 0)))

### `manufacturer_stock_movement`

<sub>File: `02_manufacturer/V2_2__create_manufacturer_inventory.sql`</sub>

| Column           | Type        | Key                                       | Null | Default             |
| ---------------- | ----------- | ----------------------------------------- | ---- | ------------------- |
| `movement_id`    | uuid        | 🔑 PK                                     | NN   | `gen_random_uuid()` |
| `product_id`     | uuid        | 🔗 FK → manufacturer_inventory.product_id | NN   |                     |
| `performed_by`   | uuid        | 🔗 FK → manufacturing_admin.user_id       | NN   |                     |
| `movement_type`  | varchar(20) |                                           | NN   |                     |
| `quantity`       | integer     |                                           | NN   |                     |
| `reference_type` | varchar(30) |                                           | null |                     |
| `reference_id`   | uuid        |                                           | null |                     |
| `note`           | text        |                                           | null |                     |
| `created_at`     | timestamptz |                                           | NN   | `now()`             |

**Constraints**

- `pk_manufacturer_stock_movement` — PRIMARY KEY (movement_id)
- `fk_manufacturer_stock_movement_admin` — FOREIGN KEY (performed_by) REFERENCES manufacturing_admin(user_id)
- `fk_manufacturer_stock_movement_inventory` — FOREIGN KEY (product_id) REFERENCES manufacturer_inventory(product_id)
- `ck_manufacturer_stock_movement_qty` — CHECK ((quantity > 0))
- `ck_manufacturer_stock_movement_ref` — CHECK (((reference_type IS NULL) = (reference_id IS NULL)))
- `ck_manufacturer_stock_movement_type` — CHECK (movement_type IN ('STOCK_IN', 'STOCK_OUT', 'RESERVATION', 'RELEASE', 'ADJUSTMENT'))

### `agency_order`

<sub>File: `02_manufacturer/V2_3__create_agency_order.sql`</sub>

| Column       | Type        | Key                                 | Null | Default             |
| ------------ | ----------- | ----------------------------------- | ---- | ------------------- |
| `order_id`   | uuid        | 🔑 PK                               | NN   | `gen_random_uuid()` |
| `report_id`  | uuid        | 🔗 FK → sap_report.report_id        | NN   |                     |
| `agency_id`  | uuid        | 🔗 FK → agency.agency_id            | NN   |                     |
| `created_by` | uuid        | 🔗 FK → manufacturing_admin.user_id | NN   |                     |
| `status`     | varchar(20) |                                     | NN   | `'DRAFT'`           |
| `created_at` | timestamptz |                                     | NN   | `now()`             |
| `updated_at` | timestamptz |                                     | NN   | `now()`             |

**Constraints**

- `pk_agency_order` — PRIMARY KEY (order_id)
- `fk_agency_order_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `fk_agency_order_creator` — FOREIGN KEY (created_by) REFERENCES manufacturing_admin(user_id)
- `fk_agency_order_report` — FOREIGN KEY (report_id) REFERENCES sap_report(report_id)
- `uq_agency_order_id_agency` — UNIQUE (order_id, agency_id)
- `uq_agency_order_report_agency` — UNIQUE (report_id, agency_id)
- `ck_agency_order_status` — CHECK (status IN ('DRAFT', 'CONFIRMED', 'HANDED_OVER', 'DISPATCHED', 'CANCELLED'))

### `agency_order_item`

<sub>File: `02_manufacturer/V2_3__create_agency_order.sql`</sub>

| Column          | Type    | Key                           | Null | Default             |
| --------------- | ------- | ----------------------------- | ---- | ------------------- |
| `order_item_id` | uuid    | 🔑 PK                         | NN   | `gen_random_uuid()` |
| `order_id`      | uuid    | 🔗 FK → agency_order.order_id | NN   |                     |
| `product_id`    | uuid    | 🔗 FK → product.product_id    | NN   |                     |
| `requested_qty` | integer |                               | NN   |                     |
| `allocated_qty` | integer |                               | NN   | `0`                 |

**Constraints**

- `pk_agency_order_item` — PRIMARY KEY (order_item_id)
- `fk_agency_order_item_order` — FOREIGN KEY (order_id) REFERENCES agency_order(order_id) ON DELETE CASCADE
- `fk_agency_order_item_product` — FOREIGN KEY (product_id) REFERENCES product(product_id)
- `uq_agency_order_item_product` — UNIQUE (order_id, product_id)
- `ck_agency_order_item_qty` — CHECK (((requested_qty > 0) AND (allocated_qty >= 0) AND (allocated_qty <= requested_qty)))

### `warehouse_handover`

<sub>File: `02_manufacturer/V2_4__create_warehouse_handover.sql`</sub>

| Column               | Type        | Key                                 | Null | Default             |
| -------------------- | ----------- | ----------------------------------- | ---- | ------------------- |
| `handover_id`        | uuid        | 🔑 PK                               | NN   | `gen_random_uuid()` |
| `handover_reference` | varchar(50) | UQ                                  | NN   |                     |
| `report_id`          | uuid        | 🔗 FK → sap_report.report_id · UQ   | NN   |                     |
| `warehouse_id`       | uuid        | 🔗 FK → warehouse.warehouse_id      | NN   |                     |
| `handed_over_by`     | uuid        | 🔗 FK → manufacturing_admin.user_id | NN   |                     |
| `received_by`        | uuid        | 🔗 FK → warehouse_admin.user_id     | null |                     |
| `status`             | varchar(20) |                                     | NN   | `'DRAFT'`           |
| `sent_at`            | timestamptz |                                     | null |                     |
| `received_at`        | timestamptz |                                     | null |                     |
| `created_at`         | timestamptz |                                     | NN   | `now()`             |

**Constraints**

- `pk_warehouse_handover` — PRIMARY KEY (handover_id)
- `fk_warehouse_handover_receiver` — FOREIGN KEY (received_by) REFERENCES warehouse_admin(user_id)
- `fk_warehouse_handover_report` — FOREIGN KEY (report_id) REFERENCES sap_report(report_id)
- `fk_warehouse_handover_sender` — FOREIGN KEY (handed_over_by) REFERENCES manufacturing_admin(user_id)
- `fk_warehouse_handover_warehouse` — FOREIGN KEY (warehouse_id) REFERENCES warehouse(warehouse_id)
- `uq_warehouse_handover_reference` — UNIQUE (handover_reference)
- `uq_warehouse_handover_report` — UNIQUE (report_id)
- `ck_warehouse_handover_status` — CHECK (status IN ('DRAFT', 'SENT', 'RECEIVED', 'REJECTED'))
- `ck_warehouse_handover_times` — CHECK (((received_at IS NULL) OR (sent_at IS NULL) OR (received_at >= sent_at)))

### `warehouse_handover_item`

<sub>File: `02_manufacturer/V2_4__create_warehouse_handover.sql`</sub>

| Column             | Type    | Key                                     | Null | Default             |
| ------------------ | ------- | --------------------------------------- | ---- | ------------------- |
| `handover_item_id` | uuid    | 🔑 PK                                   | NN   | `gen_random_uuid()` |
| `handover_id`      | uuid    | 🔗 FK → warehouse_handover.handover_id  | NN   |                     |
| `order_item_id`    | uuid    | 🔗 FK → agency_order_item.order_item_id | NN   |                     |
| `quantity`         | integer |                                         | NN   |                     |

**Constraints**

- `pk_warehouse_handover_item` — PRIMARY KEY (handover_item_id)
- `fk_warehouse_handover_item_handover` — FOREIGN KEY (handover_id) REFERENCES warehouse_handover(handover_id) ON DELETE CASCADE
- `fk_warehouse_handover_item_order_item` — FOREIGN KEY (order_item_id) REFERENCES agency_order_item(order_item_id)
- `uq_warehouse_handover_item_line` — UNIQUE (handover_id, order_item_id)
- `ck_warehouse_handover_item_qty` — CHECK ((quantity > 0))

---

## 03_dispatch_fleet — Dispatch & fleet

### `driver`

<sub>File: `03_dispatch_fleet/V3_1__create_driver_vehicle.sql`</sub>

| Column                | Type         | Key                      | Null | Default             |
| --------------------- | ------------ | ------------------------ | ---- | ------------------- |
| `driver_id`           | uuid         | 🔑 PK                    | NN   | `gen_random_uuid()` |
| `agency_id`           | uuid         | 🔗 FK → agency.agency_id | NN   |                     |
| `full_name`           | varchar(150) |                          | NN   |                     |
| `nic`                 | varchar(12)  | UQ                       | NN   |                     |
| `contact_number`      | varchar(20)  |                          | NN   |                     |
| `address`             | text         |                          | null |                     |
| `licence_number`      | varchar(20)  | UQ                       | NN   |                     |
| `licence_expiry_date` | date         |                          | NN   |                     |
| `is_active`           | boolean      |                          | NN   | `true`              |
| `created_at`          | timestamptz  |                          | NN   | `now()`             |

**Constraints**

- `pk_driver` — PRIMARY KEY (driver_id)
- `fk_driver_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `uq_driver_licence` — UNIQUE (licence_number)
- `uq_driver_nic` — UNIQUE (nic)
- `ck_driver_nic` — CHECK ((nic ~ '^([0-9]{9}[VvXx]|[0-9]{12})$'))

### `vehicle`

<sub>File: `03_dispatch_fleet/V3_1__create_driver_vehicle.sql`</sub>

| Column                | Type          | Key                      | Null | Default             |
| --------------------- | ------------- | ------------------------ | ---- | ------------------- |
| `vehicle_id`          | uuid          | 🔑 PK                    | NN   | `gen_random_uuid()` |
| `agency_id`           | uuid          | 🔗 FK → agency.agency_id | NN   |                     |
| `registration_number` | varchar(20)   | UQ                       | NN   |                     |
| `vehicle_type`        | varchar(20)   |                          | NN   |                     |
| `max_load_kg`         | numeric(10,2) |                          | NN   |                     |
| `operational_status`  | varchar(20)   |                          | NN   | `'AVAILABLE'`       |
| `is_active`           | boolean       |                          | NN   | `true`              |
| `created_at`          | timestamptz   |                          | NN   | `now()`             |
| `updated_at`          | timestamptz   |                          | NN   | `now()`             |

**Constraints**

- `pk_vehicle` — PRIMARY KEY (vehicle_id)
- `fk_vehicle_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `uq_vehicle_registration` — UNIQUE (registration_number)
- `ck_vehicle_max_load` — CHECK ((max_load_kg > 0))
- `ck_vehicle_status` — CHECK (operational_status IN ('AVAILABLE', 'ON_TRIP', 'UNDER_MAINTENANCE', 'OUT_OF_SERVICE'))
- `ck_vehicle_type` — CHECK (vehicle_type IN ('LORRY', 'VAN', 'TRUCK', 'THREE_WHEELER', 'MOTORBIKE'))

### `vehicle_maintenance`

<sub>File: `03_dispatch_fleet/V3_1__create_driver_vehicle.sql`</sub>

| Column             | Type          | Key                            | Null | Default             |
| ------------------ | ------------- | ------------------------------ | ---- | ------------------- |
| `maintenance_id`   | uuid          | 🔑 PK                          | NN   | `gen_random_uuid()` |
| `vehicle_id`       | uuid          | 🔗 FK → vehicle.vehicle_id     | NN   |                     |
| `maintenance_type` | varchar(30)   |                                | NN   |                     |
| `description`      | text          |                                | null |                     |
| `service_date`     | date          |                                | NN   |                     |
| `cost`             | numeric(12,2) |                                | null |                     |
| `next_due_date`    | date          |                                | null |                     |
| `recorded_by`      | uuid          | 🔗 FK → agency_manager.user_id | NN   |                     |
| `created_at`       | timestamptz   |                                | NN   | `now()`             |

**Constraints**

- `pk_vehicle_maintenance` — PRIMARY KEY (maintenance_id)
- `fk_vehicle_maintenance_manager` — FOREIGN KEY (recorded_by) REFERENCES agency_manager(user_id)
- `fk_vehicle_maintenance_vehicle` — FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id)
- `ck_vehicle_maintenance_cost` — CHECK (((cost IS NULL) OR (cost >= 0)))
- `ck_vehicle_maintenance_due` — CHECK (((next_due_date IS NULL) OR (next_due_date >= service_date)))
- `ck_vehicle_maintenance_type` — CHECK (maintenance_type IN ('SERVICE', 'REPAIR', 'TYRE', 'INSURANCE', 'REVENUE_LICENCE', 'OTHER'))

### `dispatch_schedule`

<sub>File: `03_dispatch_fleet/V3_2__create_dispatch_schedule.sql`</sub>

| Column           | Type        | Key                                    | Null | Default             |
| ---------------- | ----------- | -------------------------------------- | ---- | ------------------- |
| `schedule_id`    | uuid        | 🔑 PK                                  | NN   | `gen_random_uuid()` |
| `handover_id`    | uuid        | 🔗 FK → warehouse_handover.handover_id | NN   |                     |
| `warehouse_id`   | uuid        | 🔗 FK → warehouse.warehouse_id         | NN   |                     |
| `scheduled_date` | date        |                                        | NN   |                     |
| `created_by`     | uuid        | 🔗 FK → warehouse_admin.user_id        | NN   |                     |
| `supervisor_id`  | uuid        | 🔗 FK → warehouse_supervisor.user_id   | null |                     |
| `status`         | varchar(20) |                                        | NN   | `'DRAFT'`           |
| `created_at`     | timestamptz |                                        | NN   | `now()`             |
| `updated_at`     | timestamptz |                                        | NN   | `now()`             |

**Constraints**

- `pk_dispatch_schedule` — PRIMARY KEY (schedule_id)
- `fk_dispatch_schedule_admin` — FOREIGN KEY (created_by) REFERENCES warehouse_admin(user_id)
- `fk_dispatch_schedule_handover` — FOREIGN KEY (handover_id) REFERENCES warehouse_handover(handover_id)
- `fk_dispatch_schedule_supervisor` — FOREIGN KEY (supervisor_id) REFERENCES warehouse_supervisor(user_id)
- `fk_dispatch_schedule_warehouse` — FOREIGN KEY (warehouse_id) REFERENCES warehouse(warehouse_id)
- `ck_dispatch_schedule_status` — CHECK (status IN ('DRAFT', 'PUBLISHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))

### `dispatch_allocation`

<sub>File: `03_dispatch_fleet/V3_2__create_dispatch_schedule.sql`</sub>

| Column                   | Type        | Key                                   | Null | Default             |
| ------------------------ | ----------- | ------------------------------------- | ---- | ------------------- |
| `dispatch_allocation_id` | uuid        | 🔑 PK                                 | NN   | `gen_random_uuid()` |
| `schedule_id`            | uuid        | 🔗 FK → dispatch_schedule.schedule_id | NN   |                     |
| `order_id`               | uuid        | 🔗 FK → agency_order.order_id · UQ    | NN   |                     |
| `agency_id`              | uuid        | 🔗 FK → agency_order.agency_id        | NN   |                     |
| `pickup_scheduled_at`    | timestamptz |                                       | null |                     |
| `loading_bay`            | varchar(20) |                                       | null |                     |
| `status`                 | varchar(20) |                                       | NN   | `'PENDING'`         |
| `notes`                  | text        |                                       | null |                     |
| `created_at`             | timestamptz |                                       | NN   | `now()`             |
| `updated_at`             | timestamptz |                                       | NN   | `now()`             |

**Constraints**

- `pk_dispatch_allocation` — PRIMARY KEY (dispatch_allocation_id)
- `fk_dispatch_allocation_order` — FOREIGN KEY (order_id, agency_id) REFERENCES agency_order(order_id, agency_id)
- `fk_dispatch_allocation_schedule` — FOREIGN KEY (schedule_id) REFERENCES dispatch_schedule(schedule_id) ON DELETE CASCADE
- `uq_dispatch_allocation_order` — UNIQUE (order_id)
- `ck_dispatch_allocation_status` — CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'READY_FOR_PICKUP', 'PICKED_UP', 'DELIVERED', 'CANCELLED'))

### `dispatch_allocation_item`

<sub>File: `03_dispatch_fleet/V3_2__create_dispatch_schedule.sql`</sub>

| Column                   | Type    | Key                                                | Null | Default             |
| ------------------------ | ------- | -------------------------------------------------- | ---- | ------------------- |
| `allocation_item_id`     | uuid    | 🔑 PK                                              | NN   | `gen_random_uuid()` |
| `dispatch_allocation_id` | uuid    | 🔗 FK → dispatch_allocation.dispatch_allocation_id | NN   |                     |
| `order_item_id`          | uuid    | 🔗 FK → agency_order_item.order_item_id            | NN   |                     |
| `allocated_qty`          | integer |                                                    | NN   |                     |
| `loaded_qty`             | integer |                                                    | null |                     |
| `received_qty`           | integer |                                                    | null |                     |

**Constraints**

- `pk_dispatch_allocation_item` — PRIMARY KEY (allocation_item_id)
- `fk_dispatch_allocation_item_allocation` — FOREIGN KEY (dispatch_allocation_id) REFERENCES dispatch_allocation(dispatch_allocation_id) ON DELETE CASCADE
- `fk_dispatch_allocation_item_order_item` — FOREIGN KEY (order_item_id) REFERENCES agency_order_item(order_item_id)
- `uq_dispatch_allocation_item_line` — UNIQUE (dispatch_allocation_id, order_item_id)
- `ck_dispatch_allocation_item_qty` — CHECK (((allocated_qty > 0) AND ((loaded_qty IS NULL) OR ((loaded_qty >= 0) AND (loaded_qty <= allocated_qty))) AND ((received_qty IS NULL) OR ((loaded_qty IS NOT NULL) AND (received_qty >= 0) AND (received_qty <= loaded_qty)))))

### `dispatch_review`

<sub>File: `03_dispatch_fleet/V3_3__create_dispatch_review.sql`</sub>

| Column                   | Type        | Key                                                | Null | Default             |
| ------------------------ | ----------- | -------------------------------------------------- | ---- | ------------------- |
| `review_id`              | uuid        | 🔑 PK                                              | NN   | `gen_random_uuid()` |
| `dispatch_allocation_id` | uuid        | 🔗 FK → dispatch_allocation.dispatch_allocation_id | NN   |                     |
| `reviewed_by`            | uuid        | 🔗 FK → agency_manager.user_id                     | NN   |                     |
| `outcome`                | varchar(20) |                                                    | NN   |                     |
| `comments`               | text        |                                                    | null |                     |
| `reviewed_at`            | timestamptz |                                                    | NN   | `now()`             |

**Constraints**

- `pk_dispatch_review` — PRIMARY KEY (review_id)
- `fk_dispatch_review_allocation` — FOREIGN KEY (dispatch_allocation_id) REFERENCES dispatch_allocation(dispatch_allocation_id) ON DELETE CASCADE
- `fk_dispatch_review_manager` — FOREIGN KEY (reviewed_by) REFERENCES agency_manager(user_id)
- `ck_dispatch_review_comment` — CHECK (((outcome = 'ACCEPTED') OR (comments IS NOT NULL)))
- `ck_dispatch_review_outcome` — CHECK (outcome IN ('ACCEPTED', 'REJECTED', 'CHANGE_REQUESTED'))

### `shipment_trip`

<sub>File: `03_dispatch_fleet/V3_4__create_shipment_trip.sql`</sub>

| Column                   | Type        | Key                                                     | Null | Default             |
| ------------------------ | ----------- | ------------------------------------------------------- | ---- | ------------------- |
| `shipment_trip_id`       | uuid        | 🔑 PK                                                   | NN   | `gen_random_uuid()` |
| `dispatch_allocation_id` | uuid        | 🔗 FK → dispatch_allocation.dispatch_allocation_id · UQ | NN   |                     |
| `vehicle_id`             | uuid        | 🔗 FK → vehicle.vehicle_id                              | NN   |                     |
| `driver_id`              | uuid        | 🔗 FK → driver.driver_id                                | NN   |                     |
| `scheduled_by`           | uuid        | 🔗 FK → agency_manager.user_id                          | NN   |                     |
| `status`                 | varchar(20) |                                                         | NN   | `'SCHEDULED'`       |
| `expected_pickup_at`     | timestamptz |                                                         | null |                     |
| `picked_up_at`           | timestamptz |                                                         | null |                     |
| `arrived_at`             | timestamptz |                                                         | null |                     |
| `created_at`             | timestamptz |                                                         | NN   | `now()`             |
| `updated_at`             | timestamptz |                                                         | NN   | `now()`             |

**Constraints**

- `pk_shipment_trip` — PRIMARY KEY (shipment_trip_id)
- `fk_shipment_trip_allocation` — FOREIGN KEY (dispatch_allocation_id) REFERENCES dispatch_allocation(dispatch_allocation_id)
- `fk_shipment_trip_driver` — FOREIGN KEY (driver_id) REFERENCES driver(driver_id)
- `fk_shipment_trip_manager` — FOREIGN KEY (scheduled_by) REFERENCES agency_manager(user_id)
- `fk_shipment_trip_vehicle` — FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id)
- `uq_shipment_trip_allocation` — UNIQUE (dispatch_allocation_id)
- `ck_shipment_trip_status` — CHECK (status IN ('SCHEDULED', 'AT_WAREHOUSE', 'LOADED', 'IN_TRANSIT', 'ARRIVED', 'CANCELLED'))
- `ck_shipment_trip_times` — CHECK (((arrived_at IS NULL) OR (picked_up_at IS NULL) OR (arrived_at >= picked_up_at)))

### `shipment_document`

<sub>File: `03_dispatch_fleet/V3_4__create_shipment_trip.sql`</sub>

| Column             | Type         | Key                                    | Null | Default             |
| ------------------ | ------------ | -------------------------------------- | ---- | ------------------- |
| `document_id`      | uuid         | 🔑 PK                                  | NN   | `gen_random_uuid()` |
| `shipment_trip_id` | uuid         | 🔗 FK → shipment_trip.shipment_trip_id | NN   |                     |
| `document_type`    | varchar(20)  |                                        | NN   |                     |
| `document_number`  | varchar(50)  |                                        | null |                     |
| `barcode`          | varchar(100) | UQ                                     | null |                     |
| `file_url`         | text         |                                        | NN   |                     |
| `created_at`       | timestamptz  |                                        | NN   | `now()`             |

**Constraints**

- `pk_shipment_document` — PRIMARY KEY (document_id)
- `fk_shipment_document_trip` — FOREIGN KEY (shipment_trip_id) REFERENCES shipment_trip(shipment_trip_id) ON DELETE CASCADE
- `uq_shipment_document_barcode` — UNIQUE (barcode)
- `ck_shipment_document_type` — CHECK (document_type IN ('DELIVERY_NOTE', 'INVOICE', 'GATE_PASS', 'OTHER'))

### `pickup_confirmation`

<sub>File: `03_dispatch_fleet/V3_4__create_shipment_trip.sql`</sub>

| Column                   | Type        | Key                                         | Null | Default             |
| ------------------------ | ----------- | ------------------------------------------- | ---- | ------------------- |
| `pickup_confirmation_id` | uuid        | 🔑 PK                                       | NN   | `gen_random_uuid()` |
| `shipment_trip_id`       | uuid        | 🔗 FK → shipment_trip.shipment_trip_id · UQ | NN   |                     |
| `confirmed_by`           | uuid        | 🔗 FK → warehouse_supervisor.user_id        | NN   |                     |
| `confirmed_at`           | timestamptz |                                             | NN   | `now()`             |
| `signature_url`          | text        |                                             | null |                     |
| `remarks`                | text        |                                             | null |                     |

**Constraints**

- `pk_pickup_confirmation` — PRIMARY KEY (pickup_confirmation_id)
- `fk_pickup_confirmation_supervisor` — FOREIGN KEY (confirmed_by) REFERENCES warehouse_supervisor(user_id)
- `fk_pickup_confirmation_trip` — FOREIGN KEY (shipment_trip_id) REFERENCES shipment_trip(shipment_trip_id)
- `uq_pickup_confirmation_trip` — UNIQUE (shipment_trip_id)

### `dispatch_discrepancy`

<sub>File: `03_dispatch_fleet/V3_5__create_dispatch_discrepancy.sql`</sub>

| Column               | Type        | Key                                                 | Null | Default             |
| -------------------- | ----------- | --------------------------------------------------- | ---- | ------------------- |
| `discrepancy_id`     | uuid        | 🔑 PK                                               | NN   | `gen_random_uuid()` |
| `shipment_trip_id`   | uuid        | 🔗 FK → shipment_trip.shipment_trip_id              | NN   |                     |
| `allocation_item_id` | uuid        | 🔗 FK → dispatch_allocation_item.allocation_item_id | null |                     |
| `reported_by`        | uuid        | 🔗 FK → app_user.user_id                            | NN   |                     |
| `issue_type`         | varchar(20) |                                                     | NN   |                     |
| `quantity_affected`  | integer     |                                                     | null |                     |
| `description`        | text        |                                                     | NN   |                     |
| `status`             | varchar(20) |                                                     | NN   | `'OPEN'`            |
| `resolved_by`        | uuid        | 🔗 FK → warehouse_admin.user_id                     | null |                     |
| `resolution_note`    | text        |                                                     | null |                     |
| `reported_at`        | timestamptz |                                                     | NN   | `now()`             |
| `resolved_at`        | timestamptz |                                                     | null |                     |

**Constraints**

- `pk_dispatch_discrepancy` — PRIMARY KEY (discrepancy_id)
- `fk_dispatch_discrepancy_item` — FOREIGN KEY (allocation_item_id) REFERENCES dispatch_allocation_item(allocation_item_id)
- `fk_dispatch_discrepancy_reporter` — FOREIGN KEY (reported_by) REFERENCES app_user(user_id)
- `fk_dispatch_discrepancy_resolver` — FOREIGN KEY (resolved_by) REFERENCES warehouse_admin(user_id)
- `fk_dispatch_discrepancy_trip` — FOREIGN KEY (shipment_trip_id) REFERENCES shipment_trip(shipment_trip_id)
- `ck_dispatch_discrepancy_qty` — CHECK (((quantity_affected IS NULL) OR (quantity_affected > 0)))
- `ck_dispatch_discrepancy_resolved` — CHECK (((status NOT IN ('RESOLVED', 'REJECTED')) OR ((resolved_by IS NOT NULL) AND (resolved_at IS NOT NULL))))
- `ck_dispatch_discrepancy_status` — CHECK (status IN ('OPEN', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED'))
- `ck_dispatch_discrepancy_type` — CHECK (issue_type IN ('SHORTAGE', 'EXCESS', 'DAMAGED', 'WRONG_ITEM', 'OTHER'))

### `delivery_trip`

<sub>File: `03_dispatch_fleet/V3_6__create_delivery_trip.sql`</sub>

| Column         | Type        | Key                            | Null | Default             |
| -------------- | ----------- | ------------------------------ | ---- | ------------------- |
| `trip_id`      | uuid        | 🔑 PK                          | NN   | `gen_random_uuid()` |
| `agency_id`    | uuid        | 🔗 FK → agency.agency_id       | NN   |                     |
| `agent_id`     | uuid        | 🔗 FK → agent.user_id          | NN   |                     |
| `driver_id`    | uuid        | 🔗 FK → driver.driver_id       | null |                     |
| `vehicle_id`   | uuid        | 🔗 FK → vehicle.vehicle_id     | NN   |                     |
| `scheduled_by` | uuid        | 🔗 FK → agency_manager.user_id | NN   |                     |
| `trip_date`    | date        |                                | NN   |                     |
| `status`       | varchar(20) |                                | NN   | `'PLANNED'`         |
| `started_at`   | timestamptz |                                | null |                     |
| `ended_at`     | timestamptz |                                | null |                     |
| `created_at`   | timestamptz |                                | NN   | `now()`             |
| `updated_at`   | timestamptz |                                | NN   | `now()`             |

**Constraints**

- `pk_delivery_trip` — PRIMARY KEY (trip_id)
- `fk_delivery_trip_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `fk_delivery_trip_agent` — FOREIGN KEY (agent_id) REFERENCES agent(user_id)
- `fk_delivery_trip_driver` — FOREIGN KEY (driver_id) REFERENCES driver(driver_id)
- `fk_delivery_trip_manager` — FOREIGN KEY (scheduled_by) REFERENCES agency_manager(user_id)
- `fk_delivery_trip_vehicle` — FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id)
- `ck_delivery_trip_status` — CHECK (status IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
- `ck_delivery_trip_times` — CHECK (((ended_at IS NULL) OR (started_at IS NULL) OR (ended_at >= started_at)))

### `trip_stop`

<sub>File: `03_dispatch_fleet/V3_6__create_delivery_trip.sql`</sub>

| Column               | Type        | Key                             | Null | Default             |
| -------------------- | ----------- | ------------------------------- | ---- | ------------------- |
| `trip_stop_id`       | uuid        | 🔑 PK                           | NN   | `gen_random_uuid()` |
| `trip_id`            | uuid        | 🔗 FK → delivery_trip.trip_id   | NN   |                     |
| `outlet_id`          | uuid        | 🔗 FK → retail_outlet.outlet_id | NN   |                     |
| `stop_sequence`      | integer     |                                 | NN   |                     |
| `planned_arrival_at` | timestamptz |                                 | null |                     |
| `actual_arrival_at`  | timestamptz |                                 | null |                     |
| `completed_at`       | timestamptz |                                 | null |                     |
| `status`             | varchar(20) |                                 | NN   | `'PENDING'`         |
| `failure_reason`     | text        |                                 | null |                     |

**Constraints**

- `pk_trip_stop` — PRIMARY KEY (trip_stop_id)
- `fk_trip_stop_outlet` — FOREIGN KEY (outlet_id) REFERENCES retail_outlet(outlet_id)
- `fk_trip_stop_trip` — FOREIGN KEY (trip_id) REFERENCES delivery_trip(trip_id) ON DELETE CASCADE
- `uq_trip_stop_id_outlet` — UNIQUE (trip_stop_id, outlet_id)
- `uq_trip_stop_outlet` — UNIQUE (trip_id, outlet_id)
- `uq_trip_stop_sequence` — UNIQUE (trip_id, stop_sequence)
- `ck_trip_stop_failure` — CHECK (((status NOT IN ('FAILED', 'SKIPPED')) OR (failure_reason IS NOT NULL)))
- `ck_trip_stop_sequence` — CHECK ((stop_sequence > 0))
- `ck_trip_stop_status` — CHECK (status IN ('PENDING', 'ARRIVED', 'COMPLETED', 'SKIPPED', 'FAILED'))

---

## 04_inventory_retail — Inventory, retail orders, returns & complaints

### `agency_inventory`

<sub>File: `04_inventory_retail/V4_1__create_agency_inventory.sql`</sub>

| Column              | Type        | Key                        | Null | Default             |
| ------------------- | ----------- | -------------------------- | ---- | ------------------- |
| `inventory_id`      | uuid        | 🔑 PK                      | NN   | `gen_random_uuid()` |
| `agency_id`         | uuid        | 🔗 FK → agency.agency_id   | NN   |                     |
| `product_id`        | uuid        | 🔗 FK → product.product_id | NN   |                     |
| `quantity_on_hand`  | integer     |                            | NN   | `0`                 |
| `quantity_reserved` | integer     |                            | NN   | `0`                 |
| `reorder_level`     | integer     |                            | NN   | `0`                 |
| `updated_by`        | uuid        | 🔗 FK → app_user.user_id   | null |                     |
| `updated_at`        | timestamptz |                            | NN   | `now()`             |

**Constraints**

- `pk_agency_inventory` — PRIMARY KEY (inventory_id)
- `fk_agency_inventory_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `fk_agency_inventory_product` — FOREIGN KEY (product_id) REFERENCES product(product_id)
- `fk_agency_inventory_user` — FOREIGN KEY (updated_by) REFERENCES app_user(user_id) ON DELETE SET NULL
- `uq_agency_inventory_product` — UNIQUE (agency_id, product_id)
- `ck_agency_inventory_qty` — CHECK (((quantity_on_hand >= 0) AND (quantity_reserved >= 0) AND (quantity_reserved <= quantity_on_hand) AND (reorder_level >= 0)))

### `agency_stock_movement`

<sub>File: `04_inventory_retail/V4_1__create_agency_inventory.sql`</sub>

| Column           | Type        | Key                                 | Null | Default             |
| ---------------- | ----------- | ----------------------------------- | ---- | ------------------- |
| `movement_id`    | uuid        | 🔑 PK                               | NN   | `gen_random_uuid()` |
| `agency_id`      | uuid        | 🔗 FK → agency_inventory.agency_id  | NN   |                     |
| `product_id`     | uuid        | 🔗 FK → agency_inventory.product_id | NN   |                     |
| `movement_type`  | varchar(20) |                                     | NN   |                     |
| `quantity`       | integer     |                                     | NN   |                     |
| `reference_type` | varchar(30) |                                     | null |                     |
| `reference_id`   | uuid        |                                     | null |                     |
| `performed_by`   | uuid        | 🔗 FK → app_user.user_id            | NN   |                     |
| `note`           | text        |                                     | null |                     |
| `created_at`     | timestamptz |                                     | NN   | `now()`             |

**Constraints**

- `pk_agency_stock_movement` — PRIMARY KEY (movement_id)
- `fk_agency_stock_movement_inventory` — FOREIGN KEY (agency_id, product_id) REFERENCES agency_inventory(agency_id, product_id)
- `fk_agency_stock_movement_user` — FOREIGN KEY (performed_by) REFERENCES app_user(user_id)
- `ck_agency_stock_movement_qty` — CHECK ((quantity > 0))
- `ck_agency_stock_movement_ref` — CHECK (((reference_type IS NULL) = (reference_id IS NULL)))
- `ck_agency_stock_movement_type` — CHECK (movement_type IN ('RECEIVED', 'DELIVERED', 'RETURNED', 'DAMAGED', 'RESERVED', 'RELEASED', 'ADJUSTMENT'))

### `warehouse_report`

<sub>File: `04_inventory_retail/V4_2__create_warehouse_report.sql`</sub>

| Column         | Type         | Key                             | Null | Default             |
| -------------- | ------------ | ------------------------------- | ---- | ------------------- |
| `report_id`    | uuid         | 🔑 PK                           | NN   | `gen_random_uuid()` |
| `warehouse_id` | uuid         | 🔗 FK → warehouse.warehouse_id  | NN   |                     |
| `generated_by` | uuid         | 🔗 FK → warehouse_admin.user_id | NN   |                     |
| `report_type`  | varchar(30)  |                                 | NN   |                     |
| `title`        | varchar(200) |                                 | NN   |                     |
| `period_start` | date         |                                 | NN   |                     |
| `period_end`   | date         |                                 | NN   |                     |
| `file_url`     | text         |                                 | null |                     |
| `generated_at` | timestamptz  |                                 | NN   | `now()`             |

**Constraints**

- `pk_warehouse_report` — PRIMARY KEY (report_id)
- `fk_warehouse_report_admin` — FOREIGN KEY (generated_by) REFERENCES warehouse_admin(user_id)
- `fk_warehouse_report_warehouse` — FOREIGN KEY (warehouse_id) REFERENCES warehouse(warehouse_id)
- `ck_warehouse_report_period` — CHECK ((period_end >= period_start))
- `ck_warehouse_report_type` — CHECK (report_type IN ('DAILY_DISPATCH', 'DISCREPANCY', 'STOCK_SUMMARY', 'MONTHLY'))

### `next_order`

<sub>File: `04_inventory_retail/V4_3__create_next_order.sql`</sub>

| Column                    | Type        | Key                             | Null | Default             |
| ------------------------- | ----------- | ------------------------------- | ---- | ------------------- |
| `next_order_id`           | uuid        | 🔑 PK                           | NN   | `gen_random_uuid()` |
| `outlet_id`               | uuid        | 🔗 FK → retail_outlet.outlet_id | NN   |                     |
| `recorded_by`             | uuid        | 🔗 FK → agent.user_id           | NN   |                     |
| `requested_delivery_date` | date        |                                 | null |                     |
| `status`                  | varchar(20) |                                 | NN   | `'PENDING'`         |
| `notes`                   | text        |                                 | null |                     |
| `created_at`              | timestamptz |                                 | NN   | `now()`             |
| `updated_at`              | timestamptz |                                 | NN   | `now()`             |

**Constraints**

- `pk_next_order` — PRIMARY KEY (next_order_id)
- `fk_next_order_agent` — FOREIGN KEY (recorded_by) REFERENCES agent(user_id)
- `fk_next_order_outlet` — FOREIGN KEY (outlet_id) REFERENCES retail_outlet(outlet_id)
- `uq_next_order_id_outlet` — UNIQUE (next_order_id, outlet_id)
- `ck_next_order_status` — CHECK (status IN ('PENDING', 'APPROVED', 'ALLOCATED', 'DELIVERED', 'CANCELLED'))

### `next_order_item`

<sub>File: `04_inventory_retail/V4_3__create_next_order.sql`</sub>

| Column               | Type    | Key                              | Null | Default             |
| -------------------- | ------- | -------------------------------- | ---- | ------------------- |
| `next_order_item_id` | uuid    | 🔑 PK                            | NN   | `gen_random_uuid()` |
| `next_order_id`      | uuid    | 🔗 FK → next_order.next_order_id | NN   |                     |
| `product_id`         | uuid    | 🔗 FK → product.product_id       | NN   |                     |
| `requested_qty`      | integer |                                  | NN   |                     |

**Constraints**

- `pk_next_order_item` — PRIMARY KEY (next_order_item_id)
- `fk_next_order_item_order` — FOREIGN KEY (next_order_id) REFERENCES next_order(next_order_id) ON DELETE CASCADE
- `fk_next_order_item_product` — FOREIGN KEY (product_id) REFERENCES product(product_id)
- `uq_next_order_item_product` — UNIQUE (next_order_id, product_id)
- `ck_next_order_item_qty` — CHECK ((requested_qty > 0))

### `outlet_return`

<sub>File: `04_inventory_retail/V4_4__create_outlet_return.sql`</sub>

| Column              | Type        | Key                                                  | Null | Default             |
| ------------------- | ----------- | ---------------------------------------------------- | ---- | ------------------- |
| `return_id`         | uuid        | 🔑 PK                                                | NN   | `gen_random_uuid()` |
| `outlet_id`         | uuid        | 🔗 FK → retail_outlet.outlet_id, trip_stop.outlet_id | NN   |                     |
| `recorded_by`       | uuid        | 🔗 FK → agent.user_id                                | NN   |                     |
| `collected_stop_id` | uuid        | 🔗 FK → trip_stop.trip_stop_id                       | null |                     |
| `reason`            | text        |                                                      | NN   |                     |
| `status`            | varchar(20) |                                                      | NN   | `'REQUESTED'`       |
| `created_at`        | timestamptz |                                                      | NN   | `now()`             |
| `collected_at`      | timestamptz |                                                      | null |                     |

**Constraints**

- `pk_outlet_return` — PRIMARY KEY (return_id)
- `fk_outlet_return_agent` — FOREIGN KEY (recorded_by) REFERENCES agent(user_id)
- `fk_outlet_return_outlet` — FOREIGN KEY (outlet_id) REFERENCES retail_outlet(outlet_id)
- `fk_outlet_return_stop` — FOREIGN KEY (collected_stop_id, outlet_id) REFERENCES trip_stop(trip_stop_id, outlet_id)
- `ck_outlet_return_collect` — CHECK (((status = 'REQUESTED') OR ((collected_stop_id IS NOT NULL) AND (collected_at IS NOT NULL))))
- `ck_outlet_return_status` — CHECK (status IN ('REQUESTED', 'COLLECTED', 'ACCEPTED', 'REJECTED'))

### `outlet_return_item`

<sub>File: `04_inventory_retail/V4_4__create_outlet_return.sql`</sub>

| Column           | Type        | Key                             | Null | Default             |
| ---------------- | ----------- | ------------------------------- | ---- | ------------------- |
| `return_item_id` | uuid        | 🔑 PK                           | NN   | `gen_random_uuid()` |
| `return_id`      | uuid        | 🔗 FK → outlet_return.return_id | NN   |                     |
| `product_id`     | uuid        | 🔗 FK → product.product_id      | NN   |                     |
| `quantity`       | integer     |                                 | NN   |                     |
| `item_condition` | varchar(20) |                                 | NN   |                     |

**Constraints**

- `pk_outlet_return_item` — PRIMARY KEY (return_item_id)
- `fk_outlet_return_item_product` — FOREIGN KEY (product_id) REFERENCES product(product_id)
- `fk_outlet_return_item_return` — FOREIGN KEY (return_id) REFERENCES outlet_return(return_id) ON DELETE CASCADE
- `uq_outlet_return_item_line` — UNIQUE (return_id, product_id, item_condition)
- `ck_outlet_return_item_cond` — CHECK (item_condition IN ('EXPIRED', 'DAMAGED', 'WRONG_ITEM', 'OTHER'))
- `ck_outlet_return_item_qty` — CHECK ((quantity > 0))

### `complaint`

<sub>File: `04_inventory_retail/V4_5__create_complaint_feedback.sql`</sub>

| Column            | Type        | Key                             | Null | Default             |
| ----------------- | ----------- | ------------------------------- | ---- | ------------------- |
| `complaint_id`    | uuid        | 🔑 PK                           | NN   | `gen_random_uuid()` |
| `agency_id`       | uuid        | 🔗 FK → agency.agency_id        | NN   |                     |
| `outlet_id`       | uuid        | 🔗 FK → retail_outlet.outlet_id | null |                     |
| `trip_id`         | uuid        | 🔗 FK → delivery_trip.trip_id   | null |                     |
| `raised_by`       | uuid        | 🔗 FK → app_user.user_id        | NN   |                     |
| `complaint_type`  | varchar(30) |                                 | NN   |                     |
| `description`     | text        |                                 | NN   |                     |
| `status`          | varchar(20) |                                 | NN   | `'OPEN'`            |
| `resolution_note` | text        |                                 | null |                     |
| `created_at`      | timestamptz |                                 | NN   | `now()`             |
| `resolved_at`     | timestamptz |                                 | null |                     |

**Constraints**

- `pk_complaint` — PRIMARY KEY (complaint_id)
- `fk_complaint_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `fk_complaint_outlet` — FOREIGN KEY (outlet_id) REFERENCES retail_outlet(outlet_id)
- `fk_complaint_trip` — FOREIGN KEY (trip_id) REFERENCES delivery_trip(trip_id)
- `fk_complaint_user` — FOREIGN KEY (raised_by) REFERENCES app_user(user_id)
- `ck_complaint_resolved` — CHECK (((status NOT IN ('RESOLVED', 'CLOSED')) OR (resolved_at IS NOT NULL)))
- `ck_complaint_status` — CHECK (status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'))
- `ck_complaint_type` — CHECK (complaint_type IN ('LATE_DELIVERY', 'SHORT_DELIVERY', 'DAMAGED_GOODS', 'WRONG_ITEM', 'STAFF_BEHAVIOUR', 'OTHER'))

### `agency_feedback`

<sub>File: `04_inventory_retail/V4_5__create_complaint_feedback.sql`</sub>

| Column           | Type        | Key                                 | Null | Default             |
| ---------------- | ----------- | ----------------------------------- | ---- | ------------------- |
| `feedback_id`    | uuid        | 🔑 PK                               | NN   | `gen_random_uuid()` |
| `agency_id`      | uuid        | 🔗 FK → agency.agency_id            | NN   |                     |
| `submitted_by`   | uuid        | 🔗 FK → agency_manager.user_id      | NN   |                     |
| `rating`         | smallint    |                                     | null |                     |
| `feedback_text`  | text        |                                     | NN   |                     |
| `admin_response` | text        |                                     | null |                     |
| `responded_by`   | uuid        | 🔗 FK → manufacturing_admin.user_id | null |                     |
| `status`         | varchar(20) |                                     | NN   | `'PENDING'`         |
| `created_at`     | timestamptz |                                     | NN   | `now()`             |
| `responded_at`   | timestamptz |                                     | null |                     |

**Constraints**

- `pk_agency_feedback` — PRIMARY KEY (feedback_id)
- `fk_agency_feedback_admin` — FOREIGN KEY (responded_by) REFERENCES manufacturing_admin(user_id)
- `fk_agency_feedback_agency` — FOREIGN KEY (agency_id) REFERENCES agency(agency_id)
- `fk_agency_feedback_manager` — FOREIGN KEY (submitted_by) REFERENCES agency_manager(user_id)
- `ck_agency_feedback_rating` — CHECK (((rating IS NULL) OR ((rating >= 1) AND (rating <= 5))))
- `ck_agency_feedback_responded` — CHECK (((status <> 'RESPONDED') OR ((admin_response IS NOT NULL) AND (responded_by IS NOT NULL))))
- `ck_agency_feedback_status` — CHECK (status IN ('PENDING', 'REVIEWED', 'RESPONDED'))

---

## 05_field_delivery — Field agent, delivery & notifications

### `agent_area_assignment`

<sub>File: `05_field_delivery/V5_1__create_agent_assignment_shift.sql`</sub>

| Column          | Type | Key                              | Null | Default             |
| --------------- | ---- | -------------------------------- | ---- | ------------------- |
| `assignment_id` | uuid | 🔑 PK                            | NN   | `gen_random_uuid()` |
| `agent_id`      | uuid | 🔗 FK → agent.user_id            | NN   |                     |
| `area_id`       | uuid | 🔗 FK → operational_area.area_id | NN   |                     |
| `assigned_by`   | uuid | 🔗 FK → agency_manager.user_id   | NN   |                     |
| `assigned_from` | date |                                  | NN   | `CURRENT_DATE`      |
| `assigned_to`   | date |                                  | null |                     |

**Constraints**

- `pk_agent_area_assignment` — PRIMARY KEY (assignment_id)
- `fk_agent_area_assignment_agent` — FOREIGN KEY (agent_id) REFERENCES agent(user_id)
- `fk_agent_area_assignment_area` — FOREIGN KEY (area_id) REFERENCES operational_area(area_id)
- `fk_agent_area_assignment_manager` — FOREIGN KEY (assigned_by) REFERENCES agency_manager(user_id)
- `ck_agent_area_assignment_dates` — CHECK (((assigned_to IS NULL) OR (assigned_to >= assigned_from)))
- `uq_agent_area_assignment_active` — UNIQUE INDEX (agent_id, area_id) WHERE (assigned_to IS NULL)

### `agent_day_shift`

<sub>File: `05_field_delivery/V5_1__create_agent_assignment_shift.sql`</sub>

| Column          | Type         | Key                   | Null | Default             |
| --------------- | ------------ | --------------------- | ---- | ------------------- |
| `shift_id`      | uuid         | 🔑 PK                 | NN   | `gen_random_uuid()` |
| `agent_id`      | uuid         | 🔗 FK → agent.user_id | NN   |                     |
| `shift_date`    | date         |                       | NN   |                     |
| `check_in_at`   | timestamptz  |                       | NN   |                     |
| `check_out_at`  | timestamptz  |                       | null |                     |
| `check_in_lat`  | numeric(9,6) |                       | null |                     |
| `check_in_lng`  | numeric(9,6) |                       | null |                     |
| `check_out_lat` | numeric(9,6) |                       | null |                     |
| `check_out_lng` | numeric(9,6) |                       | null |                     |

**Constraints**

- `pk_agent_day_shift` — PRIMARY KEY (shift_id)
- `fk_agent_day_shift_agent` — FOREIGN KEY (agent_id) REFERENCES agent(user_id)
- `uq_agent_day_shift_date` — UNIQUE (agent_id, shift_date)
- `ck_agent_day_shift_in` — CHECK (((check_in_lat IS NULL) = (check_in_lng IS NULL)))
- `ck_agent_day_shift_out` — CHECK (((check_out_lat IS NULL) = (check_out_lng IS NULL)))
- `ck_agent_day_shift_times` — CHECK (((check_out_at IS NULL) OR (check_out_at >= check_in_at)))

### `outlet_allocation`

<sub>File: `05_field_delivery/V5_2__create_outlet_allocation.sql`</sub>

| Column          | Type        | Key                                                                        | Null | Default             |
| --------------- | ----------- | -------------------------------------------------------------------------- | ---- | ------------------- |
| `allocation_id` | uuid        | 🔑 PK                                                                      | NN   | `gen_random_uuid()` |
| `outlet_id`     | uuid        | 🔗 FK → next_order.outlet_id, retail_outlet.outlet_id, trip_stop.outlet_id | NN   |                     |
| `next_order_id` | uuid        | 🔗 FK → next_order.next_order_id                                           | null |                     |
| `trip_stop_id`  | uuid        | 🔗 FK → trip_stop.trip_stop_id · UQ                                        | null |                     |
| `created_by`    | uuid        | 🔗 FK → agency_manager.user_id                                             | NN   |                     |
| `status`        | varchar(20) |                                                                            | NN   | `'DRAFT'`           |
| `notes`         | text        |                                                                            | null |                     |
| `created_at`    | timestamptz |                                                                            | NN   | `now()`             |
| `updated_at`    | timestamptz |                                                                            | NN   | `now()`             |

**Constraints**

- `pk_outlet_allocation` — PRIMARY KEY (allocation_id)
- `fk_outlet_allocation_manager` — FOREIGN KEY (created_by) REFERENCES agency_manager(user_id)
- `fk_outlet_allocation_next_order` — FOREIGN KEY (next_order_id, outlet_id) REFERENCES next_order(next_order_id, outlet_id)
- `fk_outlet_allocation_outlet` — FOREIGN KEY (outlet_id) REFERENCES retail_outlet(outlet_id)
- `fk_outlet_allocation_trip_stop` — FOREIGN KEY (trip_stop_id, outlet_id) REFERENCES trip_stop(trip_stop_id, outlet_id)
- `uq_outlet_allocation_stop` — UNIQUE (trip_stop_id)
- `ck_outlet_allocation_status` — CHECK (status IN ('DRAFT', 'CONFIRMED', 'LOADED', 'DELIVERED', 'PARTIALLY_DELIVERED', 'FAILED', 'CANCELLED'))
- `ck_outlet_allocation_stop_set` — CHECK ((status IN ('DRAFT', 'CONFIRMED', 'CANCELLED') OR (trip_stop_id IS NOT NULL)))

### `outlet_allocation_item`

<sub>File: `05_field_delivery/V5_2__create_outlet_allocation.sql`</sub>

| Column               | Type    | Key                                     | Null | Default             |
| -------------------- | ------- | --------------------------------------- | ---- | ------------------- |
| `allocation_item_id` | uuid    | 🔑 PK                                   | NN   | `gen_random_uuid()` |
| `allocation_id`      | uuid    | 🔗 FK → outlet_allocation.allocation_id | NN   |                     |
| `product_id`         | uuid    | 🔗 FK → product.product_id              | NN   |                     |
| `allocated_qty`      | integer |                                         | NN   |                     |
| `delivered_qty`      | integer |                                         | NN   | `0`                 |

**Constraints**

- `pk_outlet_allocation_item` — PRIMARY KEY (allocation_item_id)
- `fk_outlet_allocation_item_allocation` — FOREIGN KEY (allocation_id) REFERENCES outlet_allocation(allocation_id) ON DELETE CASCADE
- `fk_outlet_allocation_item_product` — FOREIGN KEY (product_id) REFERENCES product(product_id)
- `uq_outlet_allocation_item_product` — UNIQUE (allocation_id, product_id)
- `ck_outlet_allocation_item_qty` — CHECK (((allocated_qty > 0) AND (delivered_qty >= 0) AND (delivered_qty <= allocated_qty)))

### `proof_of_delivery`

<sub>File: `05_field_delivery/V5_3__create_proof_of_delivery.sql`</sub>

| Column          | Type         | Key                                 | Null | Default             |
| --------------- | ------------ | ----------------------------------- | ---- | ------------------- |
| `pod_id`        | uuid         | 🔑 PK                               | NN   | `gen_random_uuid()` |
| `trip_stop_id`  | uuid         | 🔗 FK → trip_stop.trip_stop_id · UQ | NN   |                     |
| `captured_by`   | uuid         | 🔗 FK → agent.user_id               | NN   |                     |
| `receiver_name` | varchar(150) |                                     | NN   |                     |
| `signature_url` | text         |                                     | NN   |                     |
| `photo_url`     | text         |                                     | null |                     |
| `latitude`      | numeric(9,6) |                                     | null |                     |
| `longitude`     | numeric(9,6) |                                     | null |                     |
| `delivered_at`  | timestamptz  |                                     | NN   | `now()`             |
| `remarks`       | text         |                                     | null |                     |

**Constraints**

- `pk_proof_of_delivery` — PRIMARY KEY (pod_id)
- `fk_proof_of_delivery_agent` — FOREIGN KEY (captured_by) REFERENCES agent(user_id)
- `fk_proof_of_delivery_stop` — FOREIGN KEY (trip_stop_id) REFERENCES trip_stop(trip_stop_id)
- `uq_proof_of_delivery_stop` — UNIQUE (trip_stop_id)
- `ck_proof_of_delivery_lat` — CHECK (((latitude >= -90) AND (latitude <= 90)))
- `ck_proof_of_delivery_lng` — CHECK (((longitude >= -180) AND (longitude <= 180)))
- `ck_proof_of_delivery_pair` — CHECK (((latitude IS NULL) = (longitude IS NULL)))

### `delivery_issue`

<sub>File: `05_field_delivery/V5_4__create_delivery_issue_trip_report.sql`</sub>

| Column         | Type        | Key                            | Null | Default             |
| -------------- | ----------- | ------------------------------ | ---- | ------------------- |
| `issue_id`     | uuid        | 🔑 PK                          | NN   | `gen_random_uuid()` |
| `trip_id`      | uuid        | 🔗 FK → delivery_trip.trip_id  | NN   |                     |
| `trip_stop_id` | uuid        | 🔗 FK → trip_stop.trip_stop_id | null |                     |
| `reported_by`  | uuid        | 🔗 FK → agent.user_id          | NN   |                     |
| `issue_type`   | varchar(30) |                                | NN   |                     |
| `description`  | text        |                                | NN   |                     |
| `status`       | varchar(20) |                                | NN   | `'OPEN'`            |
| `reviewed_by`  | uuid        | 🔗 FK → agency_manager.user_id | null |                     |
| `reported_at`  | timestamptz |                                | NN   | `now()`             |
| `resolved_at`  | timestamptz |                                | null |                     |

**Constraints**

- `pk_delivery_issue` — PRIMARY KEY (issue_id)
- `fk_delivery_issue_agent` — FOREIGN KEY (reported_by) REFERENCES agent(user_id)
- `fk_delivery_issue_manager` — FOREIGN KEY (reviewed_by) REFERENCES agency_manager(user_id)
- `fk_delivery_issue_stop` — FOREIGN KEY (trip_stop_id) REFERENCES trip_stop(trip_stop_id)
- `fk_delivery_issue_trip` — FOREIGN KEY (trip_id) REFERENCES delivery_trip(trip_id)
- `ck_delivery_issue_resolved` — CHECK (((status <> 'RESOLVED') OR (resolved_at IS NOT NULL)))
- `ck_delivery_issue_status` — CHECK (status IN ('OPEN', 'REVIEWED', 'RESOLVED'))
- `ck_delivery_issue_type` — CHECK (issue_type IN ('VEHICLE_BREAKDOWN', 'ROAD_BLOCKED', 'OUTLET_CLOSED', 'ACCIDENT', 'STOCK_SHORTAGE', 'OTHER'))

### `trip_report`

<sub>File: `05_field_delivery/V5_4__create_delivery_issue_trip_report.sql`</sub>

| Column           | Type        | Key                                | Null | Default             |
| ---------------- | ----------- | ---------------------------------- | ---- | ------------------- |
| `trip_report_id` | uuid        | 🔑 PK                              | NN   | `gen_random_uuid()` |
| `trip_id`        | uuid        | 🔗 FK → delivery_trip.trip_id · UQ | NN   |                     |
| `submitted_by`   | uuid        | 🔗 FK → agent.user_id              | NN   |                     |
| `summary`        | text        |                                    | null |                     |
| `report_url`     | text        |                                    | null |                     |
| `submitted_at`   | timestamptz |                                    | NN   | `now()`             |
| `reviewed_by`    | uuid        | 🔗 FK → agency_manager.user_id     | null |                     |
| `reviewed_at`    | timestamptz |                                    | null |                     |

**Constraints**

- `pk_trip_report` — PRIMARY KEY (trip_report_id)
- `fk_trip_report_agent` — FOREIGN KEY (submitted_by) REFERENCES agent(user_id)
- `fk_trip_report_manager` — FOREIGN KEY (reviewed_by) REFERENCES agency_manager(user_id)
- `fk_trip_report_trip` — FOREIGN KEY (trip_id) REFERENCES delivery_trip(trip_id)
- `uq_trip_report_trip` — UNIQUE (trip_id)
- `ck_trip_report_content` — CHECK (((summary IS NOT NULL) OR (report_url IS NOT NULL)))
- `ck_trip_report_review` — CHECK (((reviewed_by IS NULL) = (reviewed_at IS NULL)))

### `retail_shop_proposal`

<sub>File: `05_field_delivery/V5_5__create_retail_shop_proposal.sql`</sub>

| Column              | Type         | Key                                  | Null | Default             |
| ------------------- | ------------ | ------------------------------------ | ---- | ------------------- |
| `proposal_id`       | uuid         | 🔑 PK                                | NN   | `gen_random_uuid()` |
| `proposed_by`       | uuid         | 🔗 FK → agent.user_id                | NN   |                     |
| `area_id`           | uuid         | 🔗 FK → operational_area.area_id     | NN   |                     |
| `shop_name`         | varchar(150) |                                      | NN   |                     |
| `shop_type`         | varchar(30)  |                                      | NN   |                     |
| `owner_name`        | varchar(150) |                                      | null |                     |
| `contact_number`    | varchar(20)  |                                      | NN   |                     |
| `address`           | text         |                                      | NN   |                     |
| `latitude`          | numeric(9,6) |                                      | null |                     |
| `longitude`         | numeric(9,6) |                                      | null |                     |
| `status`            | varchar(20)  |                                      | NN   | `'PENDING'`         |
| `reviewed_by`       | uuid         | 🔗 FK → agency_manager.user_id       | null |                     |
| `review_note`       | text         |                                      | null |                     |
| `created_outlet_id` | uuid         | 🔗 FK → retail_outlet.outlet_id · UQ | null |                     |
| `created_at`        | timestamptz  |                                      | NN   | `now()`             |
| `reviewed_at`       | timestamptz  |                                      | null |                     |

**Constraints**

- `pk_retail_shop_proposal` — PRIMARY KEY (proposal_id)
- `fk_retail_shop_proposal_agent` — FOREIGN KEY (proposed_by) REFERENCES agent(user_id)
- `fk_retail_shop_proposal_area` — FOREIGN KEY (area_id) REFERENCES operational_area(area_id)
- `fk_retail_shop_proposal_manager` — FOREIGN KEY (reviewed_by) REFERENCES agency_manager(user_id)
- `fk_retail_shop_proposal_outlet` — FOREIGN KEY (created_outlet_id) REFERENCES retail_outlet(outlet_id)
- `uq_retail_shop_proposal_outlet` — UNIQUE (created_outlet_id)
- `ck_retail_shop_proposal_approved` — CHECK (((status <> 'APPROVED') OR (created_outlet_id IS NOT NULL)))
- `ck_retail_shop_proposal_lat` — CHECK (((latitude >= -90) AND (latitude <= 90)))
- `ck_retail_shop_proposal_lng` — CHECK (((longitude >= -180) AND (longitude <= 180)))
- `ck_retail_shop_proposal_pair` — CHECK (((latitude IS NULL) = (longitude IS NULL)))
- `ck_retail_shop_proposal_review` — CHECK (((status = 'PENDING') OR ((reviewed_by IS NOT NULL) AND (reviewed_at IS NOT NULL))))
- `ck_retail_shop_proposal_status` — CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))
- `ck_retail_shop_proposal_type` — CHECK (shop_type IN ('GROCERY', 'SUPERMARKET', 'PHARMACY', 'BAKERY', 'OTHER'))

### `location_log`

<sub>File: `05_field_delivery/V5_6__create_location_log.sql`</sub>

| Column        | Type         | Key                           | Null | Default                        |
| ------------- | ------------ | ----------------------------- | ---- | ------------------------------ |
| `log_id`      | bigint       | 🔑 PK                         | NN   | `GENERATED ALWAYS AS IDENTITY` |
| `agent_id`    | uuid         | 🔗 FK → agent.user_id         | NN   |                                |
| `trip_id`     | uuid         | 🔗 FK → delivery_trip.trip_id | null |                                |
| `latitude`    | numeric(9,6) |                               | NN   |                                |
| `longitude`   | numeric(9,6) |                               | NN   |                                |
| `speed_kmh`   | numeric(5,2) |                               | null |                                |
| `accuracy_m`  | numeric(6,2) |                               | null |                                |
| `recorded_at` | timestamptz  |                               | NN   |                                |

**Constraints**

- `pk_location_log` — PRIMARY KEY (log_id)
- `fk_location_log_agent` — FOREIGN KEY (agent_id) REFERENCES agent(user_id)
- `fk_location_log_trip` — FOREIGN KEY (trip_id) REFERENCES delivery_trip(trip_id)
- `ck_location_log_acc` — CHECK (((accuracy_m IS NULL) OR (accuracy_m >= 0)))
- `ck_location_log_lat` — CHECK (((latitude >= -90) AND (latitude <= 90)))
- `ck_location_log_lng` — CHECK (((longitude >= -180) AND (longitude <= 180)))
- `ck_location_log_speed` — CHECK (((speed_kmh IS NULL) OR (speed_kmh >= 0)))

### `notification`

<sub>File: `05_field_delivery/V5_7__create_notification.sql`</sub>

| Column              | Type         | Key                      | Null | Default             |
| ------------------- | ------------ | ------------------------ | ---- | ------------------- |
| `notification_id`   | uuid         | 🔑 PK                    | NN   | `gen_random_uuid()` |
| `user_id`           | uuid         | 🔗 FK → app_user.user_id | NN   |                     |
| `notification_type` | varchar(30)  |                          | NN   |                     |
| `title`             | varchar(150) |                          | NN   |                     |
| `message`           | text         |                          | NN   |                     |
| `reference_type`    | varchar(30)  |                          | null |                     |
| `reference_id`      | uuid         |                          | null |                     |
| `is_read`           | boolean      |                          | NN   | `false`             |
| `created_at`        | timestamptz  |                          | NN   | `now()`             |
| `read_at`           | timestamptz  |                          | null |                     |

**Constraints**

- `pk_notification` — PRIMARY KEY (notification_id)
- `fk_notification_user` — FOREIGN KEY (user_id) REFERENCES app_user(user_id) ON DELETE CASCADE
- `ck_notification_read` — CHECK ((is_read = (read_at IS NOT NULL)))
- `ck_notification_ref` — CHECK (((reference_type IS NULL) = (reference_id IS NULL)))
- `ck_notification_type` — CHECK (notification_type IN ('LOW_STOCK', 'ORDER_UPDATE', 'DISPATCH_SCHEDULED', 'TRIP_ASSIGNED', 'DISCREPANCY', 'COMPLAINT', 'PROPOSAL_REVIEWED', 'SYSTEM'))

---

## Views (04_inventory_retail/R\_\_reporting_views.sql)

- **`v_agency_complaint_summary`**: agency_id, agency_name, total_complaints, open_complaints, last_complaint_at
- **`v_agency_stock_status`**: agency_id, agency_name, product_id, product_name, quantity_on_hand, quantity_reserved, available_qty, reorder_level, needs_reorder
- **`v_manufacturer_stock`**: product_id, product_code, product_name, total_qty, reserved_qty, available_qty, below_minimum
