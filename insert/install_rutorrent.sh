############################################
#        installation de rutorrent         #
############################################

# création de userRuto dans install_apache.sh
# Modifier la configuration du site par défaut (pour rutorrent) dans install_apache.sh

# téléchargement
mkdir $REPWEB/source
cd $REPWEB/source
cmd="wget https://github.com/Novik/ruTorrent/archive/master.zip"; $cmd || __msgErreurBox "$cmd" $?
unzip -o master.zip
mv -f ruTorrent-master $REPWEB/rutorrent
chown -R www-data:www-data $REPWEB/rutorrent

# fichier de config config.php générique ( modif dans conf/user/nonuser/)
mv $REPWEB/rutorrent/conf/config.php $REPWEB/rutorrent/conf/config.php.old
cp $REPLANCE/fichiers-conf/ruto_config.php $REPWEB/rutorrent/conf/config.php
chown -R www-data:www-data $REPWEB/rutorrent
chmod -R 755 $REPWEB/rutorrent

# modif .htaccess dans /rutorrent  le passwd paramétré dans sites-available
echo -e 'Options All -Indexes\n<Files .htaccess>\norder allow,deny\ndeny from all\n</Files>' > $REPWEB/rutorrent/.htaccess

# modif du thème de rutorrent
mkdir -p $REPWEB/rutorrent/share/users/$userRuto/torrents
mkdir $REPWEB/rutorrent/share/users/$userRuto/settings
chown -R www-data:www-data $REPWEB/rutorrent/share/users/$userRuto
chmod -R 777 $REPWEB/rutorrent/share/users/$userRuto

echo 'O:6:"rTheme":2:{s:4:"hash";s:9:"theme.dat";s:7:"current";s:8:"Oblivion";}' > $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat
chmod u+rwx,g+rx,o+rx $REPWEB/rutorrent/share/users/$userRuto
chmod 666 $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat
chown www-data:www-data $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat

echo
echo "**********************************************"
echo "|    ruTorrent installed and configured      |"
echo "**********************************************"
sleep 1

# installation de mediainfo et ffmpeg
if [[ $nameDistrib == "Debian" && $os_version_M -eq 8 ]]; then
  chmod 777 /etc/apt/sources.list
  echo $sourceMediaD8 >> /etc/apt/sources.list
  chmod 644 /etc/apt/sources.list
  apt-get update -yq
  cmd="apt-get install -yq --force-yes deb-multimedia-keyring"; $cmd || __msgErreurBox "$cmd" $?
  apt-get update -yq
  cmd="apt-get install -y --force-yes $paquetsMediaD8"; $cmd || __msgErreurBox "$cmd" $?
elif [[ $nameDistrib == "Debian" && $os_version_M -eq 9 ]]; then
  cmd="apt-get install -yq $paquetsMediaD9"; $cmd || __msgErreurBox "$cmd" $?
else
  cmd="apt-get install -yq --force-yes $paquetsMediaU"; $cmd || __msgErreurBox "$cmd" $?
fi
echo
echo "*****************************************"
echo "|    mediainfo and ffmpeg installed     |"
echo "*****************************************"
sleep 1

## plugins rutorrent
mkdir -p $REPWEB/rutorrent/plugins/conf

cp $REPLANCE/fichiers-conf/ruto_plugins.ini $REPWEB/rutorrent/plugins/conf/plugins.ini

# création de conf/users/userRuto en prévision du multiusers
mkdir -p $REPWEB/rutorrent/conf/users/$userRuto
cp $REPWEB/rutorrent/conf/access.ini $REPWEB/rutorrent/conf/plugins.ini $REPWEB/rutorrent/conf/users/$userRuto
cp $REPLANCE/fichiers-conf/ruto_multi_config.php $REPWEB/rutorrent/conf/users/$userRuto/config.php

sed -i -e 's/<port>/'$PORT_SCGI'/' -e 's/<username>/'$userLinux'/' $REPWEB/rutorrent/conf/users/$userRuto/config.php

chown -R www-data:www-data $REPWEB/rutorrent/conf

# Ajouter le plugin log-off

cd $REPWEB/rutorrent/plugins
cmd="wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rutorrent-logoff/logoff-1.3.tar.gz"; $cmd || __msgErreurBox "$cmd" $?
cmd="tar -zxf logoff-1.3.tar.gz"; $cmd || __msgErreurBox "$cmd" $?

# action pro Qwant
sed -i "s|\(\$logoffURL.*\)|\$logoffURL = \"https://www.qwant.com/\";|" $REPWEB/rutorrent/plugins/logoff/conf.php
sed -i "s|\(\$allowSwitch.*\)|\$allowSwitch = \"$userRuto\";|" $REPWEB/rutorrent/plugins/logoff/conf.php
echo -e "\n;;\n        [logoff]\n        enabled = yes" >> $REPWEB/rutorrent/plugins/conf/plugins.ini

chown -R www-data:www-data $REPWEB/rutorrent/plugins/logoff
echo
echo "********************************************"
echo "|       ruTorrent plugins installed        |"
echo "********************************************"
sleep 1

headTest=`curl -Is http://$IP/rutorrent/| head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
if [[ "$headTest" == Unauthorized* ]]; then
  echo
  echo "*********************************"
  echo "|  ruTorrent works correctly    |"
  echo "*********************************"
  sleep 1
else
  __msgErreurBox "curl -Is http://$IP/rutorrent/| head -n 1 | awk -F\" \" '{ print $3 }' return $headTest" "http $headTest"
fi