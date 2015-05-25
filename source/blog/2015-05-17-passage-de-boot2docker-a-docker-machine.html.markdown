---
title: Passage de boot2docker à docker-machine
date: 2015-05-17 13:12:14 +0200
tags: sysadm, dev, linux, osx
image: trainstation

---
Entre mon nouveau job, mon passage à OSX pour le boulot, et la défaillance de mon portable sous Linux, j'ai eu peu de temps à consacrer à l'actualité de Docker. Cependant ça bouge pas mal ces derniers temps avec des projets comme [machine](https://docs.docker.com/machine/), [compose](https://docs.docker.com/compose/) et [swarm](https://docs.docker.com/swarm/) et j'ai récemment essayé de rattraper un peu le retard. Dans ce billet je vais exposer ma découverte de `docker-machine` qui m'a permis de retrouver l'usage courant que j'avais de docker sous Linux.

READMORE

## Boot2Docker

Comme un bon OSXien bien élevé au grain, j'ai tout d'abord suivi les conseils du net en installant [boot2docker](https://github.com/boot2docker/boot2docker) pour faire fonctionner docker sous forme d'une VM Linux sous VirtualBox. La procédure est très simple&nbsp;:

```console
$ brew cask install virtualbox 
$ brew install boot2docker
$ boot2docker up
```

Les recettes installent les dernières versions des logiciels requis. `boot2docker` est au final un executable permettant de lancer/stopper/mettre à jour la VM en suivant les mises à jour de docker. Jusque là tout va bien, on parvient même à oublier la présence de cette VM et il m'est arrivé de chercher la cause de l'absence d'un service web en appelant `http://localhost:<service_port>` au lieu de `http://<boot2docker_ip>:<service_port>`...

Il existe certes quelques soucis de performances inhérents à l'usage de VirtualBox qui n'est pas par définition très véloce sur les systèmes de fichiers. Celà dit pour un usage en développent ce n'est pas très ennuyeux, et il existe des [solutions de contournement](http://blog.blackfire.io/how-we-use-docker.html).

## Docker Machine

Dernièrement, le sous-projet `machine` est arrivé chez Docker permettant de faire la même chose mais avec la possibilité d'utiliser différents _drivers_. En fonction du _driver_ utilisé `machine` va installer un système d'exploitation permettant d'utiliser docker sur la cible indiquée. Cette cible pouvant être un fournisseur de ressources sur le _cloud_ ou votre propre installation VirtualBox locale.

L'intérêt évident ici est de permettre d'utiliser les mêmes commandes et d'acquérir les mêmes habitudes quel que soit l'environnement cible que l'on manipule (dev, staging, prod) et quelque soit le service utilisé (VirtualBox, service Cloud, voire en développant son propre _driver_).

Pour répliquer l'environnement boot2docker, il suffit donc d'installer `docker-machine` ou de suivre les [consignes d'installation](https://docs.docker.com/machine/#installation) du site officiel. Dès lors, `machine` va télécharger au besoin la dernière version de l'iso de _boot2docker_ et déployer une nouvelle VM sous VirtualBox, exactement de la même manière que le processus “natif” de boot2docker.

```console
$ brew install docker-machine
$ docker-machine create --driver virtualbox dev
INFO[0000] Creating SSH key...
INFO[0000] No default boot2docker iso found locally, downloading the latest release...
INFO[0001] Downloading latest boot2docker release to /Users/bob/.docker/machine/cache/boot2docker.iso...
INFO[0044] Creating VirtualBox VM...
INFO[0051] Starting VirtualBox VM...
INFO[0051] Waiting for VM to start...
INFO[0103] 'dev' has been created and is now the active machine.
INFO[0103] To point your Docker client at it, run this in your shell: eval '$(docker-machine env dev)'
```
Remarquez la dernière ligne qui est assez importante. Lancer `eval '$(docker-machine env dev)'` permet en effet de paramétrer le _shell_ courant pour permettre d'utiliser l'environnement choisi avec les outils docker.

```console
$ eval '$(docker-machine env dev)'

$ docker info
Containers: 0
Images: 0
Storage Driver: aufs
Root Dir: /mnt/sda1/var/lib/docker/aufs
Backing Filesystem: extfs
Dirs: 0
Dirperm1 Supported: true
Execution Driver: native-0.2
Kernel Version: 4.0.3-boot2docker
Operating System: Boot2Docker 1.6.2 (TCL 5.4); master : 4534e65 - Wed May 13 21:24:28 UTC 2015
CPUs: 8
Total Memory: 997.3 MiB
Name: dev
[...]
Labels:
 provider=virtualbox

$ docker run busybox echo Hello World
Unable to find image 'busybox:latest' locally
latest: Pulling from busybox
cf2616975b4a: Pull complete
6ce2e90b0bc7: Pull complete
8c2e06607696: Already exists
busybox:latest: The image you are pulling has been verified. Important: image verification is a tech preview feature and should not be relied on to provide security.
Digest: sha256:38a203e1986cf79639cfb9b2e1d6e773de84002feea2d4eb006b52004ee8502d
Status: Downloaded newer image for busybox:latest
Hello World

$ docker ps -a
CONTAINER ID        IMAGE               COMMAND              CREATED             STATUS                      PORTS               NAMES
d289f3082caf        busybox:latest      'echo Hello World'   11 seconds ago      Exited (0) 11 seconds ago                       drunk_pare
```

Et comme je le disais plus haut, le _workflow_ est exactement le même en utilisant un autre _driver_&nbsp;:

```console
$ docker-machine create --driver digitalocean --digitalocean-access-token=$MY_ACCESS_TOKEN docker-prod
INFO[0000] Creating SSH key...
INFO[0001] Creating Digital Ocean droplet...
INFO[0201] 'docker-prod' has been created and is now the active machine.
INFO[0201] To point your Docker client at it, run this in your shell: eval '$(docker-machine env docker-prod)'

$ eval '$(docker-machine env docker-prod)'

$ docker run busybox echo Hello World
Unable to find image 'busybox:latest' locally
latest: Pulling from busybox
cf2616975b4a: Pull complete
6ce2e90b0bc7: Pull complete
8c2e06607696: Already exists
busybox:latest: The image you are pulling has been verified. Important: image verification is a tech preview feature and should not be relied on to provide security.
Digest: sha256:38a203e1986cf79639cfb9b2e1d6e773de84002feea2d4eb006b52004ee8502d
Status: Downloaded newer image for busybox:latest
Hello World

$ docker ps -a
CONTAINER ID        IMAGE               COMMAND              CREATED             STATUS                     PORTS               NAMES
7b8b283fceaa        busybox:latest      'echo Hello World'   11 seconds ago      Exited (0) 9 seconds ago                       gloomy_bohr
```

Et ces deux environnements sont désormais accessibles en permuttant d'une cible à l'autre avec la commande `eval` indiquée au démarrage d'une machine&nbsp;:

```console
$ docker-machine ls
NAME          ACTIVE   DRIVER         STATE     URL                         SWARM
dev                    virtualbox     Running   tcp://192.168.99.102:2376
docker-prod   *        digitalocean   Running   tcp://45.55.254.233:2376

$ eval '$(docker-machine env dev)'

$ docker ps -a
CONTAINER ID        IMAGE               COMMAND              CREATED             STATUS                      PORTS               NAMES
d289f3082caf        busybox:latest      'echo Hello World'   2 minutes ago       Exited (0) 2 minutes ago                        drunk_pare
```

## Accéder aux containers depuis l'hôte

Il y avait encore quelque chose qui me gênait dans l'usage d'une VM pour Docker en local, c'est l'accès aux containers directement depuis ma machine. Sous linux, Docker est exposé sur une interface routée par défaut. Avec une VM sous VirtualBox, il faut déclarer la route manuellement&nbsp;:

```console
$ /usr/sbin/scutil -w State:/Network/Interface/vboxnet0/IPv4 -t 0

$ sudo /sbin/route -n add -net 172.17.0.0 -netmask 255.255.0.0 -gateway $(docker-machine ip)
```

On peut ainsi créer un _container_ et le _ping_er depuis le système local.

```console
$ docker run --name=redis -d redis

$ ping -c 3 $(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $(docker ps -ql))
PING 172.17.0.1 (172.17.0.1): 56 data bytes
64 bytes from 172.17.0.1: icmp_seq=0 ttl=63 time=3.164 ms
64 bytes from 172.17.0.1: icmp_seq=1 ttl=63 time=3.985 ms
64 bytes from 172.17.0.1: icmp_seq=2 ttl=63 time=9.379 ms

--- 172.17.0.1 ping statistics ---
3 packets transmitted, 3 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 3.164/5.509/9.379/2.757 ms
```

Cette manipulation ne résistant pas au reboot, sous OSX on peut ajouter un `plist` pour remettre la route au démarrage de la machine. Il faut toutefois faire attention à quel _vboxnet_ est rattaché la VM et quelle est l'ip attribuée par VirtualBox&nbsp;:

Voici le plist (`/Library/LaunchDaemons/com.docker.route.plist`) pour ma VM sur le vboxnet0 et d'adresse IP 192.168.99.100

```xml 
<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE plist PUBLIC '-//Apple//DTD PLIST 1.0//EN' 'http://www.apple.com/DTDs/PropertyList-1.0.dtd'>
<plist version='1.0'>
<dict>
  <key>Label</key>
  <string>com.docker.route</string>
  <key>ProgramArguments</key>
  <array>
    <string>bash</string>
    <string>-c</string>
    <!-- You need to adapt the vboxnet0 to the interface that suits your setup, use ifconfig to find it -->
    <string>/usr/sbin/scutil -w State:/Network/Interface/vboxnet0/IPv4 -t 0;sudo /sbin/route -n add -net 172.17.0.0 -netmask 255.255.0.0 -gateway 192.168.99.100</string>
  </array>
  <key>KeepAlive</key>
  <false/>
  <key>RunAtLoad</key>
  <true/>
  <key>LaunchOnlyOnce</key>
  <true/>
</dict>
</plist>
```

## Bonus: accéder aux containers par un nom DNS

Le top du top serait d'avoir un système qui permet d'accéder aux conteneurs créés par leur nom plutôt que par un IP ou une redirection de port. On trouve pas mal de projets liés à cette problèmatique sur github, mais celui qui a retenu mon attention est [dnsdock](https://github.com/tonistiigi/dnsdock). Il s'appuie sur les recherches d'[autres](http://www.asbjornenge.com/wwc/vagrant_skydocking.html) [projet](https://github.com/tonistiigi/dnsdock), mais il a pour lui la simplicité que je recherchais à la fois dans son installation et son utilisation.

Dans un premier temps il suffit de lancer un conteneur qui va repérer la création/suppression d'autre conteneur et enregistrer leurs nom dans un service DNS&nbsp;:

```console
$ docker run -d -v /var/run/docker.sock:/var/run/docker.sock --name dnsdock --restart=always -p 172.17.42.1:53:53/udp tonistiigi/dnsdock
```

Notez l'utilisation `--restart=always` permettant de recharger le container au redémarrage de la VM.

Ensuite, il suffit d'ajouter un `resolver` à OSX pour résoudre les noms des conteneurs avec le suffixe `.docker` (voir la documentation de dnsdock pour un paramétrage différent).

```console
$ sudo mkdir -p /etc/resolver ; echo 'nameserver 172.17.42.1' | sudo tee /etc/resolver/docker

$ ping redis.docker
PING redis.docker (172.17.0.2): 56 data bytes
64 bytes from 172.17.0.2: icmp_seq=0 ttl=63 time=2.256 ms
64 bytes from 172.17.0.2: icmp_seq=1 ttl=63 time=5.212 ms
64 bytes from 172.17.0.2: icmp_seq=2 ttl=63 time=2.228 ms

--- redis.docker ping statistics ---
3 packets transmitted, 3 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 2.228/3.232/5.212/1.400 ms
```

A priori il est possible de faire la même chose sous Linux en ajoutant l'adresse de _bridge_ au fichier `/etc/resolv.conf` en tant que _resolver_, mais n'en ayant plus sous la main je ne peux donner de mode opératoire. L'utilisation d'une autre image comme [docker-spy](https://github.com/iverberk/docker-spy) pourrait être opportune également.

## Conclusion

Voilà, j'ai désormais de quoi faire tourner des conteneurs Docker de manière pas trop douloureuse sous OSX, mais entre boot2docker et docker-machine alors, comment choisir&nbsp;? Les moins de 40 ans ne comprendront surement pas l'allusion mais voici ma petite recette pour choisir.

![Pub FLUOGUM](http://i.imgur.com/QkkmmIs.png)

À ma gauche un _host_ qui tourne sous boot2docker.

À ma droite mon _host_ qui tourne sous docker-machine.

A priori c'est la même chose, mais ce n'est pas la même chose !

Car dans mon host, y'a du docker-machine,

et ♫ “docker-machine, c'est bon pour [créer et switcher d'environnement](https://twitter.com/icecrime/status/599928881953443840)&nbsp;!”
