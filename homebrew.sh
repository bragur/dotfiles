#!/bin/bash
set -Eeuo pipefail

if [ "${1}" != "--source-only" ]; then
	. ./print.sh --source-only
fi

check_brew() {
  info "Checking if brew exists"
  which -s brew
  if [[ $? != 0 ]] ; then
    retval=0
  else
    retval=1
  fi
  return "$retval"
}
