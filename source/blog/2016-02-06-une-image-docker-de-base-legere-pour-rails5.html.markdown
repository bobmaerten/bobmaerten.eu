---
title: Une image docker de base légère pour rails5
date: 2016-02-06 13:38:57 UTC
tags: ruby, sysadm, dev, linux
image: city
---
Une des bonnes pratiques pour la construction d'images docker est de minimiser leur taille et en particulier d'avoir le moins de "couche" possible. D'ailleurs, il y a quelques jours, Docker a [annoncé la migration de ses images officielles](https://www.brianchristner.io/docker-is-moving-to-alpine-linux/) de la distribution ubuntu à alpine-linux pour réduire au maximum le volume de données utiles. Parmi ces images, c'est [`ruby:alpine`](https://hub.docker.com/_/ruby/) qui m'intéresse particulièrement, et c'était l'occasion rêvée d'expérimenter la création d'une image d'une application de base pour rails 5.0.0-beta2.

READMORE

Il faut dire que l'image officielle de rails n'est pas des plus légère :

    $ docker images | grep rails
    rails   latest   efa7b55d5f4d   9 days ago   826.4 MB

L'idée est donc de partir de l'image officielle ruby-alpine qui a également l'avantage de fournir la version 2.3 de ruby.

```dockerfile
FROM ruby:2.3-alpine
MAINTAINER bob.maerten@gmail.com

COPY Gemfile Gemfile.lock /app/
WORKDIR /app

RUN \
    # Install ruby packages needed for runtime
    apk add --no-cache \
      nodejs \
      postgresql-client \
      libgcrypt \
      libxml2 \
      libxslt \
      tzdata \
    # Install ruby packages needed for native gems building
 && apk add --no-cache --virtual build-dependencies \
      build-base \
      postgresql-dev \
      libc-dev \
      curl-dev \
      qt-dev \
      libxml2-dev \
      libxslt-dev \
      linux-headers \
    # Configure bundler to use system libxml libraries at compile time
 && bundle config build.nokogiri --use-system-libraries \
    # Install default rails5 gems
 && bundle install --without development test \
    # Remove native gem building dependencies to ease weight on docker image
 && apk del build-dependencies \
    # Also remove cache to gain even more
 && rm -rf /var/cache/apk/*

ADD . /app
RUN chown -R nobody:nogroup /app
USER nobody
ENV RAILS_ENV production

CMD  ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

Reste plus qu'à construire cette image :

    $ docker build -t rails5-alpine-base .

Pour constater une jolie économie :

    $ docker images | grep rails
    rails5-alpine-base  latest  fab4676a469a  2 minutes ago  216.1 MB
    rails               latest  efa7b55d5f4d  9 days ago     826.4 MB

Et pourtant fonctionnelle, pour peu qu'on lui associe une base postgres, comme avec ce _compose file_ :

    postgres:
      image: postgres:9.5
      environment:
        POSTGRES_USER: railsapp
        POSTGRES_PASSWORD: railsapp

    web:
      image: bobmaerten:rails5-alpine-base
      links:
        - postgres
      ports:
        - '3000:3000'
      environment:
        RAILS_ENV: development
        DATABASE_URL: "postgresql://railsapp:railsapp@postgres/railsapp?pool=5"

Et de lancer la _stack_ avec la commande :

    $ docker-compose up -d

Et voila notre application rails de base disponible !

![Ruby on Rails 5](../2016-02-06-une-image-docker-de-base-legere-pour-rails5/Ruby_on_Rails.png)

Bon, évidemment il ne s'agit là que de l'application nue, et il est fort probable que pour chaque nouvelle gem ajoutée à notre `Gemfile` une _lib_ manquera à l'appel et il faudra spécialiser l'image en reprenant le _process_.

Pour ce faire, il est donc possible de créer un autre `Dockerfile` qui hérite de notre image de base et reprendre l'ajout de _packages_ nécessaires à la compilation des gems natives, un peu comme cet exemple :

    FROM bobmaerten:rails5-alpine-base
    MAINTAINER bob.maerten@gmail.com

    # switch to root to install packages
    USER root
    RUN set -x \
      && apk add --no-cache \
            #  <insert packages needed for runtime here> \
            bash \
     && apk add --no-cache --virtual .gems-builddeps \
            # <insert packages needed for native gem buiding here> \
            build-base \
            postgresql-dev \
            libc-dev \
            curl-dev \
            qt-dev \
            libxml2-dev \
            libxslt-dev \
            linux-headers \
       && rm -rf /var/cache/apk/*

    COPY Gemfile /app/
    COPY Gemfile.lock /app/
    RUN bundle install

    # Remove gems building packages deps
    RUN apk del .gems-builddeps

    # switch back to default user to run app
    USER nobody
    COPY . /app

    CMD  ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

Mais cela me fait poser la question de l'intérêt de sous-classer plutôt que de profiter du système de cache de docker et de reprendre la création de l'image quasiment à sa base (alpine:3.3).

Je ne pense pas avoir assez de recul ni sur cette problématique ni sur l'usage au quotidien de rails avec docker pour répondre à cette question. Mais si vous avez un avis la dessus (en attendant un retour prochain des commentaires), n'hésitez pas à ma le partager via les réseaux sociaux, ou par mail si vous préférez plus d''intimité, après un passage sur [keybase.io](https://keybase.io/bobmaerten).
