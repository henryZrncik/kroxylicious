#!/usr/bin/env bash
#
# Copyright Kroxylicious Authors.
#
# Licensed under the Apache Software License version 2.0, available at http://www.apache.org/licenses/LICENSE-2.0
#

# Loads a container-image tarball into a Minikube profile and *fails* if it did not actually land.
#
# `minikube image load` exits 0 even when the load failed (kubernetes/minikube#23471) - a missing
# tarball, for example, only prints "The image ... was not found" and still exits 0. So this wrapper:
#   1. fails up front if the tarball does not exist;
#   2. after the load, fails unless `minikube image ls` lists <expected-repo> (e.g. kroxylicious/operator).
#
# Usage: minikube-image-load.sh [--profile|-p <profile>] <tarball> <expected-repo>
#
# If --profile/-p is omitted, Minikube's own current profile is used (i.e. the -p flag is
# not passed to the underlying `minikube` subcommands).

set -euo pipefail

usage() {
  echo "usage: $0 [--profile|-p <profile>] <tarball> <expected-repo>" >&2
}

profile=""
positional=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p | --profile)
      if [[ $# -lt 2 ]]; then
        echo "minikube-image-load: $1 requires an argument" >&2
        usage
        exit 2
      fi
      profile=$2
      shift 2
      ;;
    --)
      shift
      positional+=("$@")
      break
      ;;
    -*)
      echo "minikube-image-load: unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      positional+=("$1")
      shift
      ;;
  esac
done

if [[ ${#positional[@]} -ne 2 ]]; then
  usage
  exit 2
fi

tarball=${positional[0]}
expected_repo=${positional[1]}

# When no profile is supplied, omit -p entirely so the minikube subcommands act on
# Minikube's own current profile. profile_desc is only used for messages.
profile_args=()
profile_desc="the current Minikube profile"
if [[ -n "${profile}" ]]; then
  profile_args=(-p "${profile}")
  profile_desc="profile '${profile}'"
fi

# Check that the tarball exists before attempting to load it
if [[ ! -f "${tarball}" ]]; then
  echo "minikube-image-load: tarball does not exist: ${tarball}" >&2
  exit 1
fi

# Load the image into the target Minikube profile
minikube image load "${profile_args[@]}" "${tarball}"

# Verify that the expected repository is now listed in the profile's images
if ! minikube image ls "${profile_args[@]}" | grep -qF "${expected_repo}"; then
  echo "minikube-image-load: ${expected_repo} is not in ${profile_desc} after loading ${tarball} (kubernetes/minikube#23471)" >&2
  exit 1
fi

# Print the list of images in the profile that match the expected repository
minikube image ls "${profile_args[@]}" | grep -F "${expected_repo}"
