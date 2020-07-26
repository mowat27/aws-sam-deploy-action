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

# Enter bash strict mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# set -euo pipefail
# IFS=$'\n\t'

function output {
  echo "::set-output name=$1::$2"
}

action=$1; shift
if [[ -z $action ]]; then 
  echo >&2 "Please pass up, down or a command to run"
fi

case "$action" in 
  # Deploy the AWS SAM clouformation template
  "up")
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

