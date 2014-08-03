/**
 * OrientDB DBExist class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

use Exception;

/**
 * DBExist() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DBExist extends OperationAbstract
{
	protected _dbName;

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

		let this->operation = OperationAbstract::REQUEST_DB_EXIST;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param string dbName      Name of the database to check
	 * @return string
	 */
	public function run(string dbName) -> string
	{
		let this->_dbName = dbName;

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
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return boolean
	 */
	protected function parseResponse() -> boolean
	{
		var session, status, exists;

		let status = this->readByte(this->socket);
		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let session = this->readInt(this->socket);
			this->parent->setSessionServer(session);
			let exists = this->readByte(this->socket);

			switch ord(exists) {
				case 1:
					return true;
				case 0:
				default:
					return false;
			}
		}
		else {
			throw new Exception("could not check the database", 400);
		}

		return false;
	}
}