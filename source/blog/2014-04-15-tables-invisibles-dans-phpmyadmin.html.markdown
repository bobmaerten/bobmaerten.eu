---
title: Tables invisibles dans PHPMyAdmin
date: 2014-04-15 16:45 CEST
tags: sysadm, dev
image: sliders
---
Hé, cela faisait un bail que je n'avais pas posté quelque chose ici, alors pour y remédier, un petit retour sur un cas bizarre qui m'est arrivé cet après-midi.

Je souhaitais migrer une base mysql sur un nouveau serveur, donc exportée via un `mysqldump --opt` classique. Or, pour je ne sais quelle raison, les tables n'apparaissaient pas dans l'interface de PHPMyAdmin, alors que visible via la ligne de commande ou utilisable par l'application associée.

Après quelques recherches (merci [stackoverflow](http://stackoverflow.com/questions/5539589/imported-tables-are-not-showing-up-in-phpmyadmin/9905956#9905956) !) il est apparu qu'il s'agissait d'un problème de vues extraites dans le dump sql avec un `DEFINER` inexistant sur le nouveau serveur :

```sql
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`plop`@`old-db-server` SQL SECURITY DEFINER */
/*!50001 VIEW `stats ressources` AS select `logs`.`user_fullname` AS `user_fullname`,`logs`.`foreign_key` AS `foreign_key`,`logs`.`linked_element_name` AS `linked_element_name`,`logs`.`elapsed_time` AS `elapsed_time` from `logs` where (`logs`.`elapsed_time` <> 'NULL') */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
```

Dans cet example, l'utilisateur `plop@old-db-server` n'étant pas défini sur mon nouveau serveur, les tables était invisibles dans PHPMyAdmin, et plus grave encore faisait même planter la sauvegarde de notre agent MySQL de Time Navigator avec un message obscur du genre « Impossible de sauvegarder, présence d'un objet flou. ». Voilà, débrouille-toi avec ça !

Moralité, faites attention avec les vues et surtout comment et avec quel utilisateur vous les définissez. Mon conseil : `root@localhost` ;-)
