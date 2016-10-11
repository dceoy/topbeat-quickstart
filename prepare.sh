#!/usr/bin/env bash
#
# Usage:  ./prepare.sh
#         ./prepare.sh [ -h | --help | -v | --version | --run ]
#         ./prepare.sh [ -e | --elasticsearch ] [elasticsearch host]
#
# Description:
#   Download Topbeat and load the index template in Elasticsearch.
#
# Options:
#   -h, --help            Print usage
#   -v, --version         Print version information and quit
#   -e, --elasticsearch   Set a server with Elasticsearch running (default: localhost:9200)

set -e

if [[ "${1}" = '--debug' ]]; then
  set -x
  shift 1
fi

SCRIPT_NAME='prepare.sh'
TOPBEAT_VERSION='1.3.1'
ELASTICSEARCH_HOST='localhost:9200'
DOWNLOAD_DIR='download'

function print_version {
  echo "${SCRIPT_NAME}: topbeat ${TOPBEAT_VERSION}"
}

function print_usage {
  sed -ne '
    1,2d
    /^#/!q
    s/^#$/# /
    s/^# //p
  ' ${SCRIPT_NAME}
}

function abort {
  echo "${*}" >&2
  exit 1
}

while [[ -n "${1}" ]]; do
  case "${1}" in
    '-v' | '--version' )
      print_version
      exit 0
      ;;
    '-h' | '--help' )
      print_usage
      exit 0
      ;;
    '-e' | '--elasticsearch' )
      if [[ "${2}" =~ ^[^\-] ]]; then
        ELASTICSEARCH_HOST="${2}"
        shift 2
      else
        abort "flag needs an argument: ${1}"
      fi
      ;;
    * )
      abort 'invalid argument'
      ;;
  esac
done

echo '[ Download Topbeat ]'
[[ -d "${DOWNLOAD_DIR}" ]] || mkdir "${DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}"

case "${OSTYPE}" in
  linux* )
    TOPBEAT_DIR="topbeat-${TOPBEAT_VERSION}-x86_64"
    [[ ! -d "${TOPBEAT_DIR}" ]] \
      && curl -LO "https://download.elastic.co/beats/topbeat/topbeat-${TOPBEAT_VERSION}-x86_64.tar.gz" \
      && tar xzvf "${TOPBEAT_DIR}.tar.gz"
    ;;
  darwin* )
    TOPBEAT_DIR="topbeat-${TOPBEAT_VERSION}-darwin"
    [[ ! -d "${TOPBEAT_DIR}" ]] \
      && curl -LO "https://download.elastic.co/beats/topbeat/topbeat-${TOPBEAT_VERSION}-darwin.tgz" \
      && tar xzvf "${TOPBEAT_DIR}.tgz"
    ;;
  * )
    abort 'unsupported os type'
    ;;
esac

DASHBOARDS_DIR="beats-dashboards-${TOPBEAT_VERSION}"
[[ ! -d "${DASHBOARDS_DIR}" ]] \
  && curl -LO "https://download.elastic.co/beats/dashboards/${DASHBOARDS_DIR}.zip" \
  && unzip "${DASHBOARDS_DIR}.zip"
echo

echo '[ Prepare Topbeat ]'
cd "${TOPBEAT_DIR}"
curl -XPUT "http://${ELASTICSEARCH_HOST}/_template/topbeat" -d@topbeat.template.json
cd ..

cd "${DASHBOARDS_DIR}"
./load.sh -url "http://${ELASTICSEARCH_HOST}"
cd ../..

[[ ! -f 'topbeat.yml' ]] \
  && sed -e "s/\\[\"localhost:9200\"\\]/\\[\"${ELASTICSEARCH_HOST}\"\\]/" \
       "${DOWNLOAD_DIR}/${TOPBEAT_DIR}/topbeat.yml" > topbeat.yml
[[ ! -f 'topbeat' ]] \
  && ln -s "${DOWNLOAD_DIR}/${TOPBEAT_DIR}/topbeat" .

echo && echo
echo '[ Start Topbeat ]'
echo '# Run this command:'
echo "# sudo ./topbeat -e -c topbeat.yml -d 'publish'"
