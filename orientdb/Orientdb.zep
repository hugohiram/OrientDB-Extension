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
	public driverVersion = "0.1";
	public protocolVersion = 15;
	public clientId = null;
	public serialization;

	protected sessionDB;
	protected sessionServer;

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

	/////////////////////////////////////////
	//     Server (CONNECT Operations)     //
	/////////////////////////////////////////

	/**
	 * Database Shutdown method
	 *
	 * @param string serverUser Username to connect to the OrientDB server
	 * @param string serverPass Password to connect to the OrientDB server
	 * @return array
	 */
	public function Shutdown(string serverUser, string serverPass)
	{
		var resourceClass;
		let resourceClass = new Shutdown(this);

		return resourceClass->run(serverUser, serverPass);
	}

	/**
	 * Database Connect method
	 *
	 * @param string serverUser Username to connect to the OrientDB server
	 * @param string serverPass Password to connect to the OrientDB server
	 * @return array
	 */
	public function Connect(string serverUser, string serverPass)
	{
		var resourceClass;
		let resourceClass = new Connect(this);

		return resourceClass->run(serverUser, serverPass);
	}

	/**
	 * Database Open method
	 *
	 * @param string dbName Name of the database to open
	 * @param string dbType Type of the database: document|graph
	 * @param string dbUser Username for the database
	 * @param string dbPass Password of the user
	 * @return array
	 */
	public function DBOpen(string dbName, string dbType, string dbUser, string dbPass)
	{
		var resourceClass;
		let resourceClass = new DBOpen(this);

		return resourceClass->run(dbName, dbType, dbUser, dbPass);
	}

	/**
	 * Create database method
	 *
	 * @param string dbName      Name of the new database
	 * @param string dbType      Type of the new database: document|graph, "document" by default
	 * @param string storageType Storage type of the new database: plocal|memory, "plocal" by default
	 * @return array
	 */
	public function DBCreate(string dbName, string dbType = "document", string storageType = "plocal")
	{
		this->canPerformServerOperation();

		var resourceClass;
		let resourceClass = new DBCreate(this);

		return resourceClass->run(dbName, dbType, storageType);
	}

	/**
	 * Check if database exists method
	 *
	 * @param string dbName Name of the database to check
	 * @return array
	 */
	public function DBExist(string dbName)
	{
		this->canPerformServerOperation();

		var resourceClass;
		let resourceClass = new DBExist(this);

		return resourceClass->run(dbName);
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
	 * Select method
	 *
	 * @param string dbName Name of the database to open
	 * @param string dbType Type of the database: document|graph
	 * @return array
	 */
	public function select(string query, string fetchplan = "*:0")
	{
		this->canPerformDatabaseOperation();

		var resourceClass;
		let resourceClass = new Select(this);

		return resourceClass->run(query, fetchplan);
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