#!/bin/bash

/usr/sbin/sshd
status=$?
if [[ $status -ne 0 ]]; then
    echo "Failed to start sshd: $status"
    exit $status
fi

if [[ ! -f "/opt/btfs/config" ]]; then
    if [[ "$NEW_WALLET" == "true" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs init
        status=$?
    elif [[ -n "$MNEMONIC_WORDS" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs init -s "$MNEMONIC_WORDS"
        status=$?
    elif [[ -n "$PRIVATE_KEY" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs init -i "$PRIVATE_KEY"
        status=$?
    else
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs init
        status=$?
    fi

    ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs --api /ip4/0.0.0.0/tcp/5001 daemon &
    status=$?

    if [[ -n "$DOMAINAPI" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["http://$DOMAINAPI:5001", "http://0.0.0.0:5001"]'
    else
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["http://0.0.0.0:5001"]'
    fi
    ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "GET", "POST"]'

    if [[ -n "$WALLET_PASSWORD" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs wallet password --password="$WALLET_PASSWORD"
    fi

    if [[ "$ENABLE_STORAGE" == "true" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs config profile apply storage-host
    fi

    killall -9 btfs
    sleep 10
    ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs --api /ip4/0.0.0.0/tcp/5001 daemon &
    status=$?
else
    ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs --api /ip4/0.0.0.0/tcp/5001 daemon &
    status=$?
fi

if [[ $status -ne 0 ]]; then
    echo "Failed to start btfs: $status"
    exit $status
fi
