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
}