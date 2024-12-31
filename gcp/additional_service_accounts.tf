# Custom Terraform service account that can be configured with additional permissions
# and used to create terraform resources.
resource "google_service_account" "omnistrate_terraform" {
  project = data.google_project.current.project_id
  account_id   = "omnistrate-terraform-${lower(var.account_config_identity_id)}"
  display_name = "Omnistrate Terraform Service Account"
}
