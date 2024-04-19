# Omnistrate dataplane agent service account
resource "google_service_account" "omnistrate_dataplane_agent" {
  project = data.google_project.current.project_id
  account_id   = "omnistrate-da-${lower(var.account_config_identity_id)}"
  display_name = "omnistrate-da-${lower(var.account_config_identity_id)}"
  description = "Omnistrate Dataplane Agent Service Account for account ${lower(var.account_config_identity_id)}"
}

# Permissions for dataplane agent service account
resource "google_project_iam_member" "compute_admin_for_dataplane" {
  project = data.google_project.current.project_id
  role   = "roles/compute.admin"
  member = "serviceAccount:${google_service_account.omnistrate_dataplane_agent.email}"
}

resource "google_project_iam_member" "kubernetes_admin_for_dataplane" {
  project = data.google_project.current.project_id
  role   = "roles/container.admin"
  member = "serviceAccount:${google_service_account.omnistrate_dataplane_agent.email}"
}

resource "google_project_iam_member" "storage_admin_for_dataplane" {
  project = data.google_project.current.project_id
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.omnistrate_dataplane_agent.email}"
}

resource "google_project_iam_member" "service_account_user_for_dataplane" {
  project = data.google_project.current.project_id
  role   = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.omnistrate_dataplane_agent.email}"
}

resource "google_project_iam_custom_role" "omnistrate_custom_iam_sa_policy_manager" {
  project     = data.google_project.current.project_id
  role_id     = "omnistrateServiceAccountPolicyManager"
  title       = "Omnistrate IAM Service Account Policy Manager (custom role)"
  description = "Custom role allowing retrieval and manipulation of IAM service account policies from Omnistrate dataplane agent"
  permissions = ["iam.serviceAccounts.getIamPolicy", "iam.serviceAccounts.setIamPolicy"]
}

resource "google_project_iam_member" "service_account_manager_for_dataplane" {
  project = data.google_project.current.project_id
  role = "projects/${data.google_project.current.project_id}/roles/${google_project_iam_custom_role.omnistrate_custom_iam_sa_policy_manager.role_id}"
  member = "serviceAccount:${google_service_account.omnistrate_dataplane_agent.email}"
}
