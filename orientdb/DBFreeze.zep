/**
 * OrientDB DBFreeze class
 * Freezes a database.
 * Flushes all cached content to the disk storage and allows to perform only read commands. 
 * Database will be "frozen" till release database command will not been executed.
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
 * DBFreeze() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DBFreeze extends OperationAbstract
{
	protected _dbName;
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

		let this->operation = OperationAbstract::REQUEST_DB_FREEZE;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param string dbName Name of the database to check
	 * @param string storageType Storage type of the database: plocal|local|memory, "plocal" by default
	 * @return boolean
	 */
	public function run(string dbName, string storageType = "plocal") -> boolean
	{
		let this->_dbName = dbName;
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
		this->addByte(chr(this->operation));

		let this->session = this->parent->getSession();
		this->addInt(this->session);

		// database name
		this->addString(this->_dbName);
		// storage type
		this->addString(this->_storage);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return boolean
	 */
	protected function parseResponse() -> boolean
	{
		var status;

		let status = this->readByte(this->socket);
		let this->session = this->readInt(this->socket);
		this->parent->setSession(this->session);
		//if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
		if (ord(status) == OperationAbstract::STATUS_SUCCESS) {
			return true;
		}
		else {
			this->handleException();
		}

		return false;
	}
}