README
=======

Michele Welponer, wp install automation bash script 
Copyright (C) 2016  Michele Welponer

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

---

#Prerequisites

Environment
---------
- Ubuntu 14.04 x64
- last version of WordPress


Assumptions
------

We assume we want to automate the installation process running a script within the remote webserver i.e., scp the script onto the remote server, connect to the remote server via ssh and run the script.


#Installation


Prepare the script
---------

Download, unzip and then scp the script files onto the remote server (let's assume the remote server is 'example.net' the remote sudoer user 'mike').

```
$ scp ~/kata.sh mike@example.net:/home/mike/
$ scp ~/mysql_secure_installation mike@example.net:/home/mike/
$ ssh mike@example.net
$ sh kata.sh

```

The script
-------

The script will verify the installation of few Wordpress dependencies: php, apache, mysql and wp-cli, a tool to automate/manage the wp installation from the command
prompt.
It will then proceed with the installation of Wordpress and with the installation of few plugins to improve security and speed. Mysql will then be secured removing test dbs root remote access, change of the root password. File permissions on wp folders and files will be tuned based on recommendations from http://codex.wordpress.org/Hardening_WordPress#File_permissions. Finally the apache virtualhost will be created.


#Further enhancements
 
Security/speed Issues and optimizations
---------

we can further speed up the response time using one or few of the following techniques:

- apache cache (e.g., file cache / mem cache)
- mysql config tuning
- php config tuning
- wp caching (e.g., wp-super-cache )
- app multi istances + load balancer (see apache mod_proxy_balancer)

If we use a load balancer we can have a single db for example on a dedicated server, private IP with the istances pointing to it. We then need to deal with managing a multi instance queue.
As another option we can have multi instances with dedicated dbs. We then need to deal with databases synchronization. We can have different solutions, multiple virtual machines, clustering, etc.. things need to be properly evaluated according to the specific case.

Security can be further improved keeping instances and db/dbs on private IPs (disallow remote db access) while leaving apache as frontend with public IPs



Deployment automations
----

We can automate the process of deploying of new versions of wp using capistrano. The configuration is trivial. Capistrano permits to keep track of all the site versions and to fast roll back to a previous version if anything goes wrong after a new deployment.

See the link https://github.com/Mixd/wp-deploy

Together with Capistrano it's nice to use git. Git repo can be on the development machine or a different server.
So we develop in our local machine/local git copy, we commit, pull rebase if we are not coding alone and push our work onto the git repo. Then from our local machine we can 'cap production deploy' i.e. tell capistrano to deploy the new version onto the production server.
