#! /bin/bash

apt update
apt install -y tcpdump bind9-utils dnsutils net-tools
apt install -y unbound

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
        local-data: "vm.branch1.salawu.net 3600 IN A 10.10.0.5"
        local-data: "vm.branch2.salawu.net 3600 IN A 10.20.0.5"
        local-data: "vm.branch3.salawu.net 3600 IN A 10.30.0.5"
        local-data: "vm.branch4.salawu.net 3600 IN A 10.40.0.5"

        # hosts redirected to PrivateLink


forward-zone:
        name: "az.salawu.net."
        forward-addr: 10.11.3.4
        forward-addr: 10.22.3.4

forward-zone:
        name: "."
        forward-addr: 168.63.129.16
EOF

sleep 10
systemctl restart unbound
systemctl enable unbound

# test scripts
#-----------------------------------

# ping-ip

cat <<EOF > /usr/local/bin/ping-ip
echo -e "\n ping ip ...\n"

echo "branch1 - 10.10.0.5 -\$(ping -qc2 -W1 10.10.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "branch2 - 10.20.0.5 -\$(ping -qc2 -W1 10.20.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "branch3 - 10.30.0.5 -\$(ping -qc2 -W1 10.30.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "hub1    - 10.11.0.5 -\$(ping -qc2 -W1 10.11.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "hub2    - 10.22.0.5 -\$(ping -qc2 -W1 10.22.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "spoke1  - 10.1.0.5 -\$(ping -qc2 -W1 10.1.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "spoke2  - 10.2.0.5 -\$(ping -qc2 -W1 10.2.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"


echo "spoke4  - 10.4.0.5 -\$(ping -qc2 -W1 10.4.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "spoke5  - 10.5.0.5 -\$(ping -qc2 -W1 10.5.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

EOF
chmod a+x /usr/local/bin/ping-ip

# ping-dns

cat <<EOF > /usr/local/bin/ping-dns
echo -e "\n ping dns ...\n"

echo "vm.branch1.salawu.net - \$(dig +short vm.branch1.salawu.net | tail -n1) -\$(ping -qc2 -W1 vm.branch1.salawu.net 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "vm.branch2.salawu.net - \$(dig +short vm.branch2.salawu.net | tail -n1) -\$(ping -qc2 -W1 vm.branch2.salawu.net 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "vm.branch3.salawu.net - \$(dig +short vm.branch3.salawu.net | tail -n1) -\$(ping -qc2 -W1 vm.branch3.salawu.net 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "vm.hub1.az.salawu.net - \$(dig +short vm.hub1.az.salawu.net | tail -n1) -\$(ping -qc2 -W1 vm.hub1.az.salawu.net 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "vm.hub2.az.salawu.net - \$(dig +short vm.hub2.az.salawu.net | tail -n1) -\$(ping -qc2 -W1 vm.hub2.az.salawu.net 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "vm.spoke1.az.salawu.net - \$(dig +short vm.spoke1.az.salawu.net | tail -n1) -\$(ping -qc2 -W1 vm.spoke1.az.salawu.net 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "vm.spoke2.az.salawu.net - \$(dig +short vm.spoke2.az.salawu.net | tail -n1) -\$(ping -qc2 -W1 vm.spoke2.az.salawu.net 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"


echo "vm.spoke4.az.salawu.net - \$(dig +short vm.spoke4.az.salawu.net | tail -n1) -\$(ping -qc2 -W1 vm.spoke4.az.salawu.net 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

echo "vm.spoke5.az.salawu.net - \$(dig +short vm.spoke5.az.salawu.net | tail -n1) -\$(ping -qc2 -W1 vm.spoke5.az.salawu.net 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"

EOF
chmod a+x /usr/local/bin/ping-dns

# curl-ip

cat <<EOF > /usr/local/bin/curl-ip
echo -e "\n curl ip ...\n"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.10.0.5) - branch1 (10.10.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.20.0.5) - branch2 (10.20.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.30.0.5) - branch3 (10.30.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.11.0.5) - hub1    (10.11.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.22.0.5) - hub2    (10.22.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.1.0.5) - spoke1  (10.1.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.2.0.5) - spoke2  (10.2.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.3.0.5) - spoke3  (10.3.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.4.0.5) - spoke4  (10.4.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.5.0.5) - spoke5  (10.5.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.6.0.5) - spoke6  (10.6.0.5)"
EOF
chmod a+x /usr/local/bin/curl-ip

# curl-dns

cat <<EOF > /usr/local/bin/curl-dns
echo -e "\n curl dns ...\n"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.branch1.salawu.net) - vm.branch1.salawu.net"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.branch2.salawu.net) - vm.branch2.salawu.net"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.branch3.salawu.net) - vm.branch3.salawu.net"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.hub1.az.salawu.net) - vm.hub1.az.salawu.net"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.hub2.az.salawu.net) - vm.hub2.az.salawu.net"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke1.az.salawu.net) - vm.spoke1.az.salawu.net"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke2.az.salawu.net) - vm.spoke2.az.salawu.net"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke3.az.salawu.net) - vm.spoke3.az.salawu.net"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke4.az.salawu.net) - vm.spoke4.az.salawu.net"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke5.az.salawu.net) - vm.spoke5.az.salawu.net"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke6.az.salawu.net) - vm.spoke6.az.salawu.net"
EOF
chmod a+x /usr/local/bin/curl-dns

# trace-ip

cat <<EOF > /usr/local/bin/trace-ip
echo -e "\n trace ip ...\n"
traceroute 10.10.0.5
echo -e "branch1\n"
traceroute 10.20.0.5
echo -e "branch2\n"
traceroute 10.30.0.5
echo -e "branch3\n"
traceroute 10.11.0.5
echo -e "hub1   \n"
traceroute 10.22.0.5
echo -e "hub2   \n"
traceroute 10.1.0.5
echo -e "spoke1 \n"
traceroute 10.2.0.5
echo -e "spoke2 \n"
traceroute 10.3.0.5
echo -e "spoke3 \n"
traceroute 10.4.0.5
echo -e "spoke4 \n"
traceroute 10.5.0.5
echo -e "spoke5 \n"
traceroute 10.6.0.5
echo -e "spoke6 \n"
EOF
chmod a+x /usr/local/bin/trace-ip
