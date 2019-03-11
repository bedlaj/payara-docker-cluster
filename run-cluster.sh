#!/bin/bash - 
#===============================================================================
#
#          FILE: run-cluster.sh
# 
#         USAGE: ./run-cluster.sh 
# 
#   DESCRIPTION: A script to launch Payara docker containers and configure them
#                in a cluster
# 
#        AUTHOR: Mike Croft
#  ORGANIZATION: Payara
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#DOCKER="docker -H localhost" #for TCP pipe - EG to call from bash windows subsystem
DOCKER="docker" #for unix  pipe
ASADMIN=/opt/payara/appserver/bin/asadmin
PAYA_HOME=/opt/payara
PASSWORD=admin
RASADMIN="$ASADMIN --user admin --passwordfile=$PAYA_HOME/pfile --port 4848 --host das"

# Attempt to clean up any old containers
$DOCKER kill das   >/dev/null 2>&1
$DOCKER kill node1 >/dev/null 2>&1

$DOCKER rm das     >/dev/null 2>&1
$DOCKER rm node1   >/dev/null 2>&1

# Update the image
$DOCKER pull payara/server-full:latest
#create network
$DOCKER network create -d bridge payaranet

# Run
$DOCKER run -i -p 5858:4848 -p 18081:28081 -p 18080:28080 \
           -t -d --name das --network=payaranet -h das \
           -e DISPLAY=$DISPLAY \
           -v /tmp/.X11-unix:/tmp/.X11-unix \
           payara/server-full:latest  /bin/bash
$DOCKER run -i -p 28081:28081 -p 28080:28080 \
           -t -d --name node1 --network=payaranet -h node1 \
           -e DISPLAY=$DISPLAY \
           -v /tmp/.X11-unix:/tmp/.X11-unix \
           payara/server-full:latest  /bin/bash

createPasswordFile() {

cat << EOF > pfile
AS_ADMIN_PASSWORD=$PASSWORD
AS_ADMIN_SSHPASSWORD=payara
EOF

$DOCKER cp pfile das:$PAYA_HOME
$DOCKER cp pfile node1:$PAYA_HOME

}

startDomain() {

$DOCKER exec das $ASADMIN start-domain production

}

enableSecureAdmin() {

# Set admin password
    
$DOCKER exec das curl  -X POST \
    -H 'X-Requested-By: payara' \
    -H "Accept: application/json" \
    -d id=admin \
    -d AS_ADMIN_PASSWORD= \
    -d AS_ADMIN_NEWPASSWORD=$PASSWORD \
    http://localhost:4848/management/domain/change-admin-password
    
$DOCKER exec das $RASADMIN enable-secure-admin
$DOCKER exec das $ASADMIN restart-domain production

}


createConfigNodeCluster() {

$DOCKER exec das $RASADMIN create-cluster cluster
$DOCKER exec das $RASADMIN create-node-config --nodehost node1 node1

$DOCKER exec das $RASADMIN create-local-instance --cluster cluster i00
$DOCKER exec das $RASADMIN create-local-instance --cluster cluster i01
$DOCKER exec node1 $RASADMIN create-local-instance --node node1 --cluster cluster i10
$DOCKER exec node1 $RASADMIN create-local-instance --node node1 --cluster cluster i11

$DOCKER exec das $RASADMIN start-local-instance --sync full i00
$DOCKER exec das $RASADMIN start-local-instance --sync full i01
$DOCKER exec node1 $RASADMIN start-local-instance --sync full i10
$DOCKER exec node1 $RASADMIN start-local-instance --sync full i11


$DOCKER exec das $RASADMIN create-system-properties --target i00 INST_ID=i00
$DOCKER exec das $RASADMIN create-system-properties --target i01 INST_ID=i01
$DOCKER exec das $RASADMIN create-system-properties --target i10 INST_ID=i10
$DOCKER exec das $RASADMIN create-system-properties --target i11 INST_ID=i11

$DOCKER exec das $RASADMIN create-jvm-options --target cluster "-DjvmRoute=\${INST_ID}"

}

createPasswordFile
startDomain
enableSecureAdmin
createConfigNodeCluster
