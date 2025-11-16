#!/bin/bash
source ../../.env && forge test --mt "test_puppetV3" --fork-url $MAINNET_FORKING_URL
