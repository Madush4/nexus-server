# Nexus — Database Migrations Guide (Flyway + PostgreSQL)

The database is defined only by the Flyway migrations in
`src/main/resources/db/migration`. Hibernate never creates or changes tables.

Full column-by-column reference with every PK / FK / UNIQUE / CHECK: [`DATABASE_SCHEMA.md`](DATABASE_SCHEMA.md)

---

## 1. File structure

```
nexus-server/
├── pom.xml
├── docs/
│   ├── DB_MIGRATIONS.md          ← this guide
│   └── DATABASE_SCHEMA.md        ← generated table reference
└── src/main/resources/
    ├── application.properties
    └── db/migration/
        ├── V1__init_common.sql                         shared trigger function
        │
        ├── 01_core/
        │   ├── V1_1__create_app_user.sql               app_user
        │   ├── V1_2__create_product.sql                product
        │   ├── V1_3__create_agency_area_outlet.sql     agency, operational_area, retail_outlet
        │   ├── V1_4__create_warehouse.sql              warehouse
        │   ├── V1_5__create_user_role_profiles.sql     manufacturing_admin, warehouse_admin,
        │   │                                           warehouse_supervisor, agency_manager, agent
        │   ├── V1_6__create_audit_log.sql              audit_log
        │   ├── V1_7__add_created_by_and_deactivation.sql  created_by / deactivated_at / deactivated_by
        │   │                                           on warehouse, agency, app_user (soft delete)
        │   └── V1_8__add_super_admin.sql               super_admin (+ SUPER_ADMIN role)
        │
        ├── 02_manufacturer/
        │   ├── V2_1__create_sap_report.sql             sap_report, sap_report_item
        │   ├── V2_2__create_manufacturer_inventory.sql manufacturer_inventory, manufacturer_stock_movement
        │   ├── V2_3__create_agency_order.sql           agency_order, agency_order_item
        │   └── V2_4__create_warehouse_handover.sql     warehouse_handover, warehouse_handover_item
        │
        ├── 03_dispatch_fleet/
        │   ├── V3_1__create_driver_vehicle.sql         driver, vehicle, vehicle_maintenance
        │   ├── V3_2__create_dispatch_schedule.sql      dispatch_schedule, dispatch_allocation,
        │   │                                           dispatch_allocation_item
        │   ├── V3_3__create_dispatch_review.sql        dispatch_review
        │   ├── V3_4__create_shipment_trip.sql          shipment_trip, shipment_document, pickup_confirmation
        │   ├── V3_5__create_dispatch_discrepancy.sql   dispatch_discrepancy
        │   └── V3_6__create_delivery_trip.sql          delivery_trip, trip_stop
        │
        ├── 04_inventory_retail/
        │   ├── V4_1__create_agency_inventory.sql       agency_inventory, agency_stock_movement
        │   ├── V4_2__create_warehouse_report.sql       warehouse_report
        │   ├── V4_3__create_next_order.sql             next_order, next_order_item
        │   ├── V4_4__create_outlet_return.sql          outlet_return, outlet_return_item
        │   ├── V4_5__create_complaint_feedback.sql     complaint, agency_feedback
        │   └── R__reporting_views.sql                  3 views (repeatable)
        │
        └── 05_field_delivery/
            ├── V5_1__create_agent_assignment_shift.sql agent_area_assignment, agent_day_shift
            ├── V5_2__create_outlet_allocation.sql      outlet_allocation, outlet_allocation_item
            ├── V5_3__create_proof_of_delivery.sql      proof_of_delivery
            ├── V5_4__create_delivery_issue_trip_report.sql  delivery_issue, trip_report
            ├── V5_5__create_retail_shop_proposal.sql   retail_shop_proposal
            ├── V5_6__create_location_log.sql           location_log
            └── V5_7__create_notification.sql           notification
```

**Totals:** 53 tables, 3 views, 32 migration files.

### Why the folders are numbered like this
Flyway runs files by **version number**, not by folder name, and it scans sub-folders automatically.
The folders are ordered so that **every FK points to a table created earlier**:

```
01_core ─▶ 02_manufacturer ─▶ 03_dispatch_fleet ─▶ 04_inventory_retail ─▶ 05_field_delivery
(users,     (SAP report,        (handover → schedule   (stock ledger,          (allocations,
 agency,     agency order,        → allocation →         orders, returns         POD, GPS log,
 outlet,     handover)            shipment & delivery    — returns point at      notifications)
 product)                         trips, trip_stop)      trip_stop)
```

A module may only add FKs to tables in its own folder or in a **lower-numbered** folder.

---

## 2. Modules

| Folder | Tables | What the tables cover |
|---|---|---|
| `01_core` | 13 | Users + role subclasses (incl. super_admin), product, agency, area, outlet, warehouse, audit log |
| `02_manufacturer` | 8 | SAP/ERP report, manufacturer stock, agency orders, warehouse handover |
| `03_dispatch_fleet` | 13 | Drivers, vehicles, maintenance, dispatch schedule/allocation/items, review, shipment trip + docs + pickup, discrepancies, delivery trips + stops (route) |
| `04_inventory_retail` | 9 + 3 views | Agency inventory + stock ledger, warehouse reports, retail next-orders, returns, complaints, agency feedback, reporting views |
| `05_field_delivery` | 10 | Agent area assignment, day shifts, outlet allocations, proof of delivery, delivery issues, trip reports, shop proposals, GPS location log, notifications |

`01_core` is the **critical path**: every other module's FKs depend on it, so it must be merged first.

### Cross-module links (agree these in the API contract)
| From → To | Link |
|---|---|
| `02_manufacturer` → `03_dispatch_fleet` | `warehouse_handover` / `agency_order_item` feed `dispatch_schedule` / `dispatch_allocation_item` |
| `03_dispatch_fleet` → `04_inventory_retail` | `dispatch_allocation_item.received_qty` → `agency_stock_movement (RECEIVED)` |
| `03_dispatch_fleet` → `05_field_delivery` | `trip_stop` is used by `outlet_allocation`, `proof_of_delivery`, `delivery_issue` |
| `05_field_delivery` → `03_dispatch_fleet` | `location_log` is read by real-time monitoring / route replay |
| every module → `05_field_delivery` | insert into `notification` |
| every module → `01_core` | insert into `audit_log` |

---

## 3. Team rules for migrations

1. **Never edit a migration after it is merged** (into `db-configuration`, `dev` or `main`). Flyway stores a checksum, so a changed file makes every teammate's app fail on start-up, and their tables would no longer match. To change a table, add a **new** migration. Before merging, you may edit freely — reset your local DB with `docker compose down -v`.
2. **Initial schema:** each folder has its own version prefix: `01_core` = `V1_x`, `02_manufacturer` = `V2_x`, `03_dispatch_fleet` = `V3_x`, `04_inventory_retail` = `V4_x`, `05_field_delivery` = `V5_x`.
3. **After the first shared release**, name every new migration with a **timestamp version** inside your own folder. This stops two people picking the same number:
   `V2026_11_20_1430__add_vehicle_fuel_type.sql`
4. **Need a column in another module's table?** Add the new migration in **that table's folder** (agree it with whoever works on that module).
5. **Merge order for the first PRs:** `01_core` → `02` → `03` → `04` → `05`.
6. **Repeatable migrations (`R__*.sql`)** hold views only. Edit them in place, and Flyway re-runs them whenever the content changes.
7. **Naming conventions:** snake_case everywhere; constraints are named `pk_<table>`, `fk_<table>_<target>`, `uq_<table>_<cols>`, `ck_<table>_<rule>`, `idx_<table>_<cols>`.
8. **Types:** `UUID` PKs with `gen_random_uuid()` (`BIGINT IDENTITY` only for high-volume logs), `TIMESTAMPTZ` for time, `NUMERIC(p,s)` for money/weights, `VARCHAR(n)` + `CHECK` for statuses.
9. **Index every FK column.** PostgreSQL does not create these automatically.

---

## 4. Configuration (application.properties)

Setup steps (Docker, `.env`, pgAdmin) are in the [`README`](../README.md). The database settings:

```properties
spring.config.import=optional:file:.env[.properties]

spring.datasource.url=jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5433}/${DB_NAME:nexus}
spring.datasource.username=${DB_USER:nexus}
spring.datasource.password=${DB_PASSWORD:nexus_dev_pw}

spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
spring.flyway.validate-on-migrate=true
spring.flyway.clean-disabled=true

# Hibernate must only CHECK the schema, never change it
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false
```

PostgreSQL 18 runs in Docker on host port **5433** (values come from your `.env`).

Local only, when you pull a teammate's lower-numbered migration after yours already ran:
`spring.flyway.out-of-order=true` (keep this OFF in shared/production environments).

---

## 5. Design decisions worth knowing

- **One `app_user` table with role subclasses** (EER disjoint specialization). Each subclass has a fixed `role` column and a composite FK `(user_id, role) → app_user(user_id, role)`, so the database itself refuses an `agent` row for a user whose role isn't `AGENT`.
- **Composite FKs keep related rows consistent:**
  - `dispatch_allocation(order_id, agency_id)` → `agency_order`, so the agency must match the order.
  - `outlet_allocation(trip_stop_id, outlet_id)` and `(next_order_id, outlet_id)`, so the order and the stop must be for the same outlet.
  - `outlet_return(collected_stop_id, outlet_id)`, so the return must be collected at that outlet's stop.
  - `agency_stock_movement(agency_id, product_id)` → `agency_inventory`, so stock can only move for a stocked product.
- **Derived values are not stored:** available stock = on_hand − reserved, and complaint totals live in views (`v_agency_stock_status`, `v_manufacturer_stock`, `v_agency_complaint_summary`).
- **GPS decision:** coordinates are stored only where a feature needs them:
  - `agency`, `warehouse`, `retail_outlet`: route optimisation and the map.
  - `retail_shop_proposal`: captured on site, then copied to the outlet when approved.
  - `proof_of_delivery`: proves the agent was at the shop.
  - `agent_day_shift`: check-in/out position.
  - `location_log`: live tracking history.

  **No Google Maps URL is stored.** The frontend builds it from the coordinates: `https://www.google.com/maps?q=<lat>,<lng>`.
- **Role hierarchy:** SUPER_ADMIN adds/deactivates MANUFACTURING_ADMIN (`manufacturing_admin.created_by` -> `super_admin`); MANUFACTURING_ADMIN adds/deactivates warehouses, agencies, warehouse admins and agency managers. Only one ACTIVE super admin is allowed (partial unique index).
- **Remove = deactivate (soft delete):** `is_active = false` / `account_status = 'INACTIVE'` plus `deactivated_at` + `deactivated_by`. Hard DELETE is blocked by FKs so history is kept.
- **Drivers are not users.** They don't log in. The agent uses the mobile app.