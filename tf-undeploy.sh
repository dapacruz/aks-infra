#!/usr/bin/env bash

set -e

cd infra

echo -e "\nDestroying infra ...\n"
terraform destroy -auto-approve
rm -fr .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

cd ../tf_state_store

echo -e "\nDestroying tf_state_store ...\n"
terraform destroy -auto-approve
rm -fr .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

