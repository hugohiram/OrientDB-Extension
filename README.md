# OrientDB-Extension
==================

An [OrientDB](https://github.com/nuvolabase/orientdb) binary extension for PHP written in [Zephir](http://zephir-lang.com/) language. Go to the [wiki](https://github.com/hugohiram/OrientDB-Extension/wiki) to know more. Just want to download and test the extension? [download it from here](https://github.com/hugohiram/OrientDB-Extension/blob/master/ext/modules).

Go [here](https://github.com/hugohiram/OrientDB-Extension/wiki/Index) to get the full list of supported methods and examples on how to use them.

## Description ##

The current version is 0.10.0, the status is considered as *Beta*, the development covers most of the features that are documented by the OrientDB binary documentation, with the exception of the Transactions. This is a port from Anton Terekhov's [OrientDB-PHP](https://github.com/AntonTerekhov/OrientDB-PHP) driver.

The purpose of this development is to have a fast and simple PHP extension, it is intended only for document databases, initially graph databases will not be supported. Compatible with PHP 5.x and PHP 7.0.

The record decoder was rewritten, it doesn't decode the response into multiple properties, it converts the OrientDB [propietary format](https://github.com/orientechnologies/orientdb/wiki/Record-CSV-Serialization) into a JSON.

## Protocol version ##

The latest version supported is v.26. It contains changes from v.27 and v.28, but it does not support token sessions yet.

## Requirements ##

This extension requires:

### PHP 5.x ###
* PHP 5.4.x or newer
    * PCRE extension
    * JSON extension (php5-json)
    * PHP development headers and tools (php5-dev)
* [Zephir v0.8.0a](http://docs.zephir-lang.com/en/latest/install.html)

Haven't tried in a PHP 5.3.x installation.

### PHP 7.x ###
* PHP 7.0 or newer
    * PCRE extension
    * JSON extension (php7.0-json)
    * PHP development headers and tools (php7.0-dev)
* [Zephir v0.9.3a-dev](http://docs.zephir-lang.com/en/latest/install.html)

## Clone and build ##

### PHP 5.x ###

    git clone https://github.com/hugohiram/OrientDB-Extension
    cd OrientDB-Extension
    sudo su
    zephir build
    cp ext/modules/orientdb.so /PATH-TO-PHP/share/modules/orientdb.so
    service apache2 restart

### PHP 7.x ###

    git clone https://github.com/hugohiram/OrientDB-Extension
    cd OrientDB-Extension
    sudo su
    zephir build --backend=ZendEngine3
    cp ext/modules/orientdb.so /PATH-TO-PHP/share/modules/orientdb.so
    service apache2 restart

## Unit testing ##

Install composer, go to the root of the project:

    composer install

To run the tests, go to the root of the project;

    phpunit tests/

## Contribute ##

Any help is appreciated, thorough testing on complex schemas is required, as well as unit testing and performance tests.