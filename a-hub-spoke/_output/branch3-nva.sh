Section: IOS configuration

crypto ikev2 proposal AZURE-IKE-PROPOSAL 
encryption aes-cbc-256
integrity sha1
group 2
!
crypto ikev2 policy AZURE-IKE-PROFILE 
proposal AZURE-IKE-PROPOSAL
match address local 10.30.1.9
!
crypto ikev2 keyring AZURE-KEYRING
peer 20.166.49.157
address 20.166.49.157
pre-shared-key changeme
peer 20.166.49.88
address 20.166.49.88
pre-shared-key changeme
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local 10.30.1.9
match identity remote address 20.166.49.157 255.255.255.255
match identity remote address 20.166.49.88 255.255.255.255
authentication remote pre-share
authentication local pre-share
keyring local AZURE-KEYRING
lifetime 28800
dpd 10 5 on-demand
!
crypto ipsec transform-set AZURE-IPSEC-TRANSFORM-SET esp-gcm 256 
mode tunnel
!
crypto ipsec profile AZURE-IPSEC-PROFILE
set transform-set AZURE-IPSEC-TRANSFORM-SET 
set ikev2-profile AZURE-IKE-PROPOSAL
set security-association lifetime seconds 3600
!
interface Tunnel0
ip address 10.30.30.1 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.30.1.9
tunnel destination 20.166.49.157
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Tunnel1
ip address 10.30.30.5 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.30.1.9
tunnel destination 20.166.49.88
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Loopback0
ip address 192.168.30.30 255.255.255.255
!
ip route 0.0.0.0 0.0.0.0 10.30.1.1
ip route 10.22.5.15 255.255.255.255 Tunnel0
ip route 10.22.5.14 255.255.255.255 Tunnel1
ip route 10.30.0.0 255.255.255.0 10.30.2.1
!
!
router bgp 65003
bgp router-id 192.168.30.30
neighbor 10.22.5.15 remote-as 65515
neighbor 10.22.5.15 ebgp-multihop 255
neighbor 10.22.5.15 soft-reconfiguration inbound
neighbor 10.22.5.15 update-source Loopback0
neighbor 10.22.5.14 remote-as 65515
neighbor 10.22.5.14 ebgp-multihop 255
neighbor 10.22.5.14 soft-reconfiguration inbound
neighbor 10.22.5.14 update-source Loopback0
network 10.30.0.0 mask 255.255.255.0
