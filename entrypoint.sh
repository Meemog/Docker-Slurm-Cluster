#!/bin/bash
set -ex

# runtime dirs
install -d -o munge -g munge -m 0700 /var/log/munge /var/lib/munge
install -d -o munge -g munge -m 0711 /run/munge

if [ -f /tmp/munge.key ]; then
    install -m 400 -o munge -g munge /tmp/munge.key /etc/munge/munge.key
fi

ssh-keygen -A

echo "Starting munged..."
runuser -u munge -- munged

if [ "$ROLE" = "login" ]; then
    echo "Starting slurmctld..."
    slurmctld -Dvvv &
elif [ "$ROLE" = "compute" ]; then
    echo "Starting slurmd..."
    slurmd -Dvvv &
fi

exec /usr/sbin/sshd -D