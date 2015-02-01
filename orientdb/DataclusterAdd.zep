/**
 * OrientDB DataclusterAdd class
 * Add a new data cluster.
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
 * DataclusterAdd() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DataclusterAdd extends OperationAbstract
{
	protected _clusterName;
	protected _clusterId;

	/**
	 * Orientdb\DataclusterAdd constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_DATACLUSTER_ADD;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @param string name Name of the new cluster
	 * @param short  id   ID of the cluster
	 * @return int
	 */
	public function run(string name, int id) -> int
	{
		let this->_clusterName = name;
		let this->_clusterId = id;

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

		// (name:string)
		this->addString(this->_clusterName);
		// (cluster-id:short)
		this->addShort(this->_clusterId);

		/*if (this->parent->protocolVersion < 24) {
			type
			location
			datasegment-name
		}*/
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return int
	 */
	protected function parseResponse() -> int
	{
		var status, cluster;

		let status = this->readByte(this->socket);
		let this->session = this->readInt(this->socket);
		this->parent->setSession(this->session);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let cluster = this->readShort(this->socket);
			return cluster;
		}
		else {
			this->handleException();
		}

		return 0;
	}
}