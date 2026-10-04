# Demo DB Migration (Liquibase)

Liquibase changeset repo for the demo Order Service database (PostgreSQL).
Migrations run on the AKS self-hosted runner `aks-runners`
(Actions Runner Controller, see `../aks`).

## Project Structure

```
.
├── changes/
│   ├── release-1.0.0/
│   │   ├── 0001_create_customers.sql
│   │   ├── 0002_create_products.sql
│   │   ├── 0003_seed_products.sql
│   │   ├── 0004_create_orders.sql
│   │   ├── 0005_create_order_items.sql
│   │   └── rollback.sql
│   ├── release-1.0.1/
│   │   ├── 0001_add_customers_phone_and_address.sql
│   │   └── rollback.sql
│   └── release-1.0.2/
│       ├── 0001_create_order_status_history.sql
│       ├── 0002_create_order_summary_view.sql
│       └── rollback.sql
├── .github/workflows/
│   └── migrate.yml           # CI: run tagged migrations on the runner
├── changelog.dev.yaml        # Changelog for dev environment  (schema: public)
├── changelog.uat.yaml        # Changelog for uat environment  (schema: demo_app)
├── changelog.prd.yaml        # Changelog for prd environment  (schema: demo_app)
├── docker-compose.yml        # Local Postgres for development
└── liquibase.properties
```

All SQL files are idempotent (`IF NOT EXISTS`, `ON CONFLICT DO NOTHING`,
`CREATE OR REPLACE`) and reference the target schema through the
`${AppSchema}` changelog property.

## Environment Variables

| Variable                           | Description                           | Example                                                     |
|------------------------------------|---------------------------------------|-------------------------------------------------------------|
| `LIQUIBASE_COMMAND_URL`            | JDBC connection string for PostgreSQL | `jdbc:postgresql://mydb.postgres.database.azure.com:5432/demo?sslmode=require` |
| `LIQUIBASE_COMMAND_USERNAME`       | Database username                     | `demo`                                                      |
| `LIQUIBASE_COMMAND_PASSWORD`       | Database password                     | `*****`                                                     |
| `LIQUIBASE_COMMAND_CHANGELOG_FILE` | Which changelog to run                | `changelog.dev.yaml` / `changelog.prd.yaml`                 |

## Local Development

Start a local Postgres and run migrations with a local Liquibase installation:

```bash
docker compose up -d        # Postgres on localhost:5433 (set PG_PORT to change)

export LIQUIBASE_COMMAND_URL="jdbc:postgresql://localhost:5433/demo_dev"
export LIQUIBASE_COMMAND_USERNAME="demo"
export LIQUIBASE_COMMAND_PASSWORD="demo"
export LIQUIBASE_COMMAND_CHANGELOG_FILE="changelog.dev.yaml"

liquibase --changelog-file="$LIQUIBASE_COMMAND_CHANGELOG_FILE" validate
liquibase --changelog-file="$LIQUIBASE_COMMAND_CHANGELOG_FILE" update
liquibase --changelog-file="$LIQUIBASE_COMMAND_CHANGELOG_FILE" history
```

Apply up to a specific release only:

```bash
liquibase --changelog-file="changelog.dev.yaml" update-to-tag --tag=release-1.0.1
```

Rollback a release:

```bash
liquibase --changelog-file="changelog.dev.yaml" rollback --tag=release-1.0.0
```

Without a local Liquibase install, use the official image:

```bash
docker run --rm --network demo-liquibase_default \
  -v "$PWD":/liquibase/changelog -w /liquibase/changelog \
  -e LIQUIBASE_COMMAND_URL="jdbc:postgresql://postgres:5432/demo_dev" \
  -e LIQUIBASE_COMMAND_USERNAME=demo -e LIQUIBASE_COMMAND_PASSWORD=demo \
  liquibase/liquibase:4.33 --changelog-file=changelog.dev.yaml update
```

## CI/CD Pipeline

### Database migration

The GitHub Actions workflow (`.github/workflows/migrate.yml`) triggers whenever
a git tag is pushed. It runs Liquibase on the AKS `aks-runners` scale set
(Java and Liquibase are installed on the fly with `actions/setup-java` and
`liquibase/setup-liquibase`). The runner reaches the Postgres Flexible Server
through its private endpoint inside the AKS VNet.

Connection details are **hardcoded in the workflow** (demo only): host
`pg-demo-liquibase-uudjy9.postgres.database.azure.com`, user `pgadmin`. No
GitHub Environments, variables or secrets are required.

Jobs run sequentially `dev → uat → prd`; each job:

1. Validates the environment's changelog.
2. Prints the SQL that `update-to-tag` would apply (`update-to-tag-sql`).
3. Runs `update-to-tag` with the pushed tag, then prints `history`.

For a single-environment rerun, use **Run workflow** and select
`target_environment: dev|uat|prd|all` plus an existing Liquibase tag. Tag pushes
run all environments; `MIGRATION_TAG` is set from the pushed tag.

| Job           | Changelog file       | Database   | Schema     |
|---------------|----------------------|------------|------------|
| `migrate_dev` | `changelog.dev.yaml` | `demo_dev` | `public`   |
| `migrate_uat` | `changelog.uat.yaml` | `demo_uat` | `demo_app` |
| `migrate_prd` | `changelog.prd.yaml` | `demo_prd` | `demo_app` |

The UAT and PRD changelogs create objects under the `demo_app` schema (created
by the first changeset). Liquibase tracking tables (`databasechangelog`,
`databasechangeloglock`) always live in `public`.

### Triggering a release

```bash
git tag release-1.0.2
git push origin release-1.0.2
```

The Liquibase tag must exist in the changelog (`tagDatabase`), so the git tag
name has to match a `release-x.y.z` changeset id.

## Adding a New Release

1. Create a new release folder and SQL files:
   ```
   changes/release-1.1.0/
   ├── 0001_add_new_column.sql
   └── rollback.sql
   ```

2. Add a new `changeSet` block at the bottom of each `changelog.*.yaml`:
   ```yaml
   - changeSet:
       id: release-1.1.0
       author: demo
       changes:
         - tagDatabase:
             tag: release-1.1.0
         - sqlFile:
             path: changes/release-1.1.0/0001_add_new_column.sql
             dbms: postgresql
             endDelimiter: ";"
             splitStatements: "true"
       rollback:
         - sqlFile:
             path: changes/release-1.1.0/rollback.sql
             dbms: postgresql
             endDelimiter: ";"
             splitStatements: "true"
   ```

3. **Never modify** an existing changeset — always add a new release.
