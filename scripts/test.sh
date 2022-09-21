#!/bin/sh

BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
LIGHT_GREEN='\033[1;32m'
LIGHT_PURPLE='\033[1;35m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m' # No Color

export AWS_REGION=${AWS_REGION:-us-west-2}
GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
success=true

printf "Entering directory ${BLUE}${GIT_REPO_ROOT}${NO_COLOR}\n\n\n"

function clean_modules() {
    if [ -d ${GIT_REPO_ROOT}/src/modules ]; then
        find ${GIT_REPO_ROOT}/src/modules -type d -name '.terraform' \
            | sed "s~^${GIT_REPO_ROOT}/~~" | sort -u \
            | xargs -I % sh -c "test ! -f %/terraform.tfstate && echo \"${RED}Deleting directory${NO_COLOR} ${BLUE}%${NO_COLOR}\" && rm -rf ${GIT_REPO_ROOT}/%" \
            || errors=$((errors+1))
        echo ""
        find ${GIT_REPO_ROOT}/src/modules -type f -name '.terraform.lock.hcl' \
            | sed "s~^${GIT_REPO_ROOT}/~~" | sort -u \
            | xargs -I % sh -c "echo \"${RED}Deleting file${NO_COLOR} ${BLUE}%${NO_COLOR}\" && rm -f ${GIT_REPO_ROOT}/%" \
            || errors=$((errors+1))
        echo "\n"
    fi
}

function terraform_init_validate() {
    printf "${LIGHT_BLUE}Initializing & Validating Syntax...${NO_COLOR}\n\n"
    find ${GIT_REPO_ROOT}/src -not -path '*/\.*' -type f -name "*.tf" -printf '%h\n' | sed "s~^${GIT_REPO_ROOT}/~~" | sed "s~^${GIT_REPO_ROOT}/~~" | sort -u | while read -r directory ; do
        printf "Initializing ${BLUE}${directory}/${NO_COLOR}\n"
        terraform -chdir="${GIT_REPO_ROOT}/$directory" init -backend=false -input=false > /dev/null && printf "${LIGHT_GREEN}Success!${NO_COLOR} Directory initialized.\n\n" || { success=false; }
        printf "Validating ${BLUE}${directory}/${NO_COLOR}\n"
        terraform -chdir="${GIT_REPO_ROOT}/$directory" validate || { success=false; printf "\n"; }
        $success
    done || { printf "${RED}Syntax Validation FAILED.${NO_COLOR}\n"; exit 1; }
    printf "${LIGHT_BLUE}Syntax Validation Passed.${NO_COLOR}\n"
}

function terraform_fmt() {
    printf "\n\n${LIGHT_BLUE}Checking Formatting...${NO_COLOR}\n\n"
    find ${GIT_REPO_ROOT}/src -not -path '*/\.*' -type f -name "*.tf" -printf '%h\n' | sed "s~^${GIT_REPO_ROOT}/~~" | sort -u | while read -r directory ; do
        printf "Formatting ${BLUE}${directory}/${NO_COLOR}\n"
        terraform -chdir="${GIT_REPO_ROOT}/$directory" fmt -check -write=false -diff=true && printf "${LIGHT_GREEN}Success!${NO_COLOR} Formatting is correct.\n\n" || { success=false; printf "\n"; }
        $success
    done || { printf "${RED}Some terraform files must be formatted, run 'make lint' to fix.${NO_COLOR}\n"; exit 1; }
    printf "${LIGHT_BLUE}Format Checks Passed.${NO_COLOR}\n\n\n"
}

clean_modules
terraform_init_validate
terraform_fmt
# clean_modules

printf "${LIGHT_GREEN}ALL TESTS PASSED √${NO_COLOR}\n"
