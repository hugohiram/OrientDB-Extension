/**
 * OrientDB DataclusterDrop class
 * Remove a cluster.
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
 * DataclusterDrop() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DataclusterDrop extends OperationAbstract
{
	protected _clusterNumber;

	/**
	 * Orientdb\DataclusterDrop constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_DATACLUSTER_DROP;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param short number Number of the cluster to delete
	 * @return int
	 */
	public function run(int number) -> int
	{
		let this->_clusterNumber = number;

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

		// (cluster-number:short)
		this->addShort(this->_clusterNumber);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return int
	 */
	protected function parseResponse() -> int
	{
		var status, deleted;

		let status = this->readByte(this->socket);
		let this->session = this->readInt(this->socket);
		this->parent->setSession(this->session);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let deleted = this->readBoolean(this->socket);
			return deleted;
		}
		else {
			this->handleException();
		}

		return 0;
	}
}