FROM centos:centos7

# base system upgrade and system dependencies
RUN yum upgrade -y && \
    yum install -y epel-release && \
    yum install -y \
      ganglia-gmetad ganglia-web \
      httpd php rsync wget tar && \
    yum clean all

# configure
RUN rm -rf /etc/httpd/conf.d/ganglia.conf && \
    ln -s /usr/share/ganglia /var/www/html/ganglia

# enable server
RUN systemctl enable httpd gmetad

#RUN yum install -y ganglia-gmond && yum clean all && systemctl enable gmond

CMD ["/sbin/init"]
