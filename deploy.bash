#!/bin/bash
export RELEASE_NAME="${INPUT_RELEASE_NAME}-${ENVIRONMENT}"
export CHART_VERSION=$INPUT_CHART_VERSION
export CHART=$INPUT_CHART
export NAMESPACE=$INPUT_NAMESPACE
export REF=$INPUT_REF
export BRANCH=$INPUT_BRANCH
export IMAGE=$INPUT_IMAGE
export DOCKER_IMAGE=$INPUT_IMAGE
export TAG=$INPUT_TAG
export CONTEXT=$INPUT_CONTEXT
export TOKEN=$INPUT_TOKEN
export URL=$INPUT_URL
export DOCKER_TAG=$INPUT_TAG
export ROLLOUT_RESTART_ALL_DEPLOYMENTS=$INPUT_ROLLOUT_RESTART_ALL_DEPLOYMENTS
BASEDIR="${GITHUB_WORKSPACE}/deploy"
VALUES_FILE="${BASEDIR}/.generated/values.yaml"

if [[ $DEBUG ]]; then
  printenv
  echo "BASEDIR ${BASEDIR}"
  echo "VALUES_FILE ${VALUES_FILE}"
fi

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

rancher login ${URL} --token ${TOKEN} --context ${CONTEXT}

APP_ID=$(rancher apps | grep -o '.*:'$RELEASE_NAME)

if [ -z "$CHART_VERSION" ]; then
  echo "Auto use latest chart version"
  CHART_VERSION=$(rancher apps st $CHART | tail -1)
fi

if [[ $APP_ID ]]; then
  echo "Upgrade app $APP_ID"
  if [[ $ONLY_UPDATE_IMAGE ]]; then
    rancher app upgrade --set image.repository=${IMAGE} --set image.tag=${TAG} ${APP_ID} ${CHART_VERSION}
  else
    rancher app upgrade --values ${VALUES_FILE} ${APP_ID} ${CHART_VERSION}
  fi
else
  echo "Install app"
  rancher app install --no-prompt --namespace ${NAMESPACE} --values ${VALUES_FILE} --version ${CHART_VERSION} ${CHART} ${RELEASE_NAME}
fi

if [ $ROLLOUT_RESTART_ALL_DEPLOYMENTS == 1 ]; then
  declare -a DEPLOYMENTS
  DEPLOYMENTS=($(rancher kubectl get deployments --namespace=$NAMESPACE -o name))

  for (( i=0; i<${#DEPLOYMENTS[@]}; i++ )) do
    echo "Rollout restart: ${DEPLOYMENTS[$i]}"
    rancher kubectl rollout restart ${DEPLOYMENTS[$i]} --namespace=$NAMESPACE
  done;
fi
