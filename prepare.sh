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
      flag="${1}"
      shift 1
      if [[ "${1}" =~ ^[^\-] ]]; then
        ELASTICSEARCH_HOST="${1}"
        shift 1
      else
        abort "flag needs an argument: ${flag}"
      fi
      ;;
    * )
      abort 'invalid argument'
      ;;
  esac
done

echo '[ Download Topbeat ]'
case "${OSTYPE}" in
  linux* )
    TOPBEAT_DIR="topbeat-${TOPBEAT_VERSION}-x86_64"
    [[ ! -d "${TOPBEAT_DIR}" ]] \
      && curl -LO "https://download.elastic.co/beats/topbeat/${TOPBEAT_DIR}.tar.gz" \
      && tar xzvf "${TOPBEAT_DIR}.tar.gz"
    ;;
  darwin* )
    TOPBEAT_DIR="topbeat-${TOPBEAT_VERSION}-darwin"
    [[ ! -d "${TOPBEAT_DIR}" ]] \
      && curl -LO "https://download.elastic.co/beats/topbeat/${TOPBEAT_DIR}.tgz" \
      && tar xzvf "${TOPBEAT_DIR}.tgz"
    ;;
  * )
    abort 'unsupported os type'
    ;;
esac
echo

echo '[ Load the index template ]'
curl -XPUT "http://${ELASTICSEARCH_HOST}/_template/topbeat" -d@${TOPBEAT_DIR}/topbeat.template.json
echo && echo

echo '[ Start Topbeat ]'
echo '# Run this command:'
echo "# cd ${TOPBEAT_DIR} && sudo ./topbeat -e -c topbeat.yml -d 'publish'"
