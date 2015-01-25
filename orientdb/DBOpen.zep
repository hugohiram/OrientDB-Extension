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

use Orientdb\Exception\OrientdbException;

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
	 * @param boolean stateless  Set a stateless connection using a token based session
	 * @return string
	 */
	public function run(string dbName, string dbType, string dbUser, string dbPass, boolean stateless) -> string
	{
		let this->_dbName = dbName;
		let this->_dbType = dbType;
		let this->_dbUser = dbUser;
		let this->_dbPass = dbPass;
		let this->_stateless = stateless;

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
				this->addByte((int)this->_stateless);
			}
		}

		// db name (database-name:string)
		this->addString(this->_dbName);
		// db type (database-type:string)
		this->addString(this->_dbType);
		// db user (user-name:string)
		this->addString(this->_dbUser);
		// db pass (user-password:string)
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
		var token;

		//list(protocol, status, transaction) = this->getBasicResponse();
		let protocol = this->readShort(this->socket);
		let status = this->readByte(this->socket);
		let transaction = this->readInt(this->socket);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let session = this->readInt(this->socket);
			this->parent->setSessionDB(session);

			if (this->parent->protocolVersion > 26) {
				let token = this->readString(this->socket);
				this->parent->setSessionToken(token);
			}

			let numClusters = this->readShort(this->socket);
			let clusters = [];
			var pos;
			for pos in range(1, numClusters) {
				let cluster = [
					"name": this->readString(this->socket),
					"id":   this->readShort(this->socket),
					"type": (this->parent->protocolVersion < 24)? this->readString(this->socket) : null,
					"datasegmentid": (this->parent->protocolVersion < 24)? this->readShort(this->socket)  : null
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

				throw new OrientdbException("Could not open database, maybe it doesn't exist, try the DBExist operation", 400);
			}
			else {
				throw new OrientdbException("unknown error", 400);
			}
		}

		return [];
	}
}