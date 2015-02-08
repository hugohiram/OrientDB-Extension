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

	/**
	 * Orientdb\OrientdbRecordData constructor
	 *
	 * @param string content Content to decode
	 */
	public function __construct(content)
	{
		let this->isDecoded = false;
		let this->content = content;
		let this->data = new stdClass();
		let this->metadata = new stdClass();
		let this->json = "";
	}

	/**
	 * Setter
	 *
	 * @param string name  Name of the property
	 * @param mixed  value Value of the property
	 */
	public function __set(name, value) -> void
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
		let decoder = new OrientdbRecordDataDecoder(this->content);
		let this->data = decoder->getJson(true);
		let this->json = json_encode(this->data);
		let this->metadata = decoder->getMetadata();

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
}