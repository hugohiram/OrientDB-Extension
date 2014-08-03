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

Use Exception;

/**
 * DBOpen() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DBOpen extends OperationAbstract
{
	protected _dbName;
	protected _dbType;
	protected _dbUser;
	protected _dbPass;

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
	 * @param string dbName Name of the database to open
	 * @param string dbType Type of the database: document|graph
	 * @param string dbUser Username for the database
	 * @param string dbPass Password of the user
	 * @return string
	 */
	public function run(string dbName, string dbType, string dbUser, string dbPass) -> string
	{
		let this->_dbName = dbName;
		let this->_dbType = dbType;
		let this->_dbUser = dbUser;
		let this->_dbPass = dbPass;

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

		// db name
		this->addString(this->_dbName);
		// db type
		this->addString(this->_dbType);
		// db user
		this->addString(this->_dbUser);
		// db pass
		this->addString(this->_dbPass);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return array
	 */
	protected function parseResponse() -> array
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

			return ["numClusters":numClusters, "clusters":clusters, "config":config, "release":release];
		}
		else {
			if (status == (chr(OperationAbstract::STATUS_ERROR))) {
				let session = this->readInt(this->socket);
				this->parent->setSessionServer(session);

				this->handleException();

				throw new Exception("Could not open database, maybe it doesn't exist, try the DBExist operation", 400);
			}
			else {
				throw new Exception("unknown error", 400);
			}
		}

		return [];
	}
}