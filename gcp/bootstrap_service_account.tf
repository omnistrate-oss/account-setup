provider "google" {
  # credentials = "path_to_service_account_key.json"
  region  = "us-central1"
  zone    = "us-central1-c"

  default_labels = {
    "omnistrate-com_managed-by" = "omnistrate"
  }
}

variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
  default     = ""
}

variable "project_number" {
  description = "The Google Cloud Project Number"
  type        = string
  default     = ""
}

variable "account_config_identity_id" {
  description = "Suffix for the session name in IAM trust policy unique to your account configuration. Equivalent to sts:ExternalId"
  type        = string
}

# Fetch the project ID dynamically
data "google_project" "current" {
    project_id = var.project_id
}

# Omnistrate bootstrap service account
resource "google_service_account" "omnistrate_bootstrap" {
  project = data.google_project.current.project_id
  account_id   = "omni-btstrp-${lower(var.account_config_identity_id)}"
  display_name = "Omnistrate Bootstrap Service Account"
}

# Config connector bootstrap service account
resource "google_service_account" "config_connector_bootstrap" {
  project = data.google_project.current.project_id
  account_id   = "config-connector-sa"
  display_name = "Config Connector Bootstrap Service Account"
}

## Perms for omnistrate bootstrap service account
resource "google_project_iam_member" "compute_admin" {
  project = data.google_project.current.project_id
  role   = "roles/compute.admin"
  member = "serviceAccount:${google_service_account.omnistrate_bootstrap.email}"
}

resource "google_project_iam_member" "kubernetes_admin" {
  project = data.google_project.current.project_id
  role   = "roles/container.admin"
  member = "serviceAccount:${google_service_account.omnistrate_bootstrap.email}"
}

resource "google_project_iam_member" "security_admin" {
  project = data.google_project.current.project_id
  role   = "roles/iam.securityAdmin"
  member = "serviceAccount:${google_service_account.omnistrate_bootstrap.email}"
}

resource "google_project_iam_member" "service_account_user" {
  project = data.google_project.current.project_id
  role   = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.omnistrate_bootstrap.email}"
}

## Perms for config connector bootstrap service account
resource "google_project_iam_member" "cc_compute_admin" {
    project = data.google_project.current.project_id
    role   = "roles/compute.admin"
    member = "serviceAccount:${google_service_account.config_connector_bootstrap.email}"
}

resource "google_project_iam_member" "cc_security_admin" {
    project = data.google_project.current.project_id
    role   = "roles/iam.securityAdmin"
    member = "serviceAccount:${google_service_account.config_connector_bootstrap.email}"
}

resource "google_project_iam_member" "cc_kubernetes_admin" {
    project = data.google_project.current.project_id
    role   = "roles/container.admin"
    member = "serviceAccount:${google_service_account.config_connector_bootstrap.email}"
}

resource "google_project_iam_member" "cc_service_account_user" {
    project = data.google_project.current.project_id
    role   = "roles/iam.serviceAccountUser"
    member = "serviceAccount:${google_service_account.config_connector_bootstrap.email}"
}

resource "google_project_iam_member" "cc_storage_admin" {
    project = data.google_project.current.project_id
    role   = "roles/storage.admin"
    member = "serviceAccount:${google_service_account.config_connector_bootstrap.email}"
}

resource "google_project_iam_member" "cc_workload_identity_user" {
    project = data.google_project.current.project_id
    role   = "roles/iam.workloadIdentityUser"
    member = "serviceAccount:${google_service_account.config_connector_bootstrap.email}"
}