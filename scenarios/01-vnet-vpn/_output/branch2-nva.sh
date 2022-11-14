Section: IOS configuration

crypto ikev2 proposal AZURE-IKE-PROPOSAL 
encryption aes-cbc-256
integrity sha1
group 2
!
crypto ikev2 policy AZURE-IKE-PROFILE 
proposal AZURE-IKE-PROPOSAL
match address local 10.20.1.9
!
crypto ikev2 keyring AZURE-KEYRING
peer 40.118.97.188
address 40.118.97.188
pre-shared-key changeme
peer 40.118.101.82
address 40.118.101.82
pre-shared-key changeme
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local 10.20.1.9
match identity remote address 40.118.97.188 255.255.255.255
match identity remote address 40.118.101.82 255.255.255.255
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
ip address 10.20.20.1 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.20.1.9
tunnel destination 40.118.97.188
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Tunnel1
ip address 10.20.20.5 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.20.1.9
tunnel destination 40.118.101.82
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Loopback0
ip address 192.168.20.20 255.255.255.255
!
ip route 0.0.0.0 0.0.0.0 10.20.1.1
ip route 10.2.1.4 255.255.255.255 Tunnel0
ip route 10.2.1.5 255.255.255.255 Tunnel1
ip route 10.20.0.0 255.255.255.0 10.20.2.1
!
router bgp 65002
bgp router-id 192.168.20.20
neighbor 10.2.1.4 remote-as 65515
neighbor 10.2.1.4 ebgp-multihop 255
neighbor 10.2.1.4 soft-reconfiguration inbound
neighbor 10.2.1.4 update-source Loopback0
neighbor 10.2.1.5 remote-as 65515
neighbor 10.2.1.5 ebgp-multihop 255
neighbor 10.2.1.5 soft-reconfiguration inbound
neighbor 10.2.1.5 update-source Loopback0
network 10.20.0.0 mask 255.255.255.0
