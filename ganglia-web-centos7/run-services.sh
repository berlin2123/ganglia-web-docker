#!/bin/bash

usage() { cat << EOF
Usage: docker run wookietreiber/ganglia [opts]
Run a ganglia-web container.
    -? | -h | -help | --help            print this help
    --timezone arg                      set timezone within the container,
                                        must be path below /usr/share/zoneinfo,
                                        e.g. Europe/Berlin
EOF
}

while true ; do
  case "$1" in
    -?|-h|-help|--help)
      usage
      exit 0
      ;;

    --timezone)
      shift
      TIMEZONE=$1
      shift
      ;;

    "")
      break
      ;;

    *)
      usage > /dev/stderr
      exit 1
      ;;
  esac
done

set -x


# apply timezone if set
[[ -n $TIMEZONE ]] && ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime



### run httpd

# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/* /tmp/httpd*

exec /usr/sbin/apachectl -DFOREGROUND &


### run gmetad
exec /usr/sbin/gmetad -d 1

