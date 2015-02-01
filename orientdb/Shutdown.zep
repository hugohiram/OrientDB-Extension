/**
 * OrientDB Shutdown class
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
 * Shutdown() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class Shutdown extends OperationAbstract
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
		let this->session = this->parent->getSession();
		let this->operation = OperationAbstract::REQUEST_SHUTDOWN;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param string serverUser Username to connect to the OrientDB server
	 * @param string serverPass Password to connect to the OrientDB server
	 * @return void
	 */
	public function run(string serverUser, string serverPass) -> void
	{
		let this->_serverUser = serverUser;
		let this->_serverPass = serverPass;

		this->prepare();
		this->execute();
		this->parseResponse();
	}

	/**
	 * Prepare the parameters
	 * 
	 * @return void
	 */
	protected function prepare() -> void
	{
		this->resetRequest();
		let this->session = this->parent->getSession();
		this->addByte(chr(this->operation));
		this->addInt(this->session);

		// server's username
		this->addString(this->_serverUser);
		// server's password
		this->addString(this->_serverPass);
	}

	/**
	 * Parse the response from the socket
	 */
	protected function parseResponse() -> void
	{
		var status;

		let status = this->readByte(this->socket);
		let this->session = this->readInt(this->socket);
		this->parent->setSession(this->session);

		if (status == (chr(OperationAbstract::STATUS_ERROR))) {
			this->handleException();
		}
		else {
			if (status != (chr(OperationAbstract::STATUS_SUCCESS))) {
				throw new OrientdbException("unknown error", 400);
			}
		}
	}
}