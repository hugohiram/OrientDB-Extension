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
	//protected id { set, get };
	// version of the document
	protected version { set, get };
	// raw content of the record
	protected content { set, get };
	// 
	//protected properties { set, get };
	// decoded data
	protected data { set, get };

	/**
	 * Orientdb\OrientdbRecord constructor
	 */
	public function __construct()
	{
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
}