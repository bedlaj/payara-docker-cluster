#!/bin/bash - 
#===============================================================================
#
#          FILE: cleanup-cluster.sh
# 
#         USAGE: ./cleanup-cluster.sh 
# 
#   DESCRIPTION: A script to cleanup the Payara cluster containers
# 
#        AUTHOR: Mike Croft
#  ORGANIZATION: Payara
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#DOCKER="docker -H localhost" #for TCP pipe - EG to call from bash windows subsystem
DOCKER="docker"

# Attempt to clean up any old containers
$DOCKER kill das   >/dev/null 2>&1
$DOCKER kill node1 >/dev/null 2>&1

$DOCKER rm das     >/dev/null 2>&1
$DOCKER rm node1   >/dev/null 2>&1

$DOCKER network rm payaranet
