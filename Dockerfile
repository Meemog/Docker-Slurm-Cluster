FROM rockylinux:9

RUN dnf -y update && \
    dnf -y install dnf-plugins-core && \
    dnf config-manager --set-enabled crb || true && \
    dnf -y install epel-release && \
    dnf makecache

RUN dnf -y groupinstall "Development Tools" && \
    dnf -y install \
      wget tar perl openssl-devel pam-devel numactl-devel \
      hwloc-devel lua-devel readline-devel libibmad libibumad \
      munge munge-devel \
      openssh-server openssh-clients sudo \
    && dnf clean all

RUN groupadd -r slurm && useradd -r -g slurm slurm

RUN useradd -m dev

# Make the dev user a sudouser
RUN usermod -aG wheel dev
RUN echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev && \
    chmod 0440 /etc/sudoers.d/dev

RUN mkdir -p /var/log/munge /var/lib/munge /run/munge && \
    chown -R munge:munge /var/log/munge /var/lib/munge /run/munge && \
    chmod 700 /var/log/munge /var/lib/munge /run/munge

WORKDIR /usr/src

ARG SLURM_VERSION=20.11.9

RUN wget -O slurm.tar.bz2 \
    https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2 && \
    tar -xjf slurm.tar.bz2

WORKDIR /usr/src/slurm-${SLURM_VERSION}

RUN ./configure \
    --prefix=/usr/local/slurm \
    --sysconfdir=/etc/slurm \
    --with-munge \
    --disable-dependency-tracking \
    --disable-cgroup

RUN make -j$(nproc) && make install

RUN find /usr/local/slurm/lib/slurm -name "*cgroup*" -delete || true

RUN mkdir -p \
      /etc/slurm \
      /var/log/slurm \
      /slurm/state /slurm/spool && \
    chown -R slurm:slurm \
      /var/log/slurm \
      /slurm

ENV SLURM_NO_SYSTEMD=1

ENV PATH="/usr/local/slurm/bin:/usr/local/slurm/sbin:$PATH"
RUN echo 'export PATH=/usr/local/slurm/bin:/usr/local/slurm/sbin:$PATH' \
    > /etc/profile.d/slurm.sh

RUN ssh-keygen -A

RUN rm -f /usr/local/slurm/lib/slurm/task_cgroup.so || true && \
    rm -f /usr/local/slurm/lib/slurm/cgroup*.so || true

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]