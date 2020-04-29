#!/usr/bin/env bash


## Exit if not running with root/level permissions
if [[ "${EUID}" != '0' ]]; then echo "Try: sudo ${0##*/} ${@:---help}"; exit 1; fi


#
#    Set defaults for script variables; some of which maybe overwritten
#
## Find true directory this script resides in
__SOURCE__="${BASH_SOURCE[0]}"
while [[ -h "${__SOURCE__}" ]]; do
    __SOURCE__="$(find "${__SOURCE__}" -type l -ls | sed -n 's@^.* -> \(.*\)@\1@p')"
done
__DIR__="$(cd -P "$(dirname "${__SOURCE__}")" && pwd)"
__NAME__="${__SOURCE__##*/}"
__AUTHOR__='S0AndS0'
__DESCRIPTION__='Configures Nginx hidden service'

_torrc_path='/etc/tor/torrc'
_tor_lib_dir='/var/lib/tor'
_tor_port='80'
_service_dir='/etc/nginx'
_service_name='nginx_server'
_service_port='8080'
_client_names=''
_service_wrtie_global_configs='0'
_clobber='0'



#
#    Source modules
#
## Provides: 'falure' <line-number> <command> exit-code
source "${__DIR__}/modules/trap-failure/failure.sh"
trap 'failure "LINENO" "BASH_LINENO" "${BASH_COMMAND}" "${?}"' ERR

## Provides:  'argument_parser <ref_to_allowed_args> <ref_to_user_supplied_args>'
source "${__DIR__}/modules/argument-parser/argument-parser.sh"


#
#    Functions that organize this script
#


license(){
    local _date="$(date +'%Y')"
    cat <<EOF
# ${__DESCRIPTION__}
# Copyright (C) ${_date:-2020}  ${__AUTHOR__}
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation; version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
EOF
}


usage(){
    cat <<EOF
${__DESCRIPTION__}

  -e    --examples
Prints example usage and exits

  -h    --help
Prints this message and exits

  -n    --notes
Prints notes about Tor configurations and script options then exits

  -l    --license
Shows script or project license and exits

  --torrc-path    --torrc=${_torrc_path}
Path to torrc configuration file.
Linux default path is usually...
    /etc/tor/torrc
MacOS default path may be...
    /usr/local/etc/tor/torrc

  --tor-lib-dir     --tor-lib    --lib-dir=${_tor_lib_dir}
Path to Tor hidden services directory

  --tor-port        --virt-port=${_tor_port}
Port number Tor listens on and forwards to '--service-port'

  --service-dir=${_service_dir}
Where 'sites-available' and 'sites-enabled' directories are found

  --service-port    --target-port=${_service_port}
Port service listens on and is forwarded to from '--tor-port'

  --service-write-global-configs  --write-global-configs  --global-configs
Write/overwrite '${_service_dir}/nginx.conf' global configurations

  --client-names    --clients=${_client_names:-lamb,spam}
Optional, comma seperated list of authorized clients

  --clobber
Overwrite existing files instead of throwing errors

> Note, '--clobber' has no effect for operations that append to files

  ${_service_name}
Directory name for service under '--tor-lib-dir'
EOF
}


examples(){
  cat <<EOF
## 0. Run script to append configurations and restart services
sudo ${__NAME__} --torrc='/etc/tor/torrc'\\
  --tor-lib-dir='/var/lib/tor'\\
  --tor-port='80'\\
  --service-port='8080'\\
  nginx_server


## 1. Alternatively run script within Docker container
docker run --torrc='/etc/tor/torrc'\\
  --tor-lib-dir='/var/lib/tor'\\
  --tor-port='80'\\
  --service-port='8080'\\
  --service-write-global-configs\\
  nginx_server
EOF
}


## Pass arrays by reference/name to the `argument_parser` function
_passed_args=("${@:?No arguments provided}")
_acceptable_args=(
    '--examples|-e:bool'
    '--help|-h:bool'
    '--license|-l:bool'
    '--notes|-n:bool'
    '--torrc-path|--torrc:path'
    '--tor-lib-dir|--tor-lib|--lib-dir:path'
    '--tor-port|--virt-port:alpha_numeric'
    '--service-dir:path'
    '--service-port|--target-port:alpha_numeric'
    '--service-write-global-configs|--write-global-configs|--global-configs:bool'
    '--client-names|--clients|--client:list'
    '--clobber:bool'
    '--service-name:posix-nil'
)
argument_parser '_passed_args' '_acceptable_args'
_exit_status="$?"


## Print documentation for the script and exit, or allow further execution
if ((_help)) || ((_exit_status)); then
    usage
    exit "${_exit_status:-0}"
elif ((_examples)); then
    examples
    exit "${_exit_status:-0}"
elif ((_license)); then
    license
    exit "${_exit_status:-0}"
# elif ((_notes)); then
#     notes
#     exit "${_exit_status:-0}"
# elif ! ((${#_client_names})); then
#   printf >&2 'Missing required parameter(s), please review usage before trying again...\n'
#   usage
#   exit "1"
fi


#
#    Do the things if exiting has not happened yet
#
[[ -f "${_torrc_path}" ]] || {
   printf >&2 'No torrc configuration file found at -> %s\n' "${_torrc_path}"
   exit 1
}


[[ -d "${_service_dir}" ]] || {
  printf >&2 'No service directory found at -> %s\n' "${_service_dir}"
  exit 1
}


read -r -d '' _torrc_config_block <<EOF
HiddenServiceDir ${_tor_lib_dir}/${_service_name}
HiddenServicePort ${_tor_port} 127.0.0.1 ${_service_port}
EOF

[[ "$(grep -q "${_torrc_config_block}" "${_torrc_path}")" ]] && {
  printf >&2 'Configuration may already exist for %s within -> \n' "${_service_name}" "${_torrc_path}"
  ((_clobber)) || {
    exit 1
  }
}

(("${#_client_names}")) && {
  read -r -d '' _torrc_config_block <<EOF
${_torrc_config_block}
HiddenServiceAuthorizeClient stealth ${_client_names}
EOF
}

tee -a "${_torrc_path}" <<<"${_torrc_config_block}"

systemctl restart tor.service || {
    printf >&2 'Cannot restart Tor service\n'
    exit ${?:-1}
}


[[ -f "${_tor_lib_dir}/${_service_name}/hostname" ]] && {
  (("${#_client_names}")) && {
    awk -v _client_names="${_client_names}" '{
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
  }

  _onion_domain="$(
    awk '{
      if ($1 ~ "onion") {
        print $1
        exit 0
      }
      exit 1
    }' "${_tor_lib_dir}/${_service_name}/hostname"
  )"
} || {
  printf >&2 'Cannot find hidden service hostname file -> %s/hostname\n' "${_tor_lib_dir}/${_service_name}"
  exit ${?:-1}
}


(("${#_onion_domain}")) || {
  printf >&2 'Cannot read Onion domain from hostname file -> %s\n' "${_tor_lib_dir}/${_service_name}/hostname"
  exit 1
}


[[ -f "${_service_dir}/sites-available/${_service_name}" ]] && {
  printf >&2 'Service configuration file already exists -> %s\n' "${_service_name}"
  ((_clobber)) || {
    exit 1
  }
}


tee -a "${_service_dir}/sites-available/${_service_name}" 1>/dev/null <<EOF
server {
  listen 127.0.0.1:${_service_port};
  root /var/www/${_service_name}/;
  index index.html index.htm;
  server_name ${_onion_domain};
}
EOF

ln -s "${_service_dir}/sites-available/${_service_name}.onion" "${_service_dir}/sites-enabled/${_service_name}.onion"


((_service_wrtie_global_configs)) && {
  [[ -f "${_service_dir}/nginx.conf" ]] && {
    printf >&2 'Server global configuration file already exists -> %s\n' "${_service_dir}/nginx.conf"
    ((_clobber)) || {
      exit 1
    }
  }
  tee -a "${_service_dir}/nginx.conf" 1>/dev/null <<EOF
user www-data;
worker_processes 4;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;


events {
	worker_connections 768;
}


http {
  ## Basic Settings
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
  server_tokens off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;


  ## SSL Settings
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	ssl_prefer_server_ciphers on;


  ## Gzip Settings
	gzip on;
	gzip_disable "msie6";


	## Virtual Host Configs
	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}
EOF
}



systemctl restart nginx.service || {
    printf >&2 'Cannot restart Tor service\n'
    exit ${?:-1}
}
