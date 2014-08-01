/**
 * OrientDB DBOpen class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

/**
 * DBOpen() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DBOpen extends OperationAbstract
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
		let this->operation = OperationAbstract::REQUEST_DB_OPEN;
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
		this->addString(parameters[2]);
		this->addString(parameters[3]);
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
		var numClusters;
		var cluster;
		var clusters;
		var config;
		var release;

		//list(protocol, status, transaction) = this->getBasicResponse();
		let protocol = this->readShort(this->socket);
		let status = this->readByte(this->socket);
		let transaction = this->readInt(this->socket);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let session = this->readInt(this->socket);
			this->parent->setSessionDB(session);
			let numClusters = this->readShort(this->socket);
			let clusters = [];
			var pos;
			for pos in range(1, numClusters) {
				let cluster = [
					"name": this->readString(this->socket),
					"id": this->readShort(this->socket),
					"type": this->readString(this->socket),
					"datasegmentid": this->readShort(this->socket)
				];
				
				let clusters[] = cluster;
			}

			let config = this->readBytes(this->socket);
			let release = this->readString(this->socket);
		}
	}
}