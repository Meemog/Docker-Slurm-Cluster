# (not very) Quickstart

Run
```sh
$ ./cluster-up <Num Nodes>
```

Wait ~10 mins

SSH into the login node
```sh
$ ssh -i cluster_key dev@localhost -p 2222
```

To wipe docker for a fresh restart
```sh
$ ./prune-all
```
> [!WARNING]
> This action will destroy all docker containers and volumes.
> Make sure you have a backup before continuing.