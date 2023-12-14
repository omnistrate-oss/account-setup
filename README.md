# account-setup
Terraform script to setup the customer's cloud provider account to provision the dataplane in, required for a BYOA scenario.

## Setup your AWS account for Omnistrate
```bash
cd aws
terraform init
terraform apply
```

## Setup your GCP account for Omnistrate
### Ensure the following services are enabled (please replace the `project-id` with your project ID)
- IAM Service Account Credentials API
https://console.cloud.google.com/apis/library/iamcredentials.googleapis.com?project=project-id
- Compute Engine APIs
https://console.cloud.google.com/apis/library/compute.googleapis.com?project=project-id
- Kubernetes Engine APIs
https://console.cloud.google.com/apis/library/container.googleapis.com?project=project-id

then run the following commands:

```bash
cd gcp
gcloud auth application-default login
terraform init
TF_VAR_project_id=<project-id> TF_VAR_project_number=<project-number> terraform apply
```

## Setup in one line

This installs brew, git and terraform, then initializes and applies the required config based on your cloud provider of choice, all you need is to run the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/omnistrate/account-setup/master/setup.sh)"
```

you can also specify the cloud provider directly as an argument:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/omnistrate/account-setup/master/setup.sh)" aws|gcp
```