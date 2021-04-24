#!/bin/bash

name=$1


# this file needs an service account for testnet that can create accounts
flowJson="~/.flow.dev.json"
keys=$(flow keys generate -o json)

publicKey=$(echo $keys | jq ".private" -r)
privateKey=$(echo $keys | jq ".public" -r)

account=$(flow accounts create --host access.devnet.nodes.onflow.org:9000 --config-path ~/.flow-dev.json --key $publicKey -o json)


address=$(echo $account | jq ".address" -r)


cat << EOF
"$name" : {
  "address": "$address",
  "keys": "$privateKey",
  "chain": "flow-testnet"
}
EOF
