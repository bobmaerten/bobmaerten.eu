---
title: Optimiser sa configuration Apache/httpd avec des macros
date: 2014-04-29 08:35 CEST
tags: sysadm, debian
---
Depuis quelques temps, nous avons pris l'habitude au bureau d'installer systématiquement toutes nos applications web derrière un *'reverse proxy'*. Cela permet de gagner en souplesse par le fait de déclarer dans notre DNS une adresse générique pour l'application et de pouvoir gérer facilement en aval l'emplacement de l'application sur tel ou tel serveur, gérer la maintenance, ou encore établir une répartition de charge si le besoin s'en fait sentir.

Ce n'est pas de cela que je voulais vous parler (quoique ça pourrait faire l'objet d'un autre billet), mais c'est pour situer un peu le contexte. Je voulais préciser cela car pour ce faire jusqu'alors, en bon sysadmin fainéant je faisais une copie d'un fichier de référence, puis activais le *'vhost'* par un classique `a2ensite nouveau-reverse-proxy` puis rechargeait la configuration apache via `service apache2 reload`.

Worklfow tout à fait classique, mais au combien répétitif (chose qu'on déteste, nous les sysadmins) et potentiellement source d'encore plus de travail si jamais on doit intervenir sur la configuration générale : repasser sur tous les fichiers de déclaration de vhosts. /o\

C'est alors que mon collègue me parle du module Macro de Apache/httpd. Disponible dans la documentation officielle à partir de la version 2.4 du serveur web, il est cependant disponible en tant que module tiers (et dispo dans les dépôts Debian depuis belle lurette) pour les version antérieurs (dont la 2.2 version officielle de la Debian stable courante). Son installation sous wheezy est on ne peut plus simple d'ailleurs :

    sudo apt-get install libapache2-mod-macro
    sudo a2enmod macro

Dès lors, il est possible d'utiliser la déclaration de macro dans la configuration de Apache/httpd.

Une macro se définit avec la déclaration `<Macro></Macro>` et permet donc d'insérer le texte saisi entre les tags à l'aide de la directive `Use`. Voici un exemple très basique dans lequel nous allons remplacer une déclaration courante de configuration :

    <Macro LocationOptions>
    AllowOverride All
    Order deny,allow
    Deny from all
    Allow from 127.0.0.1 ::1
    </Macro>

    <Location /private>
        Use LocationOptions
    <Location>
    <Location /alsoprivate>
        Use LocationOptions
    <Location>

Cet exemple montre qu'il est possible de factoriser des élements de configuration souvent utilisés. Cependant, le plus intéressant est d'utiliser les macros avec des paramètres, ci-dessous je reprends l'exemple précédent afin d'utiliser un paramètre pour le 'Allow from' :

    <Macro LocationOptions $allowfrom>
    AllowOverride All
    Order deny,allow
    Deny from all
    Allow from $allowfrom
    </Macro>

    <Location /localonly>
        Use LocationOptions '127.0.0.1 ::1'
    <Location>
    <Location /networkprivate>
        Use LocationOptions '192.168.1.0/24'
    <Location>

On imagine tout de suite tout ce qu'on peut gagner à utiliser des macro. Toutefois, il faut faire avec les restrictions du module, à savoir qu'il n'est pas possible de déclarer des macros avec un nombre de paramètres variables, ni encore de surcharger le nom d'une macro. On se retrouve doncassez vite avec un nombre conséquent de macro pour gérer les différents cas possible. Voir dans le gist suivant l exemple de [la configuration de nos *'reverse-proxies'*](https://gist.github.com/bobmaerten/11393514).

Voilà donc comment je configure un nouveau reverse proxy désormais : une ligne à ajouter dans le fichier de configuration par défaut de Apache/httpd et un `service apache2 reload`. Les plus futés auront flairé tout de suite ou je voulais en venir dès le début : un playbook Ansible ! Mais ce sera pour un autre billet. ;-)
