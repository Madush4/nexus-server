# Nexus — Database Setup (PostgreSQL + Flyway + Spring Boot)

You do **not** create tables by hand. Flyway runs every file in
`src/main/resources/db/migration` the first time Spring Boot starts and
creates all **53 tables + 3 views**. On later starts it only runs new files.

PostgreSQL **18** runs in Docker on host port **5433**, so it never clashes
with a PostgreSQL already installed on your laptop (which usually uses 5432).

---

## 1. Files involved

These are already in the repo — you only create `.env` yourself:

```
nexus-server/
├── pom.xml                          dependencies (JPA, Flyway, PostgreSQL driver)
├── compose.yaml                     local PostgreSQL 18 in Docker
├── .env.example                     template — copy to .env
├── .env                             YOUR copy (git-ignored, never committed)
├── docs/
│   ├── DB_SETUP.md                  this guide
│   ├── DB_MIGRATIONS.md             migration structure + team rules
│   └── DATABASE_SCHEMA.md           every table, PK/FK/constraints
└── src/main/resources/
    ├── application.properties       datasource + Flyway settings
    └── db/migration/
        ├── V1__init_common.sql
        ├── 01_core/                 V1_1 … V1_8
        ├── 02_manufacturer/         V2_1 … V2_4
        ├── 03_dispatch_fleet/       V3_1 … V3_6
        ├── 04_inventory_retail/     V4_1 … V4_5 + R__reporting_views.sql
        └── 05_field_delivery/       V5_1 … V5_7
```

`.gitignore` already ignores `.env` (and keeps `.env.example`).

---

## 2. Create the `.env` file

```bash
cp .env.example .env        # Windows CMD: copy .env.example .env
```

```dotenv
DB_HOST=localhost
DB_PORT=5433
DB_NAME=nexus
DB_USER=nexus
DB_PASSWORD=change_me       # your own password: letters, numbers, _ and - only
```

Spring Boot and Docker both read this file. Set the password **before** the
first `docker compose up` — Docker only applies it when the database is first created.

---

## 3. Start PostgreSQL

### Option A — Docker (recommended, same for everyone)

Open **Docker Desktop** first (wait for "Engine running"), then:

```bash
docker compose up -d
docker compose ps           # wait for: Up (healthy)   0.0.0.0:5433->5432/tcp
```

This creates an empty database `nexus` owned by user `nexus`.

### Option B — no Docker, using PostgreSQL installed on your machine (13 or newer)

In pgAdmin, connect to your local server as `postgres`, open the **Query Tool** and run
(use the same password as in `.env`):

```sql
CREATE USER nexus WITH PASSWORD 'change_me';
CREATE DATABASE nexus OWNER nexus;
```

Then set `DB_PORT=5432` in your `.env`.

---

## 4. Run Spring Boot — Flyway creates the tables

| Windows                    | macOS                    |
| -------------------------- | ------------------------ |
| `mvnw.cmd spring-boot:run` | `./mvnw spring-boot:run` |

Or run `NexusServerApplication` from IntelliJ. In the log you should see:

```
Successfully validated 32 migrations
Migrating schema "public" to version "1 - init common"
Migrating schema "public" to version "1.1 - create app user"
...
Migrating schema "public" to version "5.7 - create notification"
Migrating schema "public" with repeatable migration "reporting views"
Successfully applied 32 migrations to schema "public"
```

Flyway may print a warning that PostgreSQL 18 is newer than it officially
supports — that is only a warning; the migrations still run.

---

## 5. Check it worked

### pgAdmin

**Servers → Register → Server…**

| Field                | Value                          |
| -------------------- | ------------------------------ |
| Name                 | `Nexus (Docker)`               |
| Host                 | `localhost`                    |
| Port                 | `5433` (Option B: `5432`)      |
| Maintenance database | `nexus`                        |
| Username             | `nexus`                        |
| Password             | your `DB_PASSWORD` from `.env` |

Tables: **Databases → nexus → Schemas → public → Tables**. Then open the Query Tool:

```sql
SELECT count(*) FROM pg_tables WHERE schemaname = 'public';   -- 54 (53 + flyway_schema_history)
SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank;
```

### Terminal (optional, Docker only)

```bash
docker exec -it nexus-postgres psql -U nexus -d nexus -c "\dt"
```

---

## How the connection works

| Setting (application.properties)                       | What it does                                                                                          |
| ------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `spring.config.import=optional:file:.env[.properties]` | loads `DB_*` values from `.env`                                                                       |
| `spring.datasource.url / username / password`          | JDBC connection to PostgreSQL (`localhost:5433/nexus`)                                                |
| `spring.flyway.locations=classpath:db/migration`       | Flyway scans this folder **and its sub-folders**                                                      |
| `spring.flyway.clean-disabled=true`                    | stops anyone wiping the database by accident                                                          |
| `spring.jpa.hibernate.ddl-auto=validate`               | Hibernate only **checks** your `@Entity` classes against the tables; it never creates or changes them |

---

## Common problems

| Error                                               | Fix                                                                                                                                                   |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Connection refused` / pgAdmin "connection timeout" | Docker Desktop isn't running, or the DB isn't up → open Docker Desktop, then `docker compose up -d`                                                   |
| `port is already allocated`                         | Something else uses 5433 → change `DB_PORT` in `.env`, then `docker compose up -d`                                                                    |
| `password authentication failed`                    | `.env` password differs from the one the database was first created with → `docker compose down -v` then `up -d` (deletes local data)                 |
| `Validate failed: Migration checksum mismatch`      | A migration that already ran was edited. If it's merged: revert and add a new migration. If it's only local: `docker compose down -v` and start again |
| `Schema-validation: missing column/table`           | Your `@Entity` doesn't match the SQL → fix the entity (or add a new migration). Don't switch `ddl-auto` to `update`                                   |
| `Detected resolved migration not applied`           | A teammate added a lower version than your latest → locally add `spring.flyway.out-of-order=true`                                                     |

## Start completely fresh (local only)

```bash
docker compose down -v      # deletes the database volume
docker compose up -d
./mvnw spring-boot:run      # Windows: mvnw.cmd spring-boot:run — Flyway recreates everything
```
