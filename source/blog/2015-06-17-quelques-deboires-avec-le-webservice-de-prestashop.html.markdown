---
title: Quelques déboires avec le webservice de Prestashop
date: 2015-06-17 19:15:39 UTC
tags: dev, work
image: forestway
---
Tiens il y avait un moment que je n'avais pas écrit par ici, et une fois n'est pas coutume il s'agit d'un billet pour évacuer. C'est Prestashop qui va en prendre pour son grade. Eh oui, Prestashop. Car même si mon activité principale est d'évoluer avec Ruby on Rails, il arrive à l'occasion que l'on doivent explorer d'autres univers.

READMORE

Dans le cadre du boulot nous devons actuellement interfacer un *backoffice* maison avec un *front-end* Prestashop. Pour cela, nous avons pris le parti d'utiliser au maximum l'API REST de l'outil. Celle-ci est assez bien fichue car elle permet non seulement d'accéder aux principaux éléments de la boutique (produits, commandes, clients, stocks, etc.) mais également de les modifier. Et c'est sur ces mises à jour que s'est déversé la rage que je tente d'évacuer ici…

J'avais des erreurs 500 qui se déclenchaient lors de mes tentatives de mise à jours via le webservice, mais rien d'autre. Les retours des appels HTTP se contentaient de préciser d'aller voir les logs, dans lesquels il n'y avait bien évidemment rien, malgré un paramétrage de PHP/Apache plutôt verbeux.

Il faut savoir que les appels à l'API ne sont pas verbeux par défaut, et il m'a fallu longuement chercher pour comprendre et forcer le système de verbosité du webservice de Prestashop. J'ai clairement perdu les réflexes et les usages des applications PHP, et surtout travaillant avec Rails, on s'habitue vite aux environnements bien isolés et proprement déclarés (merci `RAKE_ENV/RAILS_ENV`).

Par convention les valeurs permettant de contrôler le comportement de Prestashop sont à modifier dans `config/settings.inc.php`. Or pour la verbosité des messages d'erreurs du webservice, il faut forcer dans `config/defines.inc.php` la variable `_PS_MODE_DEV_` à **true** par que dans celui dans lequel on s'attend à ce que ça fonctionne, eh bien, ça ne fonctionne pas. Et je passe sur le fait de devoir fonctionner en mode `DEV` pour avoir les messages d'erreurs de l'API. Eh donc ça veut dire qu'en prod, tu dois tourner en mode dev aussi&nbsp;?!

D'autre part, la consigne dans les documentations du webservice stipulent bien que pour la modification d'une ressource il faut d'abord récupérer le contenu XML via le webservice pour le renvoyer selon le même format avec les modifications. Cela ne fonctionnait pas sur certaines ressources (stock, produits, etc.) mais par manque de verbosité des messages il était délicat de comprendre pourquoi.

Avec des messages plus “clairs” sur la mise à jour du stock comme : “Vous ne pouvez pas mettre à jour le stock disponible quand il dépend du stock”, ce n'est pas forcément beaucoup plus évident, mais en l'occurrence l'idée est ici de modifier non seulement la valeur de quantité mais également la valeur de `depends_on_stock`. Je n'aurais jamais trouvé sans l'affichage de ces messages d'erreurs&nbsp;!

D'autres sont plus mystérieux dans la mesure ou il faut supprimer des lignes pour que la validation de la ressource s'effectue correctement. Ce n'est bien évidemment pas précisé dans la documentation, uniquement sur ces fichus messages d'erreur. Pour la mise à jour d'un produit par exemple&nbsp;: “*parameter `manufacturer_name` not writable. Please remove this attribute of this XML*”, signifie qu'il faut supprimer le paramètre spécifié dans le XML passé (et `quantity` également au passage, message qui n'apparaît qu'à la tentative suivante…). Bref, tout cela va peut-être sans dire pour les habitués du *framework*, mais ça va tout de même mieux en le disant.

Déjà que j'étais pas fan de XML, mais là, devoir le triturer pour pouvoir mettre à jour des données, c'était le pompon. Heureusement qu'il y a des *libs* qui font ça à peu près bien, mais tout ça reste du XML et quelque part, pas franchement naturel à utiliser.

Allez, on va dire que c'était un mauvais moment à passer. Jusqu'à la prochaine mise à jour de l'API… 😬
