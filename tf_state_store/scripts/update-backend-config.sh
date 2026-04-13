#!/usr/bin/env bash

set -euo pipefail

FILE="../infra/backend.tfbackend"

perl -i -pe "s|^storage_account_name\s*=.*|storage_account_name = \"$STORAGE_ACCOUNT_NAME\"|" "$FILE"
perl -i -pe "s|^container_name\s*=.*|container_name = \"$CONTAINER_NAME\"|"                   "$FILE"
perl -i -pe "s|^tenant_id\s*=.*|tenant_id = \"$TENANT_ID\"|"                                 "$FILE"
perl -i -pe "s|^subscription_id\s*=.*|subscription_id = \"$SUBSCRIPTION_ID\"|"               "$FILE"
perl -i -pe "s|^client_id\s*=.*|client_id = \"$CLIENT_ID\"|"                                 "$FILE"
perl -i -pe "s|^client_secret\s*=.*|client_secret = \"$CLIENT_SECRET\"|"                     "$FILE"

