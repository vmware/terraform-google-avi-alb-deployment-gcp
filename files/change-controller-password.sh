#!/bin/bash
OLD_PASSWORD=
NEW_PASSWORD=
CONTROLLER_ADDRESS=
AVI_VERSION=
AVI_TENANT_NAME="admin"

usage()
{
    echo "usage: change-controller-password.sh [[[--old-password password ] [--new-password password ] [--controller-address address] [--avi-version version]] | [--help]]"
}

while [ "$1" != "" ]; do
    case $1 in
        --old-password )    shift
                                OLD_PASSWORD=$1
                                ;;
        --new-password ) shift  
                                NEW_PASSWORD=$1
                                ;;
        --controller-address )  shift  
                                CONTROLLER_ADDRESS=$1
                                ;;
        --avi-version )  shift  
                                AVI_VERSION=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

until $(curl -k -X GET --output /dev/null --silent --head --fail https://$CONTROLLER_ADDRESS); do
    sleep 10
done
# Login to the Controller with the default credentials and save the cookie-jar
curl -k -i -c ./cookie-jar -POST "https://$CONTROLLER_ADDRESS/login" \
-H "X-Avi-Version: $AVI_VERSION" -H "X-Avi-Tenant: $AVI_TENANT_NAME" \
-H "Content-Type: application/json" -d '{"username": "admin", "password": "'$OLD_PASSWORD'"}' 

# Setup CSRF Token 
AVI_CSRF_TOKEN=$(sed -nr "s/.*csrftoken\s+(.*)$/\1/p" ./cookie-jar)

# Change Password
curl -v -k -i -b ./cookie-jar --location --request PUT "https://$CONTROLLER_ADDRESS/api/useraccount" \
-H "X-CSRFToken: $AVI_CSRF_TOKEN" -H "Referer: https://$CONTROLLER_ADDRESS/" -H "X-Avi-Tenant: $AVI_TENANT_NAME" -H "Content-Type: application/json" \
-d '{"username": "admin", "password": "'$NEW_PASSWORD'", "old_password": "'$OLD_PASSWORD'"}'

#delete cookie-jar file
rm -f ./cookie-jar
