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
* [Zephir 0.5.9](http://zephir-lang.com/install.html)

Haven't tried in a PHP 5.3.x installation.

## clone and build ##

    git clone https://github.com/hugohiram/OrientDB-Extension
    cd OrientDB-Extension
    sudo su
    zephir build
    cp ext/modules/orientdb.so /PATH-TO-PHP/share/modules/orientdb.so
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
* Query (REQUEST_COMMAND - OSQLSynchQuery)
* Command (REQUEST_COMMAND - OCommandSQL)
* DBSize (REQUEST_DB_SIZE)
* DBCountRecords (REQUEST_DB_COUNTRECORDS)
* DBReload (REQUEST_DB_RELOAD)
* DBFreeze (REQUEST_DB_FREEZE)
* DBRelease (REQUEST_DB_RELEASE)
* DataclusterAdd (REQUEST_DATACLUSTER_ADD)
* DataclusterDrop (REQUEST_DATACLUSTER_DROP)
* DataclusterCount (REQUEST_DATACLUSTER_COUNT)

## TODOs ##

* Autoloader
* REQUEST_CONFIG_GET
* REQUEST_CONFIG_SET
* REQUEST_CONFIG_LIST
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
* REQUEST_POSITIONS_CEILING
* REQUEST_TX_COMMIT
* REQUEST_PUSH_RECORD
* REQUEST_PUSH_DISTRIB_CONFIG
* REQUEST_DB_COPY
* REQUEST_REPLICATION
* REQUEST_CLUSTER
* REQUEST_DB_TRANSFER
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

### Protocol version ###
To se the protocol version, use the `setProtocolVersion` method. The latest version supported is v.26

#### Example
```php
try{
    $orient = new Orientdb\Orientdb('locaho...', 2424);
    $orient->setProtocolVersion(24);
}
catch(OrientdbException $e) {
    var_dump($e->getMessage());
    var_dump($e->getCode());
}
```
---

### Connect ###
##### (REQUEST_CONNECT) #####
This is the first operation requested by the client when it needs to work with the server instance. It returns the session id of the client.
```php
connect(string username, string password [,boolean stateless = false]) : void
```
#### Parameters
Parameter  | Description   | Mandatory
---------- | ------------- | -----------
**_username_** | Username for the OrientDB Server | yes
**_password_** | Password for the OrientDB Server | yes
**_stateless_** | Type of session, true for stateless, false or empty for stateful | no

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->Connect('admin', 'admin');
```
---

### DBOpen ###
##### (REQUEST_DB_OPEN) #####
This is the first operation the client should call. It opens a database on the remote OrientDB Server. Returns an array with the database configuration and clusters.
```php
DBOpen(string dbName, string dbType, string dbUser, string dbPass [, boolean stateless = false]) : array
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_dbName_** | Name of the database | yes
**_dbType_** | Type of the database: document-graph, only document is supported at the moment | yes
**_dbUser_** | for the database | yes
**_dbPass_** | Password for the database | yes
**_stateless_** | Type of session, true for stateless, false or empty for stateful | no

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
```
---

### Shutdown ###
##### (REQUEST_SHUTDOWN) #####
Shut down the server. Requires "shutdown" permission to be set in orientdb-server-config.xml file and to be connected to the server. Typically the credentials are those of the OrientDB server administrator. This is not the same as the admin user for individual databases.
```php
Shutdown(string username, string password) : void
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_username_** | Username for the OrientDB Server | yes
**_password_** | Password for the OrientDB Server | yes

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->Shutdown('admin', 'admin');
```
---

### DBCreate ###
##### (REQUEST_DB_CREATE) #####
Creates a database in the remote OrientDB server instance
```php
DBCreate(string dbName [, string dbType = "document" [, string storageType = "plocal" ]] ) : void
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_dbName_** | Name of the database | yes
**_dbType_** | Type of the database: document-graph, _document_ by default, only document is supported at the moment | no
**_storageType_** | Storage type: plocal or memory, _plocal_ by default | no

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
DBClose( ) : void
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
DBExist(string dbName [, string storageType = "plocal" ]) : boolean
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_dbName_** | Name of the database to check | yes
**_storageType_** | Storage type: plocal-memory, _plocal_ by default | no

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
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_dbName_** | Name of the database to delete | yes
**_dbType_** | Type of the database: plocal or memory, _plocal_ by default | no

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->Connect('admin', 'admin');
$orient->DBDrop('test');	
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

### Query ###
##### (REQUEST_COMMAND - OSQLSynchQuery) #####
Executes a _command_ operation of type _OSQLSynchQuery_ (**_select_**)
```php
query(string query [, int limit = -1, [, string fetchplan = "*:0" ]] ) : array
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_query_** | Query to execute | yes
**_limit_** | Limit of results in the query, no limit by default | no
**_fetchplan_** | Fetchplan, none by default: "*:0" | no

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
$records = $orient->query('select from basic');
if (!empty($records)) {
	foreach ($records as $record) {
	    $data = $record->data;
		var_dump($data);
        // the content is not parsed until one of the properties is called:
        $data->name;
        var_dump($data);
	}
}
```
---

### Command ###
##### (REQUEST_COMMAND - OCommandSQL) #####
Executes a _command_ operation of type _OCommandSQL_ 
(**_insert_**, **_update_**, **_delete_**, **_traverse_**)
```php
command(string query) : array
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_query_** | Query to execute | yes

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
$result = $orient->command('create class simple');
$result = $orient->command('create property simple.name string');
$result = $orient->command('create property simple.year integer');
$result = $orient->command('insert into simple set name = "my name", year = "2015"');
$result = $orient->command('drop class simple');

//$result = $orient->command( "traverse extlist from #10:1");

```
---

### DBSize ###
##### (REQUEST_DB_SIZE) #####
Asks for the size of a database in the OrientDB Server instance.
```php
DBSize() : int
```
#### Parameters
no parameters needed

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
$size = $orient->DBSize(); 
```
---

### DBCountRecords ###
##### (REQUEST_DB_COUNTRECORDS) #####
Asks for the number of records in a database in the OrientDB Server instance.
```php
DBCountRecords() : int
```
#### Parameters
no parameters needed

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
$count = $orient->DBCountRecords();
```
---

### DBReload ###
##### (REQUEST_DB_RELOAD) #####
Reloads database information. Available since 1.0rc4.
```php
DBReload( ) : void
```
#### Parameters
no parameters needed

#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
$config = $orient->DBReload();
```
---

### DBFreeze ###
##### (REQUEST_DB_FREEZE) #####
Flushes all cached content to the disk storage and allows to perform only read commands. 
Database will be "frozen" till release database command will not been executed.
```php
DBFreeze( string dbName [, string storageType = "plocal" ] ) : long
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_dbName_** | Name of the database | yes
**_storageType_** | Type of storage: plocal or memory | no


#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$result = $orient->Connect($serverUser, $serverPass);
$freezed = $orient->DBFreeze("test", "plocal");
```
---

### DBRelease ###
##### (REQUEST_DB_RELEASE) #####
Switches database from "frozen" state to normal mode.
```php
DataclusterCount( string dbName [, string storageType = "plocal" ] ) : long
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_dbName_** | Name of the database | yes
**_storageType_** | Type of storage: plocal or memory | no


#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$result = $orient->Connect($serverUser, $serverPass);
$freezed = $orient->DBFreeze("test", "plocal");
$released = $orient->DBRelease("test", "plocal");
```
---

### DataclusterAdd ###
##### (REQUEST_DATACLUSTER_ADD) #####
Add a new data cluster.
```php
DataclusterAdd(string name, int id) : int
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_name_** | Name of the new cluster | yes
**_id_** | ID of the cluster | yes


#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
$cluster = $orient->DataclusterAdd("myCluster", 20);
```
---

### DataclusterDrop ###
##### (REQUEST_DATACLUSTER_DROP) #####
Remove a cluster.
```php
DataclusterDrop(int number) : int
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_number_** | Number of the cluster | yes


#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
$cluster = $orient->DataclusterDrop(20);
```
---

### DataclusterCount ###
##### (REQUEST_DATACLUSTER_COUNT) #####
Returns the number of records in one or more clusters.
```php
DataclusterCount( array clusters [, boolean tombstone = false ] ) : long
```
#### Parameters
Parameter  | Description   |  Mandatory
---------- | ------------- | -----------
**_clusters_** | Array with the numbers of the clusters | yes
**_tombstone_** | whether deleted records should be taken in account, autosharded storage only | no


#### Example
```php
$orient = new Orientdb\Orientdb('localhost', 2424);
$orient->DBOpen('test', 'document', 'admin', 'admin');
$clusters = array(10);
$records = $orient->DataclusterCount($clusters);
```
---

