# Omnistrate service account (principal used for service instances)
resource "google_service_account" "omnistrate_service" {
  project = data.google_project.current.project_id
  account_id   = "omni-btstrp-org-q9h5kjuc0n"
  display_name = "Omnistrate Bootstrap Service Account"
  description = "Omnistrate Service Account for account ${lower(var.account_config_identity_id)}"
}

# Permissions for service account
resource "google_project_iam_member" "metric_writer_for_service" {
  project = data.google_project.current.project_id
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.omnistrate_service.email}"
}

resource "google_project_iam_member" "log_writer_for_service" {
  project = data.google_project.current.project_id
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.omnistrate_service.email}"
}

resource "google_project_iam_member" "secret_accessor_for_service" {
  project = data.google_project.current.project_id
  role   = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.omnistrate_service.email}"
}
