#! /bin/sh

hugo
rsync -avz docs/ chewie@mesburnes.fr:/var/www/kevinsztern.fr/content/
