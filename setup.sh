#!/bin/bash

$CLOUD_PROVIDER=$1

check_command() {
    command -v "$1" >/dev/null 2>&1
}

check_install_brew() { 
    if [! check_command "brew"] 
    then
        echo "Homebrew is not installed. Installing it now."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "Home brew is installed."
}

get_cloud_provider() {
    echo "Select your cloud provider:"
    echo "0. Exit script"
    echo "1. Amazon Web Services (AWS)"
    echo "2. Google Cloud Platform (GCP)"
    read -p "Enter the number corresponding to your choice: " choice

    case $choice in
        0)
            CLOUD_PROVIDER="Not set"
            exit 1
            ;;
        1)
            CLOUD_PROVIDER="aws"
            ;;
        2)
            CLOUD_PROVIDER="gcp"
            ;;
        *)
            echo "Invalid choice. Please select 1 or 2 (or 0 to exit)."
            get_cloud_provider
            ;;
    esac
    echo "Cloud provider set to $CLOUD_PROVIDER."
}

if [ -z "$1" ] 
then
    get_cloud_provider
fi

check_install_brew

if [! check_command "git"]
then
    echo "Git is not installed. Installing it now."
    brew install git
fi

if [! check_command "terraform"]
then
    echo "Terraform is not installed. Installing it now."
    brew install terraform
fi

echo "Git and Terraform are installed, now cloning account-setup repository."

git clone https://github.com/omnistrate/account-setup.git account-setup

cd account-setup

cd $CLOUD_PROVIDER

terraform init

# Uncomment this line to automatically apply the changes
terraform apply #-auto-approve

exit 0