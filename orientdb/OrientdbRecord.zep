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
	protected type;
	// Name of the class
	//protected classname { set, get };
	// Cluster number
	protected cluster;
	// Position on cluster
	protected position;
	// ID of record
	protected rid = "";
	// version of the document
	protected version;
	// raw content of the record
	protected content;
	// raw extra of the record
	protected extra;
	// raw fetch of the record
	protected fetched { set, get };
	// decoded data
	protected data;
	// debug flag
	protected debug;
	// autodecode flag
	protected _autoDecode;


	/**
	 * Orientdb\OrientdbRecord constructor
	 */
	public function __construct(boolean autodecode = false, boolean debug = false)
	{
		let this->_autoDecode = autodecode;
		let this->debug = debug;
		let this->content = [];

		if (this->debug == true) {
	   		syslog(LOG_DEBUG, __METHOD__ );
	   	}
	}

	/**
	 * Setter
	 *
	 * @param string name  Name of the property
	 * @param mixed  value Value of the property
	 */
	public function __set(name, value) -> void
	{
		if (this->debug == true) {
	   		syslog(LOG_DEBUG, __METHOD__ . " - name: " . name);
	   	}

		if (property_exists(this, name)) {
			let this->{name} = value;
		}
		else {
			let this->content[name] = value;
			if (name == "raw") {
				let this->data = new OrientdbRecordData(value, this->_autoDecode, this->debug);

				if this->_autoDecode {
					let this->content["json"] = this->data->getJson();
					let this->content["classname"] = this->data->getClassname();
					let this->content["properties"] = this->data->getMetadata();
				}
				else {
					let this->content["json"] = null;
					let this->content["classname"] = null;
					let this->content["properties"] = null;
				}
			}
		}

		this->setRid();
	}

	/**
	 * Getter
	 *
	 * @param string name Name of the property
	 * @return mixed
	 */
	public function __get(name)
	{
		if (this->debug == true) {
	   		syslog(LOG_DEBUG, __METHOD__ . " - name: " . name);
	   	}
		if (property_exists(this, name)) {
			return this->{name};
		}
		elseif (array_key_exists(name, this->content)) {
			return this->content[name];
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
				if (this->debug == true) {
                    syslog(LOG_DEBUG, __METHOD__ . " - rid: " . rid);
                    syslog(LOG_DEBUG, __METHOD__ . " - json: " . item->data->json);
				}
				item->mergeFetchedRecords();

				var jsonStr;
				let jsonStr = substr_replace(item->data->json, "\"@rid\":\"" . rid . "\"," , 1, 0);

				this->data->replace(regex, jsonStr);
			}

			unset(this->fetched);
		}

		let this->content["json"] = this->data->getJson();

        if empty this->content["classname"] {
            let this->content["classname"] = this->data->getClassname();
        }

        if empty this->content["properties"] {
            let this->content["properties"] = this->data->getMetadata();
        }

        this->setRid();
	}

	/**
	 * Set the RID
	 *
	 * @return void
	 */
	public function setRid() -> void
	{
		if (empty(this->rid) && !empty(this->cluster) && !empty(this->position)) {
			let this->rid = "#" . this->cluster . ":" . this->position;
			if (this->debug == true) {
			    syslog(LOG_DEBUG, __METHOD__ . " - RID: " . this->rid);
			}
		}
	}
}