---
title: Comportement des touches Home et End du pavé numérique sous OSX
date: 2015-06-26 15:23:10 UTC
tags: dev, work, osx
image: mba1
---
Le truc qui me rendait fous depuis mon passage sous OSX c'était le comportement des touches `Home` et `End` du pavé numérique. En tant que développeur, dans mon éditeur de texte, le comportement est d'aller respectivement en début et en fin de ligne. Or dans le navigateur et en particulier dans les *textarea* de GitHub, le comportement des touches en question est rattaché au *viewport* du navigateur. Si bien que lorsque naturellement j'appuie sur `Home` pour revenir en début de ligne, mon navigateur me renvoyait en début de page.

READMORE

![Rage](http://media.giphy.com/media/wvQIqJyNBOCjK/giphy.gif)

Mais en fouillant un peu, ce comportement ne semble pas naturel pour pas de gens, qui pour le coup installent un outil appelé [Karabiner](https://pqrs.org/osx/karabiner/), permettant de modifier le comportement du clavier en général.

Cependant le comportement modifié rentrait en conflit avec ma configuration sous iTerm2, ce n'était donc pas mieux.

Au final, c'est dans [un billet](http://www.evansweb.info/2005/03/24/mac-os-x-and-home-end-keys/) du [blog de Jon Evans](http://www.evansweb.info/) datant de plus de 10 que je trouve une solution simple, rapide, parfaitement adaptée et toujours valide&nbsp;! Le site ne semble plus alimenté depuis quelques années mais est toujours dispo, chapeau bas [@burmasauce](https://twitter.com/burmasauce).

Toujours est-il que la solution est de créer un fichier `~/Library/KeyBindings/DefaultKeyBinding.dict` contenant&nbsp;:

```
{
        /* Remap Home / End to be correct :-) */
        "\UF729"  = "moveToBeginningOfLine:";                   /* Home         */
        "\UF72B"  = "moveToEndOfLine:";                         /* End          */
        "$\UF729" = "moveToBeginningOfLineAndModifySelection:"; /* Shift + Home */
        "$\UF72B" = "moveToEndOfLineAndModifySelection:";       /* Shift + End  */
}
```

et de redémarrer une nouvelle session afin de retrouver un niveau de santé mentale viable.
