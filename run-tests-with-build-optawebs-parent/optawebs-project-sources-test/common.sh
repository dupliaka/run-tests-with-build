#!/usr/bin/env bash

# Runs a cypress tests from a container
# param1: test application URL
# param2: directory containing a 'cypress' subdirectory with cypress tests
# param3: cypress image version
function run_cypress() {
  local _application_url=$1
  local _frontend_directory=$2
  local _cypress_image_version=$3
  local _container_runtime=$4

  "${_container_runtime}" run \
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
  while [[ "200" != $(curl -LI "${_application_url}" -o /dev/null -w '%{http_code}' -s) && ${_spent} -lt ${_timeout_seconds} ]]; do
    sleep ${_increment}
    _spent=$((_spent + _increment))
    echo "Waiting for ${_spent} seconds for ${_application_url} to become available."
  done
}

# Stores logs from all pods in the project
function store_logs_from_pods() {
  local _target_directory=$1
  for pod in $(oc get pods -o name); do
    sanitized_pod=${pod#"pod/"}
    oc logs "${sanitized_pod}" >"${_target_directory}/${sanitized_pod}.log"
  done
}

# Replaces FROM docker instruction to pull images by hashes
# param1: path to dockerfile
# param2: container runtime to request image information (docker/podman)
function replace_hash_names_in_dockerfile() {
    local _dockerfile=$1
    local _container_runtime=$2

    if [ ! -f "${_dockerfile}" ]; then
        echo "${_dockerfile} does not exist."
    fi
    # get image name from FROM operation
    _image_name="$(grep FROM "${_dockerfile}" | sed 's/FROM //')"
    # get hash by docker/podman image inspect
    _image_hash="$(${_container_runtime} image inspect "${_image_name}" | jq -r 'map(.RepoDigests)[0][0]' | sed -r 's/^.*@/@/')"

    if [ -z "${_image_hash}" ] || [ "${_image_hash}" = "null" ]; then
        echo "Failed to resolve $_image_name image hash for file ${_dockerfile}"
    else
    # concat image name and hash
        _image_hash_name=$(echo "${_image_name}" | sed -r 's/:.*$//')"${_image_hash}"
        echo "Replaced image name ${_image_name} to ${_image_hash_name}"
    # substitude new image coordinate
        sed -r -i 's;FROM [^\\s]+$;FROM '${_image_hash_name}';' "${_dockerfile}"
    fi
}

# Finds all Dockerfile and tries to resolve image names to hashes
# param1: path to basedir of the project
# param2: container runtime to request image information (docker/podman)
function replace_hash_names() {
    local _s_path=$1
    local _container_runtime=$2
    paths=$(find "${_s_path}" -name "Dockerfile*")
    echo "${paths}" | while read line; do
        replace_hash_names_in_dockerfile "${line}" "${_container_runtime}"
    done
}

