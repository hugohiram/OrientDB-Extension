/**
 * OrientDB DBCreate class
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
 * DBCreate() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DBCreate extends OperationAbstract
{
	protected _dbName;
	protected _dbType;
	protected _storage;


	/**
	 * Orientdb\DBOpen constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_DB_CREATE;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param string dbName      Name of the new database
	 * @param string dbType      Type of the new database: document|graph, "document" by default
	 * @param string storageType Storage type of the new database: plocal|memory, "plocal" by default
	 * @return string
	 */
	public function run(string dbName, string dbType = "document", string storageType = "plocal") -> string
	{
		let this->_dbName = dbName;
		let this->_dbType = dbType;
		let this->_storage = storageType;

		this->prepare();
		this->execute();
		let this->response = this->parseResponse();

		return this->response;
	}

	/**
	 * Prepare the parameters
	 * 
	 * @return void
	 */
	protected function prepare() -> void
	{
		this->resetRequest();
		let this->transaction = this->parent->getSessionServer();
		this->addByte(chr(this->operation));
		this->addInt(this->transaction);

		// database name
		this->addString(this->_dbName);
		// database type
		this->addString(this->_dbType);
		// storage type
		this->addString(this->_storage);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return void
	 */
	protected function parseResponse() -> void
	{
		var session, status;

		let status = this->readByte(this->socket);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let session = this->readInt(this->socket);
			this->parent->setSessionServer(session);
		}
		else {
			if (status == (chr(OperationAbstract::STATUS_ERROR))) {
				let session = this->readInt(this->socket);
				this->parent->setSessionServer(session);

				this->handleException();
			}
			else {
				throw new OrientdbException("unknown error", 400);
			}
		}
	}
}