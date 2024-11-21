+++
title = "A bunch of tips and a bag of tricks"
date = 2024-11-20T15:40:45+05:30
path = "tips-and-tricks"
[taxonomies]
tags = ["productivity"]
+++

This post will end up being non-linear which contains many of those small things which are referred from time to time but forgotten knowing we can search them later, however having a single place to look them up might be good, well at-least for me. Please note none of these should be used for critical systems and no liability assumed, here we go:

We can view the configuration parameter of current kernel at `/boot/config-$(uname -r)` to find whether a feature is compiled/supported on our machine. Openssl have commands to play with certificates and many security related options and often times if we are in a pinch to view the text output of certificates, we can do so by `openssl storeutl -noout -text -certs <bundle.crt>`.

During laptop refreshes we might want to transfer old data to new machine and netcat could be a good fit for it and yes there are superior tools to do the much, given two machines in same network or even same lan and netcat is good enough to transfer data over TCP:
```
Receiver: nc -l 9999 | pv | tar -xvf-
Sender:   tar -cvf * | pv | nc -w2 <receiver-host/ip> 9999
```

`pv` here is another program which visualizes progress and don't be tempted to transfer over UDP even if on same network, make sure your firewall allows the port.

There could be a possibility when network configuration is changed on servers, a refresh is necessary and we may get cut off over ssh if network is down. With a simple utility, ie, `at` we can set the job to run commands relative to the time, an example after configuring NetworkManager

```
# bring down the interface at 2min from now and bring it up after sleeping for 5 seconds
$ at now+2min
at> nmcli c down <iface>
at> sleep 5
at> nmcli c up <iface>
at> [control-D]
```

When a server has more than 1 NIC and DHCP is configured to provide a static IP based on MAC address we may not get same interface name assigned to the NIC after a restart due to enumeration of devices, additionally when we create a bridge on the NIC that may get an IP assigned by DHCP which can't be resolved in the local network.

To have a running service configured on bridge network which has more than 1 NIC be accessible in local network we can do:
``` sh
# 1. make the names of NIC interfaces static
> cat /etc/udev/rules.d/70-interface-names.rules
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="<MAC>", ATTR{type}=="1", NAME="eno1"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="<MAC>", ATTR{type}=="1", NAME="eno2"
[...]

# 2. create a network bond, here the `MAC` address is the one already configured at DHCP which gets a static IP
# this MAC address belongs to one of the NICs, YMMV with the bond.options
nmcli c add type bond con-name bond0 ifname bond0 802-3-ethernet.cloned-mac-address 'MAC' bond.options 'mode=balance-tlb,downdelay=0,miimon=100,updelay=0'
nmcli c mod <child> master bond0
nmcli c up <child>

# 3. create the bridge network (reusing the same MAC address)
nmcli c add type bridge con-name bridge0 ifname bridge0 bridge.mac-address 'MAC'
nmcli c mod <child> master bridge0
nmcli c up <child>
```

We are effectively making the MAC address configured at DHCP is surfaced from NIC to bond to bridge as in recent kernels the MAC address isn't reused and this may make Spanning Tree Protocol work a bit harder, you have been informed.

Most of the times, I keep SELinux up in servers, virtual machines and workstations alike and use Incus from time to time which provides base images with SELinux off, Incus provides a mechanism to exec, push/pull files from VMs for which an agent will be run on the VM but it may not work if SELinux is enforced, generating SEL rules for this agent didn't quite work for me and as I trust this process we can unconfine only this program which is a lot better than having SELinux disabled via:
``` ini
> cat /usr/lib/systemd/system/incus-agent.service;
[Unit]
Description=Incus - agent
Documentation=https://linuxcontainers.org/incus/docs/main/
Before=multi-user.target cloud-init.target cloud-init.service cloud-init-local.service
DefaultDependencies=no

[Service]
Type=notify
WorkingDirectory=-/run/incus_agent
ExecStartPre=/lib/systemd/incus-agent-setup
# ------- added -------- #
SELinuxContext=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
# ---------------------- #
ExecStart=/run/incus_agent/incus-agent
Restart=on-failure
RestartSec=5s
StartLimitInterval=60
StartLimitBurst=10
```

We turn gears to a usual pattern seen in networking connecting to corporate links, ie, VPN and Split DNS. NetworkManager dispatcher scripts can be setup to perform any operation based on events. All the scripts are provided what the event is and script can take any corresponding action, below are some useful examples and you can find more available [actions here](https://networkmanager.dev/docs/api/latest/NetworkManager-dispatcher.html).

1. Configure search domain when certain vpn is activated
``` sh
> cat /etc/NetworkManager/dispatcher.d/corp-vpn
#!/usr/bin/env bash

if [[ $2 != "vpn-up" ]]; then return 0; fi

uuid=$(nmcli -g name,uuid c s --active | grep "<NAME>" | awk -F: '{print $2}')
if [[ -z $uuid ]]; then return 0; fi

# modify if not done already
search=$(nmcli -f ipv4.dns-search c s $uuid | awk '{print $2}')
if [[ ! $search =~ 'lab' ]]; then nmcli c mod $uuid ipv4.dns-search "$search,<EXTRA_SEARCH_DOMAINS_SEP_BY_COMMA>"; fi
```

2. Split DNS with NetworkManager and dnsmasq
``` sh
# let dnsmasq be manag:xed by NetworkManager
> cat /etc/NetworkManager/conf.d/00-use-dnsmasq.conf
[main]
dns=dnsmasq

# inform dnsmasq any queries for a certain domain be resolved via different DNS
> cat /etc/NetworkManager/dnsmasq.d/00-custom.conf 
server=/<domain>/<dns-ip>
addn-hosts=/etc/hosts

# disable systemd-resolve and let NetworkManager dnsmasq plugin take over
sudo systemctl stop systemd-resolved.service
sudo systemctl disable systemd-resolved.service
sudo rm /etc/resolv.conf
sudo touch /etc/resolv.conf
sudo systemctl restart NetworkManager
```
That's good to an extent but above always tries to resolve the domain via configured DNS and it may not be available if we aren't not any VPN. Remember, you can club NetworkManager dispatcher script with custom DNS based on events and can achieve to resolve DNS based on which network is currently active.

3. Configure dnsmasq with systemd-networkd
There seems to be multiple technologies to configure networking and NetworkManager, systemd-networkd seems to be competing at that. I observed NetworkManager is suggested more for machines involving Wireless interfaces and systemd-networkd mostly for servers, I'll just go with it.

Configuring dnsmasq with NetworkManager is easy but it's hard to have it run with systemd-networkd and systemd-resolved. The idea is,
- Make resolved to query DNS via dnsmasq and set dnsmasq to serve only local queries
- Make dnsmasq not to use resolv.conf or /etc/hosts while resolving DNS to stop any cycles

``` sh
# dnsmasq config
> grep -E '^\w' /etc/dnsmasq.conf
user=dnsmasq
group=dnsmasq
local-service=host
conf-dir=/etc/dnsmasq.d,.rpmnew,.rpmsave,.rpmorig

# config for a custom domain
> cat /etc/dnsmasq.d/00-custom.conf 
no-resolv
no-hosts
server=/<domain>/<dns-ip>

# instruct resolved to use dnsmasq
> cat /etc/systemd/resolved.conf 
[Resolve]
DNS=127.0.0.1 # dnsmasq address
```

There are many tools to manage dotfiles with features to sync across multiple machines and at the same time, to start simple (and probably stay simple through out) we can use git bare repo to have the folder structure be reflected on the machine without any extra tools, below is [what I use](https://github.com/leelavg/dotfiles/blob/main/.starter.sh) for managing dotfiles. Please be careful when you add new files to the config, explicity mention the path and use `cfg add -u` for staging modified files.
``` sh
git clone --bare git@github.com:<repo> $HOME/.dot
function cfg {
  /usr/bin/git --git-dir=$HOME/.dot/ --work-tree=$HOME $@
}
cfg checkout 2>&1 | grep -E "\s+\." | awk {'print $1'} | xargs -I{} mv -f {} /tmp/
cfg checkout
cfg config status.showUntrackedFiles no
```

I daily drive tmux and below is helpful to have an indication if panes are synchronized
``` sh
# if panes are in sync the value will be "[host]" in red or else "host" in green
sync_pane="#{?pane_synchronized,#[fg=red][#{=10:host_short}],#[fg=green]#{=10:host_short}}"
# just position where we want the value
set -g status-right "${sync_pane}"
```

I [find ble.sh](https://github.com/akinomyoga/ble.sh) gives a new look and feel for bash shell, the line editor part, more importantly it doesn't slow you down. It is well documented for the features it supports and below is the config I use and the (foot) terminal uses gruvbox theme for reference.
``` sh
bind 'set completion-ignore-case on'
bind 'set visible-stats on'

ble-face auto_complete=fg=gray
ble-face region_insert=fg=gray
ble-face command_function=fg=magenta
ble-face vbell_erase=bg=240
ble-face menu_filter_input=bold
ble-face command_directory=fg=blue,underline
ble-face filename_directory=fg=blue,underline

bleopt filename_ls_colors="$LS_COLORS"
bleopt prompt_eol_mark=''
bleopt exec_errexit_mark=
bleopt exec_elapsed_mark=
bleopt exec_exit_mark=
bleopt edit_marker=
bleopt edit_marker_error=
bleopt history_erasedups_limit=
bleopt complete_menu_color=
```

We can end this post with configuring lsp for python, why should this even be part of this post? Because I found it hard to configure it correctly as I don't use vscode which has tight integration. Python configuration is also an issue as system depends on it and it'll be hard if our applications needs changes in system libraries as well.

I use virtualenvwrapper for managing python dependencies and versionfox for managing programming languages itself, I'll concentrate only on the former here. Virtualenvwrapper provides ability to add hooks when certain events happen, ie, run a script when env is activated or deactivated etc, certainly there are many [customizations available](https://virtualenvwrapper.readthedocs.io/en/latest/scripts.html). I believe procedure stay same for any other program of this nature as virtualenvwrapper only works for *nix systems.

The requirement is to share a single virtualenv with all supporting packages installed be shared with other virtualenvironments, think of sharing your lsp packages or those huge machine learning modules which can't be avoided in many lines of work these days.

``` sh
# file is in <virtualenvpath>/postactivate
#!/bin/bash
# This hook is sourced after every virtualenv is activated.

# do not run if the env is "lsp"
test x$(basename ${VIRTUAL_ENV}) = "xlsp" && return

# lsp venv doesn't exist
# (needs to be created manually first before using in any other virtualenv)
LSP_PY=$(dirname $VIRTUAL_ENV)/lsp/bin/python
test ! -e ${LSP_PY} && return

# add path of lsp site-packages to current env
add2virtualenv $(${LSP_PY} -c "import sysconfig; paths=sysconfig.get_paths(); print(paths.get('platlib'), paths.get('purelib'), sep='\n')")
```

``` sh
# file is in <virtualenvpath>/predeactivate
#!/bin/bash
# This hook is sourced before every virtualenv is deactivated.

rm -f $(virtualenvwrapper_get_site_packages_dir)/_virtualenv_path_extensions.pth
```

Once above is in place, install lsp related packages in the single virtualenv and configure your editor to invoke the lsp which is available from the virtualenv, here is the helix-editor config for reference
``` toml
[[language]]
name = "python"
language-servers = [ "pylsp" ]
auto-format = true

[language-server.pylsp]
# this is a custom script available in PATH
command = "pylsp-hx"

# plugins already bundles with pylsp
[language-server.pylsp.config.pylsp.plugins]
autopep8.enabled = false
flake8.enabled = false
jedi_symbols.include_import_symbols = false
jedi_completion.enabled = false
mccabe.enabled = false
preload.enabled = false
pycodestyle.enabled = false
pyflakes.enabled = false
pylint.enabled = false
rope_autoimport.enabled = true
rope_autoimport.completions.enabled= true
rope_autoimport.code_actions.enabled= true
rope_completion.enabled = true
yapf.enabled = false

# custom installed but can be made to use pylsp
[language-server.pylsp.config.ruff]
plugins.pyls_ruff.enabled = true
```
The custom script to start lsp is as below. Nevertheless, due to the nature of python I find it hard to configure it and many competing tools is not making it any easier. I hope the newer rust tools could provide a unified flow, at least in the tooling area.
``` sh
> cat .local/bin/pylsp-hx
#!/usr/bin/bash

test x${VIRTUAL_ENV} != x && ${VIRTUAL_ENV}/bin/python -m pylsp
```
