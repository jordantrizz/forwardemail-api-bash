#!/usr/bin/env bash
# --------------------------
# -- feapi.sh script
# 
# -------------------------
SCRIPT_NAME=feapi
VERSION=0.0.1

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
        _debug "basename - `basename "$0"`"
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
_debug_all

# ------------
# -- Functions
# ------------

# -- usage
usage () {
	echo "Usage: $SCRIPT_NAME <list|create>"
	echo ""
	echo " Commands"
	echo "    list   -List aliases"
	echo "    create <alias> <destination-emails>   -Creates an alias with comma separated destination emals"
	echo ""
}

create_alias () {
	_debug_all
}

# --------------
# -- Main script
# --------------

args=$@
if [ ! $1 ]; then
        usage
fi

if [[ $1 == 'create' ]]; then
	if [[ ! -n $2 ]] || [[ ! -n $3 ]]; then
		usage
		exit
	fi
	echo "-- Creating alias $2 with emails $3"
	create_alias $2 $3
fi
