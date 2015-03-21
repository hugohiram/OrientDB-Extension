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
	 * @param var     content Content of the new record
	 * @param string  type	  Type of data: b = raw, f = flat, d = document
	 * @param boolean mode	  false = synchronous (default), true = asynchronous
	 * @param int	  cluster Number of data segment
	 * @return array
	 */
	public function run(int cluster, var content, string type, boolean mode, int segment) -> array
	{
	    if is_array(content) {
	        let this->_content = content;
	    }
	    elseif is_object(content) {
	        let this->_content = get_object_vars(content);
	    }

		let this->_cluster = cluster;
		let this->_type	= type;
		let this->_mode	= mode;
		let this->_segment = segment;

		let this->_record = new OrientdbRecord();

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
			let record->content = json_encode(this->_content);
			//let record->data = new OrientdbRecordData(record->content);

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
			if (this->parent->debug == true) {
				syslog(LOG_DEBUG, __METHOD__ . " - Status: error");
			}
			this->handleException();
		}

		return [];
	}
}