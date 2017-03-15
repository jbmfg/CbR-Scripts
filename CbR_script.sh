#!/bin/bash


function process {
        echo Getting $1...
        sleep 1
}

function post {
        echo Posting $1 to cb...
        /usr/share/cb/cbpost $1 &>> $od/script.log
}


sleep 1
clear

#read -e -p "Is there an allicance connection (used to post to cb) Y/n? " alliance
#alliance=${alliance:-Y}
#echo $alliance
# To Lowercase
# alliance=$(tr '[A-Z]' '[a-z]'<<<$alliance)

read -e -p "Where should files be saved? (user cb needs write access to this directory) " -i "/tmp" od
sleep 1
clear
echo Using $od
sleep 1
echo "$(date)" > $od/script.log # clear the log file
cat /etc/cb/server.token >> $od/server.token
process server.token
psql -d cb -p 5002 -c "select name,enabled from alliance_feeds order by name asc;" >> $od/alliance_feeds.txt
process alliance_feeds.txt
openssl x509 -in /etc/cb/certs/carbonblack-alliance-client.crt -subject -noout |cut -d'=' -f7 |cut -d'/' -f1 >> $od/customer_token.txt
process customer_token.txt
psql -d cb -p 5002 -c "Copy (Select * from watchlist_entries) to '$od/watchlists.csv' with CSV" &>> $od/script.log;
process watchlists.csv
tail -n +1 /var/log/cb/solr/debug.log | grep 'path=/select' | awk '{print $7"\t"$4}' | sed 's/QTime=//g' | sort -rn >> $od/slow_watchlists.txt
process slow_watchlists.txt
grep "XMAX.*MemTotal" /etc/cb/solr/tomcat6.conf | sed -rn 's/.*0\.([0-9][0-9]).*/\1\%/p' >> $od/solr_JVM.txt
process solr_JVM.txt
psql cb -p 5002 -c "SELECT * FROM cb_settings WHERE key LIKE 'EventPurgeEarliestTime_0'" >> $od/oldest_document.txt
process oldest_document.txt
read -n 1 -s -p "Everything collected.  Press any key to continue..."
clear

while true; do
        read -p "Run cbdiag now? " yn
        case $yn in
                [Yy]* )
                        cd $od;
                        /usr/share/cb/cbdiag --no-perf-stats --tmpdir=$od;
                        cbdiag=true;
                        read -n 1 -s -p "cbdiag complete. Press any key to continue..."
                        break;;
                [Nn]* )
                        read -n 1 -s -p "Can be run later with /usr/share/cb/cbdiag.  Press any key to continue...";
                        break;;
                * ) echo "please enter Y[es] or N[o]";;
        esac
done

clear

while true; do
        read -p "Post files now? (CB Alliance connection needed) " yn
        case $yn in
                [Yy]* )
                post $od/server.token;
                post $od/alliance_feeds.txt;
                post $od/customer_token.txt;
                post $od/watchlists.csv;
                post $od/slow_watchlists.txt;
                post $od/solr_JVM.txt;
                post $od/oldest_document.txt;
                if [ $cbdiag ]; then post $od/cbdiag*.zip; fi
                echo Everything posted succesfully.  All files available in $od.;
                break;;
                [Nn]* ) echo All files available in $od; exit;;
                * ) echo "please enter Y[es] or N[o]";;
        esac
done

while true; do
        read -p "Show log file? " yn
        case $yn in
                [Yy]* ) cat $od/script.log;break;;
                [Nn]* ) break;;
        esac
done


read -n1 -s -p "Finished.  Press any key to exit..."
clear
sleep 1
exit 0