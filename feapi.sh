#!/usr/bin/env bash
# --------------------------
# -- feapi.sh script
# 
# -------------------------

# ------------
# -- Variables
# ------------
SCRIPT_NAME=feapi
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
API_URL="https://api.forwardemail.net"


# ----------------
# -- Key Functions
# ----------------
_debug () {
        if [ -f .debug ];then
                echo -e "${CCYAN}**** DEBUG $@${NC}"
        fi
}

_debug_all () {
        _debug "--------------------------"
        _debug "arguments - $@"
        _debug "funcname - ${FUNCNAME[@]}"
        _debug "basename - $SCRIPTPATH"
        _debug "sourced files - ${BASH_SOURCE[@]}"
        _debug "--------------------------"
}

_error () {
        echo -e "${CRED}$@${NC}";
}

_success () {
        echo -e "${CGREEN}$@${NC}";
}

# -------
# -- Init
# -------
#echo "-- Loading $SCRIPT_NAME - v$VERSION"
#. $(dirname "$0")/functions.sh
#_debug "Loading functions.sh"

# -- Colors
export TERM=xterm-color
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

export NC='\e[0m' # No Color
export CBLACK='\e[0;30m'
export CGRAY='\e[1;30m'
export CRED='\e[0;31m'
export CLIGHT_RED='\e[1;31m'
export CGREEN='\e[0;32m'
export CLIGHT_GREEN='\e[1;32m'
export CBROWN='\e[0;33m'
export CYELLOW='\e[1;33m'
export CBLUE='\e[0;34m'
export CLIGHT_BLUE='\e[1;34m'
export CPURPLE='\e[0;35m'
export CLIGHT_PURPLE='\e[1;35m'
export CCYAN='\e[0;36m'
export CLIGHT_CYAN='\e[1;36m'
export CLIGHT_GRAY='\e[0;37m'
export CWHITE='\e[1;37m'

# --------
# -- Debug
# --------
_debug_all $@

if [[ -f $SCRIPTPATH/.test ]]; then
        _debug "Testing mode on .test in $SCRIPTPATH"
        TEST=1
else
        _debug "Testing mode off no .test in $SCRIPTPATH"
fi

# ------------
# -- Functions
# ------------

# -- usage
usage () {
	echo "Usage: $SCRIPT_NAME <list|create>"
	echo ""
	echo " Commands"
	echo "    list-alias <domain>				-List all aliases for domain"
	echo "    get-alias <domain>				-Retrive domain aliases"
	echo "    create <alias> <destination-emails>		-Creates an alias with comma separated destination emails"
	echo ""
}

query () {
        if [[ $TEST == "1" ]]; then
                output=$(<$SCRIPTPATH/.test)
                _debug "query: testfile api: $API_KEY"
        else
                QUERY="$API_URL$1"
                _debug "query: $1 api: $API_KEY"
                output=$(curl -sX GET $QUERY -u $API_KEY:)
        fi
}

list_aliases () {
	#GET /v1/domains/auxarktrading.com/aliases
	#Querystring Parameter	Required	Type	Description
	#name	No	String (RegExp supported)	Search for aliases in a domain by name
	#recipient	No	String (RegExp supported)	Search for aliases in a domain by recipient	

	DOMAIN=$1
	_debug "args: $@"
	_debug "domain = $DOMAIN"
	echo "-- Listing aliases"
	query "/v1/domains/$DOMAIN/aliases"
	echo ${output[@]} | jq -r '.[].name' | xargs -i echo {}@$DOMAIN
}

getalias () {
	# GET /v1/domains/:domain_name/aliases/:alias_id
	# curl https://api.forwardemail.net/v1/domains/:domain_name/aliases/:alias_id -u API_TOKEN:
	echo "-- Getting alias $2"
}

create_alias () {
	_debug_all $@
	
}

# --------------
# -- Main script
# --------------

args=$@
if [ ! $1 ]; then
        usage
        exit
fi

if [[ -f ~/.feapi ]]; then
	_success "Found ~/.feapi"
        source ~/.feapi
        if [[ $API_KEY ]]; then
        	_success "Found API key."
        else
        	_error "No API key found."
        fi
else
	_error "No ~/.feapi file exists, no token."
fi

if [[ $1 == "list-aliases" ]]; then
	if [[ ! -n $2 ]];then usage;exit;fi
	list_aliases $2
elif [[ $1 == "getalias" ]]; then
	if [[ ! -n $2 ]];then usage;exit;fi
	echo ""

elif [[ $1 == 'create' ]]; then
	if [[ ! -n $2 ]] || [[ ! -n $3 ]]; then usage; exit;fi
	echo "-- Creating alias $2 with emails $3"
	create_alias $2 $3
else
	usage
fi