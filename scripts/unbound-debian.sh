#! /bin/bash

apt update
apt install -y tcpdump unbound bind9-utils dnsutils net-tools

touch /etc/unbound/unbound.log
chmod a+x /etc/unbound/unbound.log

cat <<EOF > /etc/unbound/unbound.conf
server:
        port: 53
        do-ip4: yes
        do-udp: yes
        do-tcp: yes

        interface: 0.0.0.0

        access-control: 0.0.0.0 deny
        access-control: 127.0.0.0/8 allow
        access-control: 10.0.0.0/8 allow
        access-control: 192.168.0.0/16 allow
        access-control: 172.16.0.0/12 allow
        access-control: 35.199.192.0/19 allow

        # local data records
        %{~ for tuple in ONPREM_LOCAL_RECORDS ~}
        local-data: "${tuple.name} 3600 IN A ${tuple.record}"
        %{~ endfor ~}

        # hosts redirected to PrivateLink
        %{~ for tuple in REDIRECTED_HOSTS ~}
        %{~ for host in tuple.hosts ~}
        local-zone: ${host} redirect
        %{~ endfor ~}
        %{~ endfor ~}

        %{~ for tuple in REDIRECTED_HOSTS ~}
        %{~ for host in tuple.hosts ~}
        local-data: "${host} ${tuple.ttl} ${tuple.class} ${tuple.type} ${tuple.record}"
        %{~ endfor ~}
        %{~ endfor ~}

%{~ for tuple in FORWARD_ZONES }
forward-zone:
        name: "${tuple.zone}"
        %{~ for target in tuple.targets ~}
        forward-addr: ${target}
        %{~ endfor ~}
%{~ endfor ~}
EOF

/etc/init.d/unbound restart
systemctl restart unbound
systemctl enable unbound

# test scripts
#-----------------------------------

# ping-ip

cat <<EOF > /usr/local/bin/ping-ip
echo -e "\n ping ip ...\n"
%{ for target in values(TARGETS) ~}
echo ${target} - \$(ping -qc2 -W1 ${target} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-ip

# ping-dns

cat <<EOF > /usr/local/bin/ping-dns
echo -e "\n ping dns ...\n"
%{ for target in keys(TARGETS) ~}
echo ${target} - \$(ping -qc2 -W1 ${target} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-dns

# curl-ip

cat <<EOF > /usr/local/bin/curl-ip
echo -e "\n curl ip ...\n"
%{ for target in values(TARGETS) ~}
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target}) - ${target}"
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-ip

# curl-dns

cat <<EOF > /usr/local/bin/curl-dns
echo -e "\n curl dns ...\n"
%{ for target in keys(TARGETS) ~}
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target}) - ${target}"
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-dns

# trace-ip

cat <<EOF > /usr/local/bin/trace-ip
echo -e "\n trace ip ...\n"
%{ for target in values(TARGETS) ~}
traceroute ${target}
echo ""
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/trace-ip

