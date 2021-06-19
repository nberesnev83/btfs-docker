#!/bin/bash
set -e

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
        if [[ $status -ne 0 ]]; then
            echo "Failed to init btfs: $status"
            exit $status
        fi
    elif [[ -n "$MNEMONIC_WORDS" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs init -s "$MNEMONIC_WORDS"
        status=$?
        if [[ $status -ne 0 ]]; then
            echo "Failed to init btfs with mnemonic words: $status"
            exit $status
        fi
    elif [[ -n "$PRIVATE_KEY" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs init -i "$PRIVATE_KEY"
        status=$?
        if [[ $status -ne 0 ]]; then
            echo "Failed to init btfs with private key: $status"
            exit $status
        fi
    else
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs init
        status=$?
        if [[ $status -ne 0 ]]; then
            echo "Failed to init btfs: $status"
            exit $status
        fi
    fi
    sleep 1

    ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs daemon &
    status=$?
    if [[ $status -ne 0 ]]; then
        echo "Failed to daemon btfs: $status"
        exit $status
    fi
    sleep 10

    if [[ "$ENABLE_STORAGE" == "true" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs config profile apply storage-host
    fi
    sleep 5

    if [[ -n "$DOMAINAPI" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["http://'$DOMAINAPI':5001", "http://0.0.0.0:5001"]'
    else
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["http://0.0.0.0:5001"]'
    fi
    ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "GET", "POST"]'
    sleep 1

    if [[ -n "$WALLET_PASSWORD" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs wallet password "$WALLET_PASSWORD"
    fi
    sleep 1

    if [[ "$ENABLE_STORAGE" == "true" ]]; then
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs storage path /opt/btfs $STORAGE_MAX
        sleep 1
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs storage announce --host-storage-time-min=5
        sleep 1
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs storage announce --host-storage-max=$STORAGE_MAX
        sleep 1
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs storage announce --enable-host-mode
        sleep 1
        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs storage announce --repair-host-enabled

        killall -9 btfs
        sleep 5

        ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs daemon &
        status=$?
        if [[ $status -ne 0 ]]; then
            echo "Failed to daemon btfs: $status"
            exit $status
        fi
        sleep 15
        curl -X POST "http://127.0.0.1:5001/api/v1/config?arg=UI.Host.Initialized&arg=true&bool=true"
    fi
    sleep 10

    killall -9 btfs
    sleep 1

    ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs --api /ip4/0.0.0.0/tcp/5001 daemon &
    status=$?
    if [[ $status -ne 0 ]]; then
        echo "Failed to daemon btfs: $status"
        exit $status
    fi
else
    ENABLE_WALLET_REMOTE=true BTFS_PATH="/opt/btfs" /usr/bin/btfs --api /ip4/0.0.0.0/tcp/5001 daemon &
    status=$?
    if [[ $status -ne 0 ]]; then
        echo "Failed to daemon btfs: $status"
        exit $status
    fi
fi

ping 127.0.0.1 >> /dev/null 2>&1
