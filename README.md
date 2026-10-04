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
├── env/
│   ├── dev.yml               # migration_tag to deploy to dev
│   ├── uat.yml               # migration_tag to deploy to uat
│   └── prod.yml              # migration_tag to deploy to prod
├── .github/workflows/
│   ├── migrate.yml           # CI: run tagged migrations on the runner (tag push)
│   └── deploy-env.yml        # CI: deploy an env when its env/*.yml changes
├── changelog.dev.yaml        # Changelog for dev environment  (schema: dev)
├── changelog.uat.yaml        # Changelog for uat environment  (schema: uat)
├── changelog.prd.yaml        # Changelog for prd environment  (schema: prd)
├── docker/initdb/            # Local only: creates dev/uat/prd schemas
├── docker-compose.yml        # Local Postgres for development
└── liquibase.properties
```

All environments share **one database** (`demo`) and are isolated by **schema**:
`dev`, `uat`, `prd`. Each changelog sets the `${AppSchema}` property to its
schema, and Liquibase is run with `--default-schema-name` and
`--liquibase-schema-name` set to that schema, so the tracking tables
(`databasechangelog`, `databasechangeloglock`) also live inside the
environment's schema. The schemas themselves are created by infrastructure
(Terraform Kubernetes Job in `../aks/postgres_init.tf`; `docker/initdb` locally),
not by the changelog.

All SQL files are idempotent (`IF NOT EXISTS`, `ON CONFLICT DO NOTHING`,
`CREATE OR REPLACE`).

## Environment Variables

| Variable                           | Description                           | Example                                                     |
|------------------------------------|---------------------------------------|-------------------------------------------------------------|
| `LIQUIBASE_COMMAND_URL`            | JDBC connection string for PostgreSQL | `jdbc:postgresql://mydb.postgres.database.azure.com:5432/demo?sslmode=require` |
| `APP_SCHEMA`                       | Target schema (`dev`/`uat`/`prd`), passed as `--default-schema-name` and `--liquibase-schema-name` | `dev` |
| `LIQUIBASE_COMMAND_USERNAME`       | Database username                     | `demo`                                                      |
| `LIQUIBASE_COMMAND_PASSWORD`       | Database password                     | `*****`                                                     |
| `LIQUIBASE_COMMAND_CHANGELOG_FILE` | Which changelog to run                | `changelog.dev.yaml` / `changelog.prd.yaml`                 |

## Local Development

Start a local Postgres and run migrations with a local Liquibase installation:

```bash
docker compose up -d        # Postgres on localhost:5433 (set PG_PORT to change)

export LIQUIBASE_COMMAND_URL="jdbc:postgresql://localhost:5433/demo"
export LIQUIBASE_COMMAND_USERNAME="demo"
export LIQUIBASE_COMMAND_PASSWORD="demo"
export APP_SCHEMA=dev                        # dev | uat | prd
export CHANGELOG_FILE="changelog.$APP_SCHEMA.yaml"
LB="liquibase --changelog-file=$CHANGELOG_FILE --default-schema-name=$APP_SCHEMA --liquibase-schema-name=$APP_SCHEMA"

$LB validate
$LB update
$LB history
```

Apply up to a specific release only:

```bash
$LB update-to-tag --tag=release-1.0.1
```

Rollback a release:

```bash
$LB rollback --tag=release-1.0.0
```

Without a local Liquibase install, use the official image:

```bash
docker run --rm --network demo-liquibase_default \
  -v "$PWD":/liquibase/changelog -w /liquibase/changelog \
  -e LIQUIBASE_COMMAND_URL="jdbc:postgresql://postgres:5432/demo" \
  -e LIQUIBASE_COMMAND_USERNAME=demo -e LIQUIBASE_COMMAND_PASSWORD=demo \
  liquibase/liquibase:4.33 --changelog-file=changelog.dev.yaml \
  --default-schema-name=dev --liquibase-schema-name=dev update
```

## CI/CD Pipeline

### Database migration

The GitHub Actions workflow (`.github/workflows/migrate.yml`) triggers whenever
a git tag is pushed. It runs Liquibase on the AKS `aks-runners` scale set
(Java and Liquibase are installed on the fly with `actions/setup-java` and
`liquibase/setup-liquibase`). The runner reaches the Postgres Flexible Server
through its private endpoint inside the AKS VNet.

Connection details are **hardcoded in the workflow** (demo only): host
`pg-demo-liquibase-opd8e6.postgres.database.azure.com`, user `pgadmin`. No
GitHub Environments, variables or secrets are required.

Jobs run sequentially `dev → uat → prd`; each job:

1. Validates the environment's changelog.
2. Prints the SQL that `update-to-tag` would apply (`update-to-tag-sql`).
3. Runs `update-to-tag` with the pushed tag, then prints `history`.

For a single-environment rerun, use **Run workflow** and select
`target_environment: dev|uat|prd|all` plus an existing Liquibase tag. Tag pushes
run all environments; `MIGRATION_TAG` is set from the pushed tag.

| Job           | Changelog file       | Database | Schema |
|---------------|----------------------|----------|--------|
| `migrate_dev` | `changelog.dev.yaml` | `demo`   | `dev`  |
| `migrate_uat` | `changelog.uat.yaml` | `demo`   | `uat`  |
| `migrate_prd` | `changelog.prd.yaml` | `demo`   | `prd`  |

Every Liquibase command runs with `--default-schema-name=$APP_SCHEMA
--liquibase-schema-name=$APP_SCHEMA`, so both the application objects and the
Liquibase tracking tables live inside the environment's schema.

### GitOps deploy per environment (`env/*.yml`)

`.github/workflows/deploy-env.yml` runs **only** when one of `env/dev.yml`,
`env/uat.yml` or `env/prod.yml` changes on `main` (path filter). Changing SQL
changesets, changelogs or docs does not trigger it. The `detect` job diffs the
push to find which env files changed and only the matching `deploy_<env>` jobs
run (several can run in parallel).

Each env file holds only the Liquibase tag to deploy; changelog, schema and
database connection stay hardcoded per job in the workflow:

```yaml
# env/dev.yml
migration_tag: release-1.0.2
```

Typical flow: add a new release (SQL + changelog), push, nothing runs. Then bump
`migration_tag` in `env/dev.yml` → dev deploys. Later bump `env/uat.yml`, then
`env/prod.yml` to promote. **Run workflow** with an environment name forces a
deploy from the current file.

### Triggering a release (tag based)

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
