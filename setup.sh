#!/bin/bash

################################################################################
# General settings

# If you change this variable, please ensure it is also added to .gitignore
WORKSPACE=ws
DEPENDENCIES_FILE=dependencies.txt
ERROR=
VERBOSE=0
SWITCH_BRANCH=0
PULL=0

usage() {
    echo "Usage: $0 [ -h ] [ -v ] [ -b BRANCH ]" 1>&2
    echo "  -h:         Print this help message." 1>&2
    echo "  -v:         Verbose" 1>&2
    echo "  -b BRANCH:  Check out BRANCH in every repository (only if the branch exists)." 1>&2
    echo "  -p:         Pull changes from upstream in every repository." 1>&2
}

while getopts ":hvb:p" opt; do case $opt in
    h)
        usage
        exit 0
        ;;
    v)
        VERBOSE=1
        ;;
    b)
        echo "Checking out branch $OPTARG in every repository (if existing)." >&2
        BRANCH=$OPTARG
        SWITCH_BRANCH=1
        ;;
    p)
        PULL=1
        ;;
    *)
        echo "Unknown access method. Error! (*)" >&2
        echo
        usage
        exit 1
        ;;
esac done


################################################################################
# Check for local changes in a cloned git repository.

check_for_and_report_local_changes() {
    local dir="$1"
    changes=0
    git -C ${dir} diff --no-ext-diff --quiet --exit-code || changes=1
    if [ ${changes} = 0 ]; then
        changes=$(git -C ${dir} ls-files --exclude-standard --others | wc -l)
    fi

    if [ ${changes} = 0 ]; then
        return 0
    fi

    if [ -n "${changes}" ]; then
        echo
        echo -e "\e[31m!!!! ===> There are uncommited changes <=== !!!!\e[0m"
        git status
    fi
}

################################################################################
# Report remote changes

check_for_and_report_remote_changes() {
    local dir="$1"
    git -C ${dir} remote update > /dev/null
    remote_status=$(LANG=C git -C ${dir} status -uno | grep "Your branch")
    if [[ ${remote_status} != *"up to date"* ]]; then
        echo -e "\e[31m $remote_status \e[0m"
    fi
}

################################################################################
# Check if target directory exists, if yes, check URL, otherwise clone.

ensure_is_cloned() {
    local basename="$1"
    local url="$2"
    local git_tag="$3"

    local dir="${WORKSPACE}/${basename}"

    if [[ $VERBOSE == 1 ]]; then
        echo
        echo -e "\e[34m########################################################################\e[0m"
    fi
    echo -e "\e[34mChecking ${dir}\e[0m"
    if [[ $VERBOSE == 1 ]]; then
        echo
    fi

    if [ -d "${dir}" ]; then
        local current_branch=$(git -C ${dir} rev-parse --abbrev-ref HEAD)

        if [[ "${current_branch}" != "${git_tag}" ]]; then
            color="\e[95m"
            echo -e "${color}current branch: ${current_branch}\e[0m"
            if [[ $VERBOSE == 1 ]]; then
                echo -e "${color}     should be: ${git_tag}\e[0m"
            fi
        else
            if [[ $VERBOSE == 1 ]]; then
                echo -e "\e[32mcurrent branch: ${current_branch}"
                echo -e "\n\e[0m"
            fi
        fi
    fi

    if [ -d "${dir}" ]; then
        local REMOTE_REPO=$(git -C ${dir} remote -v || echo "nothing")
        local reponame=$(echo $url | sed -E "s/.+github\.com\/(.+)/\1/g")
        if [[ ${REMOTE_REPO} != *"${reponame}"* ]]; then
            echo
            echo -e "\e[31m!!!! ===> THIS IS AN ERROR OR INCONSISTENCY <=== !!!!\e[0m"
            echo -e "\e[31mI expected ${url}, "
            echo -e "but ${dir} seems not to be under version control.\e[0m"
            echo -e
            ERROR=true
        else
            if [[ $VERBOSE == 1 ]]; then
                echo "${dir} already exists, its remote repositories are"
                echo "${REMOTE_REPO}"
            fi
            check_for_and_report_local_changes ${dir}
            check_for_and_report_remote_changes ${dir}
            if [[ $PULL == 1 ]]; then
                apply_git_pull ${dir}
            fi
        fi
    else
        echo "Cloning branch ${git_tag} from ${url} to ${dir} ..."
        git clone --branch "${git_tag}" "${url}" "${dir}"
    fi
}

################################################################################
# Checkout branch $BRANCH

checkout_branch() {
    local basename="$1"
    local branch="$2"

    local dir="${WORKSPACE}/${basename}"
    (
        cd ${dir}
        branch_switched=0
        git checkout $BRANCH && branch_switched=1 || true
        if [ ${branch_switched} == 1 ]; then
            echo
            echo -e "\e[31m!!!! ===> Branch $BRANCH checked out <=== !!!!\e[0m"
        fi
    )
}

################################################################################
# Pull repository

apply_git_pull() {
    local dir="$1"
    (
        git -C ${dir} pull
    )
}

################################################################################
# Find location this file is in
# Stolen from https://stackoverflow.com/a/246128/1528210

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
THIS_SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

################################################################################
# Read dependencies from file and check if directory already exists or clone them

sed -e '/^[[:space:]]*$/ d' -e '/^#/ d' ${THIS_SCRIPT_DIR}/${DEPENDENCIES_FILE} |
    while read line; do
        line_as_array=(${line})

        name=${line_as_array[0]}
        repository=${line_as_array[1]}
        git_tag=${line_as_array[2]}
        additional_args=${line_as_array[3]}

        ensure_is_cloned "${name}" "${repository}" "${git_tag}"

        if [ ${SWITCH_BRANCH} == 1 ]; then
            checkout_branch "${name}" "${BRANCH}"
        fi
    done

if [[ ${ERROR} != "" ]]; then
    echo
    echo -e "\e[95m########################################################################\e[0m"
    echo -e "\e[1m\e[31mThere were errors during setup, please check the output!\e[0m"
    echo -e "\e[95m########################################################################\e[0m"
    echo
    git status
fi

if [[ $VERBOSE == 1 ]]; then
    echo
    echo -e "\e[34m########################################################################\e[0m"
    echo -e "\e[34mChecking ${PWD}\e[0m"
    echo
else
    echo -e "\e[34mChecking ${PWD}\e[0m"
    check_for_and_report_local_changes .
    check_for_and_report_remote_changes .
    if [[ $PULL == 1 ]]; then
        apply_git_pull .
    fi
fi
