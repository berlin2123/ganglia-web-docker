#!/bin/bash


echo -e '\nContainer starting...\n'`date` >&2


### run gmetad
exec /usr/sbin/gmetad -d 1 &


### run httpd

# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/* /tmp/httpd*

exec /usr/sbin/apachectl -DFOREGROUND

