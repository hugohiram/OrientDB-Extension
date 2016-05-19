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
use Exception;

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
	private raw;
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
	 */
	public function __construct(content, boolean autoDecode = true, boolean debug = false)
	{
		let this->isDecoded = false;
		let this->raw = content;
		let this->data = new stdClass();
		let this->metadata = [];
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
		var tmpData;
		let tmpData = this->data;
		let tmpData->{name} = value;

		let this->data = tmpData;
	}

	/**
	 * Getter, if content is not decoded then decode
	 *
	 * @param string name Name of the property
	 * @return mixed
	 */
	public function __get(name)
	{
		syslog(LOG_DEBUG, __METHOD__ . " - " . name );
		if name == "metadata" {
			return this->getMetadata();
		}

		if (!this->isDecoded) {
			//decode
			this->_decode();
		}

		if isset this->data->{name} {
			return this->data->{name};
		}

		if (this->debug == true) {
			syslog(LOG_DEBUG, __METHOD__ . " - " . name . ": null");
		}

		return null;
	}

	/**
	 * Caller to decoder
	 */
	private function _decode() -> void
	{
		var e;
		var decoder;
		try {
			if (this->debug == true) {
				syslog(LOG_DEBUG, __METHOD__ . " - Start");
			}

			let decoder = new OrientdbRecordDataDecoder(this->raw, this->debug);
			if (this->debug == true) {
				syslog(LOG_DEBUG, __METHOD__ . " - getJson");
			}
			let this->json = decoder->getJson();

			if (this->debug == true) {
				syslog(LOG_DEBUG, __METHOD__ . " - json_decode");
			}
			let this->data = json_decode(this->json);

			if (this->debug == true) {
				syslog(LOG_DEBUG, __METHOD__ . " - getMetadata");
			}
			let this->metadata = decoder->getMetadata();

			if (this->debug == true) {
				syslog(LOG_DEBUG, __METHOD__ . " - getClassname");
			}
			let this->className = decoder->getClassname();

			if (this->debug == true) {
				syslog(LOG_DEBUG, __METHOD__ . " - End, record decoded");
			}

			let this->isDecoded = true;
		} catch \Exception, e {
			if (this->debug == true) {
				syslog(LOG_DEBUG, __METHOD__ . " EXCEPTION: " . e->getMessage());
			}

			let this->isDecoded = false;
		}
	}

	/**
	 * Caller to decoder
	 */
	public function replace(string regex, string replacement) -> void
	{
		let this->json = preg_replace(regex, replacement, this->json);
		let this->json = preg_replace("/(\\\\+)/", "\\\\\\", this->json);
		let this->data = json_decode(this->json);
	}

	public function getJson() -> string
	{
		return this->json;
	}

    /**
     * Return metadata
     *
     * @return array
     */
	public function getMetadata() -> array
	{
		if (this->debug == true) {
			syslog(LOG_DEBUG, __METHOD__ );
		}
		return this->metadata;
	}

	/**
	 * Returns the name of the class
	 *
	 * @return string
	 */
	private function getClassname() -> string
	{
		if (this->debug == true) {
			syslog(LOG_DEBUG, __METHOD__ );
		}
		return this->className;
	}
}