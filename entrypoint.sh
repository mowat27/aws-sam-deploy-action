#!/usr/bin/env bash

# Shortcut environment checks and start bash for debugging
if [[ $1 == "/bin/bash" ]]; then 
  exec /bin/bash 
fi

# We only accept AWS credentials from environment variables.  This is fine 
# because the container does not include the aws cli so no profiles will be 
# available.
# We require region access key and secret as a bare minimum and it's up to the 
# caller to attend to other details such as session tokens which should be
# provided via standard AWS variable names.
if [[ -z "$AWS_ACCESS_KEY_ID" || 
      -z "$AWS_SECRET_ACCESS_KEY" || 
      -z "$AWS_DEFAULT_REGION" ]]; then 
  cat >&2 <<EOF 
ERROR : AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and 
        AWS_DEFAULT_REGION must be set.
        
AWS_SESSION_TOKEN should also be be provided if you are assuming a role.
EOF
  exit 1
fi

# Validate deployment params 
if [[ -z "$S3_BUCKET" || -z "$STACK_ID" || 
      -z "$APP_NAME" || -z "$CLOUDFRONT_PARAMETER_OVERRIDES" ]]; then 
  cat >&2 <<EOF 
ERROR : Missing SAM deployment config variables.

The following variables are required.

- APP_NAME: Name of the serverless application
- STACK_ID: Unique identifier that is used to name seperate deployments of a 
            stack within an account and/or region.
- CLOUDFRONT_PARAMETER_OVERRIDES: Override values for cloudformation.
- S3_BUCKET: S3 Bucket for Cloudformation changesets

You sent:

APP_NAME="$APP_NAME"
STACK_ID="$STACK_ID"
CLOUDFRONT_PARAMETER_OVERRIDES="$CLOUDFRONT_PARAMETER_OVERRIDES"
S3_BUCKET="$S3_BUCKET"
EOF
  exit 1
fi

# Enter bash strict mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# set -euo pipefail
# IFS=$'\n\t'

function output {
  echo "::set-output name=$1::$2"
}

# shellcheck disable=2001,2086
function write_config {
cat > samconfig.toml <<EOF
version = 0.1
[default]
[default.deploy]
[default.deploy.parameters]
stack_name = "$STACK_ID-$APP_NAME"
s3_bucket = "$S3_BUCKET"
s3_prefix = "$APP_NAME"
region = "$AWS_DEFAULT_REGION"
confirm_changeset = false
capabilities = "CAPABILITY_IAM"
parameter_overrides = "$(echo $CLOUDFRONT_PARAMETER_OVERRIDES | sed 's/"/\\"/g')"
EOF
}

action=$1; shift
if [[ -z $action ]]; then 
  echo >&2 "Please pass up, down or a command to run"
fi

case "$action" in 
  # Deploy the AWS SAM clouformation template
  "up")
    write_config
    sam build && sam deploy \
                    --no-confirm-changeset \
                    --no-fail-on-empty-changeset
    ;;

  # Delete the AWS SAM clouformation stack and all its resources
  "down")
    echo >&2 "Delete has not been implemented yet"
    exit 1
    ;;
  *)
    exec "$action" "$@"
esac

