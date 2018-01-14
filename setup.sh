#!/bin/bash

# generate angular-cli.json

envsubst '${PROJECT_NAME}' <.angular-cli.json > .angular-cli.json._tmp && mv .angular-cli.json._tmp .angular-cli.json

# generate package.json
envsubst '${PROJECT_NAME} ${PROJECT_VERSION}' <package.json > package.json._tmp && mv package.json._tmp package.json

# generate docker-compose.yml
envsubst '${PROJECT_NAME} ${DOCKER_IMAGE_DEV} ${DOMAIN_DEV}' <docker-compose.yml >docker-compose.yml._tmp && mv docker-compose.yml._tmp docker-compose.yml

# generate docker-compose.prod.yml
envsubst '${PROJECT_NAME} ${DOCKER_IMAGE_PROD} ${DOMAIN_PROD}' <docker-compose.prod.yml >docker-compose.prod.yml._tmp && mv docker-compose.prod.yml._tmp docker-compose.prod.yml