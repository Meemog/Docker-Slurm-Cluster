#!/bin/bash

# runtime dirs
install -d -o munge -g munge -m 0700 /var/log/munge /var/lib/munge
install -d -o munge -g munge -m 0711 /run/munge

if [ -f /tmp/munge.key ]; then
    install -m 400 -o munge -g munge /tmp/munge.key /etc/munge/munge.key
fi

if [ "$MODULE_FRAMEWORK" = "ENV" ]; then
    dnf install -y environment-modules
    echo 'module use /data/modulefiles' > /etc/profile.d/z01_modulefiles.sh
    /tmp/setup_files/environment-modules.sh
elif [ "$MODULE_FRAMEWORK" = "LMOD" ]; then
    dnf install -y Lmod
    echo 'module use /data/modulefiles/Core' > /etc/profile.d/z01_modulefiles.sh
    /tmp/setup_files/lmod-modules.sh
fi

rm -rf /home/dev/setup_files

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