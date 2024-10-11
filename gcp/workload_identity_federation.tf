resource "google_iam_workload_identity_pool" "pool" {
  project                   = data.google_project.current.number
  workload_identity_pool_id = "omnistrate-bootstrap-id-pool"
  display_name              = "Omnistrate Access Provider Pool"
  description               = "Workfload Identity Pool for the Omnistrate Control Plane"
  disabled                  = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_iam_workload_identity_pool_provider" "oidc_provider" {
  project                            = data.google_project.current.number
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "omnistrate-oidc-prov"
  display_name                       = "Omnistrate OIDC Provider"
  description                        = "OIDC provider for the Omnistrate Control Plane"
  disabled                           = false

  attribute_mapping = {
    "google.subject"    = "assertion.sub"
    "attribute.subject" = "assertion.sub.extract('subject/{sub}/')"
  }

  oidc {
    allowed_audiences = [
      "sts.amazonaws.com"
    ]
    issuer_uri = "https://oidc.eks.us-west-2.amazonaws.com/id/9AEF0C846C22DEAEFDDD1F98C6AB9FEA"
  }
}

# Omnistrate bootstrap service account connection with the workload identity federation
resource "google_service_account_iam_member" "association" {
  service_account_id = google_service_account.omnistrate_bootstrap.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.pool.name}/subject/system:serviceaccount:bootstrap:bootstrap-sa"
}

# Config connector service account connection with the workload identity
resource "google_service_account_iam_member" "config_connector_association" {
  service_account_id = google_service_account.config_connector_bootstrap.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${data.google_project.current.project_id}.svc.id.goog[cnrm-system/cnrm-controller-manager]"
}

# Omnistrate dataplane agent service account connection with the workload identity
resource "google_service_account_iam_member" "dataplane_service_association" {
  service_account_id = google_service_account.omnistrate_dataplane_agent.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${data.google_project.current.project_id}.svc.id.goog[dataplane-agent/omnistrate-da-${lower(var.account_config_identity_id)}]"
}
