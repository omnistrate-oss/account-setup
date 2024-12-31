# account-setup
Terraform script to setup your account to provision your services

## Setup your AWS account for Omnistrate
### Please replace the `suffix-from-platform` with the ID shown on the create account config screen
```bash
cd aws
terraform init
TF_VAR_account_config_identity_id=<suffix-from-platform> terraform apply
```

## Setup your GCP account for Omnistrate
### Ensure the following services are enabled (please replace the `project-id` with your project ID)
- IAM Service Account Credentials API
https://console.cloud.google.com/apis/library/iamcredentials.googleapis.com?project=project-id
- Cloud Resource Manager API
https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com?project=project-id
- Compute Engine APIs
https://console.cloud.google.com/apis/library/compute.googleapis.com?project=project-id
- Kubernetes Engine APIs
https://console.cloud.google.com/apis/library/container.googleapis.com?project=project-id

then run the following commands:

```bash
cd gcp
gcloud auth application-default login
terraform init
TF_VAR_project_id=<project-id> TF_VAR_project_number=<project-number> TF_VAR_account_config_identity_id=<suffix-from-platform> terraform apply
```

NOTE: For brand new GCP accounts, you will need to perform an initialization step. 

- Please create an autopilot gke cluster with defaults.
- Once it's ready, please re-run the terraform.
- Once that is complete, you can delete the autopilot gke

It's a long running issue on GCP side where it doesn't setup the default identity pool for gke until the first cluster is created
