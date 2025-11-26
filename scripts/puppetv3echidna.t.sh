#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

#  SVM for solc version
SOLC_SETUP=false

if command -v svm &> /dev/null; then
    export PATH="$HOME/.cargo/bin:$PATH"
    if svm use 0.8.25 2>/dev/null; then
        if [ -f "$HOME/.cargo/bin/solc" ]; then
            export SOLC="$HOME/.cargo/bin/solc"
            export SOLC_VERSION="0.8.25"
            SOLC_SETUP=true
            echo "Using svm solc 0.8.25"
        fi
    fi
fi

# Fallback to solc-select 
if [ "$SOLC_SETUP" = false ]; then
    if command -v solc-select &> /dev/null; then
        if [ -z "$VIRTUAL_ENV" ] && [ -f "$PROJECT_ROOT/.venv/bin/activate" ]; then
            source "$PROJECT_ROOT/.venv/bin/activate" 2>/dev/null || true
        fi
        
        if solc-select use 0.8.25 2>/dev/null; then
            export SOLC_VERSION="0.8.25"
            SOLC_SETUP=true
            echo "Using solc-select solc 0.8.25 "
        fi
    fi
fi

if [ "$SOLC_SETUP" = false ]; then
    echo "Warning: Could not set up solc via svm or solc-select. Echidna will use system default."
fi

if [ -d "echidna-corpus-puppetv3" ]; then
    rm -rf echidna-corpus
    cp -r echidna-corpus-puppetv3 echidna-corpus
else
    rm -rf echidna-corpus
fi

source "$PROJECT_ROOT/.env"

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
echidna test/puppet-v3/echidna/PuppetV3EchidnaSolved.t.sol --contract PuppetV3EchidnaSolved --config test/puppet-v3/echidna/puppetv3.yaml
