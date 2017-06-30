# OpenVPN server tuned for ChromeOS clients

## Overview

This is an extension of [kylemanna/openvpn](https://hub.docker.com/r/kylemanna/openvpn/) that
includes:

* tools to make it easy to configure your ChromeOS client to connect to this VPN
* some shortcuts to make initialization automatic
* Let's Encrypt certificates for the VPN server
* an instance of dnsmasq that serves up public DNS in addition to the contents of the containers
  `/etc/hosts` and `/etc/dnsmasq.d/extra-hosts`

## Project status

_This is not an official Google product._

This is experimental software, not feature complete, not security reviewed, ant not ready to do
anything except be a science experiment.

## How to use it

1. `cp sample.env .env` and edit it to include the right values for you.
1. Put your master CA password in ca_master_password.txt - or use another supported method for
   managing docker secrets.
1. Launch the openvpn service:
   ```docker-compose up -d openvpn```
1. Get the client info:
   ```docker-compose exec openvpn /asacamano/openvpn/openvpn.sh chromeos_client <client name>```
   The client name should be a single word, no spaces or special characters.
1. Find the `.onc` file that was generated - likely at:
   ```$ ls -l ${PWD}/runtime/c:q!etc/openvpn/client-config/<client name>/${PUBLIC_HOSTNAME}```
   Download it onto your chromeos device.
1. Install the files on chromeos. Open a the [net-internals](chrome://net-internals/#chromeos)
   tab, and click `Choose File` under `Import ONC file`.
    * If it succeeded, you will see `VPN Disconnected` in the settigns menu.
    * If it failed, open the [system](chrome://system) tab, and expand `Profile[0] chrome_user_log`
1. You need to supply a password to make ChromeOS happy - but it's not used on the server, do it
   can be anything you choose.
1. If you want to specify other "host" file entries - added them to `/etc/dnsmasq.d/extra-hosts`,
   observing the standard hosts file syntax `IP name [name...]`

## Why

* kylemanna/openvpn is a popular well-supported general OpenVPN docker image, so I started with it.
* Use Let's Encrypt so that you don't have to add another CA to your client. (If someone hacks
  your VPN, and it has a CA that you trust to identify servers, they could hack your VPN to hijack
  your connections to anyone else AND present a cert your browser will trust. I don't feel like a
  password on the CA key is safe enough, given the risk. Whereas if you use a public CA to issue
  the cert for your VPN, the hacker only gets to hack you VPN traffic, but not MITM all of your SSL
  connections.)
* Store the password for the CA in a docker secret - since the CA is only used to identify clients,
  a hacker with this password can connect to your VPN, which they can do with root access to the
  VPN host anyway.
* I set some default configuration to make it possible to send all traffic to the VPN so that one
  doesn't need to do extensive configuration to handle whatever IPs are behind the VPN - anything
  the VPN server can see, the clients can see.
* TODO: Since certbot needs to use port 443 (or another on a short list of popular ports) there needs to
  be some way to proxy traffic from this service port 443 to whatever the end user acutally wants
  to be listening on port 443 - so we need haproxy (ngxin, apache, monkey, lighthttpd etc don't
  proxy SSL wihtout termination)
* TODO: Since chromeos doesn't support scp, the client needs a quick and simple way to get a .onc file,
  which is monkey.

## How it works

* It wraps kylemanna/openvpn with some resonable defaults.
* This docker images uses [expect](http://expect.sourceforge.net/) to automate some of the manual
setup tasks in the base image.

## Debugging

* open-vpn options: --verb 6 or verb 6
* `netcat -ul 1194` on the server, `nc -4u -q1 1.2.3.4 1194` on the client to see what's happening.

## Roadmap

TODO:
* run cron in supervisord
* add a cron job to look for changes to the certs, and hup the VPN server when they change
* add a cron job to refresh certbot certs daily
