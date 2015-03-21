/**
 * OrientDB RecordCreate class
 * Create a new record. Returns the position in the cluster of the new record. 
 * New records can have version > 0 (since v1.0) in case the RID has been recycled.
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
 * RecordCreate() Operation for OrientDB
 * https://github.com/orientechnologies/orientdb/wiki/Network-Binary-Protocol#request_record_create
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class RecordCreate extends OperationAbstract
{
	protected _segment;
	protected _cluster;
	protected _content;
	protected _type;
	protected _mode;

	protected _record;

	/**
	 * Orientdb\RecordCreate constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_RECORD_CREATE;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param int	  cluster ID of the cluster of the record
	 * @param array   content Content of the new record
	 * @param string  type	  Type of data: b = raw, f = flat, d = document
	 * @param boolean mode	  false = synchronous (default), true = asynchronous
	 * @param int	  cluster Number of data segment
	 * @return array
	 */
	public function run(int cluster, array content, string type, boolean mode, int segment) -> array
	{
		let this->_cluster = cluster;
		let this->_content = content;
		let this->_type	= type;
		let this->_mode	= mode;
		let this->_segment = segment;

		let this->_record = new OrientdbRecord();
		//let this->_record->type = this->_type;
		//let this->_record->cluster = this->_cluster;
		//let this->_record->content = this->_content;

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
		let this->session = this->parent->getSession();

		this->addByte(chr(this->operation));
		this->addInt(this->session);

		if (this->parent->protocolVersion < 24) {
			// (datasegment-id:short)
			this->addInt(this->_segment);
		}

		// (cluster-id:short)
		this->addShort(this->_cluster);
		// (record-content:bytes)
		this->addBytes(self::serializeContent(this->_content, this->parent->debug));
		// (record-type:byte)
		//this->addString(this->_type);
		this->addByte(this->_type);
		// (mode:byte)
		this->addBoolean(this->_mode);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return array
	 */
	protected function parseResponse() -> array
	{
		var status, record, collections;

		let status = this->readByte(this->socket);
		let this->session = this->readInt(this->socket);
		this->parent->setSession(this->session);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let record = new OrientdbRecord();
			let record->type = this->_type;
			let record->cluster = this->readShort(this->socket);
			let record->position = this->readLong(this->socket);
			let record->version = this->readInt(this->socket);
			let record->content = this->_content;
			let record->data = new OrientdbRecordData(record->content);

			let collections = this->readInt(this->socket);

			int idx;
			array changes;
			let changes = [];
			if (collections > 0) {
                for idx in range(0, collections) {
                    var change;
                    let change = [
                            "uuid-most-sig-bits"  : this->readLong(this->socket),
                            "uuid-least-sig-bits" : this->readLong(this->socket),
                            "updated-file-id"	  : this->readLong(this->socket),
                            "updated-page-index"  : this->readLong(this->socket),
                            "updated-page-offset" : this->readInt(this->socket)
                        ];
                    let changes[] = change;
                }
            }

			return record;
		}
		else {
			this->handleException();
		}

		return [];
	}

	/**
	 * Serialize the record before sending it to the server
	 *
	 * @param array	  cluster arrayValue array with the record data
	 * @param boolean cluster debug      Debug the process, false by default
	 * @return string
	 */
	public static function serializeContent(array arrayValue, boolean debug = false)
	{
		var items, sDocument;
		var key, value;

		let items = [];
		for key, value in arrayValue {
			let items[] = key . ":" . self::serialize( value );
		}

		let sDocument = implode( ",", items );

		if (debug == true) {
		    syslog(LOG_DEBUG, __CLASS__ . " - Document: " . sDocument);
        }

		return sDocument;
	}

	/**
	 * serialize value
	 *
	 * @param var value mixed datatype for the value to serialize
	 * @return string
	 */
	protected static function serialize(var value) -> string
	{
	    string regexDateTime;

		if ( value === null ) {
			return "null";
		}

		//let regexDateTime = "/^[0-9]{4}[\.\/\-](0[1-9]|1[0-2])[\.\/\-](0[1-9]|[1-2][0-9]|3[0-1])\\s?((([0-1][0-9])|([2][0-3])):([0-5][0-9]):([0-5][0-9]))?$/";
		let regexDateTime = "/^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])\\s?((([0-1][0-9])|([2][0-3])):([0-5][0-9]):([0-5][0-9]))?$/";
		//let regexDate = "/^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/";

        if (is_object(value) && ( value instanceof \DateTime )) {
        	return (string)value->getTimestamp() . "000t";
        }
		elseif ( is_string( value ) ) {
            if (preg_match(regexDateTime, value)) {
                var matches;
                string timeType;
                let matches = [];
                preg_match(regexDateTime, value, matches);
                let timeType = (count(matches) > 3)? "t" : "a";
                return (string)strtotime(value) . "000" . timeType;
			}
			elseif (preg_match("/^\\#\\d+\\:\\d+$/", value)) {
				return value;
			}

			return "\"" . str_replace( "\"", "\\\"", str_replace( "\\", "\\\\", value ) ) . "\"";
		} 
		elseif ( is_float( value ) ) {
			return value . "f";
		} 
		elseif ( is_int( value ) ) {
			return value;
		} 
		elseif ( is_bool( value ) ) {
			return value ? "true" : "false";
		}
		elseif ( is_array( value ) ) {
			return self::serializeArray( value );
		}
		else {
			return "";
		}
	}

	/**
	 * serialize array
	 *
	 * @param array arrayValue Array value to serialize
	 * @return string
	 */
	protected static function serializeArray( array arrayValue ) -> string
	{
		var key, value;
		array items;
		string valueString;
		boolean isEmbedded;
		var embeddedClass;

        let isEmbedded = false;
        let embeddedClass = "";
		let items = [];
		let valueString = "";
		if ((bool)count(array_filter(array_keys(arrayValue), "is_string"))) {
		    for key, value in arrayValue {
                if (key == "@class") {
                    let isEmbedded = true;
                    let embeddedClass = value;
                    continue;
                }

            	let items[] = key . ":" . self::serialize( value );
            }

            if (isEmbedded == true) {
                let valueString = "(" . embeddedClass . "@" . implode(",", items) . ")";
            }
            else {
                let valueString = "{" . implode(",", items) . "}";
            }
		}
		else {
		    for value in arrayValue {
		        let items[] = self::serialize( value );
		    }

		    let valueString = "[" . implode(",", items) . "]";
		}

        return valueString;
	}
}