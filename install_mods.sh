#!/bin/bash

export INSTALL_DIR=$1
export MODS_DIR=$INSTALL_DIR/Mods-Available
export USER=steam
export MODCOUNT=0
export MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ `whoami` != 'root' ]]; then
  echo "This script should be run as the root user.";
  exit;
fi
if [[ -z $1 ]]; then 
  echo "Please provide your 7DTD game server installation directory as an argument to this script."; exit 1;
fi

. install_mods.func.sh

[[ -f /etc/redhat-release ]] && yum install gcc-c++ git curl -y || apt-get install g++ git curl p7zip-full -y

# Install the Server & Mod-Management PHP Portal
[[ ! -d $INSTALL_DIR/html ]] && mkdir $INSTALL_DIR/html
cp index.php modmgr.inc.php rwganalyzer.inc.php rwganalyzer.php 7dtd_logo.png direct-download.png $INSTALL_DIR/html/

# Creating "Mods-Available" folder
echo "Creating the Mods-Available folder to install the mods into"
rm -rf $MODS_DIR && mkdir $MODS_DIR
cd $MODS_DIR

# Sqlite support is broke in ServerTools at the moment, so we have to manually compile the Sqlite 
# Interop Assembly package. Below is a one-liner compatible with Ubuntu & CentOS to accomplish this.
if [[ ! -f /data/7DTD/7DaysToDieServer_Data/Mono/x86_64/libSQLite.Interop.so ]]; then
  rm -rf System.Data.SQLite && git clone https://github.com/moneymanagerex/System.Data.SQLite && \
  cd System.Data.SQLite/Setup && \
  /bin/bash ./compile-interop-assembly-release.sh && ln -s ../SQLite.Interop/src/generic/libSQLite.Interop.so $INSTALL_DIR/7DaysToDieServer_Data/Mono/x86_64/libSQLite.Interop.so && \
  echo "yes" && cd ../.. && echo "./7DaysToDieServer_Data/Mono/x86_64/libSQLite.Interop.so Sym-Linked to this custom compiled file";
fi

# STATIC INSTALLS: Auto-Reveal, ServerTools, Allocs Bad Company, CSMM Patrons, CSMM Patrons Allocs Map Addon, COMPOPack
#1: Auto-Reveal
git_clone https://github.com/XelaNull/7dtd-auto-reveal-map.git && \
yes | cp -f $MODCOUNT/7dtd-auto-reveal-map/loop_start_autoreveal.sh / && chmod a+x /*.sh
(/usr/bin/crontab -l 2>/dev/null; echo '* * * * * /loop_start_autoreveal.sh') | /usr/bin/crontab -
ln -s $MODS_DIR/1/7dtd-auto-reveal-map $INSTALL_DIR/7dtd-auto-reveal-map

# All oher Mods we should gather from a URL-downloaded file
cd $INSTALL_DIR/7dtd-servermod && rm -rf install_mods.list.cmd
wget https://raw.githubusercontent.com/XelaNull/7dtd-servermod/master/install_mods.list.cmd
chmod a+x install_mods.list.cmd && ./install_mods.list.cmd

echo "Applying CUSTOM CONFIGS against application default files ${MYDIR}" && cd $MYDIR && chmod a+x *.sh && ./7dtd-APPLY-CONFIG.sh
chown $USER $INSTALL_DIR -R