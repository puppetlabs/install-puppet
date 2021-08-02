#!/usr/bin/env bash

INSTALL_OPTIONS=( "$@" )
PUPPET_BIN=/opt/puppetlabs/bin/puppet

beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

# Check whether a command exists - returns 0 if it does, 1 if it does not
exists() {
  if command -v "$1" >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
      -v|--version) EXPECTED_VERSION="$2"; shift ;;
      -c|--collection) EXPECTED_COLLECTION="$2"; shift;
        case $EXPECTED_COLLECTION in
          puppet|puppet-nightly) EXPECTED_VERSION="7." ;;
          puppet6|puppet6-nightly) EXPECTED_VERSION="6." ;;
          puppet7|puppet7-nightly) EXPECTED_VERSION="7." ;;
        esac
        ;;
      --cleanup) EXPECT_CLEANUP=true; shift ;;
      *) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
  esac
  shift
done

bash install.sh "${INSTALL_OPTIONS[@]}"
# curl -sSL https://raw.githubusercontent.com/puppetlabs/install-puppet/main/install.sh | bash -s -- "${INSTALL_OPTIONS[@]}"

if [ -n "$EXPECTED_VERSION" ]; then
  if ! exists $PUPPET_BIN; then
    echo "ERROR: puppet executable not found under $(dirname $PUPPET_BIN)"
    exit 1
  fi

  echo "INFO: running $PUPPET_BIN --version"

  ACTUAL_VERSION=$($PUPPET_BIN --version)

  if ! beginswith "$EXPECTED_VERSION" "$ACTUAL_VERSION"; then
    echo "ERROR: expected version to begin with $EXPECTED_VERSION but got $ACTUAL_VERSION"
    exit 1
  fi
fi

if [[ $EXPECT_CLEANUP == true ]]; then
  if exists rpm; then
    if rpm -q "${EXPECTED_COLLECTION}-release"; then
      echo "ERROR: cleanup requested but $EXPECTED_COLLECTION-release repo was not removed"
      exit 1
    fi
  elif exists dpkg; then
    if dpkg -l "${EXPECTED_COLLECTION}-release"; then
      echo "ERROR: cleanup requested but $EXPECTED_COLLECTION-release repo was not removed/purged"
      exit 1
    fi
  else
    echo "INFO: no rpm/dpkg found; don't know how to cleanup repos"
    exit 1
  fi
fi
