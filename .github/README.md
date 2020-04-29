# Torrific Nginx
[heading__top]:
  #torrific-nginx
  "&#x2B06; Scripts to configure Nginx hidden service"


Scripts to configure Nginx hidden service

## [![Byte size of Torrific Nginx][badge__master__torrific_nginx__source_code]][torrific_nginx__master__source_code] [![Open Issues][badge__issues__torrific_nginx]][issues__torrific_nginx] [![Open Pull Requests][badge__pull_requests__torrific_nginx]][pull_requests__torrific_nginx] [![Latest commits][badge__commits__torrific_nginx__master]][commits__torrific_nginx__master]

------


- [:arrow_up: Top of Document][heading__top]

- [:building_construction: Requirements][heading__requirements]

- [:zap: Quick Start][heading__quick_start]

- [&#x1F5D2; Notes][heading__notes]

- [:card_index: Attribution][heading__attribution]

- [:balance_scale: Licensing][heading__license]


------

## Requirements
[heading__requirements]:
  #requirements
  "&#x1F3D7; Prerequisites and/or dependencies that this project needs to function properly"

This repository makes use of Git Submodules to track dependencies, to avoid incomplete downloads clone with the `--recurse-submodules` option...


```Bash
git clone --recurse-submodules git@github.com:paranoid-linux/torrific-nginx.git
```


To update tracked Git Submodules issue the following commands...


```Bash
git pull

git submodule update --init --merge --recursive
```


To force upgrade of Git Submodules...


```Bash
git submodule update --init --merge --recursive --remote
```


> Note, forcing and update of Git Submodule tracked dependencies may cause instabilities and/or merge conflicts; if however everything operates as expected after an update please consider submitting a Pull Request.


___


## Quick Start
[heading__quick_start]:
  #quick-start
  "&#9889; Perhaps as easy as one, 2.0,..."


Clone this project and the submodules that it depends upon...


```Bash
git clone --recurse-submodules git@github.com:paranoid-linux/torrific-nginx.git
```


Change current working directory...


```Bash
cd torrific-nginx
```


Use `-h` or `--help` option to list available command-line parameters...


```Bash
sudo ./torrific-nginx-server.sh --help
```


On the server configure Tor hidden service for Nginx via `torrific-nginx-server.sh` script...


```Bash
sudo ./torrific-nginx-server --torrc='/etc/tor/torrc'\
  --tor-lib-dir='/var/lib/tor'\
  --tor-port='80'\
  --service-port='8080'\
  hidden_service_name
```


Alternatively, setting up the server within a Docker container is possible via...


```Bash
docker run --name torrific-nginx\
  --tor-port='80'\
  --service-port='8080'\
  hidden_service_name
```


___


## Notes
[heading__notes]:
  #notes
  "&#x1F5D2; Additional things to keep in mind when developing"



Access to web-server can be restricted further via `--client` command-line parameter...


```Bash
## Server command

sudo ./torrific-nginx-server --torrc='/etc/tor/torrc'\
  --tor-lib-dir='/var/lib/tor'\
  --tor-port='80'\
  --service-port='8080'\
  --client='first-client,second-client,third-client'\
  hidden_service_name
```


... however, each **client** will then need to add `HidServAuth` to their torrc configuration **and** restart their Tor service, eg...


```Bash
## Client(s) command

sudo tee -a /etc/tor/torrc 1>/dev/null <<EOF
HidServAuth thegeneratedaddress.onion S0meLet7er5AndNumbers
EOF


sudo systemctl restart tor.service
```


... hint, when `--client` list is defined the service `hostname` file will contain authorizations for each listed client name...


```Bash
## Server commands

_tor_lib_dir='/var/lib/tor'
_service_name='hidden_service_name'


awk -v _client_names="first-client,second-client,third-client" '{
  split(_client_names, _names, ",")
  for (_key in _names) {
    if ($5 == _names[_key]) {
      print "HidServAuth", $1, $2, "#", $5
    } else {
      print "Cannot find", _names[_key], "within hidden service hostname file"
      exit 1
    }
  }
}' "${_tor_lib_dir}/${_service_name}/hostname"
```


------


Pull Requests are certainly welcomed if bugs are found or new features are wanted.


___


## Attribution
[heading__attribution]:
  #attribution
  "&#x1F4C7; Resources that where helpful in building this project so far."


- [GitHub -- `github-utilities/make-readme`](https://github.com/github-utilities/make-readme)

- [GitHub Gist -- `kremalicious/tor-hidden-service-host.sh`](https://gist.github.com/kremalicious/bd030dd79964f8f700f8272f03ec6af9)

- [GitHub -- `opsxcq/docker-tor-hiddenservice-nginx`](https://github.com/opsxcq/docker-tor-hiddenservice-nginx/blob/master/nginx.conf)


___


## License
[heading__license]:
  #license
  "&#x2696; Legal side of Open Source"


```
Scripts to configure Nginx hidden service
Copyright (C) 2020 S0AndS0

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

```


For further details review full length version of [AGPL-3.0][branch__current__license] License.



[branch__current__license]:
  /LICENSE
  "&#x2696; Full length version of AGPL-3.0 License"


[badge__commits__torrific_nginx__master]:
  https://img.shields.io/github/last-commit/paranoid-linux/torrific-nginx/master.svg

[commits__torrific_nginx__master]:
  https://github.com/paranoid-linux/torrific-nginx/commits/master
  "&#x1F4DD; History of changes on this branch"


[torrific_nginx__community]:
  https://github.com/paranoid-linux/torrific-nginx/community
  "&#x1F331; Dedicated to functioning code"


[issues__torrific_nginx]:
  https://github.com/paranoid-linux/torrific-nginx/issues
  "&#x2622; Search for and _bump_ existing issues or open new issues for project maintainer to address."

[pull_requests__torrific_nginx]:
  https://github.com/paranoid-linux/torrific-nginx/pulls
  "&#x1F3D7; Pull Request friendly, though please check the Community guidelines"

[torrific_nginx__master__source_code]:
  https://github.com/paranoid-linux/torrific-nginx/
  "&#x2328; Project source!"

[badge__issues__torrific_nginx]:
  https://img.shields.io/github/issues/paranoid-linux/torrific-nginx.svg

[badge__pull_requests__torrific_nginx]:
  https://img.shields.io/github/issues-pr/paranoid-linux/torrific-nginx.svg

[badge__master__torrific_nginx__source_code]:
  https://img.shields.io/github/repo-size/paranoid-linux/torrific-nginx
