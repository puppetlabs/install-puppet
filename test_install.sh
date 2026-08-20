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
          puppet8|puppet8-nightly|puppetcore8|puppetcore8-nightly) EXPECTED_VERSION="8." ;;
          puppet9|puppet9-nightly|puppetcore9|puppetcore9-nightly) EXPECTED_VERSION="9." ;;
        esac
        ;;
      -p|--password) PASSWORD=$2; EXPECT_PASSWORD=true; shift;;
      --cleanup) EXPECT_CLEANUP=true; shift ;;
      *) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
  esac
  shift
done

bash install.sh "${INSTALL_OPTIONS[@]}"

if [[ $EXPECT_PASSWORD == true ]]; then
  if exists curl; then
    validate_key=$(curl -u forge-key:"$PASSWORD" -o /dev/null -s -w "%{http_code}\n" \
      https://yum-puppetcore.puppet.com/puppet9/el/8/x86_64/repodata/repomd.xml)
  elif exists wget; then
    validate_key=$(wget --http-user=forge-key --http-password="$PASSWORD" --auth-no-challenge -O /dev/null -S \
      https://yum-puppetcore.puppet.com/puppet9/el/8/x86_64/repodata/repomd.xml 2>&1 \
      | awk '/^  HTTP/{print $2; exit}')
  else
    echo "ERROR: neither curl nor wget found; cannot validate Forge API key"
    exit 1
  fi

  if [[ "$validate_key" != "200" ]]; then
    echo "ERROR: invalid Forge API key given"
    exit 1
  fi
fi

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
