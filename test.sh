#!/bin/bash

export GIT_FILE="https://raw.githubusercontent.com/trilioData/triliovault-cfg-scripts/master/redhat-director-scripts/nova_userid.sh"

cd $HOME
curl -O $GIT_FILE
chmod 700 nova_userid.sh


