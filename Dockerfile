# Simple angular-cli docker installation
# docker build -t ng-cli .
# or specify angular-cli version
# docker build --build-arg NG_CLI_VERSION=1.6.3
ARG NODE_VERSION="6-alpine"
FROM node:${NODE_VERSION}

LABEL AUTHOR="Ashish Gupta <gotoashishgupta@gmail.com>"

# add more arguments from CI to the image so that `$ env` should reveal more info

ARG CI_BUILD_ID
ARG CI_BUILD_REF
ARG CI_REGISTRY_IMAGE
ARG CI_PROJECT_NAME
ARG CI_BUILD_REF_NAME
ARG CI_BUILD_TIME
ARG NG_CLI_VERSION
ARG USER_HOME_DIR=/tmp

ENV CI_BUILD_ID=${CI_BUILD_ID} CI_BUILD_REF=${CI_BUILD_REF} \
  CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE} CI_BUILD_TIME=${CI_BUILD_TIME} \
  NG_CLI_VERSION=${NG_CLI_VERSION:-latest}

# credits to https://github.com/emmenko/docker-nodejs-karma

RUN curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  && apt-get update && apt-get install -y Xvfb google-chrome-stable \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY xvfb.sh /etc/init.d/xvfb
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /etc/init.d/xvfb && chmod +x /entrypoint.sh

ENV DISPLAY :99.0
ENV CHROME_BIN /usr/bin/google-chrome

RUN yarn global add @angular/cli@${NG_CLI_VERSION} \
  && npm cache clean --force \
  && yarn cache clean \
  && rm -rf $(yarn cache dir)

ONBUILD RUN ["/bin/bash -c", "/entrypoint.sh"]

ARG APP_DIR=/opt/app
ARG USER_ID=1000

ENV HOME=${USER_HOME_DIR:-/tmp} \
  CI_BUILD_ID=${CI_BUILD_ID} CI_BUILD_REF=${CI_BUILD_REF} \
  CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE} CI_PROJECT_NAME=${CI_PROJECT_NAME} \
  CI_BUILD_REF_NAME=${CI_BUILD_REF_NAME} CI_BUILD_TIME=${CI_BUILD_TIME}


# npm 5 uses different userid when installing packages, as workaround su to node when installing
# see https://github.com/npm/npm/issues/16766
RUN set -xe \
  && curl -sL https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 > /usr/bin/dumb-init \
  && chmod +x /usr/bin/dumb-init \
  && mkdir -p $USER_HOME_DIR \
  && chown $USER_ID $USER_HOME_DIR \
  && chmod a+rw $USER_HOME_DIR \
  && yarn global add @angular/cli@${NG_CLI_VERSION} \
  && ng set --global packageManager=yarn \
  && sed -i -e "s/bin\/ash/bin\/sh/" /etc/passwd

COPY package.json $USER_HOME_DIR/
WORKDIR $USER_HOME_DIR
RUN yarn

#not declared to avoid anonymous volume leak
VOLUME ["$USER_HOME_DIR/.cache/yarn", "$APP_DIR/"]

WORKDIR $APP_DIR
COPY . .


EXPOSE 4200

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

USER $USER_ID
