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
	protected _autoDecode;

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

		let this->session = this->parent->getSession();
		this->addInt(this->session);

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
		var recordsCount, fetchCount, record, records, fetchRecords, resultType;

		if (this->parent->debug == true) {
			syslog(LOG_DEBUG, "------------------------ PARSING RESPONSE ------------------------");
		}

		let status = this->readByte(this->socket);
		let this->session = this->readInt(this->socket);
		this->parent->setSession(this->session);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let resultType = this->readByte(this->socket);
			if (this->parent->debug == true) {
				syslog(LOG_DEBUG, __METHOD__ . " - Result Type: " . resultType);
			}
			switch resultType {
				case "l":
					// List of records
					let recordsCount = this->readInt(this->socket);
					if (this->parent->debug == true) {
						syslog(LOG_DEBUG, __METHOD__ . " - records: " . recordsCount);
					}
					if (recordsCount == 0) {
						this->readByte(this->socket);
						return false;
					}

					let records = [];
					let fetchRecords = [];
					var pos;
					for pos in range(1, recordsCount) {
						if (this->parent->debug == true) {
							syslog(LOG_DEBUG, "------------------------ NEW RECORD ------------------------");
							syslog(LOG_DEBUG, __METHOD__ . " - record #" . pos);
						}
						let record = this->readRecord();
						let records[] = record;
						if (this->parent->debug == true) {
							syslog(LOG_DEBUG, "------------------------ END RECORD ------------------------");
						}
					}

					let status = this->readByte(this->socket);
					while (ord(status) != 0) {
						if (this->parent->debug == true) {
							syslog(LOG_DEBUG, __METHOD__ . " - status fetch: " . ord(status));
						}

						let record = this->readRecord();

						if (ord(status) == 1) {
							let records[] = record;
						}
						elseif (ord(status) == 2) {
							let fetchRecords[] = record;
						}
						let status = this->readByte(this->socket);
					}

					let fetchCount = count(fetchRecords);
					if (this->parent->debug == true) {
						syslog(LOG_DEBUG, __METHOD__ . " - status fetch: " . ord(status));
						syslog(LOG_DEBUG, __METHOD__ . " - Fetch records found: " . fetchCount);
					}
					if (fetchCount > 0) {
						var posFetch, pattern, fetchRecord, fetchRecordTmp;
						let recordsCount--;
						let fetchCount--;
						// aggressive fetchplan merge, search and replace all records with the retrieved fetch records
						// TODO: find a better alternative for the cases of column-specific fetchplans
						for pos in range(0, recordsCount) {
							for posFetch in range(0, fetchCount) {
								if (this->parent->debug == true) {
									syslog(LOG_DEBUG, __METHOD__ . " - Fetching record: " . posFetch);
								}
								let fetchRecord = fetchRecords[posFetch];

								var rid;
								let rid = "#" . fetchRecord->cluster . ":" . fetchRecord->position;

								let fetchRecordTmp = json_decode(fetchRecord->data->getJson());
								let fetchRecordTmp->{"@rid"} = rid;
								let pattern = "/\"" . rid . "\"/";

								if (this->parent->debug == true) {
									syslog(LOG_DEBUG, __METHOD__ . " - replacing pattern: " . pattern);
									syslog(LOG_DEBUG, __METHOD__ . " - replacing with: " . fetchRecord->data->getJson());
								}

								records[pos]->data->replace($pattern, json_encode(fetchRecordTmp, JSON_UNESCAPED_UNICODE));
							}
						}
					}

					let result = records;

					break;

				case "r":
					// Single record
					let record = [this->readRecord()];
					this->readByte(this->socket);

					let result = (this->_class == "Command")? record[0] : record;

					if (this->parent->debug == true) {
						syslog(LOG_DEBUG, __METHOD__ . " - Result: " . json_encode(result, JSON_UNESCAPED_UNICODE));
					}
					break;

				case "n":
					// Null
					this->readByte(this->socket);
					let result =  true;

					if (this->parent->debug == true) {
						syslog(LOG_DEBUG, __METHOD__ . " - Result: true");
					}
					break;

				case "a":
					// Other
					var tmp;
					let result = this->readString(this->socket);
					if (this->parent->debug == true) {
						syslog(LOG_DEBUG, __METHOD__ . " - Result: " . result);
					}
					if (result == "true" || result == "false") {
						let result = (result == "true")? true : false;
					}

					let tmp = this->readByte(this->socket);

					if (this->parent->debug == true) {
						syslog(LOG_DEBUG, __METHOD__ . " - " . tmp);
					}
					break;

				default:
					throw new OrientdbException("unknown response", 400);
			}

			if (this->parent->debug == true) {
				syslog(LOG_DEBUG, "------------------------ PARSING RESPONSE END ------------------------");
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
		if (this->parent->debug == true) {
			syslog(LOG_DEBUG, __METHOD__ );
		}
		var marker, record;

		let marker = this->readShort(this->socket);
		if (this->parent->debug == true) {
			syslog(LOG_DEBUG, __METHOD__ . " - marker: " . marker);
		}
		if (marker == -2) {
			// no record
			return false;
		}

		let record = new OrientdbRecord(true, this->parent->debug);
		if (marker == -3) {
			let record->cluster = this->readShort(this->socket);
			let record->position = this->readLong(this->socket);
		}
		else {
			let record->type = this->readByte(this->socket);
			let record->cluster = this->readShort(this->socket);
			let record->position = this->readLong(this->socket);
			// TODO: Find the right way to set the ID
			//let record->rid = "#" . record->cluster . ":" . record->position;
			let record->version = this->readInt(this->socket);
			let record->raw = this->readBytes(this->socket);
			if (this->parent->debug == true) {
				syslog(LOG_DEBUG, __METHOD__ . " - @RID: " . record->rid);
				//syslog(LOG_DEBUG, __METHOD__ . " - Raw: " . record->raw);
			}
			// TODO:Refactor next lines
			//let record->data = new OrientdbRecordData(record->raw, this->_autoDecode, this->parent->debug);
			//let record->classname = record->data->getClassName();
			//if (this->parent->debug == true) {
				// all properties from 'record' are protected, the log will show empty
				//syslog(LOG_DEBUG, __METHOD__ . " - data: " . json_encode(record));
			//}
		}
		if (this->parent->debug == true) {
			syslog(LOG_DEBUG, __METHOD__ . " - End" );
		}

		return record;
	}
}