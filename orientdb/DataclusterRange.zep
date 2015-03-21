/**
 * OrientDB DataclusterRange class
 * Returns the range of record ids for a cluster.
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
 * DataclusterRange() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DataclusterRange extends OperationAbstract
{
	protected _cluster;

	/**
	 * Orientdb\DataclusterRange constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_DATACLUSTER_DATARANGE;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param int cluster ID of the cluster
	 * @return long
	 */
	public function run(int cluster) -> long
	{
		let this->_cluster = cluster;

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

		this->addByte(chr(this->operation));
		let this->session = this->parent->getSession();
		this->addInt(this->session);

		// (cluster-number:short)
		this->addShort(this->_cluster);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return long
	 */
	protected function parseResponse() -> long
	{
		var status, begin, end;

		let status = this->readByte(this->socket);
		let this->session = this->readInt(this->socket);
		this->parent->setSession(this->session);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let begin = (string)this->readLong(this->socket);
			let end = (string)this->readLong(this->socket);
			return begin . end;
		}
		else {
			this->handleException();
		}

		return 0;
	}
}