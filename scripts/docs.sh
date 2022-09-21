#!/bin/sh

BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
LIGHT_GREEN='\033[1;32m'
LIGHT_PURPLE='\033[1;35m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m' # No Color

PROJECT_DIR=$(git rev-parse --show-toplevel)
SCRIPT_DIR="${PROJECT_DIR}/scripts"

terraform_docs_readme() {
  directory="$(echo ${1} | sed "s~^${PROJECT_DIR}/~~")"
  use_lockfile="${2:-true}"
  if [ ! -f ${directory}/README.md ]; then
    printf "# ${directory##*/}\n\n<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->\n<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->\n" > ${PROJECT_DIR}/${directory}/README.md
    printf "${LIGHT_GREEN}${directory}/README.md created successfully${NO_COLOR}\n"
  fi
  printf "${LIGHT_BLUE}"
  terraform-docs --config ${SCRIPT_DIR}/config/terraform-docs.yaml --lockfile="${use_lockfile}" "${directory}"
  printf "${NO_COLOR}"
}

cd ${PROJECT_DIR}

printf "Entering directory ${BLUE}${PROJECT_DIR}/${NO_COLOR}\n\n\n"

# Print version of terraform
terraform -chdir=${PROJECT_DIR}/src/ version

# Update the root module's lockfile
terraform -chdir=${PROJECT_DIR}/src init -no-color -backend=false -input=false -upgrade=true
printf "\n\n"

# Print version of terraform-docs
terraform-docs version --config ${SCRIPT_DIR}/config/terraform-docs.yaml
printf "\n"

# Update the root module's readme using lockfile
terraform_docs_readme ${PROJECT_DIR}/src "true"

# Update child modules' readmes without using lockfiles
if [ -d ${PROJECT_DIR}/src/modules ]; then
  for directory in ${PROJECT_DIR}/src/modules/*; do
    terraform_docs_readme ${directory} "false"
  done
fi
