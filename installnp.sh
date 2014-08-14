#!/bin/bash
echo "
....................................................................
.....................................................MMM............
....................................................~MMMMMM.........
....................................................?.....?MMMM,....
..............................................OMMMMMMMMMMMMMMMMMM...
..........................................MMMMMMMMMMMMMMMMMMMMMMMMMM
.........MMMM.........................NMMMMMMM ............. MMMMMMM
.......MMMMMMMMM?MMMMMMMMMMMMM=.....MMMMMM$.................. MMMMN.
...M: MMMMMMM,............... MMMMM MM,.......................MM....
.I.MMMMMM.....................MM.M..+M........................MI....
DMMMMM.........................M M.. M........................M7....
MMMMMM.........................M ~...MM.......................M8....
...MMMM........................MM.. MMMM .....................MN....
....MMM,......................7M,....MMMN ...................MM.....
.....MMM......................MM......?MMM................. MM+.....
.....8MM......................M ....... MMM...............MMM.......
......MMM....................M ...........8MMM........:MMM..........
......MMM.................. MM...............MMMMMMMMM..............
.......MMM . .............MMM.......................................
........MMMM=.........MMMMD.........................................
..........MMMMMMMMMMMMM,............................................
........................................Ready to Git Down and NERDY?
"

#Sets a path variable
thisPath="${PWD}"

#Asks the user for Database and Database User info

echo "Database Name:"
read -e dbname
echo "Database User:"
read -e dbuser
echo "Database Password: (not shown)"
read -s dbpass



#Downloads, unpacks, and cleans up WordPress
echo "Downloading WordPress . . ."
curl -O http://wordpress.org/latest.tar.gz
echo "Installing WordPress . . ."
tar -xzf latest.tar.gz
rm -f latest.tar.gz
mv wordpress/* .
rm -rf cgi-bin
rm -rf wordpress
rm -rf wp-content/plugins/hello.php
rm -rf wp-content/themes/twentytwelve
rm -rf wp-content/themes/twentythirteen

#Sets Database User name and password in wp-config
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/$dbname/g" wp-config.php
sed -i "s/username_here/$dbuser/g" wp-config.php
sed -i "s/password_here/$dbpass/g" wp-config.php

#The outputted messages here should sum things up, but this downloads and unpacks NerdPress
echo "Downloading the latest NerdPress . . ."
cd wp-content/themes
curl -O -L https://github.com/NerdyMind/nerdpress/archive/master.zip
echo "Unpacking NerdPress . . ."
unzip master.zip
rm -f master.zip
mv nerdpress-master nerdpress

echo "Downloading NerdPress child theme. . ."
curl -O -L https://github.com/NerdyMind/nerdpress-child/archive/master.zip
echo "Unpacking NerdPress Child Theme. . ."
unzip master.zip
rm -f master.zip
mv nerdpress-child-master nerdpress-child

cd $(printf $thisPath)

echo "Downloading base .gitignore file. . ."
curl -O -L https://github.com/NerdyMind/nerdygitignore/archive/master.zip
echo "Unpacking .gitignore. . ."
unzip master.zip
rm -f master.zip
mv nerdygitignore-master/.gitignore $(printf $thisPath)/.gitignore
rm -rf nerdygitignore-master

echo "Configuring git to play nice with the server"
git config --global pack.windowMemory "100m"
git config --global pack.SizeLimit "100m"
git config --global pack.threads "1"

echo "Setting up the site's Git Repository"
git init --shared=all
touch .git/hooks/post-commit
chmod u+x .git/hooks/post-commit
cat > .git/hooks/post-commit <<- _EOF_
#!/bin/sh
echo "pushing changes to the site hub (../site_hub.git)"
git push hub master
_EOF_

echo "Creating .htaccess so prying eyes can't see the .git directory"
cd .git/
touch .htaccess
cat > .htaccess <<- _EOF_
Order allow,deny
Deny from all
_EOF_
cd ..

git add .
git commit -m "Initial Import of NerdPress Files"

echo "Setting up the site's Git Repository Hub"

cd ..
mkdir site_hub.git
cd site_hub.git
hubPath="${PWD}"
git --bare init --shared=all

touch hooks/post-receive
chmod u+x hooks/post-receive
cat > hooks/post-receive <<- _EOF_
#!/bin/sh
echo "pulling changes to live site directory"
cd $(printf $thisPath)
unset GIT_DIR
git pull hub master
exec git-update-server-info
_EOF_

cd $(printf $thisPath)
git remote add hub $(printf $hubPath)
git remote show hub
git push hub master

echo "Cleaning Up . . ."
#rm -f installnp.sh
echo "NerdPress is installed! Get coding, NERD!"
echo ""
echo "To clone your site locally use this command, but swap out the user, domain, and local folder name:"
echo ""
echo "git clone ssh://user@domain.nerdymind.com/home/user/site_hub.git Name-Of-Local-Folder"

