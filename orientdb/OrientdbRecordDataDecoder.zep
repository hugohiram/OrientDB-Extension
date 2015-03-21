/**
 * OrientDB RecordDataDecoder class
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
 * OrientdbRecordDataDecoder for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package Decoder
 * @subpackage Command
 */
class OrientdbRecordDataDecoder
{
	protected content;
	protected jsonContent;
	protected position;
	protected index;
	protected metadata;
	protected element;
	protected className;
	protected property;

	const PROPERTY 	= 1;
	const VALUE 	= 2;

	/**
	 * Orientdb\OrientdbRecordDataDecoder constructor
	 *
	 * @param string content Content to decode
	 */
	public function __construct(content)
	{
		let this->content = content;
		let this->position = 0;
		let this->index = 0;
		let this->jsonContent = "";
		let this->element = [];
		let this->property = "";
		let this->metadata = new stdClass();

		this->decode(this->content);
	}

	/**
	 * Get decoded content
	 *
	 * @param boolean asObject return JSON as object, false by default
	 * @return string
	 */
	public function getJson(asObject = false)
	{
		var response = [];
		if (asObject) {
			let response = json_decode(this->jsonContent);

			return response[0];
		}

		return this->jsonContent;
	}

	/**
	 * Get metadata of decoded content
	 *
	 * @return array
	 */
	public function getMetadata() -> array
	{
		return this->metadata;
	}

	/**
	 * Decode content
	 *
	 * @param string sTransformation content to decode
	 */
	private function decode(sTransformation) -> void
	{
		int contentLength;
		var cChar, buffer, content;

		// get the @class
		let sTransformation = this->getClassname(sTransformation);

		// list to array
		let sTransformation = this->convertSetToList(sTransformation);

		// RID link to string, RID linksets to string
		let sTransformation = this->convertRidToString(sTransformation);

		let contentLength = strlen(sTransformation);
		array_push(this->element, self::PROPERTY);

		while (this->index <= contentLength) {
			let cChar = substr(sTransformation, this->index, 1);

			if (end(this->element) == self::PROPERTY) {
				// property name
				let this->property = this->decodePropertyName(sTransformation);
				this->buildJson(this->property, true);
				this->buildJson(substr(sTransformation, this->index, 1));

				array_push(this->element, self::VALUE);
			}
			else {
				if (end(this->element) == self::VALUE) {
					let content = substr(sTransformation, this->position);

					switch cChar {
						case "[":
								// list
								let this->position = this->index + 1;
								let buffer = this->decodeList(content);
								break;
						case "{":
								// map
								let this->position = this->index + 1;
								let buffer = this->decodeMap(content);
								break;
						case "(":
								// emdedded, emdeddedset
								let this->position = this->index + 1;
								let buffer = this->decodeEmbedded(content);
								break;
						case "\"":
								// string
								let buffer = this->decodeString(content);
								break;
						case "#":
								// link
								let buffer = this->decodeLink(content);
								break;
						case "t":
						case "f":
								// boolean
								let buffer = this->decodeBoolean(content);
								break;
						default:
								if (is_numeric(cChar)) {
									// numeric
									let buffer = this->decodeNumericSimple(content);
								}
								else {
									// empty
									let buffer = "null";
								}
								break;
					}

					this->buildJson(buffer);
					array_pop(this->element);

					if (this->index + 1 < contentLength) {
						let cChar = substr(sTransformation, this->index, 1);
						if (cChar == ",") {
							this->buildJson(cChar);
						}
					}
				}
			}

			let this->index++;
		}

		array_pop(this->element);

		this->closeJson();
	}

	/**
	 * Method to build the JSON
	 *
	 * @param string  buffer New content of the json
	 * @param boolean quote  Quote the content
	 */
	private function buildJson(buffer, quote = false) -> void
	{
		if (quote) {
			let buffer = "\"" . buffer . "\"";
		}

		//let this->jsonContent .= buffer;
		let this->jsonContent = this->jsonContent . buffer;
	}

	/**
	 * Finish building the JSON
	 */
	private function closeJson() -> void
	{
		let this->jsonContent = "[{" . this->jsonContent . "}]";
	}

	/**
	 * Get the name of the class from the content
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function getClassname(content) -> string
	{
		var pos_colon, pos_at, key;
		let pos_colon = strpos(content, ":");		
		let pos_at = strpos(content, "@");
		if (pos_at !== false && pos_at < pos_colon) {
			let key = substr(content, 0, pos_at);
			let this->className = key;
			let content = substr(content, strlen(key) + 1);

			this->buildJson("@class", true);
			this->buildJson(":");
			this->buildJson(key, true);
			this->buildJson(",");
		}

		return content;
	}

	/**
	 * Get the property name from the content
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function decodePropertyName(content) -> string
	{
		var pos, ending, key;
		let pos = strpos(content, ":", this->index);
		let ending = pos - this->index;
		let key = substr(content, this->index, ending);
		let this->index = pos;
		let this->position = this->index + 1;

		return key;
	}

	/**
	 * convert classname to property
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function convertEmbeddedClassnames(content) -> string
	{
		// embeddedset class
		var pattern, replacement;
		let pattern = "/\\(([a-zA-Z0-9_-]+)\\@/";
		let replacement = "(@class:\"$1\",";
		let content = preg_replace(pattern, replacement, content);

		return content;
	}

	/**
	 * convert RID to string
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function convertRidToString(content) -> string
	{
		var pattern, replacement;
		let pattern = "/(?!\")(\\#\\d+\\:\\d+)(?!\")/";
		let replacement = "\"$1\"";
		let content = preg_replace(pattern, replacement, content);

		return content;
	}

	/**
	 * convert Set to list
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function convertSetToList(content) -> string
	{
		// convert from a set:	<1,2,3>, <#10:3,#10:4> and <(name:"Luca")>
		// to a list: 			[1,2,3], [#10:0,#10:2] and [(name:"Luca")]
		let content = str_replace("<", "[", content);
		let content = str_replace(">", "]", content);

		return content;
	}

	/**
	 * Decode a list
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function decodeList(content) -> string
	{
		// list: list, linklist, linkset
		// [1,2,3] | [#10:0,#10:2] and [(name:"Luca")]
		int index = 0, level = 0, groupLevel = 0, contentLength = 0, startgroup = 0;
		var cChar, group, buffer, decoder, embeddedResult, embeddedString = "";
		boolean complex = false, groupActive = false;
		let contentLength = strlen(content);
		if (substr(content, 1, 1) == "(") {
			let complex = true;
			let startgroup = 1;
			let groupActive = false;
		}

		while (index <= contentLength) {
			//let cChar = content[index];
			let cChar = substr(content, index, 1);
			let index++;
			
			if (cChar == "[") {
				let level++;
			}
			else {
				if (cChar == "]") {
					let level--;
				}
			}

			if(complex) {
				if (cChar == "(") {

					let groupLevel++;
					let groupActive = true;
				}
				else {
					if (cChar == ")") {
						let groupLevel--;
					}
				}

				if (groupLevel == 0 && groupActive) {
					let group = substr(content, startgroup, index - startgroup);

					let decoder = new OrientdbRecordDataDecoder(substr(group, 1, -1));
					let embeddedResult = decoder->getJson();
					let startgroup = index + 1;
					let groupActive = false;
					
					let embeddedString .= embeddedResult . ",";
				}
			}

			if (level == 0) {
				break;
			}
		}

		let buffer = substr(content, 0, index);

		//let this->index += strlen(buffer);
		let this->index = this->index + strlen(buffer);
		let this->position = this->index;

		if (embeddedString) {
			let embeddedString = trim(embeddedString, ",");
			let buffer = "[" . embeddedString . "]";
		}

		this->setMetadata("list");

		return buffer;
	}

	/**
	 * Decode a link
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function decodeLink(content) -> string
	{
		// link
		// #10:0 | [#10:0,#10:2]
		string pattern;
		var buffer, matches = [];
		let pattern = "/^\\#\\d+\\:\\d+/";
		preg_match(pattern, content, matches);

		let buffer = matches[0];
		
		//let this->index += strlen(buffer);
		let this->index = this->index + strlen(buffer);
		let this->position = this->index;

		this->setMetadata("link");

		return buffer;
	}

	/**
	 * Decode a map
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function decodeMap(content) -> string
	{
		// maps
		// {"database_name":"fred","database_alias":null})
		int index = 0, level = 0, contentLength = 0;
		var cChar, buffer;
		let contentLength = strlen(content);
		while (index <= contentLength) {
			//let cChar = content[index];
			let cChar = substr(content, index, 1);
			let index++;
			
			if (cChar == "{") {
				let level++;
			}
			else {
				if (cChar == "}") {
					let level--;
				}
			}

			if (level == 0) {
				break;
			}
		}

		let buffer = substr(content, 0, index);

		//let this->index += strlen(buffer);
		let this->index = this->index + strlen(buffer);
		let this->position = this->index;

		this->setMetadata("map");

		return buffer;
	}

	/**
	 * Decode an embedded
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function decodeEmbedded(content) -> string
	{
		// embedded, embeddedsets and embeddedmaps
		// (name:"rules"), (name@@type:"document",name:"Bob")
		int index = 0, level = 0, contentLength = 0;
		var buffer, tmpBuffer, decoder, cChar;
		let contentLength = strlen(content);
		while (index <= contentLength) {
			//let cChar = content[index];
			let cChar = substr(content, index, 1);
			let index++;
			
			if (cChar == "(") {
				let level++;
			}
			else {
				if (cChar == ")") {
					let level--;
				}
			}

			if (level == 0) {
				break;
			}
		}

		let tmpBuffer = substr(content, 0, index);

		//let this->index += strlen(tmpBuffer);
		let this->index = this->index + strlen(tmpBuffer);
		let this->position = this->index;

		let decoder = new OrientdbRecordDataDecoder(substr(tmpBuffer, 1, -1));
		let buffer = decoder->getJson();

		this->setMetadata("embedded");

		return buffer;
	}

	/**
	 * Decode a string
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function decodeString(content) -> string
	{
		string pattern;
		var buffer, matches = [];
		let pattern = "/\"(?:\\\\.|[^\"\\\\])*\"/";
		preg_match(pattern, content, matches);

		let buffer = matches[0];
		//let this->index += bufferLength; //doesnt work...
		let this->index = this->index + strlen(buffer);
		let this->position = this->index + 1;

		this->setMetadata("string");

		return buffer;
	}

	/**
	 * Decode a boolean
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function decodeBoolean(content) -> string
	{
		// boolean
		string pattern;
		var buffer, matches = [];
		let pattern = "/^(true|false)/";
		preg_match(pattern, content, matches);
		
		let buffer = matches[0];
		//let this->index += strlen(buffer);
		let this->index = this->index + strlen(buffer);
		let this->position = this->index + 1;

		this->setMetadata("boolean");
		
		return buffer;
	}

	/**
	 * Decode a numeric value
	 *
	 * @param string content Content to parse
	 * @return string
	 */
	private function decodeNumericSimple(content) -> string
	{
		var buffer = "", matches = [];
		int offset;
		if (preg_match("/^\\d+(b)/", content, matches) || // byte: 124b
			preg_match("/^\\d+(s)/", content, matches) || // short: 124s
			preg_match("/^\\d+(l)/", content, matches) || // long: 124l
			preg_match("/^[-+]?(\\d*[.])?\\d+(f)/", content, matches) || // float: 120.3f
			preg_match("/^[-+]?(\\d*[.])?\\d+(d)/", content, matches) || // double: 120.3d
			preg_match("/^\\d+(t)/", content, matches) || // datetime: 1296279468000t
			preg_match("/^\\d+(a)/", content, matches)) { // date: 1306281600000a
		    int length;
			let length = strlen(matches[0]);
			if (length == 14 && (matches[1] == "t" || matches[1] == "a")) {
			    let offset = -4;
			}
			else {
			    let offset = -1;
			}
		}
		else {
			if (preg_match("/^\\d+/", content, matches)) { // integer: 124
				let offset = strlen(matches[0]);
			}
			else {
				let offset = 0;
			}
		}

		if !empty matches {
			let buffer = substr(matches[0], 0, offset);
			//let this->index += strlen(matches[0]);
			let this->index = this->index + strlen(matches[0]);
			let this->position = this->index + 1;
		}

		return buffer;
	}

	/**
	 * Decode a numeric value
	 *
	 * @param string content Content to parse
	 * @return mixed
	 */
	private function decodeNumeric(content)
	{
		string dataType = "", cast = "";
		var buffer = "", matches = [];
		int offset = -1;
		//let offset = -1;
		if (preg_match("/^\\d+b/", content, matches)) {
			// byte
			// 124b
			let dataType = "byte";
			let cast = "int";
		}
		else {
			if (preg_match("/^\\d+s/", content, matches)) {
				// short
				// 124s
				let dataType = "short";
				let cast = "int";
			}
			else {
				if (preg_match("/^\\d+l/", content, matches)) {
					// long
					// 124l
					let dataType = "long";
					let cast = "int";
				}
				else {
					if (preg_match("/^[-+]?(\\d*[.])?\\d+f/", content, matches)) {
						// float
						// 120.3f
						let dataType = "float";
						let cast = "float";
					}
					else {
						if (preg_match("/^[-+]?(\\d*[.])?\\d+d/", content, matches)) {
							// double
							// 120.3d
							let dataType = "double";
							let cast = "float";
						}
						else {
							if (preg_match("/^\\d+t/", content, matches)) {
								// datetime
								// 1296279468000t
								let dataType = "datetime";
								let cast = "string";
							}
							else {
								if (preg_match("/^\\d+a/", content, matches)) {
									// date
									// 1306281600000a
									let dataType = "date";
									let cast = "string";
								}
								else {
									if (preg_match("/^\\d+/", content, matches)) {
										// integer
										// 124
										let dataType = "integer";
										let offset = strlen(matches[0]);
										let cast = "int";
									}
									else {
										let dataType = "unknown";
										let offset = 0;
									}
								}
							}
						}
					}
				}
			}
		}

		if !empty matches {
			let buffer = substr(matches[0], 0, offset);
			settype(buffer, cast);
			//let this->index += strlen(matches[0]);
			let this->index = this->index + strlen(matches[0]);
			let this->position = this->index + 1;
			this->setMetadata(dataType);
		}

		return buffer;
	}


	protected function setMetadata(datatype)
	{
		/*
		var cChar, propertyName;
		let propertyName = this->property;
		let cChar = substr(propertyName, 0, 1);
		if (cChar == "@") {
			return null;
		}

		if !empty propertyName {
			let this->metadata[propertyName] = datatype;
		}
		var_dump(this->metadata);
		*/
	}

}
