#!/bin/bash
# Lance SSH et Apache en avant-plan pour le conteneur cible.
set -e

service ssh start
apachectl -D FOREGROUND
