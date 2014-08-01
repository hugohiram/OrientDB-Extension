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

/**
 * Connect() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class Connect extends OperationAbstract
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
		let this->transaction = -1;
		let this->operation = OperationAbstract::REQUEST_CONNECT;
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
		this->addInt(this->transaction);

		this->addString(this->parent->driverName);
		this->addString(this->parent->driverVersion);
		this->addShort(this->parent->protocolVersion);
		this->addString(this->parent->clientId);
		//this->addString(this->parent->serialization);

		this->addString(parameters[0]);
		this->addString(parameters[1]);
	}

	/**
	 * Parse the response from the socket
	 */
	protected function parseResponse() -> void
	{
		var protocol;
		var status;
		var transaction;
		var session;

		let protocol = this->readShort(this->socket);
		let status = this->readByte(this->socket);
		let transaction = this->readInt(this->socket);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let session = this->readInt(this->socket);
			this->parent->setSessionServer(session);
		}
		else {
			// [(1)(exception-class:string)(exception-message:string)]*(0)(serialized-exception:bytes)
			var exceptionClass;
			//var exceptionClass, exceptionMessage;
			let exceptionClass = this->readString(this->socket);
			//let exceptionMessage = this->readString(this->socket);
		}
	}
}