#!/bin/sh

BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
LIGHT_GREEN='\033[1;32m'
LIGHT_PURPLE='\033[1;35m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m' # No Color

test -d src && printf "Entering directory ${BLUE}src/${NO_COLOR}\n\n\n" && cd src

printf "${LIGHT_BLUE}Linting files...${NO_COLOR}\n"
find . -not -path '*/\.*' -type f -name "*.tf" -printf '%h\n' | sort -u | while read -r directory ; do
    printf "\n\nlinting directory ${BLUE}${directory}/${NO_COLOR}\n\n"
    cd $directory > /dev/null
    terraform fmt --write=true --diff=true
    cd - > /dev/null
done

printf "${LIGHT_BLUE}\nLinting complete.${NO_COLOR}\n\n"
