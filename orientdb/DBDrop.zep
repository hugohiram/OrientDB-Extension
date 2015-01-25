/**
 * OrientDB DBDrop class
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
 * DBDrop() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DBDrop extends OperationAbstract
{
	protected _dbName;
	protected _storageType;

	/**
	 * Orientdb\DBDrop constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_DB_DROP;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param string dbName      Name of the database to drop
	 * @param string storageType Storage type of the database to drop: plocal|memory
	 * @return string
	 */
	public function run(string dbName, string storageType = "plocal") -> string
	{
		let this->_dbName = dbName;
		let this->_storageType = storageType;

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
		this->addString(this->_storageType);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return void
	 */
	protected function parseResponse()
	{
		var session, status;

		let status = this->readByte(this->socket);
		let session = this->readInt(this->socket);
		this->parent->setSessionServer(session);

		if (status != (chr(OperationAbstract::STATUS_SUCCESS))) {
			this->handleException();
		}
	}
}