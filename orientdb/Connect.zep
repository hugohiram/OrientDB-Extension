/**
 * OrientDB Connect class
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
 * Connect() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class Connect extends OperationAbstract
{
	protected _serverUser;
	protected _serverPass;

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
		let this->transaction = -1;
		let this->operation = OperationAbstract::REQUEST_CONNECT;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param string serverUser Username to connect to the OrientDB server
	 * @param string serverPass Password to connect to the OrientDB server
	 * @return string
	 */
	public function run(string serverUser, string serverPass) -> string
	{
		let this->_serverUser = serverUser;
		let this->_serverPass = serverPass;

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
		this->addInt(this->transaction);

		this->addString(this->parent->driverName);
		this->addString(this->parent->driverVersion);
		this->addShort(this->parent->protocolVersion);
		this->addString(this->parent->clientId);
		//this->addString(this->parent->serialization);

		// server's username
		this->addString(this->_serverUser);
		// server's password
		this->addString(this->_serverPass);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return void
	 */
	protected function parseResponse() -> void
	{
		var protocol, status, session, transaction;

		let protocol = this->readShort(this->socket);
		let status = this->readByte(this->socket);
		let transaction = this->readInt(this->socket);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let session = this->readInt(this->socket);
			this->parent->setSessionServer(session);
		}
		else {
			if (status == (chr(OperationAbstract::STATUS_ERROR))) {
				this->handleException();
			}
			else {
				throw new OrientdbException("unknown error", 400);
			}
		}
	}
}