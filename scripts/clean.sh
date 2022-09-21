#!/bin/sh

BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
LIGHT_GREEN='\033[1;32m'
LIGHT_PURPLE='\033[1;35m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m' # No Color

errors=0
GIT_REPO_ROOT=$(git rev-parse --show-toplevel)

printf "Entering directory ${BLUE}${GIT_REPO_ROOT}/${NO_COLOR}\n\n"

find ${GIT_REPO_ROOT} -type d -name '.terraform' \
  | sed "s~^${GIT_REPO_ROOT}/~~" | sort -u \
  | xargs -I % sh -c "test ! -f %/terraform.tfstate && echo \"${RED}Deleting directory${NO_COLOR} ${BLUE}%${NO_COLOR}\" && rm -rf ${GIT_REPO_ROOT}/%" \
  || errors=$((errors+1))
echo ""

find ${GIT_REPO_ROOT} -type f -name '*.tfplan' \
  | sed "s~^${GIT_REPO_ROOT}/~~" | sort -u \
  | xargs -I % sh -c "echo \"${RED}Deleting file${NO_COLOR} ${BLUE}%${NO_COLOR}\" && rm -f ${GIT_REPO_ROOT}/%" \
  || errors=$((errors+1))
echo ""

if [ -d ${GIT_REPO_ROOT}/src/modules ]; then
  find ${GIT_REPO_ROOT}/src/modules -type f -name '.terraform.lock.hcl' \
    | sed "s~^${GIT_REPO_ROOT}/~~" | sort -u \
    | xargs -I % sh -c "echo \"${RED}Deleting file${NO_COLOR} ${BLUE}%${NO_COLOR}\" && rm -f ${GIT_REPO_ROOT}/%" \
    || errors=$((errors+1))
fi

exit $errors
