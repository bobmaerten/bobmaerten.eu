---
title: Retour (virtuel) des commentaires
date: 2015-05-10 18:09:02 +0200
tags: blog, ruby, sysadm
image: record
---
Cela faisait un petit moment que je voulais réintéger les commentaires sur ce blog. Étant hébergé sur GitHub Pages et donc purement statique, la solution est forcément externe. Je ne souhaitais pas pour autant utiliser le service évident pour ce genre de chose (disqus).


Non pas que j'eusse de quelconques griefs envers ce service mais dans la continuité de proposer du contenu relativement maitrisé (un site statique), je souhaiter également maitriser cette partie commentaires. J'avais fait quelques essais il y quelques mois avec une appli Rails appelée [Juvia](https://github.com/phusion/juvia) produite par [Phusion](http://www.phusion.nl) qui manifestment n'est plus maintenue, mais qui a poutant été mis à jour entre temps en 4.2.

READMORE

Je me suis dit que ce serait une bonne occasion de tester la mise en place de cette application dans un container Docker. De plus cela me permettrait d'associer la veille technologique nécessaire à cette mise en place avec mes nouvelles activités professionnelles (Rails + Sysadm + Hébergement).

## Construction de l'image

Les gens qui gravitent autour de docker ne chôment pas. Des images officielles pour faire tourner des scripts [ruby](https://registry.hub.docker.com/_/ruby/) et même des applications [rails](https://registry.hub.docker.com/_/rails/) sont disponibles. En regardant le Dockerfile de l'image rails, on remarque qu'elle surcharge celle de ruby2.2, qui elle même s'appuie sur une succession d'images dérivées de debian:jessie. Ce qui signifie qu'il est toujours possible d'ajouter de nouveaux packages en cas d'usage d'une gem qui nécessite une compilation particulière.

C'est ce qui s'est produit lors de l'essai de contruction de l'image de l'application de gestion des commentaires dont il est question ici. Le `Dockerfile` est très simple comme le recommande le README de l'image, mais la construction échoue&nbsp;:

    $ cat Dockerfile
    FROM rails:onbuild

    $ docker build -t juvia_image .
    Sending build context to Docker daemon 160.5 MB
    Sending build context to Docker daemon
    Step 0 : FROM rails:onbuild
    # Executing 4 build triggers
    Trigger 0, COPY Gemfile /usr/src/app/
    Step 0 : COPY Gemfile /usr/src/app/
     ---> Using cache
    Trigger 1, COPY Gemfile.lock /usr/src/app/
    Step 0 : COPY Gemfile.lock /usr/src/app/
     ---> Using cache
    Trigger 2, RUN bundle install
    Step 0 : RUN bundle install
     ---> Running in f004b22629a9
    Don't run Bundler as root. Bundler can ask for sudo if it is needed, and
    installing your bundle as root will break this application for all non-root
    users on this machine.
    Fetching gem metadata from https://rubygems.org/.........
    Fetching version metadata from https://rubygems.org/...
    Fetching dependency metadata from https://rubygems.org/..
    Using rake 10.4.2
    Installing i18n 0.7.0
    Installing json 1.8.2
    ...
    Installing capybara-screenshot 1.0.9

    Gem::Ext::BuildError: ERROR: Failed to build gem native extension.

        /usr/local/bin/ruby -r ./siteconf20150510-5-1wvt9so.rb extconf.rb
    Command 'qmake -spec linux-g++ ' not available

    Makefile not found

    Gem files will remain installed in /usr/local/bundle/gems/capybara-webkit-1.3.1 for inspection.
    Results logged to /usr/local/bundle/extensions/x86_64-linux/2.2.0-static/capybara-webkit-1.3.1/gem_make.out
    An error occurred while installing capybara-webkit (1.3.1), and Bundler cannot
    continue.
    Make sure that `gem install capybara-webkit -v '1.3.1'` succeeds before
    bundling.
    INFO[0154] The command [/bin/sh -c bundle install] returned a non-zero code: 5

Comme on le constate, il manque l'outil `qmake` pour que capybara-webkit puisse se compiler. Il faudrait ajouter l'installation du paquet en question dans le Dockerfile. Mais cette gem est dans les groupes :development et :test, qui ne sont pas utiles pour le fonctionnement en production. Pour éviter leur installation, il faudrait pouvoir préciser `--without test development` à la commande bundle. Dans tous les cas, il faut réécrire le Dockerfile et en s'inspirant de celui de l'image rails, on arrive à quelque chose comme ça&nbsp;:

    $ cat Dockerfile
    FROM ruby:2.2.2
    RUN apt-get update \
            && apt-get install sqlite3 nodejs --no-install-recommends -y qt5-default libqt5webkit5-dev \
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/*

    RUN bundle config --global frozen 1

    ENV RAILS_ENV production

    RUN mkdir -p /usr/src/app
    WORKDIR /usr/src/app

    COPY Gemfile /usr/src/app/Gemfile
    COPY Gemfile.lock /usr/src/app/Gemfile.lock
    RUN bundle install --without='development test postgres mysql' --path=help

    COPY . /usr/src/app

    RUN bundle exec rake db:create \
     && bundle exec rake db:schema:load \
     && bundle exec rake assets:precompile RAILS_GROUPS=assets

    EXPOSE 3000
    CMD ['rails', 'server', '-b', '0.0.0.0']

Je passe les petites corrections pour avoir les bonnes valeurs sur les fichiers sensibles de Rails (SECREY\_KEY\_BASE en production, des valeurs correctes dans database.yml, etc.). Au final l'image se construit et on peut valider le fonctionnement.

    $ docker run --detach --name juvia_app -e SECRET_KEY_BASE='abcde' juvia_image
    3489371959f964b3b7d85e2bbda19d294a2c841b0a987261d68794c21bb4d59b

    $ docker logs juvia_app
    [2015-05-10 17:18:12] INFO  WEBrick 1.3.1
    [2015-05-10 17:18:12] INFO  ruby 2.2.2 (2015-04-13) [x86_64-linux]
    [2015-05-10 17:18:12] INFO  WEBrick::HTTPServer#start: pid=1 port=3000

    $ curl -I $(boot2docker ip):3000
    HTTP/1.1 302 Found
    X-Frame-Options: SAMEORIGIN
    X-Xss-Protection: 1; mode=block
    X-Content-Type-Options: nosniff
    Location: http://192.168.59.103:3000/admin/dashboard/new_admin
    Content-Type: text/html; charset=utf-8
    Cache-Control: no-cache
    X-Request-Id: ba8299a1-d93d-4a14-93c1-d573e2c31178
    X-Runtime: 0.002761
    Server: WEBrick/1.3.1 (Ruby/2.2.2/2015-04-13)
    Date: Sun, 10 May 2015 17:21:14 GMT
    Content-Length: 0
    Connection: Keep-Alive

Oui, vous constatez l'utilisation de [boot2docker](http://boot2docker.io). Depuis mon passage sur OSX, mon portable sous linux a rendu l'âme (carte mère grillé), donc je me suis rabattu sur un environnement compatible, malgré [quelques surprises](https://twitter.com/bobmaerten/status/597347960058454016). Au fond c'est assez transparent, une fois la [configuration correctement installée](http://blog.blackfire.io/how-we-use-docker.html).

## Mise en place du conteneur

Voila, nous avons une image plus ou moins fonctionelle, reste plus qu'à la déployer et assurer la persistance des données.
Pour le déploiement, j'ai à ma disposition une petite instance d'un serveur Ubuntu chez [DigitalOcean](https://www.digitalocean.com/?refcode=dd83518f68db) sur lequel un _daemon_ docker assure le travail, ainsi qu'un [conteneur particulier](https://github.com/jwilder/nginx-proxy) qui “écoute” les événements du service et qui met en place un reverse-proxy sur le nom du VIRTUAL_HOST passé en variable d'environnement du conteneur.

Pour la persitance des données on peut soit monter un dossier de l'hôte lors du démarrage du conteneur avec l'option `-v` ou alors créer des _data-volumes_ et utiliser l'option `--volumes-from`. Pour des questions de simplicité et puisque je maitrise mon contexte j'utilise la première solution, mais docker préconise plutôt l'usage de conteneur de données pour des raisons de portabilité.

Voici donc la ligne de commande permettant de lancer le conteneur&nbsp;:

    docker run --name comments \
           -e VIRTUAL_HOST='comments.bobmaerten.eu' \
           -e SECRET_KEY_BASE='$(rake secret)' \
           -v /root/containers/comments/db:/usr/src/app/db \
           -v /root/containers/comments/log:/usr/src/app/log \
           --restart=always \
           --detach juvia_app

## Résultats

Si tout vas bien, lors du déploiement de cette version du site avec ce billet, le layout devrait afficher la liste des commentaires des billets ainsi qu'un formulaire pour en laisser. Ce sera l'occasion de tester l'application en réel et de voir les améliorations à apporter même si j'ai déjà quelques idées (localisation, ajout de notifications, etc.).
