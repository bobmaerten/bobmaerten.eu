---
title: 'Dépendances de paquets Debian/Ubuntu pour certain(e)s gems ruby'
date: 2013-09-05
comments: true
tags: debian, ubuntu, ruby
---
Lorsqu'il vous arrive d'installer certain(e)s gems à l'aide de la commande `gem install` ou à l'aide de `bundle`, il arrive que l'installation échoue avec un message obscur du style :

`Gem::Installer::ExtensionBuildError: ERROR: Failed to build gem native extension.`

Cela est dû à l'absence de certaines librairies nécessaires à la compilation partielle des fichiers [du|de la] gem. Ces librairies sont habituellement packagées sous Debian|Ubuntu dans des paquets labellés \*-dev.

Ci-dessous, une liste non-exhaustive de dépendances pour installer certain(e)s gems courants :

```
- nokogiri: libxml2-dev libxslt1-dev
- pg: postgresql libpq-dev
- rails: nodejs (Ubuntu seulement !)
- mysql: mysql-server mysql-client libmysqlclient-dev
- sqlite3: sqlite3 libsqlite3-dev
- capybara-webkit: libqt4-dev g++
- curb: libcurl4-gnutls-dev
- rmagick: graphicsmagick-libmagick-dev-compat libmagickwand-dev
```
