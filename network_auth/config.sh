#!/bin/bash

# Configuration for Network Authentication Script

CONFIG_FILE="network_auth_config.txt"
BASE_URL="https://portal.sasakonnect.net/"
MAX_HISTORY=5

# Portal parameters
INTERFACE_MODE="true"
PAGETYPE="remote"
WIRED_AUTH="true"
INTERFACE="v2012"
STA_IP="10.12.1.34"
URL_PARAM="http%3A//192.168.7.1/"
BAS_PORT="10443"
BAS_HTTP_PORT="8080"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color