VPN installation and setup is not included with the rest of the tool setup because I dont always need it, and also because there are other places where this would be handy on its own without the rest of the stuff in this repo.
(I guess I could put this in its own repo)

I'm aware that Ubuntu jammy includes a vpn client, but I havent been able to get it to work with my OpenVpn server

Before you begin, you will need to fetch your OpenVPN profile and download it to a file name client.ovpn in your home directory.

To install, run the following command from $REPO_DIR/openvpn:
```./install-vpn.sh```

Note that the installer will make a copy your client.ovpn file, so you can remove it from your home directory once the installation is complete.

At this point, openvpn connect client is installed and you should be able to establish a vpn connection with (you may need to restart you shell to get the .openvpn/bin directory added to your path):

```start-vpn.sh```

To disconnect from vpn, run:

```stop-vpn.sh```



Depending on how your vpn server is configured, you may have issues with docker being able to allocate subnets.  We attempt to take care of this, but it's best to verfiy you can run containers while connected to vpn before deciding you're finished with vpn setup.