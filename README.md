# account-setup
Terraform script to setup the account to provision the dataplane in

## Setup your AWS account for Omnistrate
```bash
cd aws
terraform init
terraform apply
```

## Setup your GCP account for Omnistrate
### Ensure the following services are enables (please replace the `project-id` with your project ID)
- IAM Service Account Credentials API
https://console.cloud.google.com/apis/library/iamcredentials.googleapis.com?project=project-id
- Compute Engine APIs
https://console.cloud.google.com/apis/library/compute.googleapis.com?project=project-id
- Kubernetes Engine APIs
https://console.cloud.google.com/apis/library/container.googleapis.com?project=project-id

### Setup
```bash
cd gcp
gcloud auth application-default login
terraform init
TF_VAR_project_id=<project-id> TF_VAR_project_number=<project-number> terraform apply
```