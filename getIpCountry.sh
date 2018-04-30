#!/bin/bash

#ftp://ftp.apnic.net/pub/stats/apnic/delegated-apnic-extended-latest
#ftp://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest
#ftp://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-extended-latest
#ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-extended-latest
#ftp://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-extended-latest


WORKDIR=$(pwd)
DATADIR=$WORKDIR/data
CACHEDIR=$WORKDIR/cache

###############################################################################
_LOGBASE2=$(echo 'l(2)'|bc -l)

function _postProcess () {
    cat -|grep ipv|grep -e "allocated" -e "assigned"|cut -d'|'  --fields=2-5 |sed -e"s/|/ /g"
}

function distIp () {
while read COUNTRY IPTYPE ADDRESS SUBNET
do
if [ $IPTYPE = 'ipv4' ];then
    SUBNET=$(printf '%.f \n' $(echo "32-l(${SUBNET})/$_LOGBASE2"|bc -l))
fi
echo $ADDRESS/$SUBNET $IPTYPE>> $DATADIR/$COUNTRY
done
}

function hashCheck () {
    cd $CACHEDIR
    while read URL
    do
    (
    URLBase=$(basename $URL) 
    DownPath=$CACHEDIR/$URLBase
    test -e $DownPath&&curl -s --output $DownPath.md5 $URL.md5&&(cat $DownPath.md5|md5sum -c 2>/dev/null||cat $DownPath.md5|sed -E "s/delegated-(.)*-extended-(.)*/$URLBase/g"|md5sum -c 2>/dev/null)||(echo cache miss $URLBase;mv $DownPath $DownPath.old 2>/dev/null;curl -s --output $DownPath $URL)||mv $DownPath.old $DownPath 2>/dev/null
    cat $DownPath|_postProcess|distIp
    )&
done
}

function _init () {
    test -d $DATADIR&&test -w $DATADIR||chmod u+w $DATADIR||mkdir -pZ $DATADIR||exit 1
    test -d $CACHEDIR&&test -w $CACHEDIR||chmod u+x $CACHEDIR||mkdir -pZ $CACHEDIR||exit 1
    rm -f $DATADIR/*
    rm -f $CACHEDIR/*.md5
}

_init||exit 1
hashCheck << EOL
ftp://ftp.apnic.net/pub/stats/apnic/delegated-apnic-extended-latest
ftp://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest
ftp://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-extended-latest
ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-extended-latest
ftp://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-extended-latest
EOL
wait

