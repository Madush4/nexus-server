# Nexus Server

Backend API and database for **Nexus — Smart Logistics & Delivery Operations Platform** (IN2901, Team Nexus).

| | |
|---|---|
| Language | Java 25 |
| Framework | Spring Boot 4.1 (Web MVC, Data JPA, Validation) |
| Database | PostgreSQL 18 (runs in Docker) |
| Migrations | Flyway |
| Build | Maven (wrapper included) |

---

## Prerequisites

Install these once:

| Tool | Check it works |
|---|---|
| **JDK 25** | `java -version` → `25…` |
| **Docker Desktop** (must be running) | `docker --version` |
| **Git** | `git --version` |
| pgAdmin 4 *(optional, to browse the DB)* | — |

> You do **not** need to install PostgreSQL — Docker runs it for you.

---

## Quick start

### 1. Clone and switch to `dev`

```bash
git clone <repo-url>
cd nexus-server
git checkout dev
```

### 2. Create your `.env`

```bash
cp .env.example .env          # Windows CMD: copy .env.example .env
```

```dotenv
DB_HOST=localhost
DB_PORT=5433
DB_NAME=nexus
DB_USER=nexus
DB_PASSWORD=change_me         # pick your own (letters, numbers, _ and - only)
```

`.env` is git-ignored — it stays on your laptop and is **never committed**.

### 3. Start the database

Open **Docker Desktop** first, then:

```bash
docker compose up -d
docker compose ps             # wait for: nexus-postgres  Up (healthy)  0.0.0.0:5433->5432
```

On the first run Docker creates the database `nexus` and user `nexus` using your `.env` values.

### 4. Run the backend

| Windows | macOS |
|---|---|
| `mvnw.cmd spring-boot:run` | `./mvnw spring-boot:run` |

Or press **Run** on `NexusServerApplication` in IntelliJ.

On start-up **Flyway creates all the tables automatically**. Look for this in the log:

```
Successfully applied N migrations to schema "public"
```

The API runs on **http://localhost:8080**.

---

## Database

### Ports

| Who connects | Host | Port |
|---|---|---|
| Spring Boot (IntelliJ / mvnw), pgAdmin | `localhost` | **5433** |
| `backend` container (inside Docker) | `postgres` | 5432 |
| PostgreSQL installed on your laptop (if any) | `localhost` | 5432 — not used by this project |

We use **5433** so it never clashes with a PostgreSQL already installed on your machine.

### Connect with pgAdmin

**Servers → Register → Server…**

| Field | Value |
|---|---|
| Name | `Nexus (Docker)` |
| Host | `localhost` |
| Port | `5433` |
| Maintenance database | `nexus` |
| Username | `nexus` |
| Password | your `DB_PASSWORD` from `.env` |

Tables: **Databases → nexus → Schemas → public → Tables**

Quick check (Query Tool):

```sql
SELECT count(*) FROM pg_tables WHERE schemaname = 'public';
SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank;
```

### Migrations (Flyway)

All tables are defined **only** in SQL files under `src/main/resources/db/migration`.
Hibernate never creates or changes tables (`spring.jpa.hibernate.ddl-auto=validate`).

```
db/migration/
├── V1__init_common.sql
├── 01_core/              V1_x   users & roles, product, agency, area, outlet, warehouse, audit log
├── 02_manufacturer/      V2_x   SAP report, manufacturer stock, agency orders, warehouse handover
├── 03_dispatch_fleet/    V3_x   drivers, vehicles, dispatch, shipment trips, delivery trips & stops
├── 04_inventory_retail/  V4_x   agency stock, outlet orders, returns, complaints, report views
└── 05_field_delivery/    V5_x   agent areas & shifts, outlet allocations, POD, GPS log, notifications
```

**Rules**

1. **Never edit a migration after it is merged.** Flyway checksums every file — changing one breaks everyone's start-up. Add a new migration instead.
2. Put new migrations in your module's folder. After the first release, use a timestamp version so numbers never clash:
   `V2026_11_20_1430__add_vehicle_fuel_type.sql`
3. Need a column in another module's table? Ask that module's owner to add the migration.
4. Views go in `R__*.sql` (repeatable) — edit those in place.

Full table reference: [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md) · Migration guide: [`docs/DB_MIGRATIONS.md`](docs/DB_MIGRATIONS.md)

---

## Docker commands

| Command | What it does |
|---|---|
| `docker compose up -d` | Start the database (normal daily use) |
| `docker compose ps` | Show status and ports |
| `docker compose logs postgres` | Database logs |
| `docker compose down` | Stop (data is kept) |
| `docker compose down -v` | Stop **and delete all local data** — fresh start |
| `docker compose --profile app up -d --build` | Run database **and** backend in Docker |

---

## Project structure

```
nexus-server/
├── .mvn/                         Maven wrapper
├── docs/                         DB setup, migration guide, schema reference
├── src/
│   ├── main/
│   │   ├── java/com/nexus/...    application code
│   │   └── resources/
│   │       ├── application.properties
│   │       └── db/migration/     Flyway SQL migrations
│   └── test/
├── .dockerignore
├── .env.example                  template — copy to .env
├── .gitattributes                line endings (LF for mvnw, CRLF for .cmd)
├── .gitignore
├── compose.yaml                  local PostgreSQL 18 (+ optional backend)
├── Dockerfile                    builds the backend image (Java 25)
├── mvnw / mvnw.cmd               Maven wrapper (macOS / Windows)
└── pom.xml
```

---

## Git workflow

```
main
 └── dev                          integration branch — always runnable
      ├── chore/<task>            setup / config work
      ├── feature/<task>          new features
      └── db-configuration        database work
           └── db/<topic>         one branch per migration module
```

1. Branch from the latest parent: `git checkout dev && git pull`
2. Commit using [Conventional Commits](https://www.conventionalcommits.org):
   `feat(db): …` · `fix: …` · `chore: …` · `docs: …`
3. **Before opening a PR**, start from an empty DB and check it runs:
   ```bash
   docker compose down -v && docker compose up -d
   ./mvnw spring-boot:run            # Windows: mvnw.cmd spring-boot:run
   ```
4. Open the PR into the parent branch (`db/<topic>` → `db-configuration` → `dev`).
5. Run `git status` before every commit — **`.env` must never appear**.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `Connection refused` / pgAdmin timeout | Docker Desktop isn't running, or the DB isn't up → `docker compose up -d` |
| `port is already allocated` | Something else uses 5433 → change `DB_PORT` in `.env`, then `docker compose up -d` |
| `password authentication failed` | `.env` changed after the DB was first created → `docker compose down -v` then `up -d` (deletes local data) |
| `Migration checksum mismatch` | An already-applied migration was edited. Revert it and add a new migration. Local only: `docker compose down -v` |
| `Detected resolved migration not applied` | A teammate added a lower version → locally set `spring.flyway.out-of-order=true` |
| `Schema-validation: missing table/column` | Your `@Entity` doesn't match the SQL — fix the entity or add a migration (don't use `ddl-auto=update`) |
| `./mvnw: Permission denied` (macOS) | `chmod +x mvnw` |
| `./mvnw: not found` in Docker build | Windows line endings → make sure `.gitattributes` is committed, then `git add --renormalize .` |
| Wrong Java version | `./mvnw -v` must show Java 25 → set `JAVA_HOME` / IntelliJ Project SDK to 25 |

---

## Team

**Team Nexus — Group 9** · IN2901 Software Development Project · University of Moratuwa
