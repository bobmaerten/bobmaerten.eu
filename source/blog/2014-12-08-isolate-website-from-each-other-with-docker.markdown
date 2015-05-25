---
title: How To Isolate Websites From Each Other With Modern Tools
date: 2014-12-08
tags: sysadm, web
image: forestway
---

I was recently charged to upgrade an old websites hosting architecture for non-technical people. The idea was to easyly deliver new demands, and to be able to fast create and archive websites, in the most automatic way.

## Context

The old system was based on [suExec](http://httpd.apache/org/docs/2.2/suexec.html) which provides a system to run PHP processes with the user owning the file invoked. As suExec is only available as a module/patch, I'd rather stay on standard OS-released packages like Debian stable, which means using PHP-fpm.

Access to website files was handled by a SFTP server. To preserve isofunctionnality and user habbits, we deciced to leave this feature as is.

A dedicated database was handling valid users informations in order to configure `nsswitch`. Specific UID/GID associated with user files was enabling access through an authenticated SFTP client. Daily administration was handled by a few scripts.

## Searching for a solution

First tests with PHP-fpm using different pools each affected to specific websites were encouraging, and sufficent to reproduce existing behaviour, while access to files was handled by a chrooted SSH environment. Though, I was willing to get out my comfort zone for this project, and try to learn new things.

It was the perfect time to get [Docker](https://docker.com) and [Ansible](http://ansiblework.com) out, my favorite new toys.

## Docker to the rescue

The [Docker Hub](http://registry.hub.docker.com/) delivers a bunch of official container images like [PHP or PHP with Apache](https://registry.hub.docker.com/_/php/), quickly resolving our website use case. It's only a matter of mounting a [volume](http://docs.docker.com/reference/builder/#volume) on creation for the website to be up and running.

For routing all these websites, I found an [article written by Jason Wilder](http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker) and an related [docker image](https://github.com/jwilder/nginx-proxy) which listens to the docker socket for new containers. If a specific environment variable is passed, the routing containers will update his nginx configuration and reload itself in order to reverse-proxify access to the new container by his DNS name. Neat!

This docker image is so nifty, it runs permanently on my laptop with a small script to update my local `/etc/hosts` file for newly created web containers be accessible directly by their names in my browser.

The last think to handle is how to update website systems, and eventually how to move entire websites and logic (update access). One way is to include the SFTP server in the containers but it would mean to modify the official image. Another way would be to have multiple containers and give them specific roles:

* 1 volume container for user files
* 1 php/apache container for website appliance
* 1 sftp container linked to files volume for user updates

We could also add another db container linked to the php instances, but our case, we choose to have a dedicated db server.

## Let's get ready to rumble!

Technical problems came up early though. SFTP protocol relies on SSH/SSL implementation, which has a very simple network way of connecting: just after DNS resolution, it connects on the returned IP. It means it's impossible to route with the server name in front of the docker host, and so we have to expose as many port as we have containers.

Sure it's portable, but in my case, I had to rely on our netadmin team to correctly open a moving range of port to my docker host(s). And my non-technical users would have to specify a port to their sftp connection. All of this was not really acceptable.

A compromise was found by launching a SFTP container for all websites, onto which is mounted the entire websites folder. Access from users is handled by a system equivalent to the reverse-proxy one: the container listens to the docker events though the socket, and activate/disable a user for the corresponding website php/apche container.

## Technical Architecture

                                   +------ php:apache_1 <-------+
     :80 ====> nginx-proxy --:80---+------ ...                  |
                    ^              +------ php:apache_n <-+     |
                    |                                     |     |
     :22 ====> heberg-sftp <----+                         |     |
                ^   |           |                         |     |
                |   |           |                         |     |
                +-+-+           |                         |     |
                  |          /sites/                      |     |
        unix:docker.sock      /site_1 --------------------+-----+
                              ...         volume mount    |
                              /site_n --------------------+

The docker socket is mounted inside the 2 front containers in order to let them "react" to the creation/deletion of containers with theses characteristics:

- having an environment variable named VIRTUAL_HOST
- which image is 'php:apache'

Like the Jason Wilder's article says, the reverse-proxy container adds a `upstream` and a `server` block to the nginx configuration and then reloads. The SFTP server do the following actions:

- add or delete a user account inside his container, set to the name of the website. The password is parsed from a file within the website folder (or generated if absent) and displayed in the container logs.
- redirect logs from the php containers in `access.log` and `erros.log` files in the website logs folder.

So when a backend container is started from the `php:apache` image, the `VIRTUAL_HOST` environment variable, and a mouted folder with website content, the 2 front containers activate access and routing automatically.

## Automation with Ansible

During testing of this solution, starting by hand sites and containers is easy and fast with commandline recall (Ctrl-r), or with bash-aliases or even using [Fig](http://fig.sh), but no way to do it this way in production. It has to rely on something stronger.

With tools like [Ansible](http://ansibleworks.com) (or any other orchestration tool), efficacity and reproducibility is easy. It reduce time spent deploying and errors. Courtesy of Ansible team, a native docker module is available for starting/stopping/checking containers.

A few tasks in a playbook, or even better, a role handling of the stuff with a well configured variable file and our workflow is narrowing to setting or unsetting websites in a yaml file. We can even put this file in a github/gitlab repository and attach a webhook, so when a new file is commited/pushed (via a pull-resquest), the playbook gets triggered again and the new websites are started/stopped automagicaly.

![Hannibal A-team](/images/hannibal-a-team.jpg)

## Conclusion

Obviously, all of this is slighty trimmed. All the little scripts code, log files rotation, monitoring, backups, were not taken care of in this article (Eh, I have to keep some things to be paid for ^\_^), but I was eager to share this little system I made up, which represents what I like most in my job: a simple problem on first sight, a technical challenge to build up a solution, and in the end, a really simple workflow to handle on a daily basis.

Feel free to comment or ask for details.

This is the english version of a french article named [Isoler des sites web entre eux](/blog/isoler-des-sites-web-entre-eux/).
