#!/usr/bin/env bash

set -e

cd tf_state_store

echo -e "\nInitializing tf_state_store ...\n"
terraform init

echo -e "\nDeploying tf_state_store ...\n"
terraform apply -auto-approve

CONTAINER_NAME=$(terraform output -raw container_name)
STORAGE_ACCOUNT=$(terraform output -raw storage_account_name)

cd ../infra

echo -en "\nInitializing infra ..."
until terraform init -backend-config="backend.tfbackend" &>/dev/null; do
    echo -n "."
    rm -fr .terraform .terraform.lock.hcl
    sleep 10
done
echo " done"

echo -en "\nWaiting for state lock to be released ..."
until [[ -z $(az storage blob show \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$CONTAINER_NAME" \
  --name "aks-infra/terraform.tfstate" \
  --auth-mode login \
  --query "properties.metadata.terraformlockid" -o tsv 2>/dev/null) ]]; do
  echo -n "."
  sleep 10
done
echo " done"

echo -e "\nDeploying infra ...\n"
terraform apply -auto-approve

AKS_RG_NAME=$(terraform output -raw aks_resource_group_name)
AKS_CLUSTER_NAME=$(terraform output -raw aks_cluster_name)

echo -e "\nUpdating AKS credentials ...\n"
az aks get-credentials --resource-group $AKS_RG_NAME --name $AKS_CLUSTER_NAME --overwrite-existing

