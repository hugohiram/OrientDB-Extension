/**
 * OrientDB RequestCommand class
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
 * RequestCommand class
 * https://github.com/orientechnologies/orientdb/wiki/Network-Binary-Protocol#request_command
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package Operation
 * @subpackage Command
 */
class RequestCommand extends OperationAbstract
{
	//const OPERATION = 3;
	//const COMMAND = 2;

	protected _query;
	protected _class;

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

		var calledClass;
		let calledClass = get_called_class();
		let this->_class = substr(calledClass, strpos(calledClass, "\\") + 1);
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

		let this->transaction = this->parent->getSessionDB();
		this->addInt(this->transaction);

		this->setCommandPayload();
	}

	/**
	 * Set the payload
	 * 
	 * @return void
	 */
	protected function setCommandPayload() -> void
	{
		
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return string
	 */
	protected function parseResponse()
	{
		var status, result;
		var recordsCount, record, records, resultType;

		let status = this->readByte(this->socket);
		let this->transaction = this->readInt(this->socket);
		this->parent->setSessionDB(this->transaction);

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

					let status = this->readByte(this->socket);

					while (ord(status) != 0) {
						let record = this->readRecord();
						if (ord(status) == 1) {
							let records[] = record;
						}
						let status = this->readByte(this->socket);
					}

					let result = records;
					break;

				case "r":
					// Single record
					let record = [this->readRecord()];
					this->readByte(this->socket);

					let result = (this->_class == "Command")? record[0] : record;
					break;

				case "n":
					// Null
					let result =  true;
					break;

				case "a":
					// Something other
					let result = this->readString(this->socket);
					this->readByte(this->socket);
					break;

				default:
					throw new OrientdbException("unknown response", 400);
			}

			return result;
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