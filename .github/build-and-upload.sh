#!/bin/bash
# abort on nonzero exitstatus
set -o errexit
# abort on unbound variable
set -o nounset
# don't hide errors within pipes
set -o pipefail

#set -x

MIN_BUILD_VERSION="5.0"
#MIN_BUILD_VERSION="master"
IMAGE_NAME="bigmichi1/graphhopper"

compare_version() {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i a=(${1%%[^0-9.]*}) b=(${2%%[^0-9.]*})
    local arem=${1#${1%%[^0-9.]*}} brem=${2#${2%%[^0-9.]*}}
    for ((i=0; i<${#a[@]} || i<${#b[@]}; i++)); do
        if ((10#${a[i]:-0} < 10#${b[i]:-0})); then
            return 1
        elif ((10#${a[i]:-0} > 10#${b[i]:-0})); then
            return 0
        fi
    done
    if [ "$arem" '<' "$brem" ]; then
        return 1
    elif [ "$arem" '>' "$brem" ]; then
        return 0
    fi
    return 1
}

echo "Preparing build environment"
mkdir build
cd build

echo "Downloading Dockerfile and graphhopper.sh"
curl -L https://raw.githubusercontent.com/BigMichi1/graphhopper-docker-image/main/Dockerfile > Dockerfile
curl -L https://raw.githubusercontent.com/BigMichi1/graphhopper-docker-image/main/graphhopper.sh > graphhopper.sh
chmod +x ./graphhopper.sh

echo "Cloning graphhopper"
git clone https://github.com/graphhopper/graphhopper.git
cd graphhopper
git config advice.detachedHead false

echo "Building docker images"
TAGS=`git for-each-ref --sort=committerdate refs/tags | egrep '\/[[:digit:]]+\.[[:digit:]]+(\.[[:digit:]])?$' | cut -d "/" -f3`
TAGS=`echo -e "$TAGS\nmaster"`
while read -r TAG; do
  if [ "$TAG" == "master" ] || ( compare_version "$TAG" "$MIN_BUILD_VERSION" );
  then
    echo ""
    echo "Building docker image for version $TAG"
    git clean -f -d -x
    if [ "$TAG" == "master" ]
    then
      git checkout -q "tags/$TAG"
    else
      git checkout -q master
    fi

    if [ "$TAG" == "master" ]
    then
      TAG="latest"
    fi

    IMAGE_NAME_TAG="$IMAGE_NAME:$TAG"

    echo "Checking for new commits"
    COMMIT=`git rev-parse --short HEAD`
    if docker pull $IMAGE_NAME_TAG >/dev/null 2>&1
    then
      OLD_COMMIT=`docker inspect $IMAGE_NAME_TAG | jq -r ".[].Config.Labels.\"org.opencontainers.image.revision\""`
    else
      OLD_COMMIT=""
    fi

    if [ "$OLD_COMMIT" != "$COMMIT" ]
    then
      echo "Building new revision $COMMIT for $TAG"
      cp ../Dockerfile .
      cp ../graphhopper.sh .

      docker build \
        --label org.opencontainers.image.revision=${COMMIT} \
        --label org.opencontainers.image.created="$(date --rfc-3339=seconds --utc)" \
        --label org.opencontainers.image.version=${TAG} \
        . -t $IMAGE_NAME_TAG

      echo "Publishing docker image $IMAGE_NAME_TAG"
      docker login --username $DOCKERHUB_USER --password $DOCKERHUB_TOKEN
      docker push $IMAGE_NAME_TAG
    else
      echo "Skipping build for commit $COMMIT because it is the same as already published for image $IMAGE_NAME_TAG"
    fi
  else
    echo "Skipping version $TAG"
  fi
done <<< "$TAGS"

