#!/usr/bin/env bash

set -e

terraform init -backend-config="./config.azurerm.tfbackend"

