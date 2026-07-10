# Slightly Less of a Cluster

## (not very) Quickstart

Run
```sh
$ ./cluster-build
```

Wait ~10 mins

SSH into the login node
```sh
$ ssh -i cluster_key dev@localhost -p 2222
```

## Features
To build the containers with custom settings, use
```sh
$ ./cluster-build [-m --mem memory] [-n --nodes compute nodes] [--module=[env|lmod] choose module framework] [--database enable database node]
```

### Memory
The `-m` or `--memory=` flag will allocate that many megabytes of memory to the compute nodes

### Nodes
the `-n` or `--nodes=` flag will run that many compute nodes.

### Modules
The `--module=` flag will let you load some test modules in with either environment modules or the lmod framework.
Use `--module=env` for envonment modules, `--module=lmod` for the lmod framework, or leave it blank for no module support.
As modules are installed at runtime rather than being included in the docker image, it is reccommended to allocate at least 1GB of RAM to the nodes if you are using modules.

### Database
Slurm has support for a database which stores accounting, job history, resource usage, user associations, and cluster configuration data, enabling reporting, fair-share scheduling, and centralized management across one or more Slurm clusters.
To add a container that hosts a database, use the `--database` flag

## Other Info
To bring the containers down, use
```sh
$ docker compose -p slightly-less-of-a-cluster down
```

To bring them back up again without rebuilding run
```sh
$ docker compose -p slightly-less-of-a-cluster up
```

To wipe docker for a fresh restart
```sh
$ ./prune-all
```
> [!WARNING]
> This action will destroy all docker containers and volumes.
> Make sure you have a backup before continuing.