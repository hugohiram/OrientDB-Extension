/**
 * OrientDB DBSize class
 * Asks for the size of a database in the OrientDB Server instance.
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
 * DBSize() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DBSize extends OperationAbstract
{
	/**
	 * Orientdb\DBSize constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_DB_SIZE;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @return long
	 */
	public function run() -> long
	{
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
		let this->transaction = this->parent->getSessionDB();

		this->addByte(chr(this->operation));
		this->addInt(this->transaction);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return long
	 */
	protected function parseResponse() -> long
	{
		var session, status, size;

		let status = this->readByte(this->socket);
		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let session = this->readInt(this->socket);
			this->parent->setSessionServer(session);
			let size = this->readLong(this->socket);
			return size;
		}
		else {
			this->handleException();
		}

		return 0;
	}
}