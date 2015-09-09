/**
 * OrientDB Select Query class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

/**
 * Query() command for OrientDB
 * https://github.com/orientechnologies/orientdb/wiki/Network-Binary-Protocol#request_command
 * http://orientdb.com/docs/last/Network-Binary-Protocol.html#request_command
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package Operation
 * @subpackage Command
 */
class Query extends RequestCommand
{
	//const OPERATION = 3;
	//const COMMAND = 2;

	protected _query;
	protected _limit;
	protected _fetchplan;

	const MODE = "s"; //synchronous mode
	const CLASSNAME = "com.orientechnologies.orient.core.sql.query.OSQLSynchQuery";

	/**
	 * Main method to run the operation
	 * 
	 * @param string query        Query to execute
	 * @param int    limit        Limit on the query, by default limit from query
	 * @param string fetchplan    Fetchplan, no fetchplan by default
	 * @param boolean autoDecode  If set to false, records won't decoded automatically, set it to true if records are
	 *                            not going to be used, this will save some time on execution time in that case only
	 * @return string
	 */
	public function run(string query, int limit = -1, string fetchplan = "*:0", boolean autoDecode = true)
	{
		let this->_query = query;
		let this->_limit = limit;
		let this->_fetchplan = fetchplan;
		let this->_autoDecode = autoDecode;

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
		//(mode:byte)(command-payload-length:int)(class-name:string)(command-payload)
		var commandPayload;
		this->addByte(self::MODE);

		//(text:string)(non-text-limit:int)[(fetch-plan:string)](serialized-params:bytes[])
		let commandPayload = "";
		let commandPayload .= this->addBytes(self::CLASSNAME, false);
		let commandPayload .= this->addBytes(trim(this->_query), false);
		let commandPayload .= this->addInt(this->_limit, false);//pack("N", this->_limit);
		let commandPayload .= this->addBytes(this->_fetchplan, false);
		let commandPayload .= this->addInt(0, false);//pack("N", 0);

		this->addString(commandPayload);
	}

}