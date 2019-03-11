#!/bin/bash - 
#===============================================================================
#
#          FILE: resume-cluster.sh
# 
#         USAGE: ./resume-cluster.sh 
# 
#   DESCRIPTION: Resumes docker cluster rather than recreating
# 
#        AUTHOR: Mike Croft
#  ORGANIZATION: Payara
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#DOCKER="docker -H localhost" #for TCP pipe - EG to call from bash windows subsystem
DOCKER="docker"
ASADMIN=/opt/payara/appserver/bin/asadmin
PAYA_HOME=/opt/payara
PASSWORD=admin
RASADMIN="$ASADMIN --user admin --passwordfile=$PAYA_HOME/pfile --port 4848 --host das"

$DOCKER start das 2>/dev/null
$DOCKER start node1 2>/dev/null

$DOCKER exec das $ASADMIN start-domain production

$DOCKER exec das   $RASADMIN start-local-instance --sync  full i00
$DOCKER exec das   $RASADMIN start-local-instance --sync  full i01
$DOCKER exec node1 $RASADMIN start-local-instance --sync  full i10
$DOCKER exec node1 $RASADMIN start-local-instance --sync  full i11
