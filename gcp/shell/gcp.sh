#!/bin/bash

set -euo pipefail

# Function to log messages with a timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
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
validate_and_set_params() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project-id)
                PROJECT_ID="$2"
                shift 2
                ;;
            --project-number)
                PROJECT_NUMBER="$2"
                shift 2
                ;;
            --account-config-id)
                ACCOUNT_CONFIG_ID="$2"
                shift 2
                ;;
            --issuer-uri)
                ISSUER_URI="$2"
                shift 2
                ;;
            --bootstrap-service-account-name)
                BOOTSTRAP_SERVICE_ACCOUNT_NAME="$2"
                shift 2
                ;;
            --service-model-roles)
                SERVICE_MODEL_ROLES="$2"
                shift 2
                ;;
            *)
                log "ERROR: Unknown parameter $1"
                exit 1
                ;;
        esac
    done

    # Ensure required parameters are set
    if [[ -z "${PROJECT_ID:-}" || -z "${PROJECT_NUMBER:-}" || -z "${ACCOUNT_CONFIG_ID:-}" || -z "${ISSUER_URI:-}" || -z "${BOOTSTRAP_SERVICE_ACCOUNT_NAME:-}" ]]; then
        log "ERROR: Missing required arguments. Set --project-id, --project-number, --account-config-id, --issuer-uri, and --bootstrap-service-account-name."
        log "Usage: $0 --project-id <PROJECT_ID> --project-number <PROJECT_NUMBER> --account-config-id <ACCOUNT_CONFIG_ID> --issuer-uri <ISSUER_URI> --bootstrap-service-account-name <BOOTSTRAP_SERVICE_ACCOUNT_NAME> [--service-model-roles \"serviceModelId1:role1,role2 serviceModelId2:role3,role4\"]"
        exit 1
    fi

    # Implicit CUSTOM_TF: Set true if SERVICE_MODEL_ROLES is provided and non-empty
    if [[ -n "${SERVICE_MODEL_ROLES:-}" ]]; then
        CUSTOM_TF=true
        declare -A SERVICE_MODEL_ROLE_MAP
        IFS=' ' read -r -a MODEL_ROLES_ARRAY <<< "$SERVICE_MODEL_ROLES"
        for entry in "${MODEL_ROLES_ARRAY[@]}"; do
            IFS=':' read -r service_model_id roles <<< "$entry"
            if [[ -z "$service_model_id" || -z "$roles" ]]; then
                log "ERROR: Invalid format for --service-model-roles. Expected format: \"serviceModelId1:role1,role2 serviceModelId2:role3,role4\""
                exit 1
            fi
            SERVICE_MODEL_ROLE_MAP["$service_model_id"]="$roles"
        done
    else
        CUSTOM_TF=false
    fi

    ACCOUNT_CONFIG_ID=$(echo "${ACCOUNT_CONFIG_ID}" | tr '[:upper:]' '[:lower:]')
    log "Validated parameters: PROJECT_ID=$PROJECT_ID, PROJECT_NUMBER=$PROJECT_NUMBER, ACCOUNT_CONFIG_ID=$ACCOUNT_CONFIG_ID, ISSUER_URI=$ISSUER_URI, BOOTSTRAP_SERVICE_ACCOUNT_NAME=$BOOTSTRAP_SERVICE_ACCOUNT_NAME, CUSTOM_TF=$CUSTOM_TF"
    if [[ "$CUSTOM_TF" == true ]]; then
        log "SERVICE_MODEL_ROLE_MAP: ${!SERVICE_MODEL_ROLE_MAP[@]} -> ${SERVICE_MODEL_ROLE_MAP[*]}"
    fi
}

# Function to create a service account if it does not exist
create_service_account() {
    local account_id=$1
    local display_name=$2
    local description=$3
    log "Ensuring service account $account_id exists..."
    if ! gcloud iam service-accounts list --project="$PROJECT_ID" | grep -q "$account_id"; then
        run "gcloud iam service-accounts create $account_id \
             --display-name='$display_name' \
             --description='$description' \
             --project='$PROJECT_ID'"
    else
        log "Service account $account_id already exists."
    fi
}

# Function to assign a role to a member
assign_role() {
    local member=$1
    local role=$2

    log "Ensuring role $role is assigned to $member..."
    if ! gcloud projects get-iam-policy "$PROJECT_ID" --format="json" | jq -e --arg member "$member" --arg role "$role" '.bindings[] | select(.role == $role) | .members[] | select(. == $member)' &>/dev/null; then
        run "gcloud projects add-iam-policy-binding $PROJECT_ID \
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
    if ! gcloud iam roles list --project="$PROJECT_ID" | grep -q "$role_id"; then
        run "gcloud iam roles create $role_id \
             --project=$PROJECT_ID \
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

    if ! gcloud iam service-accounts get-iam-policy "$service_account_email" --project="$PROJECT_ID" \
    --format="json" | jq -e --arg role "$role" --arg member "$member" \
    '.bindings[] | select(.role == $role) | .members[]' &>/dev/null; then
        run "gcloud iam service-accounts add-iam-policy-binding $service_account_email \
             --role=$role \
             --member=$member \
             --project=$PROJECT_ID"
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
    if ! gcloud iam workload-identity-pools describe "$pool_name" --project="$PROJECT_ID" --location=global &>/dev/null; then
        run "gcloud iam workload-identity-pools create $pool_name \
             --project=$PROJECT_ID \
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
    if ! gcloud iam workload-identity-pools providers describe "$provider_name" --project="$PROJECT_ID" --workload-identity-pool="$pool_name" --location=global &>/dev/null; then
        run "gcloud iam workload-identity-pools providers create-oidc $provider_name \
             --project=$PROJECT_ID \
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
    if gcloud services list --enabled --project="$PROJECT_ID" | grep -q "$API"; then
        log "API $API is already enabled."
    else
        log "Enabling API $API..."
        gcloud services enable "$API" --project="$PROJECT_ID"
    fi
}

# Function to create an autopilot cluster if it does not exist
create_autopilot_cluster() {
    log "Creating autopilot cluster with all defaults..."
    if ! gcloud container clusters list --project="$PROJECT_ID" --region=us-central1 --filter="name=temp-$PROJECT_ID" --format="value(name)" | grep -q "temp-$PROJECT_ID"; then
        run "gcloud container clusters create-auto temp-$PROJECT_ID --project=$PROJECT_ID --region=us-central1 --async"
        log "autopilot cluster created successfully."
    else
        log "autopilot cluster already exists."
    fi
}

# Function to delete an autopilot cluster if it exists
delete_autopilot_cluster() {
    log "Deleting autopilot cluster..."
    if gcloud container clusters list --project="$PROJECT_ID" --region=us-central1 --filter="name=temp-$PROJECT_ID" --format="value(name)" | grep -q "temp-$PROJECT_ID"; then
        log "Cluster is found. Checking its status..."
        while gcloud container clusters describe temp-$PROJECT_ID --project="$PROJECT_ID" --region=us-central1 --format="value(status)" | grep -q "PROVISIONING"; do
            log "Cluster is still being created. Waiting for it to be ready..."
            sleep 30
        done
        run "gcloud container clusters delete temp-$PROJECT_ID --project=$PROJECT_ID --region=us-central1 --async --quiet"
        log "Autopilot cluster deleted successfully."
    else
        log "Autopilot cluster does not exist."
    fi
}

# Function to create and assign roles to the bootstrap service account
bootstrap_service_account() {
    create_service_account "bootstrap-$ACCOUNT_CONFIG_ID" "Omnistrate Bootstrap Service Account" "Service account for bootstrap-$ACCOUNT_CONFIG_ID operations"
    assign_role "serviceAccount:bootstrap-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/compute.admin"
    assign_role "serviceAccount:bootstrap-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/container.admin"
    assign_role "serviceAccount:bootstrap-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.securityAdmin"
    assign_role "serviceAccount:bootstrap-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.serviceAccountUser"
}

# Function to create and assign roles to the config connector service account
config_connector_service_account() {
    create_service_account "config-connector-sa" "Config Connector Bootstrap Service Account" "Service account for config-connector-sa operations"
    assign_role "serviceAccount:config-connector-sa@$PROJECT_ID.iam.gserviceaccount.com" "roles/compute.admin"
    assign_role "serviceAccount:config-connector-sa@$PROJECT_ID.iam.gserviceaccount.com" "roles/container.admin"
    assign_role "serviceAccount:config-connector-sa@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.securityAdmin"
    assign_role "serviceAccount:config-connector-sa@$PROJECT_ID.iam.gserviceaccount.com" "roles/storage.admin"
    assign_role "serviceAccount:config-connector-sa@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.workloadIdentityUser"
}

# Function to create and assign roles to the omnistrate service account
omnistrate_service_account() {
    create_service_account "omnistrate-$ACCOUNT_CONFIG_ID" "General Omnistrate Service Account" "Service account for omnistrate-$ACCOUNT_CONFIG_ID operations"
    assign_role "serviceAccount:omnistrate-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/monitoring.metricWriter"
    assign_role "serviceAccount:omnistrate-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/logging.logWriter"
    assign_role "serviceAccount:omnistrate-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/secretmanager.secretAccessor"
    assign_role "serviceAccount:omnistrate-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/storage.objectUser"
}



# Function to create and assign roles to the omnistrate dataplane agent service account
omnistrate_da_service_account() {
    create_service_account "omnistrate-da-$ACCOUNT_CONFIG_ID" "Omnistrate Dataplane Agent Service Account" "Service account for omnistrate-da-$ACCOUNT_CONFIG_ID operations"
    assign_role "serviceAccount:omnistrate-da-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/compute.admin"
    assign_role "serviceAccount:omnistrate-da-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/container.admin"
    assign_role "serviceAccount:omnistrate-da-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/storage.admin"
    assign_role "serviceAccount:omnistrate-da-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.serviceAccountUser"
}

# Function to create a custom role and assign it to the omnistrate dataplane agent service account
create_custom_role_and_assign() {
    local custom_role_id="omnistrateServiceAccountPolicyManager"
    local custom_role_title="Omnistrate IAM Service Account Policy Manager (custom role)"
    local custom_role_desc="Custom role allowing retrieval and manipulation of IAM service account policies from Omnistrate dataplane agent"
    local custom_permissions="iam.serviceAccounts.getIamPolicy,iam.serviceAccounts.setIamPolicy"

    create_custom_role "$custom_role_id" "$custom_role_title" "$custom_role_desc" "$custom_permissions"
    assign_role "serviceAccount:omnistrate-da-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "projects/$PROJECT_ID/roles/$custom_role_id"
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
    create_oidc_provider "$pool_name" "$oidc_provider_name" "$ISSUER_URI" "$oidc_display" "$oidc_desc"
}

# Function to create and assign roles to the custom Terraform service account
omnistrate_custom_tf_service_account() {
    local service_model_id=$1
    local roles=("${@:3}")

    create_service_account "omnistrate-tf-$service_model_id" "Omnistrate Custom Terraform for $service_model_id" "Service account for Terraform resources in model $service_model_id"

    assign_service_account_iam_member "omnistrate-tf-$service_model_id@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.workloadIdentityUser" "serviceAccount:$PROJECT_ID.svc.id.goog[dataplane-agent/omnistrate-da-$ACCOUNT_CONFIG_ID]"
    assign_service_account_iam_member "omnistrate-tf-$service_model_id@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.serviceAccountTokenCreator" "serviceAccount:omnistrate-da-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com"

    for role in "${roles[@]}"; do
        assign_role "serviceAccount:omnistrate-tf-$service_model_id@$PROJECT_ID.iam.gserviceaccount.com" "$role"
    done
}
assign_tf_user_roles() {
    if [[ "$CUSTOM_TF" == true ]]; then
        for service_model_id in "${!SERVICE_MODEL_ROLE_MAP[@]}"; do
            IFS=',' read -r -a roles <<< "${SERVICE_MODEL_ROLE_MAP[$service_model_id]}"
            omnistrate_custom_tf_service_account "$service_model_id" "${roles[@]}"
        done
    else
        create_service_account "omnistrate-tf-$ACCOUNT_CONFIG_ID" "Omnistrate Terraform Service Account" "Service account for omnistrate-tf-$ACCOUNT_CONFIG_ID operations"
        assign_service_account_iam_member "omnistrate-tf-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.workloadIdentityUser" "serviceAccount:$PROJECT_ID.svc.id.goog[dataplane-agent/omnistrate-da-$ACCOUNT_CONFIG_ID]"
    fi
}

# Function to assign workload identity user roles to service accounts
assign_workload_identity_user_roles() {
    local pool_name="omnistrate-bootstrap-id-pool"
    local bootstrap_sa="system:serviceaccount:bootstrap:$BOOTSTRAP_SERVICE_ACCOUNT_NAME"
    assign_service_account_iam_member "bootstrap-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.workloadIdentityUser" "principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$pool_name/subject/$bootstrap_sa"
    assign_service_account_iam_member "config-connector-sa@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.workloadIdentityUser" "serviceAccount:$PROJECT_ID.svc.id.goog[cnrm-system/cnrm-controller-manager]"
    assign_service_account_iam_member "omnistrate-da-$ACCOUNT_CONFIG_ID@$PROJECT_ID.iam.gserviceaccount.com" "roles/iam.workloadIdentityUser" "serviceAccount:$PROJECT_ID.svc.id.goog[dataplane-agent/omnistrate-da-$ACCOUNT_CONFIG_ID]"
}

# Main function to orchestrate the script execution
main() {
    validate_and_set_params "$@"
    gcloud config set project $PROJECT_ID
    log "Checking required APIs..."
    enable_api "iam.googleapis.com"
    enable_api "cloudresourcemanager.googleapis.com"
    enable_api "compute.googleapis.com"
    enable_api "container.googleapis.com"
    create_autopilot_cluster
    bootstrap_service_account
    config_connector_service_account
    omnistrate_service_account
    omnistrate_da_service_account

    create_custom_role_and_assign
    create_workload_identity_pool_and_oidc_provider
    assign_workload_identity_user_roles
    assign_tf_user_roles
    delete_autopilot_cluster
    log "Script completed successfully."
}

main "$@"

# Usage examples
# Example 1: Basic setup
# Usage examples
# Example 1: Basic setup
# ./gcp.sh --project-id stunning-strand-448500-f3 --project-number 19204196556 --account-config-id org-EUVvex3bVm --bootstrap-service-account-name bootstrap-dev-sa --issuer-uri https://oidc.eks.us-west-2.amazonaws.com/id/C1B03794957A09E4D89FF950EFDF99C4
# ./gcp.sh --project-id sinuous-concept-448502-v4 --project-number 1070032239947 --account-config-id org-EUVvex3bVm --bootstrap-service-account-name bootstrap-dev-sa --issuer-uri https://oidc.eks.us-west-2.amazonaws.com/id/C339DC3726AD36506FB7ABE55754784F
# ./gcp.sh --project-id stunning-strand-448500-f3 --project-number 19204196556 --account-config-id org-EUVvex3bVm --bootstrap-service-account-name bootstrap-sa --issuer-uri https://oidc.eks.us-west-2.amazonaws.com/id/9AEF0C846C22DEAEFDDD1F98C6AB9FEA

# Example 2: Setup with custom Terraform roles
# ./gcp.sh --project-id my-project-id --project-number 123456789012 --account-config-id my-config-id --bootstrap-service-account-name bootstrap-dev-sa --issuer-uri https://oidc.eks.us-west-2.amazonaws.com/id/$OIDC_ID --service-model-roles "model1:role1,role2 model2:role3,role4"