---
title: Installation d'une stack gitlab avec Docker
date: 2015-01-08
tags: sysadm, web, git, docker
image: road
---
Pour les besoins de mon statut d'autoentrepreneur, j'avais besoin de pouvoir mettre à disposition de ma clientèle un accès aux sources de mes productions. La solution évidente est bien entendu d'utiliser [github](https://github.com) comme tout le monde, mais mon esprit un peu rebelle, opensource et aventurier m'a poussé à tenter d'utiliser gitlab à la place.

Je ne partais pas de nulle part cela dit, j'avais déjà mis en place une stack gitlab sur un serveur dédié, mais cette fois je voulais le faire fonctionner sur ma petite instance [DigitalOcean](https://digitalocean.com) en tant que conteneur docker.

## Mise en place des pré-requis

Les premières choses à mettre en oeuvre est de configurer le noyau pour accepter les limites mémoire de conteneur et de paramétrer l'utilisation du swap. Modifions pour cela le fichier `/etc/default/grub` avec cette ligne :
{% highlight bash %}
GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"
{% endhighlight %}
Sans oublier de recharger la configuration : `sudo update-grub`

Ensuite il faut éventuellement [créer un fichier de swap suffisant](https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04), dans la mesure où l'instance de base de DigitalOcean est fournie avec 512M de ram et 0 swap... ;-)

L'installation du docker est également nécessaire, mon système tournant sous ubuntu 14.04, j'ai suivi la [recommandation officielle](https://docs.docker.com/installation/ubuntulinux/).

## Dockerisons

Le truc cool, c'est que le boulot est quasiment déjà fait dans la mesure où un fichier `Dockerfile` est présent dans le [dépôt du code de gitlab](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/docker/Dockerfile).

La création de l'image Docker utilise les packets omnibus mis à disposition pour debian. Comme l'indique la documentation, il suffit de taper la commande suivante depuis la racine du dépôt gitlab :
{% highlight bash %}
docker build -t gitlab_image docker/
{% endhighlight %}
Une image de conteneur devrait être disponible au terme de cette commande. Il convient désormais de configurer l'environnement de l'hôte pour utiliser cette image. Pour cela, les bonnes pratiques préconisent d'utiliser un conteneur de données qu'on pourra attacher au conteneur exécutant la stack gitlab.
{% highlight bash %}
docker run --name gitlab_data gitlab_image /bin/true
{% endhighlight %}
Cela va créer un conteneur de données préconfigurées avec des répertoires partagés suivants&nbsp;:

  * `/var/opt/gitlab` pour les donnéees de l'application
  * `/var/log/gitlab` pour les logs
  * `/etc/gitlab` pour la configuration

La configuration du conteneur se fait essentiellement dans le fichier `/etc/gitlab/gitlab.rb` du conteneur de données. C'est un fichier de définitions de tableaux associatifs (ruby) qui surchargent la configuration par défaut (gitlab.yml) via des recettes [Chef](https://www.chef.io/chef/) exécutées au démarrage ou au redémarrage du controlleur du conteneur.

Pour éditer ce fichier dans le conteneur de données, utiliser la commande suivante :
{% highlight bash %}
docker run -ti -e TERM=linux --rm --volumes-from gitlab_data ubuntu vi /etc/gitlab/gitlab.rb
{% endhighlight %}
On utilise ici un conteneur de base `ubuntu` pour éditer avec `vi` le fichier de configuration `gitlab.rb` au sein du conteneur de données `gitlab_data`.

## Lancement du conteneur

Il ne reste qu'à lancer le conteneur en précisant les ports sur lesquels on souhaite qu'il réponde :
{% highlight bash %}
docker run --name gitlab_app --publish 8080:80 --publish 2222:22 --volumes-from gitlab_data --detach gitlab_image
{% endhighlight %}
### Modification de la configuration à chaud

On peut très bien éditer le fichier `gitlab.rb` et demander à recharger la configuration. Utiliser pour ceci la commande `exec` de docker :
{% highlight bash %}
docker exec -t gitlab_app gitlab-ctl reconfigure
{% endhighlight %}
Le script va analyser le fichier de configuration et éventuellement relancer les recettes Chef nécessaire avant de relancer les services.

## Enjoy!

![Gitlab installé](https://dl.dropboxusercontent.com/u/45117371/x/gitlab_docker.png)
