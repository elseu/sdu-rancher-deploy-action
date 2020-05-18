#!/bin/bash
export RELEASE_NAME="${INPUT_RELEASE_NAME}-${ENVIRONMENT}"
export CHART_VERSION=$INPUT_CHART_VERSION
export CHART=$INPUT_CHART
export NAMESPACE=$INPUT_NAMESPACE
BASEDIR=$(dirname "$0")
VALUES_FILE="${BASEDIR}/.generated/values.yaml"

global_rematch() {
  local s=$1 regex=$2
  while [[ $s =~ $regex ]]; do
    echo "${BASH_REMATCH[1]}"
    s=${s#*"${BASH_REMATCH[1]}"}
  done
}

TAG=$(global_rematch $BRANCH "refs\/tags\/(.*)")
BRANCH=$(global_rematch $BRANCH "refs\/heads\/(.*)")

# TAG
BRANCH=${BRANCH//[\/\\.]/_}
if [ -z "$TAG" ]; then
  export TAG=$BRANCH
  export ENVIRONMENT=$TAG
else
  export TAG=$TAG
  export ENVIRONMENT='production'
fi

export BRANCH_LOWER=$BRANCH
export BRANCH=$(echo $BRANCH | tr '[:lower:]' '[:upper:]')

echo "uses $BRANCH"
if [ ! -z $BRANCH ]; then
  echo 'branch:' $BRANCH
  vars=($(compgen -v $BRANCH))
  # Override environment specific settings
  for name in "${vars[@]}"; do
    echo 'use override variable' $name
    override=$(echo ${name//$BRANCH'_'/})
    echo 'becomes variable' $override
    export $override="${!name}"
    unset $name
  done
fi

mkdir -p $BASEDIR/.generated

for f in $BASEDIR/*.yaml; do
  echo $f
  envsubst <$f >"${BASEDIR}/.generated/$(basename $f)"
  if [[ $DEBUG ]]; then
    cat "./deploy/.generated/$(basename $f)";
  fi
done

rancher login ${INPUT_URL} --token ${INPUT_TOKEN} --context ${INPUT_CONTEXT}

APP_ID=$(rancher apps | grep -o '.*:'$RELEASE_NAME)

if [ -z "$CHART_VERSION" ]; then
  echo "Auto use latest chart version"
  CHART_VERSION=$(rancher apps st $CHART | tail -1)
fi

if [[ $APP_ID ]]; then
  echo "Upgrade app $APP_ID"
  if [[ $ONLY_UPDATE_IMAGE ]]; then
    rancher app upgrade --set image.repository=${DOCKER_IMAGE} --set image.tag=${TAG} ${APP_ID} ${CHART_VERSION}
  else
    rancher app upgrade --values ${VALUES_FILE} ${APP_ID} ${CHART_VERSION}
  fi
else
  echo "Install app"
  rancher app install --no-prompt --namespace ${NAMESPACE} --values ${VALUES_FILE} --version ${CHART_VERSION} ${CHART} ${RELEASE_NAME}
fi
