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

* Shutdown (REQUEST_SHUTDOWN)
* Connect (REQUEST_CONNECT)
* DBOpen (REQUEST_DB_OPEN)
* DBCreate (REQUEST_DB_CREATE)
* DBClose (REQUEST_DB_CLOSE)
* Select (SynchQuery)

## TODOs ##

* Autoloader
* Everything

## Usage ##

### Shutdown ###
##### (REQUEST_SHUTDOWN) #####

    $orient = new Orientdb\Orientdb('localhost', 2424);
    $orient->Shutdown('admin', 'admin');

### Connect ###
##### (REQUEST_CONNECT) #####

    $orient = new Orientdb\Orientdb('localhost', 2424);
    $orient->Connect('admin', 'admin');

### DBOpen ###
##### (REQUEST_DB_OPEN) #####

    $orient = new Orientdb\Orientdb('localhost', 2424);
    $orient->DBOpen('test', 'document', 'admin', 'admin');

### DBCreate ###
##### (REQUEST_DB_CREATE) #####

    $orient = new Orientdb\Orientdb('localhost', 2424);
    $orient->Connect('admin', 'admin');
    $orient->DBCreate('test', 'document', 'plocal');

### DBClose ###
##### (REQUEST_DB_CLOSE) #####

    $orient = new Orientdb\Orientdb('localhost', 2424);
    $orient->DBClose();

### Select ###
##### (Select) #####

    $orient = new Orientdb\Orientdb('localhost', 2424);
    $orient->DBOpen('test', 'document', 'admin', 'admin');
    $records = $orient->select('select from basic');
    if (!empty($records)) {
		foreach ($records as $record) {
		    $data = $record->data;
			var_dump($data);
		}
	}
