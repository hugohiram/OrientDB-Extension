/**
 * OrientDB RecordLoad class
 * Load a record by RecordID, according to a fetch plan
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
 * RecordLoad() Operation for OrientDB
 * https://github.com/orientechnologies/orientdb/wiki/Network-Binary-Protocol#request_record_load
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class RecordLoad extends OperationAbstract
{
	protected _cluster;
	protected _position;
	protected _fetchplan;
	protected _ignoreCache;
	protected _mergefetch;

	/**
	 * Orientdb\RecordLoad constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_RECORD_LOAD;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param int     cluster     ID of the cluster of the record
	 * @param int     position    Limit on the query, by default limit from query
	 * @param string  fetchplan   Fetchplan, no fetchplan by default
	 * @param boolean mergefetch  Merge fetchedplan data into the record
	 * @param boolean ignoreCache If the cache must be ignored: true = ignore the cache, false = not ignore
	 * @return array
	 */
	public function run(int cluster, int position, string fetchplan, boolean mergefetch, boolean ignoreCache) -> array
	{
		let this->_cluster = cluster;
		let this->_position = position;
		let this->_fetchplan = fetchplan;
		let this->_mergefetch = mergefetch;
		let this->_ignoreCache = ignoreCache;

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
		// (fetch-plan:string)
		this->addString(this->_fetchplan);
		// (ignore-cache:byte)
		this->addBoolean(this->_ignoreCache);
		// (load-tombstones:byte)
		this->addBoolean("false");
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return array
	 */
	protected function parseResponse() -> array
	{
		var status, record, payload;

		let record = null;

		let status = this->readByte(this->socket);
		let this->session = this->readInt(this->socket);
		this->parent->setSession(this->session);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let payload = this->readByte(this->socket);
			while (ord(payload) > 0) {
				if (ord(payload) == 1) {
					let record = new OrientdbRecord();
					let record->cluster = this->_cluster;
					let record->position = this->_position;

					if (this->parent->protocolVersion > 27) {
						//[(payload-status:byte)[(record-type:byte)(record-version:int)(record-content:bytes)]*]+
						let record->type = this->readByte(this->socket);
						let record->version = this->readInt(this->socket);
						let record->content = this->readBytes(this->socket);
					}
					else {
						//[(payload-status:byte)[(record-content:bytes)(record-version:int)(record-type:byte)]*]+
						let record->content = this->readBytes(this->socket);
						let record->version = this->readInt(this->socket);
						let record->type = this->readByte(this->socket);
					}

					let record->data = new OrientdbRecordData(record->content);
				}
				else {
					var fetched;
					let fetched = new OrientdbRecord();
					let fetched->extra = this->readShort(this->socket);
					let fetched->type = this->readByte(this->socket);
					let fetched->cluster = this->readShort(this->socket);
					let fetched->position = this->readLong(this->socket);
					let fetched->version = this->readInt(this->socket);
					let fetched->content = this->readBytes(this->socket);
					let fetched->data = new OrientdbRecordData(fetched->content);

					let record->fetched[] = fetched;
				}

				let payload = this->readByte(this->socket);
			}

			if (this->_mergefetch == true) {
				record->mergeFetchedRecords();
			}

			return record;
		}
		else {
			this->handleException();
		}

		return [];
	}
}