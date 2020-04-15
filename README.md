CitadelOS
==================

Bootstrap CitadelOS
-------
Open a ComputerCraft terminal on a computer, turtle, or pocket computer.

Copy and paste the following, then press enter.

```
wget run https://raw.githubusercontent.com/citadel-ftb/CitadelOS/master/bootstrap.lua
```

Your device should download the installer and reboot showing the CitadelOS version on startup

Install
--------

The install command will get the latest from github! Use this if a computer has become out of date.

```
install
```

It's also expected while working on new features, or testing someones feature, that this would live in another branch
while in development. To download a branch other than master, simply pass the name of the branch to the install command.

```
install feature-my-branch
```

Note that after syncing to a new branch, it should always sync to that branch on install. If you ever need to get back
to master, simply use the following, or use another branch name if switching to another feature branch.

```
install master
```

Extract
-------

Currently extract supports extracting material from chunks, indexed relative to an origin chunk defined by your GPS
hosts positions. It's required that GPS hosts are placed on at least three corners of your origin chunk, though four is
recommended.

There are also currently some hard coded values in this routine, so be aware that you'll need to modify those if using
this outside of the mining dimension in The Citadel server. Eventually, the positions for recharge and offloading will
be provided by the control program.

A single bot can extract a single chunk. This will take roughly four hours, require a player or worldspike present, and use
roughly 8000 fuel. The following will instruct a bot to mine the north (-1) east (1) chunk from the origin.

```
extract chunk 1 -1
``` 

For higher speeds, it is recommended to divide the chunk extraction work between multiple bots using sub chunk ranges.
Each extract command can additionally take an optional start sub chunk, and an optional end sub chunk, both in the range
of 0-15. Here is an example of how to split a chunk between two bots to halve the time required for mining a chunk.

Bot 1. 
```
extract chunk 1 -1 0 7
```

Bot 2.
```
extract chunk 1 -1 8
```

Notice the second sub chunk parameter is missing for bot two, this is not necessary, as the end chunk defaults to 15,
which is our intended end chunk for this bot. These ranges can be broken up in whatever way you see fit, get creative
with them!