**NOTICE**

This image was updated for rtorrent from https://github.com/stickz/rtorrent.
IRSSI is removed because there are bugs with the newest rutorrent.  Use Autobrr instead.
Hack job of a docker.  Use at your own risk. 

No testing has been done with openVPN or Privoxy.

**Application**

[rTorrent-ps](https://github.com/pyroscope/rtorrent-ps)<br/>
[ruTorrent](https://github.com/Novik/ruTorrent)<br/>
[Privoxy](http://www.privoxy.org/)<br/>
[OpenVPN](https://openvpn.net/)<br/>
[WireGuard](https://www.wireguard.com/)

**Description**

rTorrent is a quick and efficient BitTorrent client that uses, and is in development alongside, the libTorrent (not to be confused with libtorrent-rasterbar) library. It is written in C++ and uses the ncurses programming library, which means it uses a text user interface. When combined with a terminal multiplexer (e.g. GNU Screen or Tmux) and Secure Shell, it becomes a convenient remote BitTorrent client, this Docker image includes the popular ruTorrent web frontend to rTorrent for ease of use.<br/>

This Docker includes OpenVPN and WireGuard to ensure a secure and private connection to the Internet, including use of iptables to prevent IP leakage when the tunnel is down. It also includes Privoxy to allow unfiltered access to index sites, to use Privoxy please point your application at `http://<host ip>:8118`.

**Build notes**

Latest stable rTorrent-ps release from Arch Linux AUR.<br/>
Latest stable ruTorrent release from Arch Linux AUR.<br/>
Latest stable Privoxy release from Arch Linux repo.<br/>
Latest stable OpenVPN release from Arch Linux repo.<br/>
Latest stable WireGuard release from Arch Linux repo.

**!!! IMPORTANT !!!**

As from 15th of January 2020, if the web ui and/or rpc2 password have not been defined (defined via environment variables) then the password(s) will be randomised and no longer set to 'rutorrent'.

Please see link below to the rtorrentvpn FAQ, Q3. and Q4. for more details:-
https://github.com/binhex/documentation/blob/master/docker/faq/rtorrentvpn.md

**Usage**
```
docker run -d \
    --cap-add=NET_ADMIN \
    -p 9080:9080 \
    -p 9443:9443 \
    -p 8118:8118 \
    --name=<container name> \
    -v <path for data files>:/data \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=<yes|no> \
    -e VPN_USER=<vpn username> \
    -e VPN_PASS=<vpn password> \
    -e VPN_PROV=<pia|airvpn|custom> \
    -e VPN_CLIENT=<openvpn|wireguard> \
    -e VPN_OPTIONS=<additional openvpn cli options> \
    -e STRICT_PORT_FORWARD=<yes|no> \
    -e ENABLE_PRIVOXY=<yes|no> \
    -e ENABLE_AUTODL_IRSSI=<yes|no> \
    -e ENABLE_RPC2=<yes|no> \
    -e ENABLE_RPC2_AUTH=<yes|no> \
    -e ENABLE_WEBUI_AUTH=<yes|no> \
    -e RPC2_USER=<rpc2 username> \
    -e RPC2_PASS=<rpc2 password> \
    -e WEBUI_USER=<webui username> \
    -e WEBUI_PASS=<webui password> \
    -e LAN_NETWORK=<lan ipv4 network>/<cidr notation> \
    -e NAME_SERVERS=<name server ip(s)> \
    -e VPN_INPUT_PORTS=<port number(s)> \
    -e VPN_OUTPUT_PORTS=<port number(s)> \
    -e DEBUG=<true|false> \
    -e PHP_TZ=<php timezone> \
    -e UMASK=<umask for created files> \
    -e PUID=<uid for user> \
    -e PGID=<gid for user> \
    binhex/arch-rtorrentvpn
```
&nbsp;
Please replace all user variables in the above command defined by <> with the correct values.

**Access ruTorrent (web ui)**

`http://<host ip>:9080/`

or

`https://<host ip>:9443/`

Username:- Value of 'WEBUI_USER'<br/>
Password:- Value of 'WEBUI_PASS'

**Access Privoxy**

`http://<host ip>:8118`

**PIA example**
```
docker run -d \
    --cap-add=NET_ADMIN \
    -p 9080:9080 \
    -p 9443:9443 \
    -p 8118:8118 \
    --name=rtorrentvpn \
    -v /root/docker/data:/data \
    -v /root/docker/config:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=yes \
    -e VPN_USER=myusername \
    -e VPN_PASS=mypassword \
    -e VPN_PROV=pia \
    -e VPN_CLIENT=openvpn \
    -e STRICT_PORT_FORWARD=yes \
    -e ENABLE_PRIVOXY=yes \
    -e ENABLE_AUTODL_IRSSI=yes \
    -e ENABLE_RPC2=yes \
    -e ENABLE_RPC2_AUTH=yes \
    -e ENABLE_WEBUI_AUTH=yes \
    -e RPC2_USER=admin \
    -e RPC2_PASS=NzRhMjE4NjUzZDYw \
    -e WEBUI_USER=admin \
    -e WEBUI_PASS=NzRhMjE4NjUzZDYw \
    -e LAN_NETWORK=192.168.1.0/24 \
    -e NAME_SERVERS=84.200.69.80,37.235.1.174,1.1.1.1,37.235.1.177,84.200.70.40,1.0.0.1 \
    -e VPN_INPUT_PORTS=1234 \
    -e VPN_OUTPUT_PORTS=5678 \
    -e DEBUG=false \
    -e PHP_TZ=UTC \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-rtorrentvpn
```
&nbsp;
**AirVPN provider**

AirVPN users will need to generate a unique OpenVPN configuration file by using the following link https://airvpn.org/generator/

1. Please select Linux and then choose the country you want to connect to
2. Save the ovpn file to somewhere safe
3. Start the rtorrentvpn docker to create the folder structure
4. Stop rtorrentvpn docker and copy the saved ovpn file to the /config/openvpn/ folder on the host
5. Start rtorrentvpn docker
6. Check supervisor.log to make sure you are connected to the tunnel

AirVPN users will also need to create a port forward by using the following link https://airvpn.org/ports/ and clicking Add. This port will need to be specified in the rTorrent-ps configuration file located at /config/rtorrent/config/rtorrent.rc with the option `port_range = <start incoming port>-<end incoming port>` and `port_random = no`.

rTorrent-ps example config
```
port_range = 49400-49400
port_random = no
```
&nbsp;
**AirVPN example**
```
docker run -d \
    --cap-add=NET_ADMIN \
    -p 9080:9080 \
    -p 9443:9443 \
    -p 8118:8118 \
    --name=rtorrentvpn \
    -v /root/docker/data:/data \
    -v /root/docker/config:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=yes \
    -e VPN_PROV=airvpn \
    -e VPN_CLIENT=openvpn \
    -e ENABLE_PRIVOXY=yes \
    -e ENABLE_AUTODL_IRSSI=yes \
    -e ENABLE_RPC2=yes \
    -e ENABLE_RPC2_AUTH=yes \
    -e ENABLE_WEBUI_AUTH=yes \
    -e RPC2_USER=admin \
    -e RPC2_PASS=NzRhMjE4NjUzZDYw \
    -e WEBUI_USER=admin \
    -e WEBUI_PASS=NzRhMjE4NjUzZDYw \
    -e LAN_NETWORK=192.168.1.0/24 \
    -e NAME_SERVERS=84.200.69.80,37.235.1.174,1.1.1.1,37.235.1.177,84.200.70.40,1.0.0.1 \
    -e VPN_INPUT_PORTS=1234 \
    -e VPN_OUTPUT_PORTS=5678 \
    -e DEBUG=false \
    -e PHP_TZ=UTC \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-rtorrentvpn
```
&nbsp;

**IMPORTANT**<br/>
Please note 'VPN_INPUT_PORTS' is **NOT** to define the incoming port for the VPN, this environment variable is used to define port(s) you want to allow in to the VPN network when network binding multiple containers together, configuring this incorrectly with the VPN provider assigned incoming port COULD result in IP leakage, you have been warned!.

**OpenVPN**<br/>
Please note this Docker image does not include the required OpenVPN configuration file and certificates. These will typically be downloaded from your VPN providers website (look for OpenVPN configuration files), and generally are zipped.

PIA users - The URL to download the OpenVPN configuration files and certs is:-

https://www.privateinternetaccess.com/openvpn/openvpn.zip

Once you have downloaded the zip (normally a zip as they contain multiple ovpn files) then extract it to /config/openvpn/ folder (if that folder doesn't exist then start and stop the docker container to force the creation of the folder).

If there are multiple ovpn files then please delete the ones you don't want to use (normally filename follows location of the endpoint) leaving just a single ovpn file and the certificates referenced in the ovpn file (certificates will normally have a crt and/or pem extension).

**WireGuard**<br/>
If you wish to use WireGuard (defined via 'VPN_CLIENT' env var value ) then due to the enhanced security and kernel integration WireGuard will require the container to be defined with privileged permissions and sysctl support, so please ensure you change the following docker options:-  <br/>

from
```
    --cap-add=NET_ADMIN \
```
to
```
    --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
    --privileged=true \
```

PIA users - The WireGuard configuration file will be auto generated and will be stored in ```/config/wireguard/wg0.conf``` AFTER the first run, if you wish to change the endpoint you are connecting to then change the ```Endpoint``` line in the config file (default is Netherlands).

Other users - Please download your WireGuard configuration file from your VPN provider, start and stop the container to generate the folder ```/config/wireguard/``` and then place your WireGuard configuration file in there.

**Notes**<br/>
Due to Google and OpenDNS supporting EDNS Client Subnet it is recommended NOT to use either of these NS providers.
The list of default NS providers in the above example(s) is as follows:-

84.200.x.x = DNS Watch
37.235.x.x = FreeDNS
1.x.x.x = Cloudflare

User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

`id <username>`

If you want to create an additional user account for ruTorrent webui then please execute the following on the host:-

`docker exec -it <container name> /home/nobody/createuser.sh <username to create> <password for the user>`

If you want to delete a user account (or change the password for an account) then please execute the following on the host:-

`docker exec -it <container name> /home/nobody/deluser.sh <username to delete>`

If you do not define the PHP timezone you may see issues with the ruTorrent Scheduler plugin, please make sure you set the PHP timezone by specifying this using the environment variable PHP_TZ. Valid timezone values can be found here, http://php.net/manual/en/timezones.php
___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Documentation](https://github.com/binhex/documentation) | [Support forum](http://forums.unraid.net/index.php?topic=47832.0)
