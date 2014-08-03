/**
 * OrientDB DBClose class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

/**
 * DBOpen() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DBClose extends OperationAbstract
{

	/**
	 * Orientdb\DBClose constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;
		let this->transaction = -1;
		let this->operation = OperationAbstract::REQUEST_DB_OPEN;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @return string
	 */
	public function run()
	{
		this->prepare();
		this->execute();
		let this->response = this->parseResponse();

		return this->response;
	}

	/**
	 * Prepare the parameters
	 * 
	 * @param array parameters Array of parameters
	 */
	protected function prepare() -> void
	{
		this->resetRequest();
		this->addByte(chr(this->operation));
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return boolean
	 */
	protected function parseResponse()
	{
		this->parent->setSessionDB(null);

		return true;
	}
}