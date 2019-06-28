#
#   Copyright 2018  SenX S.A.S.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

##
## This is modified version of original Dockerfile to use Debian stretch (for original cf: https://github.com/senx/warp10-docker/blob/master/Dockerfile)
## The default configuration (cf: warp10.start.sh) is also tweaked to get for example nanoseconds granularity
## Bumped up sensition version to 1.0.18
##

FROM openjdk:8-jre-stretch

LABEL author="SenX S.A.S."
LABEL maintainer="do_not_contact_since_this_is_a_mod@senx.io"

# Updating
RUN apt-get update && apt-get install -y bash bash-builtins bash-completion curl ca-certificates wget python && apt-get clean

# install some useful tools for dev/debug
RUN apt-get update && apt-get install -y aptitude emacs-nox net-tools procps psmisc htop iotop nload && apt-get clean

ENV \
  WARP10_VOLUME=/data \
  WARP10_HOME=/opt/warp10 \
  WARP10_DATA_DIR=/data/warp10 \
  SENSISION_HOME=/opt/sensision \
  SENSISION_DATA_DIR=/data/sensision

ARG WARP10_VERSION=2.0.3
ARG WARP10_URL=https://dl.bintray.com/senx/generic/io/warp10/warp10/${WARP10_VERSION}

# Getting Warp 10
RUN mkdir -p /opt \
  && cd /opt \
  && wget -nv ${WARP10_URL}/warp10-${WARP10_VERSION}.tar.gz \
  && tar xzf warp10-${WARP10_VERSION}.tar.gz \
  && rm warp10-${WARP10_VERSION}.tar.gz \
  && ln -s /opt/warp10-${WARP10_VERSION} ${WARP10_HOME}

ARG SENSISION_VERSION=1.0.18
ARG SENSISION_URL=https://dl.bintray.com/senx/generic/io/warp10/sensision-service/${SENSISION_VERSION}

# Getting Sensision
RUN cd /opt \
  && wget -nv $SENSISION_URL/sensision-service-${SENSISION_VERSION}.tar.gz \
  && tar xzf sensision-service-${SENSISION_VERSION}.tar.gz \
  && rm sensision-service-${SENSISION_VERSION}.tar.gz \
  && ln -s /opt/sensision-${SENSISION_VERSION} ${SENSISION_HOME}

ENV WARP10_JAR=${WARP10_HOME}/bin/warp10-${WARP10_VERSION}.jar \
  WARP10_CONF=${WARP10_HOME}/etc/conf-standalone.conf \
  WARP10_MACROS=${WARP10_VOLUME}/custom_macros

COPY warp10.start.sh ${WARP10_HOME}/bin/warp10.start.sh
COPY setup.sh ${WARP10_HOME}/bin/setup.sh

ENV PATH=$PATH:${WARP10_HOME}/bin

VOLUME ${WARP10_VOLUME}
VOLUME ${WARP10_MACROS}


# Exposing port 8080
EXPOSE 8080 8081

# For debug purpose
RUN java -version
RUN python --version

CMD ${WARP10_HOME}/bin/warp10.start.sh
