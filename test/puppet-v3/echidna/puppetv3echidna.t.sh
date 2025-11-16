#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$PROJECT_ROOT"

if [ -d "echidna-corpus-puppetv3" ]; then
    rm -rf echidna-corpus
    cp -r echidna-corpus-puppetv3 echidna-corpus
else
    rm -rf echidna-corpus
fi

source .env

anvil --fork-url "$MAINNET_FORKING_URL" --fork-block-number 15450164 > /dev/null 2>&1 &
ANVIL_PID=$!

sleep 3

cleanup() {
    if [ ! -z "$ANVIL_PID" ]; then
        kill $ANVIL_PID 2>/dev/null || true
    fi
    rm -rf echidna-corpus
}

trap cleanup EXIT

export ECHIDNA_RPC_URL="http://127.0.0.1:8545"
export ECHIDNA_RPC_BLOCK=latest
echidna test/puppet-v3/echidna/PuppetV3EchidnaSolved.t.sol --contract PuppetV3EchidnaSolved --config test/puppet-v3/echidna/puppet.yaml
