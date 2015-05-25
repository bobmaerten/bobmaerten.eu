---
title: Attention à la visibilité interne de vos conteneurs Docker
date: 2014-10-21 13:56 CEST
tags: sysadm, linux, ubuntu
image: coffeebeans
---
Au détour d'une [question sur twitter](https://twitter.com/bourvill/status/524492824302333953) de [Maxime](https://twitter.com/bourvill), j'ai eu l'occasion de me rendre compte que par défaut, 2 *containers* Docker lancés sur le même *host* pouvaient effectivement se « voir » et donc échanger sur leur ports ouverts comme bon leur semblent.

Bien que ce ne soit pas complètement gênant, il m'a semblé que cela pouvait potentiellement poser des problèmes de sécurité, ou [comme le souligne Maxime](https://twitter.com/bourvill/status/524527521589907456) des soucis fonctionnels.

**TL;DR** : Utilisez `--icc=false` dans vos paramètres du service `docker` pour isoler les communications inter-conteneurs.

READMORE

## Explications

Comme habituellement dans ce cas là, on dégaine le [RTFM](http://fr.wikipedia.org/wiki/RTFM) et on cherche comment ça fonctionne. Il faut savoir que le comportement par défaut de Docker est de permettre justement cette communication entre *containers*. Illustrons ceci avec un exemple.

Admettons que je lance un *container* `nginx` et que j'obtienne son IP interne.

    $ docker run --name container-nginx -d nginx
    1ab647f88995b0669d7e6b777b7640149c1805ebbba953f3e6662ce2e7289fbf

    $ docker inspect --format '{{ .NetworkSettings.IPAddress }}' container-nginx
    172.17.0.2

Puis je lance un second *container* pour vérifier la connectivité avec le premier sur le port 80

    $ docker run --rm -it ubuntu
    root@ec073d0d3f63:/# apt-get update && apt-get install curl -y
    [...]
    root@ec073d0d3f63:/# curl -I http://172.17.0.2
    HTTP/1.1 200 OK
    Server: nginx/1.7.6
    Date: Tue, 21 Oct 2014 12:22:07 GMT
    Content-Type: text/html
    Content-Length: 612
    Last-Modified: Tue, 30 Sep 2014 14:16:33 GMT
    Connection: keep-alive
    ETag: '542abb41-264'
    Accept-Ranges: bytes

Ça fonctionne ! O_o

Cela est dû au paramétrage par défaut de Docker. En effet, l'option `--icc` (inter-container communication) est par défaut à `true`. Pour désactiver ce comportement (recommandé en production), modifiez la variable `DOCKER_OPTS` du fichier `/etc/default/docker` avant de relancer le service (attention, cela stoppe tous vos *containers*).

    $ grep DOCKER_OPTS /etc/default/docker
    # Use DOCKER_OPTS to modify the daemon startup options.
    DOCKER_OPTS='--icc=false'

Petite précision, cela n'affectera pas la communication entre les *containers* liés. Pour cela, Docker modifie les règles du firewall en activant une règle FORWARD.

    $ docker run --rm -it --link container-nginx:nginx ubuntu
    root@f5bb6005185e:/# apt-get update && apt-get install curl -y
    [...]
    root@f5bb6005185e:/# curl -I http://172.17.0.2
    HTTP/1.1 200 OK
    Server: nginx/1.7.6
    Date: Tue, 21 Oct 2014 12:42:50 GMT
    Content-Type: text/html
    Content-Length: 612
    Last-Modified: Tue, 30 Sep 2014 14:16:33 GMT
    Connection: keep-alive
    ETag: '542abb41-264'
    Accept-Ranges: bytes

Un coup d'oeil sur les règles *iptables* sur un autre terminal :

    $ sudo iptables -L
    Chain INPUT (policy ACCEPT)
    target     prot opt source               destination

    Chain FORWARD (policy ACCEPT)
    target     prot opt source               destination
    ACCEPT     tcp  --  172.17.0.2           172.17.0.4           tcp spt:http
    ACCEPT     tcp  --  172.17.0.4           172.17.0.2           tcp dpt:http
    ACCEPT     tcp  --  172.17.0.2           172.17.0.4           tcp spt:https
    ACCEPT     tcp  --  172.17.0.4           172.17.0.2           tcp dpt:https
    ACCEPT     all  --  anywhere             anywhere             ctstate RELATED,ESTABLISHED
    ACCEPT     all  --  anywhere             anywhere
    DROP       all  --  anywhere             anywhere

    Chain OUTPUT (policy ACCEPT)
    target     prot opt source               destination

Et une fois le *container* terminé :

    $ sudo iptables -L
    Chain INPUT (policy ACCEPT)
    target     prot opt source               destination

    Chain FORWARD (policy ACCEPT)
    target     prot opt source               destination
    ACCEPT     all  --  anywhere             anywhere             ctstate RELATED,ESTABLISHED
    ACCEPT     all  --  anywhere             anywhere
    DROP       all  --  anywhere             anywhere

    Chain OUTPUT (policy ACCEPT)
    target     prot opt source               destination

## En résumé

Si vous souhaitez sécuriser un peu mieux votre *host* Docker, en particulier si vous faites tourner des conteneurs de différents clients/publics, pensez à activer l'option `--icc=false`.
