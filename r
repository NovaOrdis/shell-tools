#!/usr/bin/env bash

[[ -f $(dirname $0)/std.shlib ]] && . $(dirname $0)/std.shlib || { echo "$(dirname $0)/std.shlib not found" 1>&2; exit 1; }

function display-help-build() {

cat <<EOF

Builds a Spring Boot project. The command must be invoked from project root.

Usage:

    b [-c] [-r] [--no-tests]

Options:

    -c - clean

    -r - refresh dependencies, equivalent to passing --refresh-dependencies to Gradle.

    --no-tests - do not run tests.

EOF
}

function display-help-run() {

cat <<EOF

Executes the current project. The project can be a Spring Boot project, a simple Gradle Java project that
contains a main class, etc. In case of a Spring Boot project, we assume we're in the project home of the
Spring Boot microservice and we run the "fat" JAR locally.

The runner supports an optional configuration file .rconfig in the project home directory. The configuration
file may contain:

* The active profile:

  active.profile=...

EOF
}

function display-help-test() {

cat <<EOF

Not sure what this does.

EOF
}

function display-help-deploy() {

cat <<EOF

Deploys the application distribution, packaged as ZIP, as found under the ./build/distributions directory.
The deployment consists in removing the old version, and unpacking the new version. The script should be
run from the root of the project (or from the root of the root project).

EOF
}


function main()  {

    local command
    local link_name=$(basename $0)

    if [[ ${link_name} = "b" ]]; then

        command="build"

    elif [[ ${link_name} = "r" ]]; then

        command="run"

    elif [[ ${link_name} = "t" ]]; then

        command="test"

    elif [[ ${link_name} = "d" ]]; then

        command="deploy"

    else

        error "unknown link ${link_name}"
        exit 1
    fi

    while [[ -n $1 ]]; do

        if [[ "help" = $1 || "--help" = $1 ]]; then

            display-help-${command}
            return 0
        fi

        shift
    done


  local clean;
  local no_tests
  local refresh_dependencies

  while [[ -n "$1" ]]; do

    if [[ "$1" = "-c" ]]; then

        clean="clean"

    elif [[ "$1" = "-r" ]]; then

       refresh_dependencies="--refresh-dependencies";

    elif [[ "$1" = "--no-tests" ]]; then

        no_tests="-x test"
    fi
    shift
  done

  local command="gradle ${clean} build ${no_tests} ${refresh_dependencies}"
  echo ${command}
  exec ${command}
}

function do-test() {

    debug "do-test($@)"

    local debug=false
    local clean=false
    local refresh_dependencies=false
    local single_test

    while [[ -n "$1" ]]; do

        if [[ "$1" = "-d" ]]; then

            debug=true;

        elif [[ "$1" = "-c" ]]; then

            clean=true;

        elif [[ "$1" = "-r" ]]; then

            refresh_dependencies=true;

        elif [[ -z "${single_test}" ]]; then

            single_test=$1
        fi

        shift
    done

    ${debug} && debug_opts="--debug-jvm"
    [ -n "${single_test}" ] && single_test_spec="--tests ${single_test}"

    ${clean} && clean_opt="clean"
    ${refresh_dependencies} && refresh_dependencies_opt="--refresh-dependencies"

    echo gradle ${clean_opt} test ${debug_opts} ${single_test_spec} ${refresh_dependencies_opt}
    gradle ${clean_opt} test ${debug_opts} ${single_test_spec} ${refresh_dependencies_opt}
}

#
# run
#
#

# Optional configuration file. May contain:
#   Active Profile: active.profile=...
#
#RCONFIG_FILE=$(pwd)/.rconfig
#
#function main() {
#
#    local debug=false;
#    local trace=false;
#    local args
#
#    while [ -n "$1" ]; do
#
#        if [ "--help" = "$1" ]; then
#
#            display_help;
#            return 0;
#
#        elif [ "-d" = "$1" ]; then
#
#            debug=true;
#
#        elif [ "--trace" = "$1" ]; then
#
#            trace=true;
#
#        else
#
#            args="${args} $1"
#        fi
#
#        shift
#    done
#
#    local lib_dir=./build/libs
#
#    check-whether-we-are-in-project-home-or-fail ${lib_dir};
#
#    local jar=$(get-spring-boot-jar ${lib_dir})
#
#    [ -z "${jar}" ] && { error "no Spring Boot JAR found in ${lib_dir} "; exit 1; }
#
#    if ${debug}; then
#
#        debug_args="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005";
#        debug_flag="--debug"
#    fi
#
#    if ${trace}; then
#
#        trace_flag="--trace"
#    fi
#
#    local active_profile=$(get-active-profile-from-rconfig)
#
#    [ -n "${active_profile}" ] && active_profile_command_line="-Dspring.profiles.active=${active_profile}"
#
#    #if [ -z "${main_class}" ]; then
#        #java ${debug_args} -jar ${jar} --spring.profiles.active=local
#        #-Dspring.flyway.baselineOnMigrate=true
#        echo java ${debug_args} ${active_profile_command_line} -jar "${jar}" ${debug_flag} ${trace_flag} ${args}
#        java ${debug_args} ${active_profile_command_line} -jar "${jar}" ${debug_flag} ${trace_flag} ${args}
#    #else
#    #    java ${debug_args} -cp ${jar} ${main_class} ${debug_flag} ${trace_flag} ${args}
#    #fi
#}
#
#function check-whether-we-are-in-project-home-or-fail() {
#
#    local lib_dir=$1
#
#    [ -z ${lib_dir} ] && { error "'lib_dir' not specified"; exit 1; }
#
#    [ -d ${lib_dir} ] || { error "$(pwd)/${lib_dir} directory not found. The script must be run from a project home ..."; exit 1; }
#}
#
##
## returns empty string if no JAR is found
##
#function get-spring-boot-jar() {
#
#    local lib_dir=$1
#
#    [ -z ${lib_dir} ] && { error "'lib_dir' not specified"; exit 1; }
#
#    find ${lib_dir} -name "*.jar"
#}
#
## return empty string if .rconfig does not esist or it does not contain an active profile
#function get-active-profile-from-rconfig() {
#
#    [ ! -f ${RCONFIG_FILE} ] && return 0;
#
#    cat ${RCONFIG_FILE} | grep "^active\.profile=" | sed -e 's/^.*=//'
#}


#
# deploy
#

#RUNTIME_DIR=/Users/ovidiu/runtime
#VERBOSE=false
#
#function main() {
#
#    local dir
#
#    dir=$(find-build-distributions-dir) || exit 1
#
#    [[ -z ${dir} ]] && { echo "[error]: no 'distributions' directory found in $(pwd) ... Has the project been built?" 1>&2; exit 1; }
#
#    local application_name=$(get-application-name)
#
#    debug "application name: ${application_name}"
#
#    [[ -z ${application_name} ]] && { echo "[error]: cannot figure out application name" 1>&2; exit 1; }
#
#    local distribution
#
#    distribution=$(find-zip-file ${dir} ${application_name}) || exit 1
#
#    debug "distribution: ${distribution}"
#
#    [[ -z ${distribution} ]] && { echo "[error]: no distribution ZIP file found in ${dir} ... Has the project been built?" 1>&2; exit 1; }
#
#    local version
#
#    version=$(get-version)
#
#    debug "version: ${version}"
#
#    [[ -n ${version} ]] && version="-${version}"
#
#    local top_directory_name=$(basename ${distribution} .zip)
#    debug "top directory: ${top_directory_name}"
#
#    [[ -d ${RUNTIME_DIR}/${top_directory_name} ]] && { rm -r ${RUNTIME_DIR}/${top_directory_name} && echo "${RUNTIME_DIR}/${top_directory_name} removed"; }
#
#    unzip -q ${distribution} -d ${RUNTIME_DIR} && echo "${top_directory_name} deployed in ${RUNTIME_DIR}"
#
#    (cd ${RUNTIME_DIR}; ln -sf ./${top_directory_name} ${application_name}) && echo "${application_name} linked to ${top_directory_name}"
#}
#
#function find-build-distributions-dir() {
#
#    local dir
#
#    find $(pwd) -type d -name distributions
#}
#
#function find-zip-file () {
#
#    local dir=$1
#    local application_name=$2
#
#    find ${dir} -type f -name ${application_name}'*.zip'
#}
#
##
## return "" if version cannot be determined
##
#function get-version () {
#
#    local gradle_properties=$(pwd)/gradle.properties
#
#    [[ ! -f ${gradle_properties} ]] && { echo "gradle.properties not found, cannot read version" 1>&2; return 1; }
#
#    cat ${gradle_properties} | grep "^version" | sed -e 's/version=//'
#}
#
##
## return "" if application name cannot be determined
##
#function get-application-name () {
#
#    local settings_gradle=$(pwd)/settings.gradle
#
#    [[ ! -f ${settings_gradle} ]] && { echo "settings.gradle not found, cannot read application name" 1>&2; return 1; }
#
#    local application_name=$(cat ${settings_gradle} | grep "^rootProject" | sed -e 's/^.*= *//')
#    application_name=${application_name#\'}
#    application_name=${application_name%\'}
#
#    echo ${application_name}
#}

main "$@"
