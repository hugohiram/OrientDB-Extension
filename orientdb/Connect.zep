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
	protected _stateless;

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
		let this->operation = OperationAbstract::REQUEST_CONNECT;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param string  serverUser Username to connect to the OrientDB server
	 * @param string  serverPass Password to connect to the OrientDB server
	 * @param boolean stateless  Set a stateless connection using a token based session
	 * @return boolean
	 */
	public function run(string serverUser, string serverPass, boolean stateless) -> boolean
	{
		let this->_serverUser = serverUser;
		let this->_serverPass = serverPass;
		let this->_stateless  = stateless;

		this->prepare();
		this->execute();
		this->parseResponse();

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
		this->addInt(this->session);

		// (driver-name:string)
		this->addString(this->parent->driverName);
		// (driver-version:string)
		this->addString(this->parent->driverVersion);
		// (protocol-version:short)
		this->addShort(this->parent->protocolVersion);
		// (client-id:string)
		this->addString(this->parent->clientId);

		if (this->parent->protocolVersion > 21) {
			// (serialization-impl:string)
			this->addString(this->parent->serialization);
			if (this->parent->protocolVersion > 26) {
				// (token-session:boolean)
				this->addBoolean(this->_stateless);
			}
		}

		// (user-name:string)
		this->addString(this->_serverUser);
		// (user-password:string)
		this->addString(this->_serverPass);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return void
	 */
	protected function parseResponse() -> void
	{
		var protocol, status, transaction, token, errorMessage;

		if (this->session <= 0) {
			let protocol = this->readShort(this->socket);
			if (protocol < this->parent->protocolVersion) {
				let errorMessage = "Database Server does not support protocol version " . protocol . ", max version allowed is v.". (string)this->parent->protocolVersion;
				throw new OrientdbException(errorMessage , 400);
			}
		}
		let status = this->readByte(this->socket);
		let transaction = this->readInt(this->socket);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let this->session = this->readInt(this->socket);
			this->parent->setSession(this->session);

			if (this->parent->protocolVersion > 26) {
				let token = this->readBytes(this->socket);
				if !empty token {
					this->parent->setToken(token);
				}
			}

			this->parent->setConnectStatus(true);

			let this->response = true;
		}
		else {
			if (status == (chr(OperationAbstract::STATUS_ERROR))) {
				this->handleException(401);
			}
			else {
				throw new OrientdbException("unknown error", 400);
			}
		}
	}
}