---
title: Tester wallabag dans Docker
date: 2014-02-14 10:30 CET
tags: sysadm
image: city
---
TL;DR: ```sudo docker pull bobmaerten/docker-wallabag && sudo docker run -p 8080:80 -d bobmaerten/docker-wallabag``` et hop, direct dans ton *browser* [http://localhost:8080](http://localhost:8080)

Évidemment, cela fonctionne mieux si vous avez déjà installé Docker. Sinon, les explications sont assez claires sur la [documentation exhaustive](http://docs.docker.io/en/latest/). Il y a même depuis la version 0.8 un support officiel pour MacOs.

READMORE

![Docker image](https://www.docker.io/static/img/homepage-docker-logo.png)

Cela faisait quelques temps que je voulais m'intéresser à [Docker](http://docker.io) et à la construction d'image. Dans le même temps, il y avait un [ticket ouvert](https://github.com/wallabag/wallabag/issues/220) sur le projet [wallabag](http://wallabag.org) pour disposer d'une image Docker afin de tester la solution. C'était donc l'occasion de s'y mettre et de contribuer à ma manière au projet.

Le principe de docker réside en la superposition de différentes couches systèmes. En fusionnant ces différentes couches (la méthode diffère en fonction du *filesystem* utilisé), on obtient alors un système complet et potentiellement issu de plusieurs sources aggrégées. Cette souplesse, liée à l'isolation du système fournit par LXC (LinuX Containers) permet de profiter de nombreuses choses regroupeés dans [l'index docker](http://index.docker.io), un site communautaire qui permet de partager des images toutes prêtes que l'on peut directement utiliser telles quelles, ou mieux, surcharger pour un autre usage.

La création d'une image docker repose sur l'équivalent d'un script qui sera exécuté. Dans ce fichier `Dockerfile`, on trouve un certain nombre de directive permettant de scripter une installation. Pour le sujet qui m'intéresse, j'avais besoin de faire tourner un script PHP derriere un serveur web. Je suis parti d'une image assez bas niveau de ubuntu saucy fournie par docker, mais j'aurais très bien pu parcourir l'index et trouver une image correspondant à mon besoin pour l'amender. Les directives sont au final assez explicites, `FROM` pour spécifier un point de départ, `RUN` pour exécuter des commandes, `ADD` pour déposer des fichiers stockés en dehors du container, etc.

Voici le Dockerfile qui permet de déployer, configurer et lancer wallabag avec nginx et php-fpm :

```
# Specify Ubuntu Saucy as base image
FROM ubuntu:saucy

MAINTAINER Bob Maerten <bob.maerten@gmail.com>

# Install latest nginx
RUN apt-get update
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install -y dialog net-tools lynx vim wget curl postfix
RUN apt-get install -y python-software-properties software-properties-common
RUN add-apt-repository ppa:nginx/stable
RUN apt-get update

# Install git nginx php-fpm and wallabag prereqs
RUN apt-get install -y nginx git php5-cli php5-common php5-sqlite php5-curl php5-fpm php5-json php5-tidy

# Configure php-fpm
RUN echo 'cgi.fix_pathinfo = 0;' >> /etc/php5/fpm/php.ini
RUN echo 'daemon off;' >> /etc/nginx/nginx.conf

# Installing git to fetch latest wallabag
RUN mkdir /var/www/wallabag || echo 'Sources directory already present'

# Clone wallabag code repository
RUN git clone https://github.com/wallabag/wallabag.git /var/www/wallabag

# Checkout latest tmux version
RUN cd /var/www/wallabag && git checkout tags/1.5.0

# Install wallabag
RUN cd /var/www/wallabag; curl -sS https://getcomposer.org/installer | php; php composer.phar install
RUN cp /var/www/wallabag/inc/poche/config.inc.php.new /var/www/wallabag/inc/poche/config.inc.php
RUN sed -i 's/('SALT', '')/('SALT', 'absolutlynotsafesaltvalue')/' /var/www/wallabag/inc/poche/config.inc.php
RUN cp /var/www/wallabag/install/poche.sqlite /var/www/wallabag/db/
RUN chown -R www-data:www-data /var/www/wallabag
RUN chmod 755 -R /var/www/wallabag
RUN rm -rf /var/www/wallabag/install

# Configure nginx to serve wallabag app
ADD ./nginx-wallabag /etc/nginx/sites-available/default

EXPOSE 80

CMD service php5-fpm start && nginx
```

Sommes toutes, il s'agit ni plus ni moins que de scripter l'installation telle qu'on la suivrait pour installer le logiciel.

De la on peut démarrer le service (grâce aux directives `CMD` et `EXPOSE`) et profiter d'un environnement wallabag fraichement installé pour tester, ou pour participer à son développement.

![wallabag image](http://www.wallabag.org/wp-content/uploads/2014/02/logo-typo-horizontal-no-bg-lg.png)

*Happy hacking!*
