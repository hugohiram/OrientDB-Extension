# OrientDB-Extension
==================

An [OrientDB](https://github.com/nuvolabase/orientdb) extension for PHP written in [Zephir](http://zephir-lang.com/) language

## Description ##

Current status is: *Alpha*, the development of this extension it's in a very early stage. This is a port from Anton Terekhov's [OrientDB-PHP](https://github.com/AntonTerekhov/OrientDB-PHP) driver.

The purpose of this development is to have a fast and simple PHP extension, it is intended only for document databases, initially graph databases will not be supported.

The record decoder was rewritten, it doesn't decode the response into multiple properties, it converts the OrientDB [propietary format](https://github.com/orientechnologies/orientdb/wiki/Record-CSV-Serialization) into a JSON.

## Requirements ##

This extension requires:

* PHP 5.4.x or newer
    * PCRE extension
    * JSON extension (php5-json)
    * PHP development headers and tools (php5-dev)
* [Zephir 0.4.2](http://zephir-lang.com/install.html)

Haven't tried in a PHP 5.3.x installation.

## clone and build ##

    git clone https://github.com/hugohiram/OrientDB-Extension
    cd OrientDB-Extension
    sudo su
    zephir build
    service apache2 restart

## Done ##

* Connect
* DBOpen
* DBClose
* Select (SynchQuery)

## TODOs ##

* Autoloader
* Everything
