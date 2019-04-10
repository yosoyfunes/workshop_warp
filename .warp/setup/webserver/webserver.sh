#!/bin/bash +x

warp_message ""
warp_message_info "Configuring Web Server - Nginx"
warp_message ""

    warp_check_os_mac

while : ; do
    respuesta_web=$( warp_question_ask_default "Do you want to add a web server (Nginx)? $(warp_message_info [Y/n]) " "Y" )

    if [ "$respuesta_web" = "Y" ] || [ "$respuesta_web" = "y" ] || [ "$respuesta_web" = "N" ] || [ "$respuesta_web" = "n" ] ; then
        break
    else
        warp_message_warn "wrong answer, you must select between two options: $(warp_message_info [Y/n]) "
    fi
done

if [ "$respuesta_web" = "Y" ] || [ "$respuesta_web" = "y" ]
then

    nginx_virtual_host=$( warp_question_ask_default "Add the virtual host name: $(warp_message_info [local.sample.com]) " "local.sample.com" )
  
    useproxy=1 #False

    case "$(uname -s)" in
        Linux)
            resp_reverse_proxy=$( warp_question_ask_default "Do You want to configure a static ip to support more than one project in parallel? $(warp_message_info [y/N]) " "N" )
            if [ "$resp_reverse_proxy" = "Y" ] || [ "$resp_reverse_proxy" = "y" ]
            then
                # autodetect docker in linux
                useproxy=0 #True
            fi;
        ;;
    esac

    if [ $useproxy = 1 ]; then
        while : ; do
            http_port=$( warp_question_ask_default "Mapping container port 80 to your machine port (host): $(warp_message_info [80]) " "80" )

            #CHECK si port es numero antes de llamar a warp_net_port_in_use
            if ! warp_net_port_in_use $http_port ; then
                warp_message_info2 "The selected port is: $http_port, the configuration for the file /etc/hosts is: $(warp_message_bold '127.0.0.1 '$nginx_virtual_host)"
                break
            else
                warp_message_warn "the port $http_port is busy, choose another one\n"
            fi;
        done

        while : ; do
            https_port=$( warp_question_ask_default "Mapping container port 443 to your machine port (host): $(warp_message_info [443]) " "443" )

            if ! warp_net_port_in_use $https_port ; then
                warp_message_info2 "The selected port is: $https_port, the configuration for the file /etc/hosts is: $(warp_message_bold '127.0.0.1 '$nginx_virtual_host)"
                break
            else
                warp_message_warn "the port $https_port is busy, choose another one\n"
            fi;
        done
    else 
        while : ; do
            http_container_ip=$( warp_question_ask_default "Attach an IP number to the container $(warp_message_info '[range 172.50.0.'$MIN_RANGE_IP' - 172.50.0.255]') " "172.50.0.$MIN_RANGE_IP" )

            if warp_check_range_ip $http_container_ip ; then
                RANGE=$(echo $http_container_ip | cut -f1 -f2 -f3 -d .)
                warp_message_warn "You should select an IP range between: $RANGE.$MIN_RANGE_IP and $RANGE.255\n"
            else 
                if ! warp_net_ip_in_use $http_container_ip ; then
                    warp_message_info2 "The selected IP is: $http_container_ip, the configuration for the file /etc/hosts is: $(warp_message_bold $http_container_ip' '$nginx_virtual_host)"
                    break
                else
                    warp_message_warn "The IP $http_container_ip is being used in another project, choose another one\n"
                fi;
            fi;
        done
    fi; 

    
    nginx_config_file=$( warp_question_ask_default "Set the name of Nginx configuration file? $(warp_message_info '['$nginx_virtual_host'.conf]') " "$nginx_virtual_host.conf" )
    
    echo "" >> $ENVIRONMENTVARIABLESFILESAMPLE
    #echo "# NGINX Configuration" >> $ENVIRONMENTVARIABLESFILESAMPLE

    cat $PROJECTPATH/.warp/setup/webserver/tpl/webserver.yml >> $DOCKERCOMPOSEFILESAMPLE

    if [ $useproxy = 0 ]; then
        echo "HTTP_BINDED_PORT=80" >> $ENVIRONMENTVARIABLESFILESAMPLE
        echo "HTTPS_BINDED_PORT=443" >> $ENVIRONMENTVARIABLESFILESAMPLE
        echo "HTTP_HOST_IP=$http_container_ip" >> $ENVIRONMENTVARIABLESFILESAMPLE
    else
        echo "HTTP_BINDED_PORT=$http_port" >> $ENVIRONMENTVARIABLESFILESAMPLE
        echo "HTTPS_BINDED_PORT=$https_port" >> $ENVIRONMENTVARIABLESFILESAMPLE
        echo "HTTP_HOST_IP=0.0.0.0" >> $ENVIRONMENTVARIABLESFILESAMPLE
    fi;

    echo "VIRTUAL_HOST=$nginx_virtual_host" >> $ENVIRONMENTVARIABLESFILESAMPLE
    echo "NGINX_CONFIG_FILE=./.warp/docker/config/nginx/sites-enabled/$nginx_config_file" >> $ENVIRONMENTVARIABLESFILESAMPLE
    echo "" >> $ENVIRONMENTVARIABLESFILESAMPLE

    mkdir -p $PROJECTPATH/.warp/docker/volumes/nginx/logs
    chmod -R 777 $PROJECTPATH/.warp/docker/volumes/nginx

    cp -R $PROJECTPATH/.warp/setup/webserver/config/nginx $PROJECTPATH/.warp/docker/config/nginx
    
    # Copying nginx base framework configuration
    #cp $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/default.conf $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/$nginx_config_file
    case $framework in
        'm1')
            cat $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/m1.conf | sed -e "s/{{SERVER_NAME}}/${nginx_virtual_host}/" > $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/$nginx_config_file
        ;;
        'm2')
            cat $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/m2.conf | sed -e "s/{{SERVER_NAME}}/${nginx_virtual_host}/" > $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/$nginx_config_file
        ;;
        'oro')
            cat $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/oro.conf | sed -e "s/{{SERVER_NAME}}/${nginx_virtual_host}/" > $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/$nginx_config_file
        ;;
        'php')
            cat $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/php.conf | sed -e "s/{{SERVER_NAME}}/${nginx_virtual_host}/" > $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/$nginx_config_file
        ;;
        *)
            cat $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/php.conf | sed -e "s/{{SERVER_NAME}}/${nginx_virtual_host}/" > $PROJECTPATH/.warp/docker/config/nginx/sites-enabled/$nginx_config_file
        ;;
    esac


fi; 

