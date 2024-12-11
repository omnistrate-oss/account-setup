# Omnistrate service account (principal used for service instances)
resource "google_service_account" "omnistrate_service" {
  project = data.google_project.current.project_id
  account_id   = "omnistrate-${lower(var.account_config_identity_id)}"
  display_name = "omnistrate-${lower(var.account_config_identity_id)}"
  description = "Omnistrate Service Account for account ${lower(var.account_config_identity_id)}"
}

# Permissions for service account
resource "google_project_iam_member" "metric_writer_for_service" {
  project = data.google_project.current.project_id
  role   = "roles/monitoring.metricWriter" # write metrics
  member = "serviceAccount:${google_service_account.omnistrate_service.email}"
}

resource "google_project_iam_member" "log_writer_for_service" {
  project = data.google_project.current.project_id
  role   = "roles/logging.logWriter"  # write logs
  member = "serviceAccount:${google_service_account.omnistrate_service.email}"
}

resource "google_project_iam_member" "secret_accessor_for_service" {
  project = data.google_project.current.project_id
  role   = "roles/secretmanager.secretAccessor" # read secrets
  member = "serviceAccount:${google_service_account.omnistrate_service.email}"
}

resource "google_project_iam_member" "storage_user_for_service" {
  project = data.google_project.current.project_id
  role   = "roles/storage.objectUser" # use GCS storage
  member = "serviceAccount:${google_service_account.omnistrate_service.email}"
}
