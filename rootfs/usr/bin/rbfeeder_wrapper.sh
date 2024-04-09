#!/usr/bin/env bash
# shellcheck shell=bash disable=SC1091

# This wrapper file will determine how to run rbfeeder, either natively or via qemu-arm-static.
# All command line arguments passed to this script will be passed directly to rbfeeder_armhf.

source /scripts/common

# attempt to run natively
if /usr/bin/rbfeeder_arm --no-start --version >/dev/null 2>&1; then
    exec /usr/bin/rbfeeder_arm "$@"

elif qemu-arm-static /usr/bin/rbfeeder_arm --no-start --version >/dev/null 2>&1; then
    exec qemu-arm-static /usr/bin/rbfeeder_arm "$@"
else
    echo "[ERROR] Could not run rbfeeder natively or via qemu"
    exec sleep infinity
fi
