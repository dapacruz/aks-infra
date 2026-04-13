#!/usr/bin/env bash

set -e

terraform init -backend-config="backend.tfbackend"

