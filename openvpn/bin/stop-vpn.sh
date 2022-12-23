#!/bin/bash

set -euo pipefail

# setup our args for update-docker-route
# TODO: make these parameters instead of env vars
cols=( "$(route | grep ^0.0.0.0 | tr -s " " | cut -d ' ' -f '2 8')" )
route_vpn_gateway=${cols[0]}
dev=${cols[1]}
script_type='route-pre-down'

sudo -E ~/.openvpn/bin/update-docker-routes

openvpn3 session-manage -c default -D

# Docker sets up its DNS setting only at startup, so if the hosts DNS
# settings change (e.g., when disconnectint from VPN), you have to restart 
# docker to make it use the new settings
if systemctl is-active docker ; then
  sudo systemctl restart docker
fi
