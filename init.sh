#!/bin/bash
chown root:docker /var/run/docker.sock
chmod u+srw /var/run/docker.sock
chmod g+rw /var/run/docker.sock 
su - "$USER_NAME"