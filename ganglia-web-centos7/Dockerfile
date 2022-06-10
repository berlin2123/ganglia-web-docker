FROM centos:centos7

ENV container docker

RUN yum -y --setopt=tsflags=nodocs install epel-release && \
    yum -y --setopt=tsflags=nodocs install \
      ganglia-gmetad ganglia-web \
      httpd php && \
    yum clean all

RUN rm -rf /etc/httpd/conf.d/ganglia.conf && \
    ln -s /usr/share/ganglia /var/www/html/ganglia

RUN sed -i 's|data_source "my cluster" localhost|data_source "cluster" 10.88.0.1:8649|g' /etc/ganglia/gmetad.conf && \
    echo 'ServerName  localhost:80' >> /etc/httpd/conf/httpd.conf

EXPOSE 80


# to avoid cdnjs.cloudflare.com unreachable
COPY download-js.cdnjs.cloudflare.com.tgz /download-js.cdnjs.cloudflare.com.tgz
RUN tar -zxf download-js.cdnjs.cloudflare.com.tgz ; cp -r download-js/cdnjs.cloudflare.com /var/www/html/ganglia/; rm -rf download-js*
RUN sed -e 's|https://cdnjs.cloudflare.com|cdnjs.cloudflare.com|g' -i.bak /var/www/html/ganglia/conf_default.php


# Simple startup script to avoid some issues observed with container restart
COPY run-services.sh /run-services.sh
RUN chmod -v +x /run-services.sh


CMD ["/run-services.sh"]
#ENTRYPOINT ["bash","/run-services.sh"]
