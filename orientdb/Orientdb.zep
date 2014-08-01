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

//use Orientdb\Exception\ConnectionException;
use Exception; //RuntimeException, DomainException;

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
			throw new Exception(this->errno, this->errstr);
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
	 * Database Open method
	 *
	 * @return array
	 */
	public function DBOpen()
	{
		var resourceClass;
		let resourceClass = new DBOpen(this);

		return call_user_func_array([resourceClass, "run"], func_get_args());
	}

	/**
	 * Select method
	 *
	 * @return array
	 */
	public function select()
	{
		var resourceClass;
		let resourceClass = new Select(this);
		
		return call_user_func_array([resourceClass, "run"], func_get_args());
	}


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
}