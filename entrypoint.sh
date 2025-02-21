#!/usr/bin/env bash
set -Eeuo pipefail

export RUNNER_ALLOW_RUNASROOT=1
export PATH=$PATH:/actions-runner

deregister_runner() {
  echo "Caught SIGTERM. Deregistering runner"
  _TOKEN=$(bash /token.sh)
  RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)
  ./config.sh remove --token "${RUNNER_TOKEN}"
  exit
}

_RUNNER_ID=$(cat /etc/hostname)
_RUNNER_NAME=${RUNNER_NAME:-${RUNNER_NAME_PREFIX:-github-runner}-${_RUNNER_ID}}
_RUNNER_WORKDIR=${RUNNER_WORKDIR:-/_work}/${_RUNNER_ID}
_LABELS=${LABELS:-default}
_RUNNER_GROUP=${RUNNER_GROUP:-Default}
_SHORT_URL=${REPO_URL:-}
_GITHUB_HOST=${GITHUB_HOST:="github.com"}

if [[ ${ORG_RUNNER:-} == "true" ]]; then
  _SHORT_URL="https://${_GITHUB_HOST}/${ORG_NAME}"
fi

if [[ -n "${ACCESS_TOKEN}" ]]; then
  _TOKEN=$(bash /token.sh)
  RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)
  _SHORT_URL=$(echo "${_TOKEN}" | jq -r .short_url)
fi

mkdir -p ${_RUNNER_WORKDIR}

echo "Configuring"
./config.sh \
    --url "${_SHORT_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${_RUNNER_NAME}" \
    --work "${_RUNNER_WORKDIR}" \
    --labels "${_LABELS}" \
    --runnergroup "${_RUNNER_GROUP}" \
    --unattended \
    --replace

unset RUNNER_TOKEN
trap deregister_runner SIGINT SIGTERM ERR EXIT

./bin/runsvc.sh
