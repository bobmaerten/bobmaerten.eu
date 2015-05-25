---
title: Isoler des sites web entre eux sur un même serveur
date: 2014-12-04
image: coffeebeans
tags: [sysadm, web]
---

Dans le cadre d'un projet de reprise d'un existant vieillissant, je devais proposer un système d'isolation d'hébergement de sites web pour un certain nombre d'entités à culture non-technique. L'idée étant de pouvoir gérer facilement la mise à disposition de ces sites, de pouvoir en créer et en archiver à la demande le plus automatiquement possible.

## Contexte

L'ancien système reposait sur l'utlisation de [suExec](http://httpd.apache/org/docs/2.2/suexec.html) permettant d'isoler l'exécution des processus PHP à l'utilisateur propriétaire du fichier appelé. Disponible uniquement sous forme de module/patch à appliquer, je souhaitais rester sur les implémentations standards livrées avec la version stable de Debian, et donc utiliser PHP-fpm.

L'accès aux fichiers des sites fonctionnait à l'aide d'un serveur SFTP mais nous ne souhaitions pas modifier cette partie pour éviter un changement d'habitudes pour les utilisateurs.

Une petite base de données se chargeait de stocker les informations des utilisateurs valides et une configuration de `nsswitch` reliait ces utilisateurs à l'environnement linux grace à un UID.GID permettant d'associer des droits sur des fichers et des accrédiations pour l'accès en modifications à ces fichiers permettant la mise à jour des sites avec un client SFTP. Quelques scripts maison permettaient la gestion au quotidien de ces sites.

## Recherche d'une solution

Un premier test avec PHP-fpm faisant usage de differents `pools` affectés à chacun des sites s'est révélé suffisant pour reproduire le comportement de l'existant, tandis que l'accès aux fichiers des sites était confié à un environnement SSH en chroot. Je restais cependant en terrain connu et pour le coup je voulais vraiment « sortir de ma zone de confort » et essayer d'apprendre des choses.

Je me suis vite mis dans la tête d'exploiter cela avec [Docker](https://docker.com) et mon outil d'orchestration favori [Ansible](http://ansiblework.com).

## Docker à la rescousse

Le [Hub](http://registry.hub.docker.com/) de Docker fournit officiellement un certain nombre d'images de conteneurs intéressants tels que [PHP ou PHP avec Apache](https://registry.hub.docker.com/_/php/) permettant de traiter facilement le cas de la gestion interne du site web. Il suffit de monter un [volume](http://docs.docker.com/reference/builder/#volume) dans le conteneur au moment de la création pour que le site répondre soit opérationnel.

Concernant la problématique du routage des sites, je suis tombé sur un [article de Jason Wilder](http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker) et son [image docker](https://github.com/jwilder/nginx-proxy) associée, permettant d'écouter sur le socket Docker l'évènement de création d'un conteneur et au passage d'intercepter une variable d'environnement passée et ainsi ajouter les informations nécessaires au relai vers le bon conteneur via un serveur `nginx` configuré en reverse-proxy.

Cette image est vraiment très pratique et complètement dynamique, à tel point qu'elle tourne désormais en permanence sur ma machine de développement, accompagnée d'[un petit script qui modifie mon fichier `/etc/hosts`](https://gist.github.com/bobmaerten/) local pour plus de souplesse.

Reste à gérer les besoins de mise à jour des sites dans le cadre d'une isolation complète et a fortiori, la possibilté de déplacer d'un bloc toute la logique du site (sur un autre serveur par exemple). Une solution est de faire tourner un service sftp à l'intérieur du conteneur laissant accès aux fichiers du conteneur, mais cela signifie modifier l'image officielle. Une autre solution est de multiplier les conteneurs et leur affecter des rôles spécifiques :

* 1 conteneur volume pour les fichiers
* 1 conteneur php/apache pour "exécuter" le site lié au volume fichier
* 1 conteneur sftp également lié au volume pour la mise à jour

On pourrait imaginer aussi un autre conteneur de base de données lié cette fois à l'instance php/apache pour fournir ce service, mais le choix de mutualiser les bases sur un serveur dédié à été préféré.

## Les problèmes commencent

Je suis cependant tombé sur un problème technique. Le protocole SFTP s'appuie sur SSH/SSL qui a un fonctionnement réseau très simple : il se connecte sur un port d'une adresse IP connue après résolution du nom DNS. Ce qui signifie qu'il est impossible de faire un "routage" via le nom du site en amont de l'hôte docker, et que dans ce cas, il faut exposer autant de ports que de conteneur de site.

Bien que certainement plus souple, cette solution n'était ni envisageable pour l'équipe réseau (gérer autant de flux que de sites) ni pour les utilisateurs (déjà retenir un couple login/passwd, alors s'il faut ajouter un port...).

Le compromis a donc été d'installer un conteneur SFTP pour tous les sites, dans lequel on monte l'arborescence des sites gérés par l'hôte. L'accès des utilisateurs étant géré par un système équivalent au conteneur reverse-proxy : écoute du socket docker pour déterminer la création/suppression d'un conteneur `php` pour activer/désactiver l'utilisateur correspondant dans le conteneur SFTP.

## Architecture technique retenue

                                   +------ php:apache_1 <-------+
     :80 ====> nginx-proxy --:80---+------ ...                  |
                    ^              +------ php:apache_n <-+     |
                    |                                     |     |
     :22 ====> heberg-sftp <----+                         |     |
                ^   |           |                         |     |
                |   |           |                         |     |
                +-+-+           |                         |     |
                  |          /sites/                      |     |
        unix:docker.sock      /site_1 --------------------+-----+
                              ...       montage volume    |
                              /site_n --------------------+

On monte le socket docker de l'hôte au niveau des deux conteneurs frontaux pour qu'ils soient à l'écoute des évenements du service Docker et qu'ils réagissent au besoin à la création/suppression de conteneurs :

- possédant la variable d'environnement `VIRTUAL_HOST`
- ayant pour image `php:apache`

Le reverse-proxy ajoute une `upstream` et un bloc `server` correspondant au conteneur créé et recharche sa configuration. Le serveur SFTP lui effectue les opérations suivantes :

- ajoute ou supprime un compte utilisateur correspondant au nom du site ; le mot de passe est celui d'un fichier de l'arborescence (ou généré si absent) et affiché dans les logs
- redirige les logs du conteneur créé vers les fichiers `access.log` et `error.log` dans l'arborescence du site.

Lorsqu'on crée les conteneurs `backend` avec l'image `php:apache`, la variable d'environnement `VIRTUAL_HOST` et un point de montage correspondant au site, les deux conteneur frontaux s'activent automatiquement pour mettre en oeuvre l'accès au site.

## Automatisation avec Ansible

Alors évidemment en phase de test, on créé des sites « à la mano » à coup de CTRL-r à la ligne de commande ou d'alias configurés « au petits oignons », mais une fois en production, pas question de prendre le risque de faire les choses manuellement.

Heureusement, [Ansible](http://ansibleworks.com) (ou tout autre outil d'orchestration) nous permet de gagner en temps, en efficacité et en reproductibilité. Cerise sur le gâteau, Ansible propose un module Docker natif permettant de démarrer/arrêter/vérfifer un conteneur avec tous ces paramètres.

Quelques tâches dans un playbook, ou encore mieux un rôle qui gère tout cela avec un fichier de variables, et notre workflow se résume à gérer l'ensemble des sites en ajoutant ou supprimant une ligne dans ce fichier de configuration. Difficile de faire plus simple, mais encore mieux en poussant un peu plus loin, il est possible (je le sais, c'est comme ça qu'on fait) de versionner ce playbook et de permettre à des utilisateurs avancés de proposer des **pull/merge-requests** et de déclencher via un **hook** à la confirmation un script qui va relancer le playbook et mettre en oeuvre les nouvelles directives automatiquement.

![Hannibal A-team](/images/hannibal-a-team.jpg)

## Conclusion

Bon évidemment, tout ceci est *légèrement* édulcoré, je vous fait l'impasse sur le code des scripts et les autres problèmatiques de rotation des fichiers de logs, de supervision et de sauvegardes (il faut bien que je puisse vendre une partie du savoir-faire !) mais voilà, je voulais partager avec vous cette rélfexion et ce travail, car il est vraiment représentatif de ce que j'aime faire dans mon métier. Une demande fonctionnelle en apparence simple, un challenge technique à mettre en oeuvre, pour arriver au final à un workflow à la hauteur de la simplicité de la demande. Et le résultat : des fonctionnels satisfaits, des opérationnels délestés et le plaisir d'un travail correctement réalisé.

*Edit du 08/12/2014* : On m'a demandé si je pouvais écrire une version anglaise de cet article, c'est chose faite dans le billet [How To Isolate Websites From Each Other With Modern Tools](/blog/isolate-website-from-each-other-with-docker).
