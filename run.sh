#!/bin/bash

/usr/sbin/sshd
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start sshd: $status"
    exit $status
fi

BTFS_PATH="/opt/btfs" /usr/bin/btfs --api /ip4/0.0.0.0/tcp/5001 daemon
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start btfs: $status"
    exit $status
fi
