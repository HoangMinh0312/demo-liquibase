-- Local only: on Azure the schemas are created by Terraform (kubernetes_job pg-init-schemas)
CREATE SCHEMA IF NOT EXISTS dev;
CREATE SCHEMA IF NOT EXISTS uat;
CREATE SCHEMA IF NOT EXISTS prd;
