/**
 * OrientDB RecordData class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

use stdClass;

/**
 * OrientdbRecordData for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package Operation
 * @subpackage Command
 */
class OrientdbRecordData
{
	private data;
	private metadata;
	private json;
	private content;
	private isDecoded;
	private debug;
	private className;

	/**
	 * Orientdb\OrientdbRecordData constructor
	 *
	 * @param string  content     Content to decode
	 * @param boolean autoDecode  If set to false, records won't decoded automatically, set it to true if records are
	 *                            not going to be used, this will save some time on execution time in that case only
	 * @param boolean debug       Enabled debug, write to syslog, "false" by default
	 *
	 * @return OrientdbRecordData
	 */
	public function __construct(content, boolean autoDecode = true, boolean debug = false)
	{
		let this->isDecoded = false;
		let this->content = content;
		let this->data = new stdClass();
		let this->metadata = new stdClass();
		let this->json = "";
		let this->debug = debug;
		let this->className = "";

        if (autoDecode == true) {
		    this->_decode();
		}
	}

	/**
	 * Setter
	 *
	 * @param string name  Name of the property
	 * @param mixed  value Value of the property
	 */
	public function __set(string name, value) -> void
	{
	    //let this->data->{name} = value;
	}

	/**
	 * Getter, if content is not decoded then decode
	 *
	 * @param string name Name of the property
	 * @return mixed
	 */
	public function __get(name)
	{
		if (!this->isDecoded) {
			//decode
			this->_decode();
		}

		if isset this->data->{name} {
			return this->data->{name};
		}

		return null;
	}

	/**
	 * Caller to decoder
	 */
	private function _decode() -> void
	{
		var decoder;
		let decoder = new OrientdbRecordDataDecoder(this->content, this->debug);
		let this->json = decoder->getJson();
		let this->data = json_decode(this->json);
		let this->metadata = decoder->getMetadata();
		let this->className = decoder->getClassname();

		let this->isDecoded = true;		
	}

	/**
	 * Caller to decoder
	 */
	public function replace(string regex, string replacement) -> void
	{
		let this->json = preg_replace(regex, replacement, this->json);
		let this->data = json_decode(this->json);
	}

	public function getJson() -> string
	{
		return this->json;
	}

	public function getMetadata() -> string
	{
		return this->metadata;
	}

	/**
	 * Returns the name of the class
	 *
	 * @return string
	 */
	private function getClassname() -> string
	{
		return this->className;
	}
}