#!/usr/bin/env bash
set -Eeuo pipefail

_ENTERPRISE_RUNNER=${ENTERPRISE_RUNNER:-false}
_ORG_RUNNER=${ORG_RUNNER:-false}
_GITHUB_HOST=${GITHUB_HOST:="github.com"}

# If URL is not github.com then use the enterprise api endpoint
if [[ ${GITHUB_HOST} = "github.com" ]]; then
    URI="https://api.${_GITHUB_HOST}"
else
    URI="https://${_GITHUB_HOST}/api/v3"
fi

API_VERSION=v3
API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
AUTH_HEADER="Authorization: token ${ACCESS_TOKEN}"

REPO_URL=${REPO_URL:-${URI}}
_PROTO="$(echo "${REPO_URL}" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
# shellcheck disable=SC2116
_URL="$(echo "${REPO_URL/${_PROTO}/}")"
_PATH="$(echo "${_URL}" | grep / | cut -d/ -f2-)"
_ACCOUNT="$(echo "${_PATH}" | cut -d/ -f1)"
_REPO="$(echo "${_PATH}" | cut -d/ -f2)"

if [[ ${_ENTERPRISE_RUNNER} == "true" ]]; then
  [[ -z ${ENTERPRISE_NAME} ]] && ( echo "ENTERPRISE_NAME required for enterprise runners"; exit 1 )
  _FULL_URL="${URI}/enterprises/${ENTERPRISE_NAME}/actions/runners/registration-token"
  _SHORT_URL="${_PROTO}${_GITHUB_HOST}/enterprises/${ENTERPRISE_NAME}"
elif [[ ${_ORG_RUNNER} == "true" ]]; then
  [[ -z ${ORG_NAME} ]] && ( echo "ORG_NAME required for org runners"; exit 1 )
  _FULL_URL="${URI}/orgs/${ORG_NAME}/actions/runners/registration-token"
  _SHORT_URL="${_PROTO}${_GITHUB_HOST}/${ORG_NAME}"
else
  _FULL_URL="${URI}/repos/${_ACCOUNT}/${_REPO}/actions/runners/registration-token"
  _SHORT_URL=${REPO_URL}
fi

RUNNER_TOKEN="$(curl -XPOST -fsSL \
  --connect-timeout 5 \
  -H "${AUTH_HEADER}" \
  -H "${API_HEADER}" \
  "${_FULL_URL}" \
| jq -r '.token')"

echo "{\"token\": \"${RUNNER_TOKEN}\", \"short_url\": \"${_SHORT_URL}\", \"full_url\": \"${_FULL_URL}\"}"
