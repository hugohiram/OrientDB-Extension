/**
 * OrientDB DataclusterCount class
 * Returns the number of records in one or more clusters.
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
 * DataclusterCount() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DataclusterCount extends OperationAbstract
{
	protected _clusters;
	protected _count;
	protected _tombstones;

	/**
	 * Orientdb\DataclusterCount constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_DATACLUSTER_COUNT;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param array   clusters  Array with the numbers of the clusters
	 * @param boolean tombstone whether deleted records should be taken in account autosharded storage only
	 * @return long
	 */
	public function run(array clusters, boolean tombstone = false) -> long
	{
		let this->_clusters = clusters;
		let this->_count = count(clusters);
		let this->_tombstones = "false";

		if (this->_count == 0) {
			throw new OrientdbException("Array cannot be empty", 400);
		}

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
		var cluster;

		this->resetRequest();
		let this->transaction = this->parent->getSessionDB();

		this->addByte(chr(this->operation));
		this->addInt(this->transaction);

		// (cluster-count:short)
		this->addShort(this->_count);

		for cluster in this->_clusters {
			// (cluster-number:short)
			this->addShort(cluster);
		}

		// (count-tombstones:byte)
		this->addByte(this->_tombstones);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return long
	 */
	protected function parseResponse() -> long
	{
		var status, session, records;

		let status = this->readByte(this->socket);
		let session = this->readInt(this->socket);
		this->parent->setSessionServer(session);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let records = this->readLong(this->socket);
			return records;
		}
		else {
			this->handleException();
		}

		return 0;
	}
}