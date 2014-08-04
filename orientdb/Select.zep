/**
 * OrientDB Select class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

/**
 * Select() command for OrientDB
 * https://github.com/orientechnologies/orientdb/wiki/Network-Binary-Protocol#request_command
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package Operation
 * @subpackage Command
 */
class Select extends OperationAbstract
{
	//const OPERATION = 3;
	//const COMMAND = 2;

	protected _query;
	protected _fetchplan;

	const MODE = "s"; //synchronous mode
	const CLASSNAME = "com.orientechnologies.orient.core.sql.query.OSQLSynchQuery";

	/**
	 * Orientdb\Select constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		//this->mode = self::COMMAND;
		let this->operation = OperationAbstract::REQUEST_COMMAND;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param string query Query to execute
	 * @return string
	 */
	public function run(string query, string fetchplan = "*:0")
	{
		let this->_query = query;
		let this->_fetchplan = fetchplan;

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
		var commandPayload;

		let this->transaction = this->parent->getSessionDB();
		this->addByte(chr(this->operation));
		this->addInt(this->transaction);

		this->addByte(self::MODE);

		let commandPayload = "";
		let commandPayload .= this->addBytes(self::CLASSNAME, false);
		let commandPayload .= this->addBytes(trim(this->_query), false);
		let commandPayload .= pack("N", -1);
		let commandPayload .= this->addBytes(this->_fetchplan, false);
		let commandPayload .= pack("N", 0);

		this->addString(commandPayload);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return string
	 */
	protected function parseResponse()
	{
		var status, session;
		var recordsCount, records, resultType;

		let status = this->readByte(this->socket);
		let session = this->readInt(this->socket);
		this->parent->setSessionDB(session);
		
		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let resultType = this->readByte(this->socket);
			switch resultType {
				case "l":
					// List of records
					let recordsCount = this->readInt(this->socket);
					if (recordsCount == 0) {
						return false;
					}

					let records = [];
					var pos;
					for pos in range(1, recordsCount) {
						let records[] = this->readRecord();
					}

					return records;

				case "r":
					// Single record
					return [this->readRecord()];

				case "n":
					// Null
					return null;

				case "a":
					// Something other
					return this->readString(this->socket);

				default:
					break;
			}
		}
		else {
			this->handleException();
		}
	}

	/**
	 * Read record from socket
	 * 
	 * @return OrientdbRecord
	 */
	protected function readRecord()// -> OrientdbRecord
	{
		var marker, clusterID, recordPos, record;

		let marker = this->readShort(this->socket);

		if (marker == -2) {
			// no record
			return false;
		}

        if (marker == -3) {
        	let clusterID = this->readShort(this->socket);
			let recordPos = this->readLong(this->socket);
		}

		let record = new OrientdbRecord();
		let record->type = this->readByte(this->socket);
		let record->cluster = this->readShort(this->socket);
		let record->position = this->readLong(this->socket);
		let record->version = this->readInt(this->socket);
		let record->content = this->readBytes(this->socket);
		let record->data = new OrientdbRecordData(record->content);

		return record;
	}
}