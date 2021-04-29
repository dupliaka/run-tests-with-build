#!/usr/bin/env bash

this_script_directory="${BASH_SOURCE%/*}"
if [[ ! -d "${this_script_directory}" ]]
then
  this_script_directory="$PWD"
fi

# shellcheck source=common.sh
. "${this_script_directory}/common.sh"

function display_help() {
  readonly script_name="./$(basename "$0")"

  echo "This script tests deployment of Optaweb Employee Rostering on OpenShift."
  echo "Usage:"
  echo "  ${script_name} PROJECT_BASEDIR CYPRESS_IMAGE_VERSION OPENSHIFT_API_URL OPENSHIFT_USER OPENSHIFT_PASSWORD"
  echo "  ${script_name} --help"
}

if [[ $1 == "--help" ]]
then
  display_help
  exit 0
fi

readonly project_basedir=$1
[[ -d ${project_basedir} ]] || {
  echo "Project base directory $project_basedir does not exist!"
  display_help
  exit 1
}

# login to OpenShift
readonly openshift_api_url=$3
readonly openshift_user=$4
readonly openshift_password=$5

oc login -u "${openshift_user}" -p "${openshift_password}" "${openshift_api_url}" --insecure-skip-tls-verify=true

#create new empty project
readonly uuid=$(uuidgen)
readonly openshift_project=employee-rostering-${uuid:0:8}
oc new-project "${openshift_project}"

# make sure the project is ready
oc get project "${openshift_project}"

chmod u+x "${project_basedir}"/runOnOpenShift.sh
yes | "${project_basedir}"/runOnOpenShift.sh || {
  echo "runOnOpenShift.sh failed!"
  echo "Saving logs and exiting."
  store_logs_from_pods "target"
  oc delete project "${openshift_project}"
  exit 1
}

readonly frontend_directory=$(find "${project_basedir}" -maxdepth 1 -name "*frontend")
[[ -d ${frontend_directory} ]] || {
  echo "No frontend module was found in ${project_basedir} as ${frontend_directory}!"
  display_help
  echo "Saving logs and exiting."
  store_logs_from_pods "target"
  oc delete project "${openshift_project}"
  exit 1
}

readonly application_url="http://$(oc get route frontend -o custom-columns=:spec.host | tr -d '\n')"
# wait for the application to become available
wait_for_url "${application_url}" 60

# run the cypress test
readonly cypress_image_version=$2
run_cypress "${application_url}" "${frontend_directory}" "${cypress_image_version}"

# store logs from all pods in the project
store_logs_from_pods "target"

# delete the project after the test run
oc delete project "${openshift_project}"
