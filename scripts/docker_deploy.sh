#!/bin/bash

DOCKER_DIR=${HOME}/docker/web/www

cd ..
jekyll build

if [ ! -d $DOCKER_DIR ]; then
    mkdir -p ${DOCKER_DIR}
fi

cp -r _site/* ${DOCKER_DIR} 

cd $OLDPWD  

