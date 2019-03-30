#!/bin/bash -e

IMAGE="gst-src-debug:1"
DIR=$(dirname $(readlink -f "$0"))

. "${DIR}/../../../script/shell.sh"
