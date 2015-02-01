/**
 * OrientDB Command class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

/**
 * Command() command for OrientDB
 * https://github.com/orientechnologies/orientdb/wiki/Network-Binary-Protocol#request_command
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package Operation
 * @subpackage Command
 */
class Command extends RequestCommand
{
	//const OPERATION = 3;
	//const COMMAND = 2;

	protected _query;

	const MODE = "s"; //synchronous mode
	const CLASSNAME = "com.orientechnologies.orient.core.sql.OCommandSQL";

	/**
	 * Main method to run the operation
	 * 
	 * @param string query SQL Query to execute
	 * @return string
	 */
	public function run(string query)
	{
		let this->_query = query;

		this->prepare();
		this->execute();
		let this->response = this->parseResponse();

		return this->response;
	}

	/**
	 * Set the payload
	 * 
	 * @return void
	 */
	protected function setCommandPayload() -> void
	{
		var commandPayload;
		this->addByte(self::MODE);

		let commandPayload = "";
		let commandPayload .= this->addBytes(self::CLASSNAME, false);
		let commandPayload .= this->addBytes(trim(this->_query), false);
		let commandPayload .= pack("N", 0);

		this->addString(commandPayload);
	}

}