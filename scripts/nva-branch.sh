Section: IOS configuration

crypto ikev2 proposal AZURE-IKE-PROPOSAL 
encryption aes-cbc-256
integrity sha1
group 2
!
crypto ikev2 policy AZURE-IKE-PROFILE 
proposal AZURE-IKE-PROPOSAL
match address local ${EXT_ADDR}
!
crypto ikev2 keyring AZURE-KEYRING
%{~ for v in TUNNELS }
peer ${v.ipsec.peer_ip}
address ${v.ipsec.peer_ip}
pre-shared-key ${v.ipsec.psk}
%{~ endfor }
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local ${EXT_ADDR}
%{~ for v in TUNNELS }
match identity remote address ${v.ipsec.peer_ip} 255.255.255.255 
%{~ endfor }
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
%{~ for v in TUNNELS }
interface ${v.ike.name}
ip address ${v.ike.address} ${v.ike.mask}
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source ${v.ike.source}
tunnel destination ${v.ike.dest}
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
%{~ endfor }
interface Loopback0
ip address ${LOOPBACK0} 255.255.255.255
!
%{~ for route in STATIC_ROUTES }
ip route ${route.network} ${route.mask} ${route.next_hop}
%{~ endfor }
!
router bgp ${LOCAL_ASN}
bgp router-id ${LOOPBACK0}
%{~ for session in BGP_SESSIONS }
neighbor ${session.peer_ip} remote-as ${session.peer_asn}
%{~ if try(session.ebgp_multihop, false) }
neighbor ${session.peer_ip} ebgp-multihop 255
%{~ endif }
neighbor ${session.peer_ip} soft-reconfiguration inbound
%{~ if try(session.as_override, false) }
neighbor ${session.peer_ip} as-override
%{~ endif }
%{~ if try(session.next_hop_self, false) }
neighbor ${session.peer_ip} next-hop-self
%{~ endif }
%{~ if try(session.source_loopback, false) }
neighbor ${session.peer_ip} update-source Loopback0
%{~ endif }
%{~ endfor }
%{~ for net in BGP_ADVERTISED_NETWORKS }
network ${net.network} mask ${net.mask}
%{~ endfor }
