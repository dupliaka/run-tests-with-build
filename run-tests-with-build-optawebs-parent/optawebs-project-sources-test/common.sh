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
        exit 1
    fi
    # get image name from FROM operation
    _image_name="$(grep FROM "${_dockerfile}" | sed 's/FROM //')"

    _repository="$(grep FROM "${_dockerfile}" | sed 's/FROM //' | sed 's;docker.io/;;'| sed 's;:*;;')"
    _tag="$(grep FROM "${_dockerfile}" | sed 's;*:;;')"

    # get authorization token
    _token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$_repository:pull" | jq -r .token)
    # get image digest for target without pulling the image
    _digest=$(curl -s -D - -H "Authorization: Bearer ${_token}" -H "Accept: application/vnd.docker.distribution.manifest.v2+json" https://index.docker.io/v2/${_repository}/manifests/${_tag} | grep docker-content-digest | cut -d ' ' -f 2)

    if [ -z "${_digest}" ] || [ "${_digest}" = "null" ]; then
        echo "Failed to resolve $_digest image hash for file ${_dockerfile}"
    else
    # concat image name and hash
    _image="${_repository}"@"${_digest}"
    # substitude new image coordinate
        sed -i 's;FROM*;FROM "${_image}";' "${_dockerfile}"
        echo "Replaced image name to $(grep FROM "${_dockerfile}")"
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

