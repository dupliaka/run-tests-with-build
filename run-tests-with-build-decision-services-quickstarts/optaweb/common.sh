#!/usr/bin/env bash

# Runs a cypress tests from a container
# param1: test application URL
# param2: directory containing a 'cypress' subdirectory with cypress tests
# param3: cypress image version
function run_cypress() {
  local _application_url=$1
  local _frontend_directory=$2
  local _cypress_image_version=$3

  podman run \
      --network=host \
      --volume "${_frontend_directory}":/e2e:Z \
      --workdir /e2e \
      --entrypoint cypress \
      cypress/included:"${_cypress_image_version}" run --project . \
      --config baseUrl="${_application_url}"
}

# Waits for a URL to become available by returning HTTP 200 or timeout.
# param1: URL to wait for
# param2: timeout in seconds
function wait_for_url() {
  local _application_url=$1
  local _timeout_seconds=$2
  local _increment=1

  local _spent=0
  while [[ "200" != $(curl -LI "${_application_url}" -o /dev/null -w '%{http_code}' -s) && ${_spent} -lt ${_timeout_seconds} ]]
  do
    sleep ${_increment}
    _spent=$((_spent + _increment))
    echo "Waiting for ${_spent} seconds for ${_application_url} to become available."
  done
}

# Stores logs from all pods in the project
function store_logs_from_pods() {
  local _target_directory=$1
  for pod in $(oc get pods -o name)
  do
    sanitized_pod=${pod#"pod/"}
    oc logs "${sanitized_pod}" > "${_target_directory}/${sanitized_pod}.log"
  done
}
