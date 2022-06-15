### Use Ganglia-web inside a centos7 container to monitor RockyLinux8/CentOS8/CentosStream9/RockyLinux9 hosts

**Purpose:**

Ganglia is a very good software package for monitoring the historical state of clusters or nodes. However, the current ganglia web interface (3.7.5) is based on php-5.6. If you are using a higher version php, such as that in the default environment of **RHEL8/Centos8/RockyLinux8**, ganglia web interface will not be displayed normally. Therefore, configuring and using php-5.6 was the necessary option to run the ganglia web interface in those new systems. Docker can easily solve this problem. That is, **running Ganglia-web inside a centos7 container** in the RHEL8/Centos8/RockyLinux8 system, which container can easily run the php-5.6. It will **ensure the normal display of the ganglia-web interface**.

### Get this container image

#### Just simply Pull from [docker.io](https://hub.docker.com/r/berlin2123/ganglia-web-centos7) (recommended)
```
podman pull docker.io/berlin2123/ganglia-web-centos7
```

#### Or build the container image by Yourself

##### Downlaod those `Dockerfile` and `run-services.sh` into your system

```
wget https://raw.githubusercontent.com/berlin2123/ganglia-web-docker/main/ganglia-web-centos7/Dockerfile
wget https://raw.githubusercontent.com/berlin2123/ganglia-web-docker/main/ganglia-web-centos7/run-services.sh
wget https://raw.githubusercontent.com/berlin2123/ganglia-web-docker/main/ganglia-web-centos7/download-js.cdnjs.cloudflare.com.tgz
wget https://raw.githubusercontent.com/berlin2123/ganglia-web-docker/main/ganglia-web-centos7/stacked.php
```

##### Manually build this container:

```
podman build -t <name_of_the_container_image>  <Path_to_the_Dockerfile>
```

If the `Dockerfile` and `run-services.sh` are saved to `/root/dockertest/cent7ganglia/`, and you want to name this image as `mybuild/cent7ganglia`, you can just run:  

```
podman build -t mybuild/cent7ganglia /root/dockertest/cent7ganglia/
```



### Run the container

1. Run the container, with the setting of timezone `-e TZ=timezone_code`,
   ```
   podman run -t -d --name ganglia -e TZ=Europe/Berlin -p 1380:80 --restart always berlin2123/ganglia-web-centos7
   ```
   You may need to use your own image or timezone name.

   You can check the runing state by 
   ```
   podman logs --since 10m ganglia
   ```
2. Create a service (systemd) that automatically starts the ganglia container
   ```
   podman generate systemd --name ganglia > /etc/systemd/system/container-ganglia.service
   ```

   Enable and start this service now
   ```
   systemctl enable --now container-ganglia.service 
   ```

3. Modify the internal configuration of the container  (If you want to use another cluster name)
   ```
   # enter the container
   podman exec -u root -it ganglia /bin/bash   
   # vi /etc/ganglia/gmetad.conf 
   # change the line:
   data_source "cluster" 10.88.0.1:8649 
   # to
   data_source "your_cluster_name" 10.88.0.1:8649
   
   # After the modification is completed, exit from the container
   exit
   ```
   Restart is required for the changes to take effect,
   ```
   systemctl restart container-ganglia.service 
   ```

4. Open ports, enable permission.
   ```
   # ports:
   firewall-cmd --add-port=1380/tcp --permanent
   firewall-cmd --reload
   firewall-cmd --list-all
   ```

5. You can visit the Ganglia-web website inside this container by,
   ```
   http://<YOUR_IP>:1380/ganglia/
   # such as
   http://192.168.1.100:1380/ganglia/
   ```


### Install gmond in nodes to collect nodes status information

1. Install gmond in a node
   ```
   dnf install -y epel-release
   dnf install -y ganglia ganglia-gmond
   ```
   There are no ganglia/gmond rpms yet in EL9 epel repository now. So you can use the EL8 rpms instead, in RHEL9/CentOS_Stream9/Rocky9 node.
   ```
   # for RHEL9/CentOS_Stream9/Rocky9 node:
   dnf install -y epel-release
   dnf install -y \
       https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/g/ganglia-3.7.2-33.el8.x86_64.rpm \
       https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/g/ganglia-gmond-3.7.2-33.el8.x86_64.rpm
   ```

2. Edit /etc/ganglia/gmond.conf
   ```
   # change the fellow part
   cluster {
     name = "cluster"               # be the same as that gmetad.conf inside your container
     owner = "unspecified"
     latlong = "unspecified"
     url = "unspecified"
   }
   ```

3. Open ports, enable permission.
   ```
   firewall-cmd --add-port=8649/udp --permanent
   firewall-cmd --add-port=8649/tcp --permanent
   firewall-cmd --reload
   firewall-cmd --list-all
   ```
4. Enable gmond service.
   ```
   systemctl enable --now gmond
   ```

5 You can monitor the nodes states in the Ganglia-web website now.

**Notice:**

To monitor other nodes, you need to ensure that gmond is always up and running on the host where this container is running. In some cases if you update the configuration of some nodes, maybe you need to restart the gmond service on the container host.
   ```
   systemctl restart gmond
   ```

### Create a reverse proxy on the host machine

To ensure visit the website through YOUR_DMAIN_NAME.

1. Write a httpd configure file like this /etc/httpd/conf.d/ganglia.conf 
   ```
   [root@Host ~]# cat /etc/httpd/conf.d/ganglia.conf 
   #
   # Ganglia monitoring system php web frontend
   #
   
   <VirtualHost *:80>
   
   ServerName ganglia.your.servername.com
   
   ProxyPass           "/" "http://127.0.0.1:1380/ganglia/"
   ProxyPassReverse    "/" "http://127.0.0.1:1380/ganglia/"
   
   
   </virtualHost>
   
   ```
2. Open ports, enable permission.
   ```
   # ports:
   firewall-cmd --zone=public --add-service=http --permanent
   firewall-cmd --reload
   firewall-cmd --list-all
   
   # permission
   setsebool -P httpd_can_network_connect on
   ```
3. Restart services.
   ```
   systemctl restart container-ganglia
   systemctl restart httpd
   ```

