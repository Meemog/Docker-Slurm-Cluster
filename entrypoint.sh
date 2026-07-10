#!/bin/bash

# runtime dirs
install -d -o munge -g munge -m 0700 /var/log/munge /var/lib/munge
install -d -o munge -g munge -m 0711 /run/munge

cp /tmp/conf/slurm.conf /etc/slurm/slurm.conf
chown slurm:slurm /etc/slurm/slurm.conf
chmod 644 /etc/slurm/slurm.conf

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
    exec /usr/sbin/sshd -D
elif [ "$ROLE" = "compute" ]; then
    echo "Starting slurmd..."
    slurmd -Dvvv &
    exec /usr/sbin/sshd -D
elif [ "$ROLE" = "database" ]; then
    cp /tmp/conf/slurmdbd.conf /etc/slurm/slurmdbd.conf
    chown slurm:slurm /etc/slurm/slurmdbd.conf
    chmod 600 /etc/slurm/slurmdbd.conf

    install -d -o mysql -g mysql -m 0755 /var/lib/mysql /run/mysqld /var/log/mariadb
    chown -R mysql:mysql /var/lib/mysql /run/mysqld /var/log/mariadb

    if [ ! -d /var/lib/mysql/mysql ]; then
        echo "Initializing MariaDB data directory..."
        mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql >/dev/null 2>&1
    fi

    if ! pgrep -x mariadbd >/dev/null 2>&1 || [ ! -S /var/lib/mysql/mysql.sock ]; then
        rm -f /var/lib/mysql/mysql.sock /run/mysqld/mysqld.pid
        echo "Starting MariaDB..."
        mariadbd --user=mysql --datadir=/var/lib/mysql \
            --socket=/var/lib/mysql/mysql.sock \
            --port=3306 \
            --bind-address=127.0.0.1 \
            --pid-file=/run/mysqld/mysqld.pid \
            --log-error=/var/log/mariadb/mariadb.log >/var/log/mariadb/console.log 2>&1 &
    fi

    for attempt in $(seq 1 60); do
        if [ -S /var/lib/mysql/mysql.sock ] && mariadb --socket=/var/lib/mysql/mysql.sock -e 'SELECT 1' >/dev/null 2>&1; then
            break
        fi

        if ! pgrep -x mariadbd >/dev/null 2>&1; then
            echo "MariaDB failed to start. Logs:" >&2
            [ -f /var/log/mariadb/mariadb.log ] && tail -n 50 /var/log/mariadb/mariadb.log >&2 || true
            [ -f /var/log/mariadb/console.log ] && tail -n 50 /var/log/mariadb/console.log >&2 || true
            exit 1
        fi

        sleep 1
    done

    echo "Creating Slurm accounting database..."
    mariadb --socket=/var/lib/mysql/mysql.sock -e "
        CREATE DATABASE IF NOT EXISTS slurm_acct_db;
        CREATE USER IF NOT EXISTS 'slurm'@'localhost' IDENTIFIED BY 'password';
        GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost';
        FLUSH PRIVILEGES;
    "

    echo "Starting slurmdbd..."
    exec slurmdbd -Dvvv
fi
