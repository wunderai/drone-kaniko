#!/busybox/sh

set -euo pipefail

export PATH=$PATH:/kaniko/

DOCKER_AUTH=`echo -n "${PLUGIN_USERNAME}:${PLUGIN_PASSWORD}" | base64 | tr -d "\n"`

REGISTRY=${PLUGIN_REGISTRY:-https://index.docker.io/v1/}

cat > /kaniko/.docker/config.json <<DOCKERJSON
{
    "auths": {
        "${REGISTRY}": {
            "auth": "${DOCKER_AUTH}"
        }
    }
}
DOCKERJSON

DOCKERFILE=${PLUGIN_DOCKERFILE:-Dockerfile}
CONTEXT=${PLUGIN_CONTEXT:-$PWD}
LOG=${PLUGIN_LOG:-info}
DESTINATION_PREFIX=${PLUGIN_DESTINATION_PREFIX:-}

if [[ -n "${PLUGIN_TARGET:-}" ]]; then
    TARGET="--target=${PLUGIN_TARGET}"
fi

if [[ "${PLUGIN_CACHE:-}" == "true" ]]; then
    CACHE="--cache=true"
fi

if [ -n "${PLUGIN_BUILD_ARGS:-}" ]; then
    BUILD_ARGS=$(echo "${PLUGIN_BUILD_ARGS}" | tr ',' '\n' | while read build_arg; do echo "--build-arg=${build_arg}"; done)
fi

if [[ "${PLUGIN_AUTO_TAG:-}" == "true" ]]; then
  AUTOTAGS=$(/autotag)
  PLUGIN_TAGS=${PLUGIN_TAGS},${AUTOTAGS}
  echo "DESTINATIONS:"
  echo "${PLUGIN_TAGS}" | tr ',' '\n' | while read tag; do echo "  - ${DESTINATION_PREFIX}${PLUGIN_REPO}:${tag} "; done
fi

if [ -n "${PLUGIN_TAGS:-}" ]; then
    DESTINATIONS=$(echo "${PLUGIN_TAGS}" | tr ',' '\n' | while read tag; do echo "--destination=${DESTINATION_PREFIX}${PLUGIN_REPO}:${tag} "; done)
else
    DESTINATIONS="--destination=${DESTINATION_PREFIX}${PLUGIN_REPO}:latest"
fi

/kaniko/executor -v ${LOG} \
    --context=${CONTEXT} \
    --dockerfile=${DOCKERFILE} \
    ${DESTINATIONS} \
    ${CACHE:-} \
    ${TARGET:-} \
    ${BUILD_ARGS:-}
