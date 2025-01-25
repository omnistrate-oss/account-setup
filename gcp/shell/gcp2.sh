#!/bin/bash

set -euo pipefail

# Get the directory of the script and current date for the log file
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
RANDOM_NUMBER=$(printf "%05d" $((RANDOM % 100000)))
LOG_FILE="$SCRIPT_DIR/gcp_sh_$(date '+%Y-%m-%d_%H-%M-%S')_${RANDOM_NUMBER}.log"

# Redirect all output to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to log messages with a timestamp
log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$message" | tee -a "$LOG_FILE"
}

# Function to retry a command up to a maximum number of attempts
retry() {
    local n=1
    local max=5
    local delay=2

    while true; do
        "$@" && break || {
            if [[ $n -lt $max ]]; then
                ((n++))
                log "Command failed. Attempt $n/$max:"
                sleep $delay
            else
                log "ERROR: Command failed after $n attempts."
                exit 1
            fi
        }
    done
}

# Function to run a command and log its execution
run() {
    log "Running: $1"
    retry eval "$1" || {
        log "ERROR: Command failed: $1"
        exit 1
    }
}

# Function to create a service account if it does not exist
create_service_account() {
    local account_id=$1
    local display_name=$2
    local description=$3
    log "Ensuring service account $account_id exists..."
    if ! gcloud iam service-accounts list --project="halogen-framing-448622-u7" | grep -q "$account_id"; then
        run "gcloud iam service-accounts create $account_id \
             --display-name='$display_name' \
             --description='$description' \
             --project='halogen-framing-448622-u7'"
    else
        log "Service account $account_id already exists."
    fi
}

# Function to assign a role to a member
assign_role() {
    local member=$1
    local role=$2

    log "Ensuring role $role is assigned to $member..."
    if ! gcloud projects get-iam-policy "halogen-framing-448622-u7" --format="json" | jq -e --arg member "$member" --arg role "$role" '.bindings[] | select(.role == $role) | .members[] | select(. == $member)' &>/dev/null; then
        run "gcloud projects add-iam-policy-binding halogen-framing-448622-u7 \
             --member=$member \
             --role=$role --quiet"
    else
        log "Role $role is already assigned to $member."
    fi
}

# Function to create a custom role if it does not exist
create_custom_role() {
    local role_id=$1
    local title=$2
    local description=$3
    local permissions=$4

    log "Ensuring custom role $role_id exists..."
    if ! gcloud iam roles list --project="halogen-framing-448622-u7" | grep -q "$role_id"; then
        run "gcloud iam roles create $role_id \
             --project=halogen-framing-448622-u7 \
             --title='$title' \
             --description='$description' \
             --permissions='$permissions' \
             --quiet"
    else
        log "Custom role $role_id already exists."
    fi
}

# Function to assign an IAM member to a service account with a specific role
assign_service_account_iam_member() {
    local service_account_email=$1
    local role=$2
    local member=$3

    log "Ensuring IAM member $member is assigned to service account $service_account_email with role $role..."
    if ! gcloud iam service-accounts get-iam-policy "$service_account_email" --project="halogen-framing-448622-u7" \
    --format="json" | jq -e --arg role "$role" --arg member "$member" \
    '.bindings[] | select(.role == $role) | .members[]' &>/dev/null; then
        run "gcloud iam service-accounts add-iam-policy-binding $service_account_email \
             --role=$role \
             --member=$member \
             --project=halogen-framing-448622-u7"
        log "Assigned IAM member $member to service account $service_account_email with role $role."
    else
        log "IAM member $member with role $role is already assigned to service account $service_account_email."
    fi
}

# Function to create a workload identity pool if it does not exist
create_workload_identity_pool() {
    local pool_name=$1
    local display_name=$2
    local description=$3

    log "Ensuring workload identity pool $pool_name exists..."
    if ! gcloud iam workload-identity-pools describe "$pool_name" --project="halogen-framing-448622-u7" --location=global &>/dev/null; then
        run "gcloud iam workload-identity-pools create $pool_name \
             --project=halogen-framing-448622-u7 \
             --display-name='$display_name' \
             --description='$description' \
             --location=global"
    else
        log "Workload identity pool $pool_name already exists."
    fi
}

# Function to create an OIDC provider if it does not exist
create_oidc_provider() {
    local pool_name=$1
    local provider_name=$2
    local issuer_uri=$3
    local display_name=$4
    local description=$5

    log "Ensuring OIDC provider $provider_name exists..."
    if ! gcloud iam workload-identity-pools providers describe "$provider_name" --project="halogen-framing-448622-u7" --workload-identity-pool="$pool_name" --location=global &>/dev/null; then
        run "gcloud iam workload-identity-pools providers create-oidc $provider_name \
             --project=halogen-framing-448622-u7 \
             --workload-identity-pool=$pool_name \
             --location=global \
             --issuer-uri=$issuer_uri \
             --attribute-mapping='google.subject=assertion.sub,attribute.subject=assertion.sub.extract(\"subject/{sub}/\")' \
             --allowed-audiences='sts.amazonaws.com' \
             --display-name='$display_name' \
             --description='$description'"
    else
        log "OIDC provider $provider_name already exists."
    fi
}

# Function to enable a specific API if it is not already enabled
enable_api() {
    local API="$1"
    if gcloud services list --enabled --project="halogen-framing-448622-u7" | grep -q "$API"; then
        log "API $API is already enabled."
    else
        log "Enabling API $API..."
        gcloud services enable "$API" --project="halogen-framing-448622-u7"
    fi
}

# Function to create an autopilot cluster if it does not exist
create_autopilot_cluster() {
    log "Creating autopilot cluster with all defaults..."
    if ! gcloud container clusters list --project="halogen-framing-448622-u7" --region=us-central1 --filter="name=temp-halogen-framing-448622-u7" --format="value(name)" | grep -q "temp-halogen-framing-448622-u7"; then
        run "gcloud container clusters create-auto temp-halogen-framing-448622-u7 --project=halogen-framing-448622-u7 --region=us-central1 --async --quiet"
        log "autopilot cluster created successfully."
    else
        log "autopilot cluster already exists."
    fi
}

# Function to delete an autopilot cluster if it exists
delete_autopilot_cluster_if_exists() {
    if gcloud container clusters list --project="halogen-framing-448622-u7" --region=us-central1 --filter="name=temp-halogen-framing-448622-u7" --format="value(name)" | grep -q "temp-halogen-framing-448622-u7"; then
        log "Deleting autopilot cluster..."
        log "Cluster is found. Checking its status..."
        while gcloud container clusters describe temp-halogen-framing-448622-u7 --project="halogen-framing-448622-u7" --region=us-central1 --format="value(status)" | grep -q "PROVISIONING"; do
            log "Cluster is still being created. Waiting for it to be ready..."
            sleep 30
        done
        run "gcloud container clusters delete temp-halogen-framing-448622-u7 --project=halogen-framing-448622-u7 --region=us-central1 --async --quiet"
        log "Autopilot cluster deleted successfully."
    else
        log "Autopilot cluster does not exist."
    fi
}

# Function to create and assign roles to the bootstrap service account
bootstrap_service_account() {
    create_service_account "bootstrap-org-ukzurk3i70" "Omnistrate Bootstrap Service Account" "Service account for bootstrap-org-ukzurk3i70 operations"
    assign_role "serviceAccount:bootstrap-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/compute.admin"
    assign_role "serviceAccount:bootstrap-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/container.admin"
    assign_role "serviceAccount:bootstrap-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/iam.securityAdmin"
    assign_role "serviceAccount:bootstrap-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/iam.serviceAccountUser"
}

# Function to create and assign roles to the omnistrate service account
omnistrate_service_account() {
    create_service_account "omnistrate-org-ukzurk3i70" "General Omnistrate Service Account" "Service account for omnistrate-org-ukzurk3i70 operations"
    assign_role "serviceAccount:omnistrate-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/monitoring.metricWriter"
    assign_role "serviceAccount:omnistrate-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/logging.logWriter"
    assign_role "serviceAccount:omnistrate-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/secretmanager.secretAccessor"
    assign_role "serviceAccount:omnistrate-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/storage.objectUser"
}

# Function to create and assign roles to the omnistrate dataplane agent service account
omnistrate_da_service_account() {
    create_service_account "omnistrate-da-org-ukzurk3i70" "Omnistrate Dataplane Agent Service Account" "Service account for omnistrate-da-org-ukzurk3i70 operations"
    assign_role "serviceAccount:omnistrate-da-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/compute.admin"
    assign_role "serviceAccount:omnistrate-da-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/container.admin"
    assign_role "serviceAccount:omnistrate-da-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/storage.admin"
    assign_role "serviceAccount:omnistrate-da-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/iam.serviceAccountUser"
}

# Function to create a custom role and assign it to the omnistrate dataplane agent service account
create_custom_role_and_assign() {
    local custom_role_id="omnistrateServiceAccountPolicyManager"
    local custom_role_title="Omnistrate IAM Service Account Policy Manager (custom role)"
    local custom_role_desc="Custom role allowing retrieval and manipulation of IAM service account policies from Omnistrate dataplane agent"
    local custom_permissions="iam.serviceAccounts.getIamPolicy,iam.serviceAccounts.setIamPolicy"

    create_custom_role "$custom_role_id" "$custom_role_title" "$custom_role_desc" "$custom_permissions"
    assign_role "serviceAccount:omnistrate-da-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "projects/halogen-framing-448622-u7/roles/$custom_role_id"
}

# Function to create a workload identity pool and OIDC provider
create_workload_identity_pool_and_oidc_provider() {
    local pool_name="omnistrate-bootstrap-id-pool"
    local pool_display="Omnistrate Access Provider Pool"
    local pool_desc="Workload Identity Pool for the Omnistrate Control Plane"
    create_workload_identity_pool "$pool_name" "$pool_display" "$pool_desc"

    local oidc_provider_name="omnistrate-oidc-prov"
    local oidc_display="Omnistrate OIDC Provider"
    local oidc_desc="OIDC provider for the Omnistrate Control Plane"
    create_oidc_provider "$pool_name" "$oidc_provider_name" "https://oidc.eks.us-west-2.amazonaws.com/id/C1B03794957A09E4D89FF950EFDF99C4" "$oidc_display" "$oidc_desc"
}


  
# Function to create and assign roles to the custom Terraform service account
omnistrate_custom_tf_service_account() {
    local service_model_id=$1
    shift
    local roles=("$@")

    create_service_account "omnistrate-tf-$service_model_id" "Omnistrate Custom Terraform for $service_model_id" "Service account for Terraform resources in model $service_model_id"

    assign_service_account_iam_member "omnistrate-tf-$service_model_id@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/iam.workloadIdentityUser" "serviceAccount:halogen-framing-448622-u7.svc.id.goog[dataplane-agent/omnistrate-da-org-ukzurk3i70]"
    assign_service_account_iam_member "omnistrate-tf-$service_model_id@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/iam.serviceAccountTokenCreator" "serviceAccount:omnistrate-da-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com"

    for role in "${roles[@]}"; do
        assign_role "serviceAccount:omnistrate-tf-$service_model_id@halogen-framing-448622-u7.iam.gserviceaccount.com" "$role"
    done
}
  


assign_tf_user_roles() {
 
    omnistrate_custom_tf_service_account "sm-a12345" "roles/compute.admin" "roles/storage.admin"  
    omnistrate_custom_tf_service_account "sm-b67890" "roles/compute.admin"  
}

# Function to assign workload identity user roles to service accounts
assign_workload_identity_user_roles() {
    local pool_name="omnistrate-bootstrap-id-pool"
    local bootstrap_sa="system:serviceaccount:bootstrap:bootstrap-sa"
    assign_service_account_iam_member "bootstrap-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/iam.workloadIdentityUser" "principal://iam.googleapis.com/projects/678069411773/locations/global/workloadIdentityPools/$pool_name/subject/$bootstrap_sa"
    local error_message=$(assign_service_account_iam_member "omnistrate-da-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/iam.workloadIdentityUser" "serviceAccount:halogen-framing-448622-u7.svc.id.goog[dataplane-agent/omnistrate-da-org-ukzurk3i70]" 2>&1 | tee /dev/stderr)
    # Handle "Identity Pool does not exist" error
    if [[ $error_message == *"INVALID_ARGUMENT: Identity Pool does not exist"* ]]; then
      echo "Default GKE Workload Identity Pool does not exist. Creating cluster and retrying..."
      create_autopilot_cluster
      log "Waiting 1 minute for the cluster Default Workload Identity Pool to be ready to complete role assigment..."
      sleep 60
      assign_service_account_iam_member "omnistrate-da-org-ukzurk3i70@halogen-framing-448622-u7.iam.gserviceaccount.com" "roles/iam.workloadIdentityUser" "serviceAccount:halogen-framing-448622-u7.svc.id.goog[dataplane-agent/omnistrate-da-org-ukzurk3i70]"
    elif [[ -z $error_message ]]; then
      echo "Error occurred: $error_message"
      exit 1
    else
      echo "IAM roles assigned successfully."
    fi
}

# Set the project configuration
gcloud config set project halogen-framing-448622-u7
log "Checking required APIs..."
enable_api "iam.googleapis.com"
enable_api "cloudresourcemanager.googleapis.com"
enable_api "compute.googleapis.com"
enable_api "container.googleapis.com"

# Execute the steps
bootstrap_service_account
omnistrate_service_account
omnistrate_da_service_account
create_custom_role_and_assign
create_workload_identity_pool_and_oidc_provider
assign_workload_identity_user_roles
assign_tf_user_roles
delete_autopilot_cluster_if_exists

log "Script completed successfully." 
