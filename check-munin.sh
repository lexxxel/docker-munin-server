#!/bin/bash

set -e

# Use first user creds to get URL access
MUNIN_USERS=${MUNIN_USERS:-${MUNIN_USER:-user}}
MUNIN_PASSWORDS=${MUNIN_PASSWORDS:-${MUNIN_PASSWORD:-password}}

test -n "$HEALTH_HOSTINFO" || {

  IFS=' ' read -ra ARR_USERS <<< "$MUNIN_USERS"
  IFS=' ' read -ra ARR_PASSWORDS <<< "$MUNIN_PASSWORDS"
  HEALTH_HOSTINFO=${ARR_USERS[0]}:${ARR_PASSWORDS[0]}@localhost
}

printf -- "Requesting index... "
curl -sSfo/dev/null \
  http://$HEALTH_HOSTINFO:8080/ \
  && echo OK || exit 1


# NOTE: check uptime graph for each node. Node contact failure would cause
# container to be considered unhealthy.
test -n "$HEALTH_CHECK_NODES" || exit 0

NODES=${NODES:-}
SNMP_NODES=${SNMP_NODES:-}
SSH_NODES=${SSH_NODES:-}

case "$HEALTH_CHECK_NODES" in 1|yes|true|on )
  HEALTH_CHECK_NODES="$NODES $SNMP_NODES $SSH_NODES" ;;
esac

for NODE in $HEALTH_CHECK_NODES
do
  NAME=`echo $NODE | cut -d ":" -f1`
  GROUP=$NAME
  printf -- "Requesting $GROUP/$NAME uptime graph... "
  curl -sSfo/dev/null \
    http://$HEALTH_HOSTINFO:8080/munin-cgi/munin-cgi-graph/$GROUP/$NAME/uptime-day.png \
      && echo OK || exit 1
done
