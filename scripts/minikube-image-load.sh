#!/usr/bin/env bash
#
# Copyright Kroxylicious Authors.
#
# Licensed under the Apache Software License version 2.0, available at http://www.apache.org/licenses/LICENSE-2.0
#

# Loads a container-image tarball into a Minikube profile and *fails* if it did not actually land.
#
# `minikube image load` exits 0 even when the load failed (kubernetes/minikube#23471), so this
# wrapper does two things it cannot fake:
#   1. treats a "no such file" / "not found" / "failed pushing" line on stderr as a failure;
#   2. afterwards greps `minikube image ls` for <expected-repo> (e.g. kroxylicious/operator).
#
# Usage: minikube-image-load.sh <profile> <tarball> <expected-repo>

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <profile> <tarball> <expected-repo>" >&2
  exit 2
fi

profile=$1
tarball=$2
expected_repo=$3

if [[ ! -f "${tarball}" ]]; then
  echo "minikube-image-load: tarball does not exist: ${tarball}" >&2
  exit 1
fi

stderr=$(minikube image load -p "${profile}" "${tarball}" 2>&1 >/dev/null) || true
[[ -n "${stderr}" ]] && echo "${stderr}" >&2

if grep -qiE 'no such file|not found|failed pushing|failed to load|error loading' <<<"${stderr}"; then
  echo "minikube-image-load: 'minikube image load' reported a failure (kubernetes/minikube#23471)" >&2
  exit 1
fi

if ! minikube image ls -p "${profile}" | grep -qF "${expected_repo}"; then
  echo "minikube-image-load: ${expected_repo} is not present in profile '${profile}' after load (kubernetes/minikube#23471)" >&2
  exit 1
fi

minikube image ls -p "${profile}" | grep -F "${expected_repo}"
