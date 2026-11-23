WILDFLY_IMAGE=$1

check_http_status() {
  response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/")
  if [ "$response" -eq 200 ]; then
    echo "Success! Received a 200 OK response."
    return 0
  fi
  return 1
}

check_wildfly_up_and_running() {
  # wait until WildFLy is up and running
  max_time=120
  retry_interval=5

  start_time=$(date +%s)
  while true; do
    current_time=$(date +%s)
    elapsed_time=$(( current_time - start_time ))
    if [ $elapsed_time -ge $max_time ]; then
      echo "Failed to get WildFly up and running within $max_time seconds."
      return 1
    fi
    if docker container logs "${CONTAINER_ID}" 2>&1 | grep -q WFLYSRV0025; then
      echo "Success! WildFly is up and running."
      return 0
    fi
    sleep $retry_interval
  done
}

check_wildfly_version() {
  if docker container logs "${CONTAINER_ID}" 2>&1 | grep -q "WFLYSRV0025.*${WILDFLY_VERSION}"; then
    echo "Success! WildFly is using version ${WILDFLY_VERSION}."
    return 0
  fi
  return 1
}

# Get the WildFly version by cutting "ENV WILDFLY_VERSION="
WILDFLY_VERSION=$(grep "ENV WILDFLY_VERSION=" Dockerfile | cut -c21-)

# Capture the ID returned by this exact `docker run`; `docker ps -l` can instead
# select the Buildx/BuildKit container while the WildFly image is still starting.
CONTAINER_ID=$(docker run -d --rm -p 8080:8080 "${WILDFLY_IMAGE}")
trap 'docker kill "${CONTAINER_ID}" >/dev/null 2>&1 || true' EXIT

if ! check_wildfly_up_and_running; then
    echo "WildFly did not boot up properly. Its container logs follow:"
    docker container logs "${CONTAINER_ID}" 2>&1 || true
    exit 1
fi

if ! check_http_status; then
    echo "WildFly did not reply to the HTTP request."
    exit 1
fi

if ! check_wildfly_version; then
    echo "WildFly did not use the expected ${WILDFLY_VERSION} version."
    exit 1
fi
