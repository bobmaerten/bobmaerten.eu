---
title: Un certificat Let's Encrypt toujours à jour sur le blog avec Docker
date: 2016-01-27 08:08:09 UTC
tags: blog, sysadm, linux
image: sliders
---
Depuis l'année dernière ce blog répond exclusivement en HTTPS grâce à un certificat valide et reconnu, issu d'une [autorité de certification chinoise](https://www.wosign.com) qui propose (proposait ?) des certificats gratuits. Mais depuis, [Let's encrypt](https://letsencrypt.org) est disponible en béta publique et je cherchais depuis quelques jours un moyen de l'inclure dans la _stack_ d'hébergement de ce blog et permettre la création et le renouvellement automatique de certificat SSL, comme il est promis dans la documentation.

READMORE

## Contexte

Ce blog est servi au travers de deux conteneurs Docker:

  * un issu de l'image officielle [nginx](http://hub.docker.com/_/nginx) sur laquelle j'y ajoute le [contenu statique](http://github.com/bobmaerten/bobmaerten.eu) ;
  * un autre exécutant l'image du [reverse-proxy nginx](http://hub.docker.com/r/jwilder/nginx-proxy) de [Jason Wilder](http://jasonwilder.com/) permettant d'uniformiser la configuration des différents sites et d'aiguiller vers le bon conteneur.

Il ne manquait plus qu'un dernier conteneur qui assurerait la gestion et le suivi des certificats issus de Let's Encrypt. Mais j'avais beau essayer d'utiliser le client officiel de différente manières, il y a toujours une étape ou le client doit se substituer au serveur web réel pour répondre au challenge proposé par les serveurs de Let's Encrypt, afin de valider la demande de certificat.

Heureusement, nous évoluons dans une sphère libre ! Il existe dès lors [moultes implémentations](https://www.metachris.com/2015/12/comparison-of-10-acme-lets-encrypt-clients/) légèrement différentes du client officiel. Et c'est avec l'une de ces implémentations qu'[Yves Blusseau](https://github.com/JrCs) a eu l'excellente idée d'[implémenter ce que je cherchais à faire](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion) : un conteneur qui fait tourner un client lets-encrypt, pilotant automatiquement la configuration du reverse-proxy pour la réponse au challenge du serveur et assurant la gestion des certificats, en incluant tout cela dans la configuration de nginx.

## Bon et techniquement, ça donne quoi ?

Donc voici les commandes qui me permettent de lancer la _stack_ de ce blog

```shell
# Démarrage du reverse-proxy nginx
docker run --name nginx-proxy \
  -p 80:80 -p 443:443 \
  -v /home/bob/certs:/etc/nginx/certs:ro \
  -v /etc/nginx/vhost.d \
  -v /usr/share/nginx/html \
  -v /var/run/docker.sock:/tmp/docker.sock:ro \
  --restart=always \
  --detach jwilder/nginx-proxy
```

Le conteneur accède au répertoire de l'hôte pour les certificats ainsi que sur le socket du _daemon_ Docker, car il a besoin de récupérer les metadonnées des conteneurs (notamment la variable VIRTUAL_HOST, voir ci-dessous). Deux volumes sur `/etc/nginx/vhost.d` et `/usr/share/nginx/html` sont déclarés car ils seront utilisés par le conteneur lets-encrypt.

```shell
# Démarrage du conteneur de gestion des certificats et de la conf nginx
docker run --name letsencrypt-companion \
  -v /home/bob/certs:/etc/nginx/certs:rw \
  --volumes-from nginx-proxy \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --restart=always \
  --detach jrcs/letsencrypt-nginx-proxy-companion
```

Ici le répertoire des certificats est monté en écriture et il sera partagé (sur l'hôte) avec le reverse-proxy. Ce conteneur utilise les volumes déclarés dans le reverse-proxy (`volumes-from`) ainsi que l'accès au socket du _daemon_ Docker également (pour lire les variables d'environnement déclarées sur les conteneurs “client”).

```shell
# Démarrage du conteneur du blog
docker run --name bobmaerten-eu \
   -e      VIRTUAL_HOST="bobmaerten.eu" \
   -e  LETSENCRYPT_HOST="bobmaerten.eu" \
   -e LETSENCRYPT_EMAIL="hello@bobmaerten.eu" \
   --restart=always \
   --detach bobmaerten/bobmaerten.eu:latest
```

Enfin, le conteneur qui sert le blog, ou je déclare les variables d'environnement qui seront utilisées pour la configuration du reverse-proxy (VIRTUAL_HOST) et du client lets-encrypt.

Au démarrage de la _stack_, le reverse-proxy détecte le VIRTUAL_HOST `bobmaerten.eu` et crée dynamiquement l'entrée `server` dans la configuration de nginx, et le client lets-encrypt modifie également dynamiquement la configuration du reverse-proxy si un certificat est échu ou renouvelé.

Je vous laisse le soin d'aller explorer les différents dépôts respectifs à cette _stack_ si vous êtes curieux du _comment-ça-marche-sous-le-capot_.
