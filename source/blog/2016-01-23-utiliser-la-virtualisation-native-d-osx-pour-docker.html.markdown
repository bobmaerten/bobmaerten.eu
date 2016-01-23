---
title: Utiliser la virtualisation native d'OSX pour Docker
date: 2016-01-23 14:16:10 UTC
tags: sysadm, dev, osx
image: book
---
Docker est un outil linux natif et pour l'utiliser sous OSX (ou Windows) il faut passer par une machine virtuelle sous linux pour faire tourner le _daemon_.

Pour cela, la pratique courante est d'installer un hyperviseur (habituellement Virtualbox) afin de faire tourner `boot2docker`, la micro-VM fournie par Docker afin de l'utiliser sous un autre système. Mais il est désormais possible de s'en passer sous OSX.

READMORE

## Hypervisor.framework

La version 10.10 (Yosemite) d'OSX a introduit un système de virtualisation natif en mode utilisateur et permet l'utilisation directe des instructions VT-x des processeurs Intel. Cela permet donc de virtualiser des applications, sans extension du noyau.

D'ailleurs, [Veertu](http://veertu.com/), récemment publié sur l'app store permet d'installer des VMs en utilisant l'hyperviseur natif d'OSX, explique bien cette différence.

![Legacy Virt](http://veertu.com/test/wp-content/uploads/2015/10/legacy.svg)
![OSX Virt](http://veertu.com/test/wp-content/uploads/2015/10/new.svg)

Bien que Veertu propose l'[installation de boot2docker](https://twitter.com/veertu_labs/status/687552097869533184) ce n'est pas de ce système dont je vais vous parler.

## Xhyve et son driver docker-machine

[Xhyve](https://github.com/mist64/xhyve) s'appuie également sur l'_hypervisor.framework_ d'OSX et permet de virtualiser des systèmes linux et BSD tout comme il était possible de le faire avec Virtualbox, mais sans la lourdeur d'Oracle. Son installation est on ne peut plus simple dès lors que *homebrew* est installé (_t'es un dev sous mac et t'as pas homebrew installé, nan mais all..._ 😬) : `brew install xhyve`.

Mais là ou cela devient intéressant, c'est qu'il existe désormais un [driver xhyve pour docker-machine](https://github.com/zchee/docker-machine-driver-xhyve) (celui de Virtualbox est utilisé par défaut si on n'en précise pas). L'installer est tout aussi simple : `brew install docker-machine-driver-xhyve`.

Cela dit, je vous recommande chaudement de tout installer avec homebrew. J'avais des restes d'installation de **docker-toolbox** et la création de la VM n'a pas fonctionné. Le mieux est donc de supprimer les binaires et de les réinstaller avec homebrew :

    brew install xhyve docker docker-machine docker-compose docker-machine-driver-xhyve

Au jour de rédaction de ce billet, voici les versions installées suite à cette commande :

  * xhyve-0.2.0
  * docker-1.9.1_1
  * docker-machine-0.5.6_1
  * docker-compose-1.5.2
  * docker-machine-driver-xhyve-0.2.1

## Création et démarrage de la VM

Pour installer et démarrer la VM docker, il suffit d'utiliser docker-machine avec le driver xhyve.

    $ docker-machine create dockerhost --driver xhyve
    Running pre-create checks...
    Creating machine...
    (dockerhost) Copying /Users/bob/.docker/machine/cache/boot2docker.iso to /Users/bob/.docker/machine/machines/dockerhost/boot2docker.iso...
    (dockerhost) Creating VM...
    (dockerhost) Extracting vmlinuz64 and initrd.img from boot2docker.iso...
    (dockerhost) /dev/disk2                                                 /Users/bob/.docker/machine/machines/dockerhost/b2d-image
    (dockerhost) "disk2" unmounted.
    (dockerhost) "disk2" ejected.
    (dockerhost) Generating 20000MB disk image...
    (dockerhost) created: /Users/bob/.docker/machine/machines/dockerhost/root-volume.sparsebundle
    (dockerhost) Creating SSH key...
    (dockerhost) Fix file permission...
    (dockerhost) Generate UUID...
    (dockerhost) Convert UUID to MAC address...
    (dockerhost) Starting dockerhost...
    (dockerhost) Waiting for VM to come online...
    (dockerhost) Waiting on a pseudo-terminal to be ready... done
    (dockerhost) Hook up your terminal emulator to /dev/ttys004 in order to connect to your VM
    Waiting for machine to be running, this may take a few minutes...
    (dockerhost) Getting to VM state...
    Machine is running, waiting for SSH to be available...
    Detecting operating system of created instance...
    Detecting the provisioner...
    Provisioning with boot2docker...
    Copying certs to the local machine directory...
    Copying certs to the remote machine...
    Setting Docker configuration on the remote daemon...
    Checking connection to Docker...
    Docker is up and running!
    To see how to connect Docker to this machine, run: docker-machine env dockerhost

Il suffit ensuite de raccrocher l'environnement local à la nouvelle VM docker :

    $ eval "$(docker-machine env dockerhost)"
    $ docker ps -a
    CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
    $ docker run --rm busybox echo 'plop!
    latest: Pulling from library/busybox
    583635769552: Pull complete
    b175bcb79023: Pull complete
    Digest: sha256:c1bc9b4bffe665bf014a305cc6cf3bca0e6effeb69d681d7a208ce741dad58e0
    Status: Downloaded newer image for busybox:latest
    plop!

Et voilà, vous pouvez effacer votre stack Virtualbox ! Bon, peut-être pas tout de suite car ceci est encore plutôt expérimental, aussi je vais éprouver la solution dans les jours/semaines qui viennent, et ce sera l'occasion d'un prochain billet pour évalauer les performances et la fiabilité de la _stack_.
