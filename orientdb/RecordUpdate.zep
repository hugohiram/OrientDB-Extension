/**
 * OrientDB RecordUpdate class
 * Update a record. Returns the new record's version.
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
 * RecordUpdate() Operation for OrientDB
 * https://github.com/orientechnologies/orientdb/wiki/Network-Binary-Protocol#request_record_update
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class RecordUpdate extends OperationAbstract
{
	protected _cluster;
	protected _position;
	protected _content;
	protected _version;
	protected _update;
	protected _type;
	protected _mode;

	/**
	 * Orientdb\RecordUpdate constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_RECORD_UPDATE;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param int	  cluster  ID of the cluster of the record
	 * @param int	  position Position of the record
	 * @param var     content  Content to update
	 * @param int	  version  Version of the record, or policy: -1 = version increment, no version control, -2 = no version control nor increment
	 * @param boolean update   Type of update: true = content has changed, false = relations have changed
	 * @param string  type	   Type of data: b = raw, f = flat, d = document
	 * @param boolean mode	   Sync mode: false = synchronous (default), true = asynchronous
	 * @return array
	 */
	public function run(int cluster, long position, var content, int version, boolean update, string type, boolean mode) -> array
	{
	    if is_array(content) {
	        let this->_content = content;
	    }
	    elseif is_object(content) {
	        let this->_content = get_object_vars(content);
	    }

		let this->_cluster = cluster;
		let this->_position = position;
		let this->_version = version;
		let this->_update = update;
		let this->_type	= type;
		let this->_mode	= mode;

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

        // (cluster-id:short)
        this->addShort(this->_cluster);
        // (cluster-position:long)
        this->addLong(this->_position);
		if (this->parent->protocolVersion >= 23) {
			// (update-content:boolean)
			this->addBoolean(this->_update);
		}
		// (record-content:bytes)
		this->addBytes(self::serializeContent(this->_content, this->parent->debug));
        // (record-version:int)
        this->addInt(this->_version);
		// (record-type:byte)
		this->addByte(this->_type);
		// (mode:byte)
		this->addBoolean(this->_mode);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return integer
	 */
	protected function parseResponse() -> int|null
	{
		var status, version, collections;

		let status = this->readByte(this->socket);
		let this->session = this->readInt(this->socket);
		this->parent->setSession(this->session);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
		    if (this->parent->debug == true) {
            	syslog(LOG_DEBUG, __METHOD__ . " - Success");
            }
			let version = this->readInt(this->socket);
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

            return version;
		}
		else {
			this->handleException();
		}

		return null;

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