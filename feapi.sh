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
REQUIRED_APPS=("jq" "column")
TEST=$(<$SCRIPTPATH/.test)
TEST_GET=$(<$SCRIPTPATH/.test_get)
TEST_POST=$(<$SCRIPTPATH/.test_post)
TEST_ERROR=$(<$SCRIPTPATH/.test_error)
TEST_CREATE=$(<$SCRIPTPATH/.test_create)


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
        _debug "test - $TEST"
        _debug "--------------------------"
}

_error () {
        echo -e "${CRED}$@${NC}";
}

_success () {
        echo -e "${CGREEN}$@${NC}";
}

_command () {
	if ! command -v $1 &> /dev/null
	then
	    _error "The command $1 could not be found and is required to run $SCRIPT_NAME"
	    exit
	fi
}

_check_commands () {
	for cmd in ${REQUIRED_APPS[@]}; do
		_command $cmd		
	done
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

if [[ $TEST == "1" ]]; then
        _debug "Testing get using .test_get file"
        TEST_FILE=$(<$SCRIPTPATH/.test_get)
elif [[ $TEST == "2" ]]; then
	_debug "Testing post using .test_post file"
	TEST_FILE=$(<$SCRIPTPATH/.test_post)
elif [[ $TEST == "3" ]]; then
        _debug "Testing error using .test_error file"
        TEST_FILE=$(<$SCRIPTPATH/.test_error)
elif [[ $TEST == "4" ]]; then
        _debug "Testing create-alias using .test_create file"
        TEST_FILE=$(<$SCRIPTPATH/.test_create)
else
        _debug "Testing mode off -- .test=$TEST"
fi

# ------------
# -- Functions
# ------------

# -- usage
usage () {
	echo "Usage: $SCRIPT_NAME <list|create>"
	echo ""
	echo " Commands"
	echo "    list-aliases <domain>				-List all aliases for domain"
	echo "    get-alias <email alias>				-Retrive specific domain alias"
	echo "    create-alias <email alias> <destination-emails>		-Creates an alias with comma separated destination emails"
	echo ""
}

split_email () {
	email=$@
	IFS=$'@' 
	email=($email)
	unset IFS
        ALIAS=${email[0]}
        DOMAIN=${email[1]}
}

curl_error () {
                status=$(echo $@ | jq -r '[.message, .statusCode] | @tsv')
                IFS=$'\t'
                status=($status)
                QUERY_MESSAGE=${status[0]}
                QUERY_CODE=${status[1]}

                echo ""
                _error "Query Error"
                _error "Query Message: $QUERY_MESSAGE"
                _error "Status Code: $QUERY_CODE"
                exit
}
                         
curl_get () {
	QUERY=$1
	CURL_QUERY="$API_URL$QUERY"

	_debug "curl_get"

        if (( $TEST >= "1" )); then
		_debug "query: $TEST_FILE"
                output=$TEST_FILE
        else
                _debug "query: $QUERY api: $API_KEY"
                _debug "cmd: curl -sX GET $CURL_QUERY -u $API_KEY:"
                output=$(curl -sX GET $CURL_QUERY -u $API_KEY:)
        fi
}

curl_post () {
	QUERY=$1
	ALIAS=$2	
        shift 2
        EMAILS=$@
        CURL_QUERY="$API_URL$QUERY"

	_debug "curl_post"
	
	# If test is set
	if (( $TEST >= "1" )); then
		_debug "Running test query"
        
		echo ""
		echo "sample CURL"
		echo "-----------"
		echo "curl -sX POST $CURL_QUERY -u $API_KEY: \\"
		echo "-d \"name=$ALIAS\" \\"
		echo "-d \"recipients=$EMAILS\""
		echo ""
		output=$TEST_FILE
        else
		_debug "query: $QUERY alias:$ALIAS emails:${EMAILS[@]}"
		_debug "cmd: curl -sX POST $CURL_QUERY -u $API_KEY: -d \"name=$ALIAS\" -d \"recipients=$EMAILS\""
	        output=$(curl -sX POST $CURL_QUERY -u $API_KEY: -d "name=$ALIAS" -d "recipients=$EMAILS")
        fi

	_debug "output"
	_debug "------"
	_debug $output
	
        if [[ $output == *"Bad Request"* ]]; then
        	_debug "curl error"
		curl_error $output
	else
        	_debug "curl success"
                _success "Query success"

        fi

}

list_aliases () {
	#GET /v1/domains/domain.com/aliases
	#Querystring Parameter	Required	Type				Description
	#name			No		String (RegExp supported)	Search for aliases in a domain by name
	#recipient		No		String (RegExp supported)	Search for aliases in a domain by recipient	

	# Variables
	_debug "args: $@"
	DOMAIN=$1
	_debug "domain = $DOMAIN"
	
	# List aliases
	echo "-- Listing aliases"
	curl_get "/v1/domains/$DOMAIN/aliases"
	echo "Aliases for $DOMAIN"
	echo "-------------------"
	echo ${output[@]} | jq -r '(["ID","ENABLED","NAME","RECIPIENTS","DESCRIPTION"] | (., map(length*"-"))), (.[]| [.id, .is_enabled, .name,(.recipients|join(",")),.description])|@tsv' | column -t
	
}

create_alias () {
	#POST /v1/domains/domain.com/aliases
	#Body Parameter	Required Type			Description
	#name		Yes	String			Alias name
	#recipients	Yes	String or Array		List of recipients (must be line-break/space/comma separated String 
	#						or Array of valid email addresses, fully-qualified domain names 
	#						("FQDN"), IP addresses, and/or webhook URL's)
	#description	No	String			Alias description
	#labels		No	String or Array		List of labels (must be line-break/space/comma separated String or Array)
	#is_enabled	No	Boolean			Whether to enable to disable this alias (if disabled, emails will be routed 
	#						nowhere but return successful status codes)

	# Variables
	_debug "args: $@"
        split_email $1
        EMAILS=$2
        _debug "alias: $ALIAS domain: $DOMAIN emails:$EMAILS"
	
	# Create alias
        echo "-- Creating alias"
        curl_post "/v1/domains/$DOMAIN/aliases" "$ALIAS" "$EMAILS"
        echo ${output[@]} | jq -r '(["ID","ENABLED","NAME","RECIPIENTS"] | (., map(length*"-"))), (.[]| [.id, .is_enabled, .name,(.recipients|join(","))])|@tsv' | column -t
}

get_alias () {
	# GET /v1/domains/:domain_name/aliases/:alias_id
	# curl https://api.forwardemail.net/v1/domains/:domain_name/aliases/:alias_id -u API_TOKEN:

	# Variables
        _debug "args: $@"
	# Split email parts
        _debug "splitting email"
	split_email $@
	_debug "alias: $ALIAS domain: $DOMAIN"

	# Get data and print
	echo "-- Getting alias $@"
	curl_get "/v1/domains/$DOMAIN/aliases/$ALIAS"
        echo "Alias $@"
        echo "-----------"
        echo ${output[@]}
}

test () {
	#cat $SCRIPTPATH/.test_post
	output=$TEST_FILE
	echo $output
}

# --------------
# -- Main script
# --------------

_check_commands

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
elif [[ $1 == "get-alias" ]]; then
	if [[ ! -n $2 ]];then usage;exit;fi
	get_alias $2
elif [[ $1 == 'create-alias' ]]; then
	if [[ ! -n $2 ]] || [[ ! -n $3 ]]; then usage; exit;fi
	create_alias $2 $3
elif [[ $1 == "test" ]]; then
	test
else
	usage
fi