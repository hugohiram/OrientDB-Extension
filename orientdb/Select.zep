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
	 * @return string
	 */
	public function run()
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
		string fetchplan;
		var query, commandPayload;
		let query = parameters[0];
		let fetchplan = isset(parameters[1]) ? parameters[1] : "*:0";

		this->addByte(chr(this->operation));

		let this->transaction = this->parent->getSessionDB();
		this->addInt(this->transaction);

		this->addByte(self::MODE);

		let commandPayload = "";
		let commandPayload .= this->addBytes(self::CLASSNAME, false);
		let commandPayload .= this->addBytes(trim(query), false);
		let commandPayload .= pack("N", -1);
		let commandPayload .= this->addBytes(fetchplan, false);
		let commandPayload .= pack("N", 0);

		this->addString(commandPayload);
		//var_dump(this->requestMessage);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return string
	 */
	protected function parseResponse()
	{
		var status;
		var transaction;
		var recordsCount;
		var records;

		let status = this->readByte(this->socket);
		
		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let transaction = this->readInt(this->socket);
			let status = this->readByte(this->socket);
			if (status == "l") {
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
			}
			else {
				if (status == "n") {
	                // Null
	                return null;
            	}
            	else {
            		if (status == "r") {
                		// Single record
                		return this->readRecord();
            		}
            		else {
            			if (status == "a") {
                			// Something other
                			return this->readString(this->socket);
                		}
                	}
                }
            }
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