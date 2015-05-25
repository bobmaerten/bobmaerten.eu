---
title: Mon nouveau travail, bilan après un mois
date: 2015-04-25 15:25:48 +0200
tags: life, work
image: road
---
Pour être tout à fait honnête, j'avais prévu de faire un point une semaine, 15j et 1 mois après mon changement de travail, mais force est de constater que je suis complètement largué sur le timing.

Il faut dire que le changement fût assez rude. Je n'aurais pas cru que de revenir à mes premières amours de développeur serait aussi difficile&nbsp;! Les journées, voire les semaines passent à une vitesse... Bref, ce n'est pas simple, mais ça revient un peu à la fois, et j'apprends plein de choses en plus de découvrir ce nouveau domaine assez méconnu pour moi qu'est le e-commerce.

READMORE

Sans entrer dans les détails, je travaille pour un client qui utilise notre solution _adhoc_ de site de e-commerce, associé à un back-office de gestion commerciale, le tout développé en [Ruby on Rails](http://rubyonrails.org/) depuis quelques années et quelques versions majeures de _RoR_, donc qui a beaucoup évolué depuis. Même sans prendre en compte mon double _noobiisme_ de sysadmin en rémission et du domaine concerné, rentrer dans le concept de l'application n'est pas simple. Mon boss a eu la bonne idée de me coller sur la couverture des tests. C'est un très bon moyen de comprendre ce qu'est censé faire l'appli, tout en me replongeant dans la logique des tests unitaires/fonctionnels. C'est également un excellent moyen d'augmenter la confiance dans les modifications que je peux apporter.

J'apprécie également le flux de travail mis en place. Répartis à quatres coins de mon écran, un éditeur de texte, plusieurs _shells_ au sein d'une session [tmux](http://tmux.sourceforge.net/) faisant tourner la _stack_ de l'application, un [guard](https://github.com/guard/guard) pour valider les tests associés au fichier que je suis en train de modifier, une console pour accéder aux données, l'appli github pour _commit_er et _push_er mes changements. Une fois le travail poussé sur github, les hooks se mettent en marche et déclenchent un test global chez [codeship](https://codeship.com) ainsi qu'une analyse du code chez [codeclimate](https://codeclimate.com) et je suis notifié du résultat dans [slack](https://slack.com).  Ces actions s'exécutent également lorsque qu'on fait un _Pull Request_ et ont la bonne idée de s'insérer directement dans les infos de github, ce qui permet d'avoir une confiance accrue dans la fusion de branche, et ça franchement c'est top.

En ce qui concerne l'organisation du travail, j'avais naturellement des appréhensions vis à vis de ma relation au télétravail, mais finalement elles se sont dissipées assez rapidement. Des _calls_ ([mumble](http://www.mumble.com)/[join.me](https://join.me)) réguliers avec mon boss et les clients (y compris quand je bloque sur un point), un [slack](https://slack.com) pour la communication interne, et un compte-rendu du travail effectué en fin de journée que j'organise un peu comme je l'entends du moment que le travail est fait. Et ça, ça change tout&nbsp;! Aller poster un courrier ou chercher un recommandé à la poste, prendre une 1/2h pour aller chez le coiffeur ou à un rendez-vous médical, effectuer une démarche administrative pendant les horaires de bureaux, tout cela est possible et accessible.

Donc me voilà, presque un mois après cette reconversion assez inatendue, de retour derrière un éditeur de texte pour transformer des specifications en services concrets, utiles et utilisés. Rien que cela est un énorme gain qui, certes me prends du temps et de l'énergie, mais qui m'apporte la satisfaction professionnelle qui me manquait tant. L'effort intellectuel est parfois difficile, tant au niveau du retard à rattraper sur les évolutions des outils, des concepts et parfois aussi de l'algorithmique que je n'ai que peu pratiquée ces dernières années, mais en vaut largement la chandelle.

J'essairai de faire d'autres points prochainement, et je l'espère des billets un peu plus techniques et concrèts quand je serai plus à l'aise. En attendant, je retourne m'imprégner de cette _codebase_ que je ne désespère pas d'appréhender globalement tantôt.
