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
$ ./cluster-build [-m --mem memory] [-n --nodes compute nodes] [--lmod enable lmod]
```

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