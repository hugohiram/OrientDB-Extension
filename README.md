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
* DBExist (REQUEST_DB_EXIST)
* DBDrop (REQUEST_DB_DROP)
* DBList (REQUEST_DB_LIST)
* Select (SynchQuery)

## TODOs ##

* Autoloader
* REQUEST_CONFIG_GET
* REQUEST_CONFIG_SET
* REQUEST_CONFIG_LIST
* REQUEST_DB_SIZE
* REQUEST_DB_COUNTRECORDS
* REQUEST_DATACLUSTER_ADD
* REQUEST_DATACLUSTER_DROP
* REQUEST_DATACLUSTER_COUNT
* REQUEST_DATACLUSTER_DATARANGE
* REQUEST_DATACLUSTER_COPY
* REQUEST_DATACLUSTER_LH_CLUSTER_IS_USED
* REQUEST_RECORD_METADATA
* REQUEST_RECORD_LOAD
* REQUEST_RECORD_CREATE
* REQUEST_RECORD_UPDATE
* REQUEST_RECORD_DELETE
* REQUEST_RECORD_COPY
* REQUEST_POSITIONS_HIGHER
* REQUEST_POSITIONS_LOWER
* REQUEST_RECORD_CLEAN_OUT
* REQUEST_POSITIONS_FLOOR
* REQUEST_COMMAND
* REQUEST_POSITIONS_CEILING
* REQUEST_TX_COMMIT
* REQUEST_DB_RELOAD
* REQUEST_PUSH_RECORD
* REQUEST_PUSH_DISTRIB_CONFIG
* REQUEST_DB_COPY
* REQUEST_REPLICATION
* REQUEST_CLUSTER
* REQUEST_DB_TRANSFER
* REQUEST_DB_FREEZE
* REQUEST_DB_RELEASE
* REQUEST_DATACLUSTER_FREEZE
* REQUEST_DATACLUSTER_RELEASE
* REQUEST_CREATE_SBTREE_BONSAI
* REQUEST_SBTREE_BONSAI_GET
* REQUEST_SBTREE_BONSAI_FIRST_KEY
* REQUEST_SBTREE_BONSAI_GET_ENTRIES_MAJOR
* REQUEST_RIDBAG_GET_SIZE

## Usage ##


### Create object ###
```php
Orientdb ( string host [, int port = 2424 [, string serialization = "csv" ]] ) : Object
```
#### Parameters
Parameter  | Description
---------- | -------------
**_host_** | IP or Host of the OrientDB Server
**_port_** | Port used on the OrientDB Server
**_serialization_** | Serialization used: csv-binary, only csv supported at the moment

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
```
---

### Exceptions ###
When something goes wrong or a criteria is not met, for ecxample when is not possible to connect to a server, the extension will throw an `OrientdbException` exception.

#### Example
```php
try{
    $orient = new Orientdb\Orientdb('locaho..', 2424);
}
catch(OrientdbException $e) {
    var_dump($e->getMessage());
    var_dump($e->getCode());
}
```
---

### Shutdown ###
##### (REQUEST_SHUTDOWN) #####
Shut down the server. Requires "shutdown" permission to be set in orientdb-server-config.xml file. Typically the credentials are those of the OrientDB server administrator. This is not the same as the admin user for individual databases.
```php
Shutdown(string username, string password) : void
```
#### Parameters
Parameter  | Description
---------- | -------------
**_username_** | Username for the OrientDB Server
**_password_** | Password for the OrientDB Server

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->Shutdown('admin', 'admin');
```
---

### Connect ###
##### (REQUEST_CONNECT) #####
This is the first operation requested by the client when it needs to work with the server instance. It returns the session id of the client.
```php
Shutdown(string username, string password) : void
```
#### Parameters
Parameter  | Description
---------- | -------------
**_username_** | Username for the OrientDB Server
**_password_** | Password for the OrientDB Server

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->Connect('admin', 'admin');
```
---

### DBOpen ###
##### (REQUEST_DB_OPEN) #####
This is the first operation the client should call. It opens a database on the remote OrientDB Server. Returnds an array with the database configuration and clusters.
```php
DBOpen(string dbName, string dbType, string dbUser, string dbPass) : array
```
#### Parameters
Parameter  | Description
---------- | -------------
**_dbName_** | Name of the database
**_dbType_** | Type of the database: document-graph, only document is supported at the moment
**_dbUser_** | for the database
**_dbPass_** | Password for the database

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
```
---

### DBCreate ###
##### (REQUEST_DB_CREATE) #####
Creates a database in the remote OrientDB server instance
```php
DBCreate(string dbName [, string dbType = "document" [, string storageType = "plocal" ]] ) : void
```
#### Parameters
Parameter  | Description
---------- | -------------
**_dbName_** | Name of the database
**_dbType_** | Type of the database: document-graph, _document_ by default, only document is supported at the moment
**_storageType_** | Storage type: plocal-memory, _plocal_ by default

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->Connect('admin', 'admin');
$orient->DBCreate('test', 'document', 'plocal');
```
---

### DBClose ###
##### (REQUEST_DB_CLOSE) #####
Closes the database and the network connection to the OrientDB Server instance. No return is expected.
```php
DBClose() : void
```
#### Parameters
no parameters needed

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
$orient->DBClose();
```
---

### DBExist ###
##### (REQUEST_DB_EXIST) #####
Asks if a database exists in the OrientDB Server instance, _true_ if exists, _false_ if doesn't exists.
```php
DBExist(string dbName) : boolean
```
#### Parameters
Parameter  | Description
---------- | -------------
**_dbName_** | Name of the database to check

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->Connect('admin', 'admin');
$exists = $orient->DBExist('test');	
```
---

### DBDrop ###
##### (REQUEST_DB_DROP) #####
Removes a database from the OrientDB Server instance.
```php
DBDrop(string dbName [, string dbType = "plocal" ] ) : void
```
#### Parameters
Parameter  | Description
---------- | -------------
**_dbName_** | Name of the database to delete
**_dbType_** | Type of the database: plocal-memory, _plocal_ by default

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->Connect('admin', 'admin');
$orient->DBDrop('test', 'plocal');	
```
---

### DBList ###
##### (REQUEST_DB_LIST) #####
List the database from the server instance.
```php
DBList() : array
```
#### Parameters
no parameters needed

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->Connect('admin', 'admin');
$databases = $orient->DBList();	
```
---

### Select ###
##### (REQUEST_COMMAND - OSQLSynchQuery) #####
Executes a _command_ operation of type _OSQLSynchQuery_
```php
Select(string query [, string fetchplan = "*:0" ] ) : array
```
#### Parameters
Parameter  | Description
---------- | -------------
**_query_** | Query to execute
**_fetchplan_** | Fetchplan, none by default: "*:0"

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
$records = $orient->select('select from basic');
if (!empty($records)) {
	foreach ($records as $record) {
	    $data = $record->data;
		var_dump($data);
	}
}
```
---

