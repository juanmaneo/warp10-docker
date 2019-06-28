#!/bin/bash
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

echo "TEST1"

warp10_pid=
sensision_pid=

source ${WARP10_HOME}/bin/setup.sh

 # SIGTERM-handler
term_handler() {
  echo "Stopping Warp 10"
  if [ $warp10_pid -ne 0 ]; then
    kill -SIGTERM "$warp10_pid"
  fi

  echo "Stopping Sensision"
  if [ $sensision_pid -ne 0 ]; then
    kill -SIGTERM "$sensision_pid"
  fi

  #
  # Wait for non child process to finish
  #
  while [ -e /proc/${warp10_pid} ] || [ -e /proc/${sensision_pid} ]
  do
    sleep 0.1
  done

  echo "All process are stopped"
  exit 143; # 128 + 15 -- SIGTERM
}

# Configuration file present launch Warp 10, Sensision and Quantum
if [ -e ${WARP10_DATA_DIR}/etc/conf-standalone.conf ]; then
  # Legacy warp10 template with no revision
  if ! grep -q  REVISION_TAG ${WARP10_DATA_DIR}/etc/conf-standalone.conf; then
    # REPLACE Hard version link with soft links
    sed -i 's_/opt/warp10-[0-9]+\.[0-9]+\.[0-9]+\(-rc[0-9]+\)?\(-[0-9]+-[a-z0-9]+\)*_\$\{standalone\.home\}_g' ${WARP10_DATA_DIR}/etc/conf-standalone.conf
    # Adds new var in the file
    echo >> ${WARP10_DATA_DIR}/etc/conf-standalone.conf
    echo "//" >> ${WARP10_DATA_DIR}/etc/conf-standalone.conf
    echo "// Directory of Warp10 standalone install" >> ${WARP10_DATA_DIR}/etc/conf-standalone.conf
    echo "//" >> ${WARP10_DATA_DIR}/etc/conf-standalone.conf
    echo "standalone.home = /opt/warp10" >> ${WARP10_DATA_DIR}/etc/conf-standalone.conf

    sed -i 's_/opt/warp10-[0-9]+\.[0-9]+\.[0-9]+\(-rc[0-9]+\)?\(-[0-9]+-[a-z0-9]+\)*_/opt/warp10_g' ${WARP10_DATA_DIR}/etc/log4j.properties
    # ADDS REVISION TO THE TEMPLATE
    sed -i "4s/\/\/.*/\/\/ REVISION_TAG=1\.0/" ${WARP10_DATA_DIR}/etc/conf-standalone.conf
  fi
  # Standalone IN_MEMORY mode
  if [ "${IN_MEMORY}" = "true" ]; then
    echo "Setting 'IN MEMORY' parameters"
    sed -i 's~^leveldb.home = ${standalone.home}/leveldb~leveldb.home = /dev/null~' ${WARP10_HOME}/etc/conf-standalone.conf
    sed -i 's~^in.memory = false~in.memory = true~' ${WARP10_HOME}/etc/conf-standalone.conf
    sed -i 's~^//in.memory.chunked = true~in.memory.chunked = true~' ${WARP10_HOME}/etc/conf-standalone.conf
    sed -i 's~^//in.memory.chunk.count =~in.memory.chunk.count = 2~' ${WARP10_HOME}/etc/conf-standalone.conf
    sed -i 's~^//in.memory.chunk.length =~in.memory.chunk.length = 86400000000~' ${WARP10_HOME}/etc/conf-standalone.conf
    sed -i "s~^#in.memory.load =~in.memory.load = ${WARP10_DATA_DIR}/memory.dump~" ${WARP10_HOME}/etc/conf-standalone.conf
    sed -i "s~^#in.memory.dump =~in.memory.dump = ${WARP10_DATA_DIR}/memory.dump~" ${WARP10_HOME}/etc/conf-standalone.conf
  fi
  # Custom macro mode
  if [ "${CUSTOM_MACRO}" = "true" ]; then
    echo "Configure macros directory"
    sed -i "s~^warpscript.repository.directory = .*~warpscript.repository.directory = ${WARP10_MACROS}~" ${WARP10_HOME}/etc/conf-standalone.conf
    sed -i 's~^warpscript.repository.refresh = 60000~warpscript.repository.refresh = 1000~' ${WARP10_HOME}/etc/conf-standalone.conf
  fi

  # Legacy sensision template
  if ! grep -q  REVISION_TAG ${SENSISION_DATA_DIR}/etc/sensision.conf; then
    # REPLACE HARD LINKS IN SENSISION CONFIGURATION
    sed -i 's/^sensision\.home.*/sensision\.home = \/opt\/sensision/' ${SENSISION_DATA_DIR}/etc/sensision.conf
    sed -i 's/^sensision\.scriptrunner\.root.*/sensision\.scriptrunner\.root= \/opt\/sensision\/scripts/' ${SENSISION_DATA_DIR}/etc/sensision.conf

    # ADDS REVISION TO THE TEMPLATE
    sed -i "10s/.*/## REVISION_TAG=1\.0/" ${SENSISION_DATA_DIR}/etc/sensision.conf
  fi

  echo "Configuration File exists - Update Quantum port (8081)"
  sed -i 's/^quantum\.port.*/quantum\.port = 8081/' ${WARP10_HOME}/etc/conf-standalone.conf

  echo "Launch Warp10"
  sed -i -e "s/127.0.0.1/0.0.0.0/g" ${WARP10_HOME}/etc/conf-standalone.conf

  # change default parameters
  sed -i -e "s/warp.timeunits = us/warp.timeunits = ns/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxops = 1000/warpscript.maxops = 10000000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxops.hard = 2000/warpscript.maxops.hard = 10000000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxbuckets = 1000000/warpscript.maxbuckets = 10000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxbuckets.hard = 100000/warpscript.maxbuckets.hard = 1000000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxdepth = 1000/warpscript.maxdepth  = 10000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxdepth.hard = 1000/warpscript.maxdepth.hard = 1000000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxfetch = 100000/warpscript.maxfetch = 1000000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxfetch.hard = 1000000/warpscript.maxfetch.hard = 10000000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxgts = 100000/warpscript.maxgts = 1000000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxgts.hard = 100000/warpscript.maxgts.hard = 1000000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxloop = 5000/warpscript.maxloop = 10000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxloop.hard = 10000/warpscript.maxloop.hard = 100000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxrecursion = 16/warpscript.maxrecursion = 24/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxrecursion.hard = 32/warpscript.maxrecursion.hard = 10000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxsymbols = 64/warpscript.maxsymbols = 1024/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxsymbols.hard = 256/warpscript.maxsymbols.hard = 10000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxpixels = 1000000/warpscript.maxpixels = 10000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  sed -i -e "s/warpscript.maxpixels.hard = 1000000/warpscript.maxpixels.hard = 1000000000/g" ${WARP10_HOME}/etc/conf-standalone.conf
  
  ${WARP10_HOME}/bin/warp10-standalone.init start
  warp10_pid=`cat ${WARP10_HOME}/logs/warp10.pid`
  echo "Warp10 running, pid=${warp10_pid}"

  # Launching sensision
  ${SENSISION_HOME}/bin/sensision.init start
  sensision_pid=`cat ${SENSISION_HOME}/logs/sensision.pid`
  echo "Sensision running, pid=${sensision_pid}"

  # TODO ends this script if warp10 is not running properly
  echo "All process are running"

  # trap 'kill ${!}; term_handler' SIGTERM SIGKILL SIGINT
  trap 'kill ${!}; term_handler' SIGTERM SIGKILL SIGINT

  # wait indefinitely
  tail -f /dev/null & wait ${!}

else
  echo "Unable to launch Warp10, configuration missing"
  exit -1
fi
