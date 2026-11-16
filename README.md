# IN2901 Manufacturer-Centric Distribution Management System — Backend

Spring Boot 3 (Java 21) backend configured with **Neon PostgreSQL** and **Flyway** database migrations for Team Nexus.

## Tech Stack
- **Java 21** & **Spring Boot 3.4**
- **Spring Data JPA** (Hibernate with `ddl-auto=validate`)
- **Flyway** (`flyway-core` & `flyway-database-postgresql`)
- **PostgreSQL JDBC Driver** (for Neon PostgreSQL)

## Getting Started

### 1. Set Environment Variables
Obtain your direct connection details from the Neon project dashboard (`manufacturer-distribution-system`) and export them in your terminal or IDE run configuration:

```bash
export DB_URL="jdbc:postgresql://YOUR_HOST:5432/neondb?sslmode=require"
export DB_USERNAME="your_username"
export DB_PASSWORD="your_password"
```
*(See `.env.example` for reference. Never commit `.env` or real credentials to GitHub.)*

### 2. Run the Application
```bash
mvn spring-boot:run
```
On startup, Flyway automatically connects to Neon, checks `flyway_schema_history`, and applies any pending migrations in `src/main/resources/db/migration/`.

## Flyway Migrations & Team Rules
Migrations live in `src/main/resources/db/migration/`:
- `V1__create_initial_tables.sql` — `manufacturer` and `agency` tables
- `V2__create_delivery_tables.sql` — `delivery_agent` table
- `V3__create_notification_tables.sql` — `notification` table

### Team Workflow Rules
1. **Never modify an already-applied migration.**
2. **Every new schema change gets a new migration file** (`V4__...`, `V5__...`).
3. **Coordinate version numbers** with the team before creating a migration so two developers never use the same `V#`.
4. **Always `git pull origin main`** before starting work or creating a migration.
5. **Do not manually create or alter tables in Neon**—let Flyway manage schema changes and `spring.jpa.hibernate.ddl-auto=validate` verify entity mappings.

