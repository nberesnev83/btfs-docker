#!/bin/bash

/usr/sbin/sshd -D
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start sshd: $status"
    exit $status
fi

BTFS_PATH="/opt/btfs" /usr/bin/btfs daemon
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start apache2ctl: $status"
    exit $status
fi
