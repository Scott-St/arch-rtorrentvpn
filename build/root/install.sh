#!/bin/bash

# exit script if return code != 0
set -e

# release tag name from build arg, stripped of build ver using string manipulation
release_tag_name="${1//-[0-9][0-9]/}"

# custom
####

mkdir /home/nobody/bin/


# pacman packages
####

# Update all packages
pacman -Syu


# define pacman packages
pacman_packages="svn git nginx php-fpm rsync openssl tmux mediainfo php-geoip zip libx264 libvpx xmlrpc-c sox python-pip"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi


# rTorrent Install
#
#

# Create build directory
mkdir ~/build

# Build and install libudns
cd ~/build && git clone https://github.com/shadowsocks/libudns
cd libudns
./autogen.sh
./configure --prefix=/usr
make -j$(nproc) CFLAGS="-O3 -fPIC"
make -j$(nproc) install

# Clone libtorrent & rtorrent stickz repo
cd ~/build && git clone https://github.com/stickz/rtorrent/

# Build and install libtorrent
cd ~/build/rtorrent/libtorrent
./autogen.sh
./configure --prefix=/usr --enable-aligned --enable-hosted-mode --enable-udns
make -j$(nproc) CXXFLAGS="-O3 -flto=\"$(nproc)\" -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing"
make install

# Build and install rtorrent
cd ~/build/rtorrent/rtorrent
./autogen.sh
./configure --prefix=/usr --with-xmlrpc-tinyxml2
make -j$(nproc) CXXFLAGS="-O3 -flto=\"$(nproc)\" -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing"
make install

# Remove build directory
rm -rf ~/build

# # Installing UDNS
# #
# cd /tmp
# git clone https://github.com/shadowsocks/libudns;
# cd libudns;
# ./autogen.sh;
# ./configure --prefix=/usr;
# make -j$(nproc) CFLAGS="-O3 -fPIC";
# make -j$(nproc) install;
# cd /tmp;
# rm -R libudns;

# # Installing xmlrpc-c
# #

# #advanced - v1.63.xx (recommended for home users)
# svn checkout svn://svn.code.sf.net/p/xmlrpc-c/code/advanced xmlrpc-c_advanced;
# cd xmlrpc-c_advanced;

# ./configure --prefix=/usr --disable-cplusplus --disable-wininet-client --disable-libwww-client --disable-abyss-server --disable-cgi-server;
# make -j$(nproc) CFLAGS="-O3";
# make -j$(nproc) install;
# cd /tmp;
# rm -R xmlrpc-c_advanced;

# # Installing libtorrent
# #
# # We strongly advise to configure with aligned memory access (--enable-aligned) to avoid critical stability issues.
# #
# #We recommend to configure with instrumentation disabled (--disable-instrumentation) to improve performance. This feature has been fixed since version 5.3.
# #
# #We recommend to configure with UDNS enabled (--enable-udns) to improve stability and performance of UDP trackers. This feature is stable as of version 6.0.
# #
# # We do not recommend using file preload. It's better to leave this decision to the Linux Kernel. 
# # You can reduce the overhead of the peer connection protocol, by disabling it entirely at compile time with (--enable-hosted-mode). 
# # If pieces.preload.type is changed from ruTorrent or .rtorrent.rc it will accept the value and ignore it for 100% backwards compatibility.

# git clone https://github.com/stickz/rtorrent stickz-rtorrent;
# cd stickz-rtorrent/libtorrent;
# ./autogen.sh;\
# ./configure --prefix=/usr --enable-aligned --enable-hosted-mode --disable-instrumentation --enable-udns;\
# make -j$(nproc) CXXFLAGS="-O3";\
# make -j$(nproc) install;


# # Installing rTorrent
# #

# cd ../rtorrent;\
# ./autogen.sh;\
# ./configure --prefix=/usr --with-xmlrpc-c --with-ncurses;\
# make -j$(nproc) CXXFLAGS="-O3";\
# make -j$(nproc) install;
# cd /tmp;
# rm -R stickz-rtorrent;

cd ~/;

# Done rTorrent install

# set tmux to use 256 colors (required by rtorrent-ps)
echo 'set -g default-terminal "screen-256color"' > /home/nobody/.tmux.conf

ffmpeg_package_name="ffmpeg-release-static.tar.xz"

# download statically linked ffmpeg (used by rutorrent screenshots plugin)
rcurl.sh -o "/tmp/${ffmpeg_package_name}" "https://dev.scne.xyz/packages/${ffmpeg_package_name}"

# unpack and move binaries
mkdir -p "/tmp/unpack" && tar -xvf "/tmp/${ffmpeg_package_name}" -C "/tmp/unpack"
mv /tmp/unpack/ffmpeg*/ff* "/usr/bin/"


# custom
####

# rutorrent
# v5.1.5-hotfix
rutorrent_package_name="v5.1.5.zip"

rcurl.sh -o "/tmp/${rutorrent_package_name}" "https://github.com/Novik/ruTorrent/archive/refs/tags/${rutorrent_package_name}"
unzip "/tmp/${rutorrent_package_name}" -d /tmp/
mkdir -p /usr/share/webapps/rutorrent
mv /tmp/ruTorrent-*/* /usr/share/webapps/rutorrent

# rutorrent plugin cloudflare requires python module 'cloudscraper', use pip to install (python-pip = python 3.x)
pip install --break-system-packages  --ignore-installed cloudscraper

# Pyrocore - new package pyrosimple
####
pip install --break-system-packages pyrosimple

# download htpasswd (problems with apache-tools and openssl 1.1.x)
rcurl.sh -o /tmp/htpasswd.tar.gz "https://dev.scne.xyz/packages/htpasswd.tar.gz"

# extract compiled version of htpasswd
tar -xvf /tmp/htpasswd.tar.gz -C /

# Dumptorrent - Plugin Requirement
github.sh --install-path "/usr/bin" --github-owner "TheGoblinHero" --github-repo "dumptorrent" --compile-src make


# config - nginx
####

# due to 'fs.protected_hardlinks = 1' being potentially set we need to grant user 'nobody' rwx for the
# file '/usr/bin/nginx' in order to permit hard linking (fix for synology users).
# see here for details:-
# https://unix.stackexchange.com/questions/233275/hard-link-creation-permissions
chmod 777 /usr/bin/nginx


# config - php
####

php_ini="/etc/php/php.ini"

# configure php memory limit to improve performance
sed -i -e "s~.*memory_limit\s\=\s.*~memory_limit = 768M~g" "${php_ini}"

# configure php max execution time to try and prevent timeout issues
sed -i -e "s~.*max_execution_time\s\=\s.*~max_execution_time = 300~g" "${php_ini}"

# configure php max file uploads to prevent issues with reaching limit of upload count
sed -i -e "s~.*max_file_uploads\s\=\s.*~max_file_uploads = 200~g" "${php_ini}"

# configure php max input variables (get/post/cookies) to prevent warnings issued
sed -i -e "s~.*max_input_vars\s\=\s.*~max_input_vars = 10000~g" "${php_ini}"

# configure php upload max filesize to prevent large torrent files failing to upload
sed -i -e "s~.*upload_max_filesize\s\=\s.*~upload_max_filesize = 20M~g" "${php_ini}"

# configure php post max size (linked to upload max filesize)
sed -i -e "s~.*post_max_size\s\=\s.*~post_max_size = 25M~g" "${php_ini}"

# configure php with additional php-geoip module
sed -i -e "/.*extension=gd/a extension=geoip" "${php_ini}"


# configure php to enable sockets module (used for autodl-irssi plugin)
#sed -i -e "s~.*extension=sockets~extension=sockets~g" "${php_ini}"

# configure php-fpm to use tcp/ip connection for listener
php_fpm_ini="/etc/php/php-fpm.conf"

echo "" >> "${php_fpm_ini}"
echo "; Set php-fpm to use tcp/ip connection" >> "${php_fpm_ini}"
echo "listen = 127.0.0.1:7777" >> "${php_fpm_ini}"

# configure php-fpm listener for user nobody, group users
echo "" >> "${php_fpm_ini}"
echo "; Specify user listener owner" >> "${php_fpm_ini}"
echo "listen.owner = nobody" >> "${php_fpm_ini}"
echo "" >> "${php_fpm_ini}"
echo "; Specify user listener group" >> "${php_fpm_ini}"
echo "listen.group = users" >> "${php_fpm_ini}"

# config - rutorrent
####

# define path variables
rutorrent_root_path="/usr/share/webapps/rutorrent"
rutorrent_config_path="${rutorrent_root_path}/conf"
rutorrent_plugins_path="${rutorrent_root_path}/plugins"

# remove external applications section from default config.php
# note this removes the lines between the patterns but not the
# pattern itself, as this is then used as an anchor for the
# re-insertion of the defined section (see next block).
sed -i '/$pathToExternals = array(/,/);/{//!d}' "${rutorrent_config_path}/config.php"

# defines paths to external applications in default config.php
# this uses the pattern as an anchor point from the previous
# command
# note the use of single quoted string to reduce escaping,
# also note the use of unicode hex char '\x27' which is a
# single quote, required as escaping a single quote in a
# single quoted string is tricky.
sed -i 's~$pathToExternals = array(.*~$pathToExternals = array(\
                "php"           => \x27/usr/bin/php\x27,              // Something like /usr/bin/php. If empty, will be found in PATH.\
                "curl"          => \x27/usr/bin/curl\x27,             // Something like /usr/bin/curl. If empty, will be found in PATH.\
                "gzip"          => \x27/usr/bin/gzip\x27,             // Something like /usr/bin/gzip. If empty, will be found in PATH.\
                "id"            => \x27/usr/bin/id\x27,               // Something like /usr/bin/id. If empty, will be found in PATH.\
                "python"        => \x27/usr/bin/python\x27,           // Something like /usr/bin/python. If empty, will be found in PATH.\
                "pgrep"         => \x27/usr/bin/pgrep\x27,            // Something like /usr/bin/pgrep. If empty, will be found in PATH.\
                "sox"           => \x27/usr/bin/sox\x27,              // Something like /usr/bin/sox. If empty, will be found in PATH.\
                "stat"          => \x27/usr/bin/stat\x27,             // Something like /usr/bin/stat. If empty, will be found in PATH.~g' "${rutorrent_config_path}/config.php"

# increase rpc timeout from 5 seconds (default) for rutorrent, as large number of torrents can mean we exceed the 5 second period
sed -i -r "s~'RPC_TIME_OUT', [0-9]+,~'RPC_TIME_OUT', 60,~g" "${rutorrent_config_path}/config.php"

# set the rutorrent autotools/autowatch plugin to 30 secs scan time, default is 300 secs
sed -i -e "s~\$autowatch_interval \= 300\;~\$autowatch_interval \= 30\;~g" "${rutorrent_plugins_path}/autotools/conf.php"

# set the rutorrent schedulder plugin to 10 mins, default is 60 mins
sed -i -e "s~\$updateInterval \= 60\;~\$updateInterval \= 10\;~g" "${rutorrent_plugins_path}/scheduler/conf.php"

# set the rutorrent diskspace plugin to point at the /data volume mapping, default is /
sed -i -e "s~\$partitionDirectory \= \&\$topDirectory\;~\$partitionDirectory \= \"/data\";~g" "${rutorrent_plugins_path}/diskspace/conf.php"

# delme - hack to remove test -x, as this is causing plugin failure for certain users (cannot reproduce at present)
sed -i -e 's~test -x.*&&\s~~g' '/usr/share/webapps/rutorrent/php/test.sh'
# /delme


# container perms
####

# define comma separated list of paths
install_paths="/usr/share/webapps,/usr/share/nginx/html,/etc/nginx,/etc/php,/run/php-fpm,/var/lib/nginx,/var/log/nginx,/etc/privoxy,/home/nobody"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 ${install_paths}

# create file with contents of here doc, note EOF is NOT quoted to allow us to expand current variable 'install_paths'
# we use escaping to prevent variable expansion for PUID and PGID, as we want these expanded at runtime of init.sh
cat <<EOF > /tmp/permissions_heredoc

# get previous puid/pgid (if first run then will be empty string)
previous_puid=\$(cat "/root/puid" 2>/dev/null || true)
previous_pgid=\$(cat "/root/pgid" 2>/dev/null || true)

# if first run (no puid or pgid files in /tmp) or the PUID or PGID env vars are different
# from the previous run then re-apply chown with current PUID and PGID values.
if [[ ! -f "/root/puid" || ! -f "/root/pgid" || "\${previous_puid}" != "\${PUID}" || "\${previous_pgid}" != "\${PGID}" ]]; then

	# set permissions inside container - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
	chown -R "\${PUID}":"\${PGID}" ${install_paths}

fi

# write out current PUID and PGID to files in /root (used to compare on next run)
echo "\${PUID}" > /root/puid
echo "\${PGID}" > /root/pgid

EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /usr/local/bin/init.sh
rm /tmp/permissions_heredoc

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc

export ENABLE_RPC2=$(echo "${ENABLE_RPC2}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${ENABLE_RPC2}" ]]; then
	echo "[info] ENABLE_RPC2 defined as '${ENABLE_RPC2}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] ENABLE_RPC2 not defined (via -e ENABLE_RPC2), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
	export ENABLE_RPC2="yes"
fi

if [[ "${ENABLE_RPC2}" == "yes" ]]; then
	export ENABLE_RPC2_AUTH=$(echo "${ENABLE_RPC2_AUTH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${ENABLE_RPC2_AUTH}" ]]; then
		echo "[info] ENABLE_RPC2_AUTH defined as '${ENABLE_RPC2_AUTH}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] ENABLE_RPC2_AUTH not defined (via -e ENABLE_RPC2_AUTH), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
		export ENABLE_RPC2_AUTH="yes"
	fi

	if [[ "${ENABLE_RPC2_AUTH}" == "yes" ]]; then
		export RPC2_USER=$(echo "${RPC2_USER}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${RPC2_USER}" ]]; then
			echo "[info] RPC2_USER defined as '${RPC2_USER}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] RPC2_USER not defined (via -e RPC2_USER), defaulting to 'admin'" | ts '%Y-%m-%d %H:%M:%.S'
			export RPC2_USER="admin"
		fi

		export RPC2_PASS=$(echo "${RPC2_PASS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${RPC2_PASS}" ]]; then
			if [[ "${RPC2_PASS}" == "rutorrent" ]]; then
				echo "[warn] RPC2_PASS defined as '${RPC2_PASS}' is weak, please consider using a stronger password" | ts '%Y-%m-%d %H:%M:%.S'
			else
				echo "[info] RPC2_PASS defined as '${RPC2_PASS}'" | ts '%Y-%m-%d %H:%M:%.S'
			fi
		else
			mkdir -p "/config/nginx/security"
			rpc2_pass_file="/config/nginx/security/rpc2_pass"
			if [ ! -f "${rpc2_pass_file}" ]; then
				# generate random password for web ui using SHA to hash the date,
				# run through base64, and then output the top 16 characters to a file.
				date +%s | sha256sum | base64 | head -c 16 > "${rpc2_pass_file}"
			fi
			# change owner as we write to "/config/nginx" later on.
			chown -R "${PUID}":"${PGID}" "/config/nginx"

			echo "[warn] RPC2_PASS not defined (via -e RPC2_PASS), using randomised password (password stored in '${rpc2_pass_file}')" | ts '%Y-%m-%d %H:%M:%.S'
			export RPC2_PASS="$(cat ${rpc2_pass_file})"
		fi

	fi
fi

export ENABLE_WEBUI_AUTH=$(echo "${ENABLE_WEBUI_AUTH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${ENABLE_WEBUI_AUTH}" ]]; then
	echo "[info] ENABLE_WEBUI_AUTH defined as '${ENABLE_WEBUI_AUTH}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] ENABLE_WEBUI_AUTH not defined (via -e ENABLE_WEBUI_AUTH), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
	export ENABLE_WEBUI_AUTH="yes"
fi

if [[ "${ENABLE_WEBUI_AUTH}" == "yes" ]]; then
	export WEBUI_USER=$(echo "${WEBUI_USER}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${WEBUI_USER}" ]]; then
		echo "[info] WEBUI_USER defined as '${WEBUI_USER}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] WEBUI_USER not defined (via -e WEBUI_USER), defaulting to 'admin'" | ts '%Y-%m-%d %H:%M:%.S'
		export WEBUI_USER="admin"
	fi

	export WEBUI_PASS=$(echo "${WEBUI_PASS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${WEBUI_PASS}" ]]; then
		if [[ "${WEBUI_PASS}" == "rutorrent" ]]; then
			echo "[warn] WEBUI_PASS defined as '${WEBUI_PASS}' is weak, please consider using a stronger password" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[info] WEBUI_PASS defined as '${WEBUI_PASS}'" | ts '%Y-%m-%d %H:%M:%.S'
		fi
	else
		mkdir -p "/config/nginx/security"
		webui_pass_file="/config/nginx/security/webui_pass"
		if [ ! -f "${webui_pass_file}" ]; then
			# generate random password for web ui using SHA to hash the date,
			# run through base64, and then output the top 16 characters to a file.
			date +%s | sha256sum | base64 | head -c 16 > "${webui_pass_file}"
		fi
		# change owner as we write to "/config/nginx" later on.
		chown -R "${PUID}":"${PGID}" "/config/nginx"

		echo "[warn] WEBUI_PASS not defined (via -e WEBUI_PASS), using randomised password (password stored in '${webui_pass_file}')" | ts '%Y-%m-%d %H:%M:%.S'
		export WEBUI_PASS="$(cat ${webui_pass_file})"
	fi
fi

export APPLICATION="rtorrent"

EOF

# replace env vars placeholder string with contents of file (here doc)
sed -i '/# ENVVARS_PLACEHOLDER/{
    s/# ENVVARS_PLACEHOLDER//g
    r /tmp/envvars_heredoc
}' /usr/local/bin/init.sh
rm /tmp/envvars_heredoc

# cleanup
cleanup.sh
