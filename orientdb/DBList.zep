/**
 * OrientDB DBList class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

use Exception;

/**
 * DBList() Operation for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class DBList extends OperationAbstract
{

	/**
	 * Orientdb\DBList constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->parent = parent;
		let this->socket = parent->socket;

		let this->operation = OperationAbstract::REQUEST_DB_LIST;
	}

	/**
	 * Main method to run the operation
	 * 
	 * @return string
	 */
	public function run() -> string
	{
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
		let this->transaction = this->parent->getSessionServer();
		this->addByte(chr(this->operation));
		this->addInt(this->transaction);
	}

	/**
	 * Parse the response from the socket
	 * 
	 * @return array
	 */
	protected function parseResponse() ->array
	{
		var session, status;
		var content, decoder, databases;

		let status = this->readByte(this->socket);
		let session = this->readInt(this->socket);
		this->parent->setSessionServer(session);

		if (status == (chr(OperationAbstract::STATUS_SUCCESS))) {
			let content = this->readString(this->socket);
			let decoder = new OrientdbRecordDataDecoder(content);
			let databases = get_object_vars(decoder->getJson(true)->databases);

			return databases;
		}
		else {
			if (status == (chr(OperationAbstract::STATUS_ERROR))) {
				this->handleException();
			}
		}

		return [];
	}
}