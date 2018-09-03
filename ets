#!/bin/bash

#ets.sh



#
# test commands
# open trace session
#    ets cs test
#
# generate traffic
#    ab -n 5 http://edge.exco.com/echo
#
# get trace file
#    ets gt test test.xml
#
function help(){
        echo ""
        echo "ets [<options>] <action> <argument1> [<argument2>]"
        echo ""
        echo "Options:"
        echo "    --url=<management-server-host-port>"
        echo "    --org=<organization>"
        echo "    --env=<organization>"
        echo "    --api=<organization>"
        echo "    --rev=<organization>"
        echo ""
        echo "curl commands are using -n option. create ~/.netrc file (%HOME%/_netrc for Windows) and add lines like:"
        echo "    machine api.enterprise.apigee.com login <email> password <password>"
        echo ""
        echo "To create session with name test"
        echo "   ets cs test"
        echo "or"
        echo "   ets --url=edge.exco.com:8080 --org=org --env=dev --api=e --rev=1 cs test 10000"
        echo ""
        echo "To get traces"
        echo ""
        echo "  ets gt test"
        echo ""
        echo "or"
        echo "   ets --url=edge.exco.com:8080 --org=org --env=dev --api=e --rev=1 gt test test.xml"
        echo ""
}

# defauls
PROMPTFORPASSWORD=N
MGMT_URL=https://api.enterprise.apigee.com
ORG=org
ENV=dev
API=echo
REV=1


declare -a ARGS

for var in "$@"; do
    
    # Ignore known bad arguments
    if [ "$var" = '-u' ]; then
        PROMPTFORPASSWORD=Y
        continue

    elif [ "${var:0:6}" = '--url=' ]; then
            MGMT_URL="${var:6}"
        continue
    
    elif [ "${var:0:6}" = '--org=' ]; then
            ORG="${var:6}"
            continue

    elif [ "${var:0:6}" = '--env=' ]; then
            ENV="${var:6}"
            continue

    elif [ "${var:0:6}" = '--api=' ]; then
            API="${var:6}"
            continue

    elif [ "${var:0:6}" = '--rev=' ]; then
            REV="${var:6}"
            continue
    fi

    ARGS[${#ARGS[@]}]="$var"
done
  
if [ ${#ARGS[@]} -lt 2 ]
then
        echo "Wrong number of mandatory arguments supplied."
        echo
    help
    exit 1
fi

ACTION=${ARGS[0]}
ARGUMENT1=${ARGS[1]}
ARGUMENT2=${ARGS[2]}

if [[ ! ";cs;gt;" =~ ";$ACTION;" ]]; then
   echo "Unsupported Action: $ACTION"
   help
   exit 1
fi



export msurl="${MGMT_URL}/v1"


export orgurl="${msurl}/organizations/${ORG}"


# cs, create session
if [ "$ACTION" == "cs" ]; then
        sessionname=$ARGUMENT1
        sessionttl=${ARGUMENT2:=10000}


# curl -v -n "${msurl}/organizations/${ORG}/apis/${API}/revisions/${REV}/deployments?action=undeploy&force=force"


export url=http://edge.exco.com/echo
# curl ${url}

export headers="-H \"Content-Type: application/x-www-url-form-encoded\" "

export createsession="?session=$sessionname&timeout=$sessionttl"


# ie
# curl -vn -X POST -H "Content-Type: application/x-www-url-form-encoded" 'http://edge.exco.com:8080/v1/organizations/org/environments/dev/apis/echo/revisions/1/debugsessions?session=test&timeout=100'
#
# [ "8092b3be-1e2b-49ff-9097-fadd4bf71aac__9", "8092b3be-1e2b-49ff-9097-fadd4bf71aac__10", "8092b3be-1e2b-49ff-9097-fadd4bf71aac__11", "8092b3be-1e2b-49ff-9097-fadd4bf71aac__12", "8092b3be-1e2b-49ff-9097-fadd4bf71aac__13" ]


#
curl -sS -n -X POST "$headers" "${orgurl}/environments/${ENV}/apis/${API}/revisions/${REV}/debugsessions${createsession}"


fi

# gt, gettrace
if [ "$ACTION" == "gt" ]; then
        sessionname=$ARGUMENT1
        sessionfile=${ARGUMENT2:=session.xml}

#curl -sS -n "${orgurl}/environments/${ENV}/apis/${API}/revisions/${REV}/debugsessions"

export retrieved=`python -c 'import datetime; print datetime.datetime.now().strftime("%s.%f")'`
export retrievediso8601=`python -c "from datetime import datetime; print datetime.fromtimestamp($retrieved).strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]"`

cat << EOT > $sessionfile
<DebugSession>
<Retrieved>$retrievediso8601</Retrieved>
<Organization>${ORG}</Organization>
<Environment>${ENV}</Environment>
<API>${API}</API>
<Revision>${REV}</Revision>
<SessionId>$retrieved</SessionId>
<Messages>
EOT

#curl -vn "${orgurl}/environments/${ENV}/apis/${API}/revisions/${REV}/debugsessions/${sessionname}/data"

gtheaders="-H \"Accept: application/xml\""

# example output of data command
# [ "8092b3be-1e2b-49ff-9097-fadd4bf71aac__1", "8092b3be-1e2b-49ff-9097-fadd4bf71aac__2", "8092b3be-1e2b-49ff-9097-fadd4bf71aac__5" ]
#
# port of "| jq -r '.[]'" to bash
#
# example invocation:
#   getitemsfromjsonarray "$d" ;
function getitemsfromjsonarray(){
        arr=$1

        declare -a keys

        for token in $arr
        do     
                keys+=("${token//[\[\],\"]/$'\n'}")
        done
        echo "${keys[@]}"
}


#for sessionid in $(curl -Ss -vn "${orgurl}/environments/${ENV}/apis/${API}/revisions/${REV}/debugsessions/$sessionname/data" | jq -r '.[]'); do
keys=$(curl -Ss -n "${orgurl}/environments/${ENV}/apis/${API}/revisions/${REV}/debugsessions/$sessionname/data")
for sessionid in $(getitemsfromjsonarray "$keys"); do


    # echo "key: $sessionid"

cat << EOT >> $sessionfile
<Message>
<DebugId>$sessionid</DebugId>
EOT

    curl -sS -n "$gtheaders" "${orgurl}/environments/${ENV}/apis/${API}/revisions/${REV}/debugsessions/$sessionname/data/$sessionid" | awk '$0 !~ /<?xml/' >> $sessionfile

cat << EOT >> $sessionfile
</Message>
EOT


done

cat << EOT >> $sessionfile
</Messages>
</DebugSession>
EOT


fi



