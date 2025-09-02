# Configure the Google Cloud provider
provider "google" {
  project = "techassessment"
  region  = "asia-southeast2" # The GCP region for Malaysia
}

# Provision a cost-efficient BigQuery Dataset for unified customer profiles
resource "google_bigquery_dataset" "customer_profiles" {
  dataset_id                  = "customer_profiles_curated"
  friendly_name               = "Unified Customer Profiles"
  description                 = "Central dataset for cleansed, unified customer data. Managed by Terraform."
  location                    = "asia-southeast2" # Must match the region
  delete_contents_on_destroy  = false # Prevent catastrophic accidental deletion

  # Enforce a default table expiration to manage storage costs and prevent orphaned tables
  default_table_expiration_ms = 365 * 24 * 60 * 60 * 1000 # 1 year

  labels = {
    environment = "production"
    cost-center = "data-platform"
  }
}

# Create a Cloud Storage bucket for raw, immutable landing data
resource "google_storage_bucket" "raw_landing_bucket" {
  name                        = "techassessment-raw-landing"
  location                    = "asia-southeast2" # The GCP region for Malaysia
  uniform_bucket_level_access = true
  force_destroy               = false

  # Critical for cost control: Automatically delete raw files after 30 days
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true # Protect against accidental overwrites
  }
}

# Create a staging bucket for processed, ephemeral data
resource "google_storage_bucket" "staging_processing_bucket" {
  name                        = "techassessment-staging-processing"
  location                    = "asia-southeast2" # The GCP region for Malaysia
  uniform_bucket_level_access = true
  force_destroy               = false # Prevents accidental deletion of non-empty bucket

  # Staging data is temporary; expire after 7 days
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
}

# Create a Data Catalog Tag Template for PII classification (Governance)
resource "google_data_catalog_tag_template" "pii_classification" {
  tag_template_id = "pii_classification"
  region          = "asia-southeast2" # The GCP region for Malaysia
  display_name    = "PII Classification"

  fields {
    field_id     = "pii_type"
    display_name = "PII Type"
    type {
      primitive_type = "STRING"
    }
    is_required = true
  }

  fields {
    field_id     = "masking_rule"
    display_name = "Masking Rule"
    type {
      primitive_type = "STRING"
    }
  }
}

# Create a Pub/Sub topic for streaming customer data ingestion
resource "google_pubsub_topic" "customer_updates" {
  name = "customer-updates"
}

# Provision a Dataflow job using a Google-provided template for streaming ingestion
resource "google_dataflow_job" "streaming_ingestion_job" {
  name              = "streaming-customer-ingestion"
  template_gcs_path = "gs://dataflow-templates-asia-southeast2/latest/PubSub_to_BigQuery"
  temp_gcs_location = "${google_storage_bucket.staging_processing_bucket.url}/temp"
  parameters = {
    inputTopic = google_pubsub_topic.customer_updates.id
    outputTableSpec = "${google_bigquery_dataset.customer_profiles.project}:${google_bigquery_dataset.customer_profiles.dataset_id}.customer_stream"
  }
  region = "asia-southeast2"

  # Ensure the job runs in the same network for security
  network = "default"

  depends_on = [
    google_bigquery_dataset.customer_profiles,
    google_storage_bucket.staging_processing_bucket,
    google_pubsub_topic.customer_updates
  ]
}
