#!/bin/bash

/usr/sbin/sshd
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start sshd: $status"
    exit $status
fi

if [ ! -f "/opt/btfs/config" ]; then
    if [ $NEW_WALLET == true ]; then
        RUN BTFS_PATH="/opt/btfs" /usr/bin/btfs init
        status=$?
    else if [ -n $MNEMONIC_WORDS ]; then
        RUN BTFS_PATH="/opt/btfs" /usr/bin/btfs init -s $MNEMONIC_WORDS
        status=$?
    else if [ -n $PRIVATE_KEY ]; then
        RUN BTFS_PATH="/opt/btfs" /usr/bin/btfs init -i $PRIVATE_KEY
        status=$?
    else
        RUN BTFS_PATH="/opt/btfs" /usr/bin/btfs init
        status=$?
    fi

    BTFS_PATH="/opt/btfs" /usr/bin/btfs --api /ip4/0.0.0.0/tcp/5001 daemon
    status=$?
else
    BTFS_PATH="/opt/btfs" /usr/bin/btfs --api /ip4/0.0.0.0/tcp/5001 daemon
    status=$?
fi

if [ $status -ne 0 ]; then
    echo "Failed to start btfs: $status"
    exit $status
fi
