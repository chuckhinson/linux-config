#!/bin/bash

set -euo pipefail

function clearDockerRoutes {
  # I'm not sure this is actually needed anymore.  
  # Once upon a time, I found docker wouldnt run containers when vpn was 
  # enabled because it would see that vpn had configured the route table 
  # to route all traffic to the vpn server and docker would assume there 
  # were no free subnets for it to use for its networking.  That doesnt 
  # seem to be the case anymore, but I cant remember how to recreate the 
  # problem (was it just with docker run, or was it only with docker 
  # compose), so I'm going to leave this code here for now and just not 
  # invoke it

  # setup our args for update-docker-route
  # TODO: make these parameters instead of env vars
  cols=( $(route | grep ^0.0.0.0 | tr -s " " | cut -d ' ' -f '2 8') )
  route_vpn_gateway=${cols[0]}
  dev=${cols[1]}
  script_type='route-pre-down'

  sudo -E ~/.openvpn/bin/update-docker-routes

}

function main {

  #clearDockerRoutes

  openvpn3 session-manage -c default -D

  # Docker sets up its DNS setting only at startup, so if the hosts DNS
  # settings change (e.g., when disconnectint from VPN), you have to restart 
  # docker to make it use the new settings
  if systemctl is-active docker ; then
    sudo systemctl restart docker
  fi

}

main "$@"