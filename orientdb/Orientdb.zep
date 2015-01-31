/**
 * OrientDB Main class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

use Orientdb\Exception\OrientdbException;

/**
 * OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package Orientdb
 */
class Orientdb
{
	// Status
	const STATUS_SUCCESS = 0x00;
	const STATUS_ERROR = 0x01;

	const SERIALIZATION_CSV		= "ORecordDocument2csv";
	const SERIALIZATION_BINARY	= "ORecordSerializerBinary";

	public driverName = "PHP-Extension";
	public driverVersion = "0.3";
	public protocolVersion = 26;
	public clientId = null;
	public serialization;

	protected sessionDB;
	protected sessionServer;
	protected sessionToken;

	public error;
	public errno;
	public errstr;

	public transaction;
	public socket;
	
	/**
	 * Orientdb\Orientdb constructor
	 *
	 * @param string host          Hostname or IP of the OrientDB Server
	 * @param int    port          Port number of the OrientDB Server, 2424 by default
	 * @param string serialization type of serialization implementation, "csv" by default
	 */
	public function __construct(string host, int port = 2424, string serialization = "csv")
	{
		let this->error = false;

		//@TODO: autoloading
		//spl_autoload_register([this, "autoload"]);

		let this->socket = new OrientDBSocket(host, port);
		if empty this->socket {
			let this->error = true;
			let this->errno = "Could not open socket";
			let this->errstr = 500;
			throw new OrientdbException(this->errno, this->errstr);
		}

		switch serialization {
			case "binary": // only CSV supported
			case "csv":
			default:
				let this->serialization = self::SERIALIZATION_CSV;
				break;
		}
	}

	/**
	 * Set protocol version
	 *
	 * @param integer protocolVersion version of the protocol
	 * @return void
	 */
	public function setProtocolVersion(int protocolVersion) -> void
	{
		if (protocolVersion > this->protocolVersion) {
			throw new OrientdbException("version " . protocolVersion . " is not supported yet, max version supported is version " . (string)this->protocolVersion, 400);
		}

		let this->protocolVersion = protocolVersion;
	}

	/////////////////////////////////////////
	//     Server (CONNECT Operations)     //
	/////////////////////////////////////////

	/**
	 * Database Shutdown method
	 *
	 * @param string serverUser Username to connect to the OrientDB server
	 * @param string serverPass Password to connect to the OrientDB server
	 * @return void
	 */
	public function Shutdown(string serverUser, string serverPass) -> void
	{
		var resourceClass;
		let resourceClass = new Shutdown(this);

		resourceClass->run(serverUser, serverPass);
	}

	/**
	 * Database Connect method
	 *
	 * @param string  serverUser Username to connect to the OrientDB server
	 * @param string  serverPass Password to connect to the OrientDB server
	 * @param boolean stateless  Set a stateless connection using a token based session
	 * @return void
	 */
	public function Connect(string serverUser, string serverPass, boolean stateless = false) -> void
	{
		var resourceClass;
		let resourceClass = new Connect(this);

		resourceClass->run(serverUser, serverPass, stateless);
	}

	/**
	 * Database Open method
	 *
	 * @param string  dbName     Name of the database to open
	 * @param string  dbType     Type of the database: document|graph
	 * @param string  dbUser     Username for the database
	 * @param string  dbPass     Password of the user
	 * @param boolean stateless  Set a stateless connection using a token based session
	 * @return array
	 */
	public function DBOpen(string dbName, string dbType, string dbUser, string dbPass, boolean stateless = false)
	{
		var resourceClass;
		let resourceClass = new DBOpen(this);

		return resourceClass->run(dbName, dbType, dbUser, dbPass, stateless);
	}

	/**
	 * Create database method
	 *
	 * @param string dbName      Name of the new database
	 * @param string dbType      Type of the new database: document|graph, "document" by default
	 * @param string storageType Storage type of the new database: plocal|memory, "plocal" by default
	 * @return array
	 */
	public function DBCreate(string dbName, string dbType = "document", string storageType = "plocal") -> void
	{
		this->canPerformServerOperation();

		var resourceClass;
		let resourceClass = new DBCreate(this);

		resourceClass->run(dbName, dbType, storageType);
	}

	/**
	 * Check if database exists method
	 *
	 * @param string dbName Name of the database to check
	 * @param string storageType Storage type of the new database: plocal|memory, "plocal" by default
	 * @return boolean
	 */
	public function DBExist(string dbName, string storageType = "plocal") -> boolean
	{
		this->canPerformServerOperation();

		var resourceClass;
		let resourceClass = new DBExist(this);

		return resourceClass->run(dbName, storageType);
	}

	/**
	 * Database Reload method
	 *
	 * @return array
	 */
	public function DBReload()
	{
		this->canPerformDatabaseOperation();

		var resourceClass;
		let resourceClass = new DBReload(this);

		return resourceClass->run();
	}

	/**
	 * Retrieve list of databases
	 *
	 * @return array
	 */
	public function DBList()
	{
		this->canPerformServerOperation();

		var resourceClass;
		let resourceClass = new DBList(this);

		return resourceClass->run();
	}

	/**
	 * drop database if exists
	 *
	 * @param string dbName Name of the database to drop
	 * @param string dbType Type of the database to drop: plocal|memory
	 * @return array
	 */
	public function DBDrop(string dbName, string dbType = "plocal")
	{
		this->canPerformServerOperation();

		var resourceClass;
		let resourceClass = new DBDrop(this);

		return resourceClass->run(dbName, dbType);
	}

	/////////////////////////////////////////
	//    Database (DB_OPEN Operations)    //
	/////////////////////////////////////////

	/**
	 * Database Close method
	 *
	 * @return array
	 */
	public function DBClose()
	{
		this->canPerformDatabaseOperation();

		var resourceClass;
		let resourceClass = new DBClose(this);

		return resourceClass->run();
	}

	/**
	 * Select query method
	 *
	 * @param string query     Select query to execute
	 * @param int    limit     Limit on the query, by default limit from query
	 * @param string fetchplan Fetchplan, no fetchplan by default
	 * @return array
	 */
	public function query(string query, int limit = -1, string fetchplan = "*:0")
	{
		this->canPerformDatabaseOperation();

		var resourceClass;
		let resourceClass = new Query(this);

		return resourceClass->run(query, limit, fetchplan);
	}

	/**
	 * Database Size method
	 *
	 * @return int
	 */
	public function DBSize() -> int
	{
		this->canPerformDatabaseOperation();

		var resourceClass;
		let resourceClass = new DBSize(this);

		return resourceClass->run();
	}

	/**
	 * Database Count Records method
	 *
	 * @return long
	 */
	public function DBCountRecords() -> long
	{
		this->canPerformDatabaseOperation();

		var resourceClass;
		let resourceClass = new DBCountRecords(this);

		return resourceClass->run();
	}

	/**
	 * Datacluster Add method
	 *
	 * @param string name Name of the cluster to create
	 * @param short  id   ID of the cluster
	 * @return int
	 */
	public function DataclusterAdd(string name, int id) -> int
	{
		this->canPerformDatabaseOperation();

		var resourceClass;
		let resourceClass = new DataclusterAdd(this);

		return resourceClass->run(name, id);
	}

	/**
	 * Datacluster Drop method
	 *
	 * @param short number Number of the cluster to delete
	 * @return int
	 */
	public function DataclusterDrop(int number) -> int
	{
		this->canPerformDatabaseOperation();

		var resourceClass;
		let resourceClass = new DataclusterDrop(this);

		return resourceClass->run(number);
	}

	/**
	 * Datacluster Count method
	 *
	 * @param array   clusters  Array with the numbers of the clusters
	 * @param boolean tombstone whether deleted records should be taken in account autosharded storage only
	 * @return long
	 */
	public function DataclusterCount(array clusters, boolean tombstone = false) -> long
	{
		this->canPerformDatabaseOperation();

		var resourceClass;
		let resourceClass = new DataclusterCount(this);

		return resourceClass->run(clusters, tombstone);
	}


	/////////////////////////////////////////
	//       Orientdb custom methods       //
	/////////////////////////////////////////

	/**
	 * Set session of DB
	 *
	 * @param string session Session ID
	 */
	public function setSessionDB(string session) -> void
	{
		let this->sessionDB = session;
	}

	/**
	 * Set session of server
	 *
	 * @param string session Session ID
	 */
	public function setSessionServer(string session) -> void
	{
		let this->sessionServer = session;
	}

	/**
	 * Set session of server
	 *
	 * @param string session Session ID
	 */
	public function setSessionToken(string token) -> void
	{
		let this->sessionToken = token;
	}

	/**
	 * Get the session of DB
	 *
	 * @return string
	 */
	public function getSessionDB() -> string
	{
		return this->sessionDB;
	}

	/**
	 * Get session of server
	 *
	 * @return string
	 */
	public function getSessionServer() -> string
	{
		return this->sessionServer;
	}

	/**
	 * Get token of server
	 *
	 * @return string
	 */
	public function getSessionToken() -> string
	{
		return this->sessionToken;
	}

	/**
	 * Autoloading method
	 *
	 * @todo  implement autoloading
	 * @param string className Class to load
	 */
	public function autoload(className)
	{
		echo className;
	}

	/**
	 * Check if there is a session created for DB, if not, throw an exception
	 *
	 * @return void
	 */
	private function canPerformDatabaseOperation() -> void
	{
		var transaction;
		let transaction = this->getSessionDB();
		if empty transaction {
			throw new OrientdbException("Cannot perform the '" . this->GetCallingMethodName() . "' operation if not connected to a database");
		}
	}

	/**
	 * Check if there is a session created for Server, if not, throw an exception
	 *
	 * @return void
	 */
	private function canPerformServerOperation() -> void
	{
		var transaction;
		let transaction = this->getSessionServer();
		if empty transaction {
			throw new OrientdbException("Cannot perform the '" . this->GetCallingMethodName() . "' operation if not connected to a server");
		}
	}

	/**
	 * Get the calling method for current method
	 *
	 * @return string
	 */
	private function GetCallingMethodName() -> string
	{
		var trace;
		let trace = debug_backtrace();

		return trace[2]["function"];
	}
}