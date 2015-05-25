---
title: L'envers du décor de mes screencasts
date: 2014-06-01 09:50 CEST
tags: sysadm, linux, life
image: camera
---
À l'occasion de la sortie de mon nouveau [screencast sur l'administration système avec Ansible](https://hackademy.io/tutoriel-videos/ansible-automatiser-gestion-serveur-partie-1) je voulais partager quelques techniques que j'ai utilisées pour produire les exemples exposés dans la video.

## Simuler des machines distantes

Vous avez remarqué que je me connectais à une bonne quinzaine de serveur tout au long de la video. Et si je vous disais que ces serveurs n'en sont pas vraiment ?!

En effet pour les besoins de l'exemple, je dois montrer des connexions SSH multiples et cela assez rapidement pour ne pas faire trainer en longueur la video. De plus je fonctionne avec 0 budget, donc hors de question de taper dans des offres cloud (même si j'en fais illusion à un moment).

C'est là que [Docker](https://docker.io) entre en scène. En arrière-plan du terminal affiché à l'écran pendant le screencast, une autre fenêtre met en oeuvre la mécanique. J'utilise des conteneurs docker pour isoler des services SSH et me permettre de simuler des accès à des machines complètes. Vous trouverez ci-dessous le `Dockerfile` et les scripts de `build` et de `start` somme toute assez classiques.

Dockerfile

    FROM     ubuntu
    MAINTAINER Bob Maerten 'bob.maerten@gmail.com'

    ENV DEBIAN_FRONTEND noninteractive
    RUN locale-gen en_US
    RUN locale-gen en_US.UTF-8
    RUN locale-gen fr_FR.UTF-8

    # make sure the package repository is up to date
    RUN echo 'deb http://archive.ubuntu.com/ubuntu trusty main universe' > /etc/apt/sources.list
    RUN apt-get update

    RUN apt-get install -y openssh-server
    RUN mkdir /var/run/sshd
    RUN echo 'root:screencast' | chpasswd

    # create some default users
    RUN mkdir /home/bob
    RUN useradd -s /bin/bash -d /home/bob bob
    RUN chown bob:bob /home/bob
    RUN echo 'bob:plop' | chpasswd

    RUN mkdir /home/user
    RUN useradd -s /bin/bash -d /home/user user
    RUN chown user:user /home/user
    RUN echo 'user:plop' | chpasswd

    RUN mkdir /home/deploy
    RUN useradd -s /bin/bash -d /home/deploy deploy
    RUN chown deploy:deploy /home/deploy
    RUN echo 'deploy:plop' | chpasswd

    # make this last one with sudo accreditations
    RUN mkdir /home/admin
    RUN useradd -s /bin/bash -d /home/admin admin
    RUN chown admin:admin /home/admin
    RUN echo 'admin:plop' | chpasswd
    ADD sudo_admin /etc/sudoers.d/10_admin
    RUN chown root: /etc/sudoers.d/10_admin
    RUN chmod 660 /etc/sudoers.d/10_admin

    EXPOSE 22
    CMD    /usr/sbin/sshd -D

sudo_admin

    admin ALL = (root) NOPASSWD: ALL

build_server.sh

    #!/bin/bash
    docker build -t hackademy/sshserver .

start_server.sh

    #!/bin/bash
    if [ -z '$1' ]
      then
        echo 'usage: $0 <server name>'
    fi
    docker run -h $1 -d hackademy/sshserver

Ce dernier script me permet donc de lancer une batterie de conteneurs qui feront office de « machines » sur lequelles j'aurais un shell disponible pour effectuer des commandes distantes. L'empreinte de ces VMs est relativement faible, en tout cas, suffisament pour que ma petite machine (C2Duo 4Go RAM) à la maison encaisse le choc.

    $ ./build_server.sh
    ...
    $ for i in $(seq 1 9); do ./start-server.sh web-0$i; done > server_ids
    $ cat server_ids
    e84065a55b84db66301147cf353972a4c7b34ba28513fc2a848e0708bc7f5d8b
    c20a0c2f18f3477290ada61d5ae7872ec7bc06c490f51af81ddc37c5ed901569
    ddf52e12278e8a92161297dc63ac782aa2f3075eab127684b68a54fd367805e5
    db31c10d76a56e6c5225b06212304a0cd83598ed5c75ee679fa80df2ecd1f0eb
    0972068252a523b1bb5ec3ac1b02943ac2246cd4047ff5e04fe9a940886b20e3
    648dd8b5bf3817e83a6dea5b585437edbc05d2d604a198e9d2f2f45e9323bae5
    6eeaf3218e1bb3a9b0ef339c004f38b73bab6fdbe4c0801da761f13ad7aeb515
    d179421e252452735634160feeb06747e980c905806f139ea2430301e9da60b5
    e2547fdb9956214632c4a3ed83ee80c10bb96ce513257530850194d7dab9ab87

Toutes ces machines ont une adresse IP que je récupère à l'aide de la commande `docker inspect`

    $ N=1
    $ for i in $(cat server_ids); \
      do echo '$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $i)  web-0$N'; \
      N=$((N+1)); \
      done
    172.17.0.2  web-01
    172.17.0.3  web-02
    172.17.0.4  web-03
    172.17.0.5  web-04
    172.17.0.6  web-05
    172.17.0.7  web-06
    172.17.0.8  web-07
    172.17.0.9  web-08
    172.17.0.10  web-09

que je peux ajouter dans un fichier `/etc/hosts` afin de pouvoir me connecter à ces machines avec leur nom. Je peux ensuite utiliser ces noms dans mon fichier `~/.ssh/config` selon les besoin du screencast.

    $ cat ~/.ssh/hosts
    Host webserver
        HostName web-01
        User admin
        IdentityFile ~/.ssh/id_rsa
        StrictHostKeyChecking no

Une fois le screencast terminé, je peux supprimer les conteneurs.

    $ for i in $(cat server_ids); do docker stop $i; done

Pratique docker, non ? ;-)

## Taper rapidement des commandes sans se planter (ou presque)

Une autre technique que j'ai utilisée consiste à éviter de taper des commandes le plus possible, car c'est souvent gage d'erreur de frappes du fait de ne pas être complètement concentré sur le terminal. J'ai donc trouvé un outil sous linux qui permet d'envoyer des frappes de touches ou des mouvements de souris sur une autre fenêtre. Il s'agit de [xdotool](http://www.semicomplete.com/projects/xdotool/xdotool.xhtml).

Associé à un petit script maison qui prend en paramètre la chaine de caractères à envoyer, lancé dans un xterm (et pas le terminal classique pour éviter la confusion des fenêtres), il m'a été possible de simuler une écriture rapide de commandes.

    $ cat ~/bin/type.sh
    #!/bin/bash
    WID=`xdotool search --onlyvisible --name 'Terminal'`
    xdotool windowfocus $WID
    xdotool type --delay $1 '$2'
    xdotool key 'Return'
    $ type.sh 50 'cette commande s'affiche caractère par caractère sur un autre terminal'

Du coup, je rassemble tout cela dans un autre script pour pré-enregistrer les lignes à taper pendant l'enregistrement du screencast, entrecoupées de `read` pour pouvoir temporiser en fonction de la piste audio préalablement enregistrée.

    $ cat screencast.sh
    #!/bin/bash
    type.sh 50 'ansible webserver -m copy -a \'src=web/contacts.html dest=/var/www/site/contacts.html\''
    read
    type.sh 50 'ansible webserver -m file -a \'dest=/var/www/tmp mode=0660 owner=www-data group=www-data\' --sudo'
    read
    type.sh 50 'ansible webserver -m apt -a \'name=php5-ldap state=present\' --sudo'
    read
    type.sh 50 'ansible dbserver -m user -a \'name=sqluser state=absent\' --sudo'

Voilà, vous savez tout. Il n'y a plus qu'à vous lancer vous aussi. De nombreux sujets n'attendent que des gens suffisamment passionnés pour les exposer aux autres. C'est intéressant à faire, on apprends plein de choses en le faisant et les retours sont toujours très intéressants.

À qui le tour ?
