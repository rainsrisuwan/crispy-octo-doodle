# crispy-octo-doodle
CDP‐deploy track
# Terraform Module for Foundational CDP Infrastructure on GCP
# Provisions secure, cost-controlled storage, processing, and governance resources.

# Pre-Requisites: 
# - Google Cloud SDK installed and authenticated (`gcloud auth application-default login`)
# - Terraform installed (v1.0+)
# - Enable required GCP APIs: BigQuery, Cloud Storage, Dataflow, Data Catalog, Pub/Sub

# Initialize Terraform:
terraform init

# Review the execution plan:
terraform plan

# Provision the infrastructure:
terraform apply

# Note: This configuration is built for the 'techassessment' project
# and the 'asia-southeast2' (Malaysia) region.

# The Dataflow job uses the official Google-provided 'PubSub_to_BigQuery' template
# to ingest real-time streaming data from the 'customer-updates' topic into BigQuery.
