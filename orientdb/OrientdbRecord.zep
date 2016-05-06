/**
 * OrientDB Record class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

/**
 * OrientdbRecord for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package Operation
 * @subpackage Command
 */
class OrientdbRecord
{
	// Type of record, d: document, f: flat data, b: raw bytes
	protected type { set, get, toString };
	// Name of the class
	protected classname { set, get };
	// Cluster number
	protected cluster { set, get };
	// Position on cluster
	protected position { set, get };
	// ID of record
	protected rid { set, get };
	// version of the document
	protected version { set, get };
	// raw content of the record
	protected content { set, get };
	// raw extra of the record
	protected extra { set, get };
	// raw fetch of the record
	protected fetched { set, get };
	// decoded data
	protected data { set, get };

	protected debug;

	/**
	 * Orientdb\OrientdbRecord constructor
	 */
	public function __construct(boolean debug = false)
	{
		let this->debug = debug;
		//echo __CLASS__;
	}

	/**
	 * Setter
	 *
	 * @param string name  Name of the property
	 * @param mixed  value Value of the property
	 */
	public function __set(name, value) -> void
	{
		if (property_exists(this, name)) {
			let this->{name} = value;
		}
	}

	/**
	 * Getter
	 *
	 * @param string name Name of the property
	 * @return mixed
	 */
	public function __get(name)
	{
		if (property_exists(this, name)) {
			return this->{name};
		}

		return null;
	}

	/**
	 * Merge fetched records
	 *
	 * @return void
	 */
	public function mergeFetchedRecords() -> void
	{
		if (this->debug == true) {
			syslog(LOG_DEBUG, __METHOD__ . " - Merging fetched records");
		}
		var item;

		if (this->data instanceof "OrientdbRecordData") {
			var tmp;
			let tmp = this->data->keyname;
		}

		if (count(this->fetched) > 0) {
		    if (this->debug == true) {
        		syslog(LOG_DEBUG, __METHOD__ . " - records to merge: " . count(this->fetched));
        	}
			for item in this->fetched {
				var regex, rid;

				let rid = "#" . item->cluster . ":" . item->position;
				let regex = "/(\"" . rid . "\")/";
				////let regex = "/(" . rid . ")\\b/";
				
				item->mergeFetchedRecords();

				var jsonStr;
				let jsonStr = substr_replace(item->data->json, "\"@rid\":\"" . rid . "\"," , 1, 0);

				this->data->replace(regex, jsonStr);
			}

			unset(this->fetched);
		}
	}
}