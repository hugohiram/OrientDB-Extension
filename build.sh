#!/bin/bash

clear

echo "Cleaning..."
zephir clean

PHPVersion=$(php -v|grep --only-matching --perl-regexp "[5-8]\.\\d+\.\\d+");
currentVersion=${PHPVersion::0-2};
compareVersion=7;

if [ $(echo " $currentVersion >= $compareVersion" | bc) -eq 1 ]; then
    echo "Building for PHP 7..."
    zephir build --backend=ZendEngine3
else
    echo "Building for PHP 5..."
    zephir build
fi

#SOURCE=ext/modules/orientdb.so
#TARGET="`php-config --extension-dir`/"

#echo "Copying extension"
#cp $SOURCE $TARGET
#if [ $? -ne 0 ]
#then
#    echo "could not copy extension to target"
#fi

echo "Restarting Apache"
service apache2 restart