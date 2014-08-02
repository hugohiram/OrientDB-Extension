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

use Exception;

/**
 * DBCreate() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DBCreate extends OperationAbstract
{

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
	 * @return string
	 */
	public function run() -> string
	{
		this->prepare(func_get_args());
		this->execute();
		let this->response = this->parseResponse();

		return this->response;
	}

	/**
	 * Prepare the parameters
	 * 
	 * @param array parameters Array of parameters
	 */
	protected function prepare(parameters) -> void
	{
		this->resetRequest();
		this->addByte(chr(this->operation));

		let this->transaction = this->parent->getSessionServer();
		this->addInt(this->transaction);

		// database name
		this->addString(parameters[0]);
		// database type
		this->addString(parameters[1]);
		// storage type
		this->addString(parameters[2]);
	}

	/**
	 * Parse the response from the socket
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
				throw new Exception("unknown error", 400);
			}
		}
	}
}