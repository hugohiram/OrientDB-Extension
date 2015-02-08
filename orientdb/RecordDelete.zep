/**
 * OrientDB RecordDelete class
 * Delete a record by its RecordID. During the optimistic transaction the record will be deleted 
 * only if the versions match. Returns true if has been deleted otherwise false.
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
 * RecordDelete() Operation for OrientDB
 * https://github.com/orientechnologies/orientdb/wiki/Network-Binary-Protocol#request_record_delete
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class RecordDelete extends OperationAbstract
{
	protected _cluster;
	protected _position;
	protected _version;
	protected _mode;

	/**
	 * Orientdb\RecordDelete constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_RECORD_DELETE;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param int     cluster  ID of the cluster of the record
	 * @param long    position Limit on the query, by default limit from query
	 * @param int     version  version of the record
	 * @param boolean mode     false = synchronous or true = asynchronous, sync as default.
	 * @return boolean
	 */
	public function run(int cluster, long position, int version, boolean mode) -> boolean
	{
		let this->_cluster = cluster;
		let this->_position = position;
		let this->_version = version;
		let this->_mode = mode;

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
		// (record-version:int)
		this->addInt(this->_version);
		// (mode:byte)
		this->addBoolean(this->_mode);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return boolean
	 */
	protected function parseResponse() -> boolean
	{
		var status;

		let status = this->readByte(this->socket);
		let this->session = this->readInt(this->socket);
		this->parent->setSession(this->session);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			var result;
			let result = this->readByte(this->socket);
			return (boolean)ord(result);
		}
		else {
			this->handleException();
		}

		return false;
	}
}