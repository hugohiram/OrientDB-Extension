/**
 * OrientDB Abstract operation class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

use Orientdb\Exception\OrientdbException;

/**
 * OperationAbstract() for OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Operation
 */
class OperationAbstract
{
	// Server (CONNECT Operations)
	const REQUEST_SHUTDOWN  = 1;
	const REQUEST_CONNECT   = 2;
	const REQUEST_DB_OPEN   = 3;
	const REQUEST_DB_CREATE = 4;
	const REQUEST_DB_EXIST  = 6;
	const REQUEST_DB_DROP   = 7;
	const REQUEST_DB_LIST	= 74;

	// Database (DB_OPEN Operations)
	const REQUEST_DB_CLOSE 	= 5;
	const REQUEST_DB_SIZE	= 8;
	const REQUEST_DB_COUNTRECORDS = 9;
	const REQUEST_DATACLUSTER_ADD	 = 10;
	const REQUEST_DATACLUSTER_DROP   = 11;
	const REQUEST_DATACLUSTER_COUNT  = 12;
	const REQUEST_DATACLUSTER_DATARANGE = 13;
	const REQUEST_DATASEGMENT_ADD	 = 20;
	const REQUEST_DATASEGMENT_REMOVE = 21;
	const REQUEST_RECORD_LOAD   = 30;
	const REQUEST_RECORD_CREATE = 31;
	const REQUEST_RECORD_UPDATE = 32;
	const REQUEST_RECORD_DELETE = 33;
	const REQUEST_COUNT 	  = 40;
	const REQUEST_COMMAND	  = 41;
	const REQUEST_TX_COMMIT   = 60;
	const REQUEST_CONFIG_GET  = 70;
	const REQUEST_CONFIG_SET  = 71;
	const REQUEST_CONFIG_LIST = 72;
	const REQUEST_DB_RELOAD   = 73;
	const REQUEST_DB_FREEZE   = 94;
	const REQUEST_DB_RELEASE  = 95;

	// Status
	const STATUS_SUCCESS = 0x00;
	const STATUS_ERROR   = 0x01;

	// Status
	const EXCEPTION_EMPTY = 0x00;
	const EXCEPTION_FOUND = 0x01;

	// Variables
	protected parent;
	protected socket;
	protected operation;
	protected requestMessage;
	protected arguments;
	//protected transaction;
	protected session;
	protected response;

	protected debug;

	/**
	 * Orientdb\OperationAbstract constructor
	 *
	 * @param object parent object of caller class
	 */
	public function __construct(parent)
	{
		//echo __CLASS__;
		let this->debug = false;
		let this->parent = parent;
		let this->socket = parent->socket;
	}

	/**
	 * Execute the operation, sends the data to the socket
	 *
	 * @return void
	 */
	protected function execute() -> void
	{
		this->socket->send(this->requestMessage);
	}

	/**
	 * Reset the request property
	 *
	 * @return void
	 */
	public function resetRequest() -> void
	{
		let this->requestMessage = "";
	}

	/**
	 * Read Raw data from socket
	 *
	 * @param object socket Object of the socket
	 * @param int	length length to read
	 * @return string
	 */
	protected function readRaw(socket, length) -> string
	{
		var data;
		let data = socket->read(length);

		return data;
	}

	/**
	 * Read "short" data from socket
	 *
	 * @param object socket Object of the socket
	 * @return int
	 */
	protected function readShort(socket) -> int
	{
		var data;
		var shortValue;
		let data = unpack("n", this->readRaw(socket, 2));
		let shortValue = Math::convertComplementShort(data);
		
		return shortValue;
	}

	/**
	 * Read "int" data from socket
	 *
	 * @param object socket Object of the socket
	 * @return int
	 */
	protected function readInt(socket) -> int
	{
		var data;
		uint intValue;
		int intResult;
		let data = unpack("N", this->readRaw(socket, 4));
		let intValue = (is_array(data))? data[1] : data;
		if (intValue > 4294967294) {
			let intResult = -((intValue ^ 0xFFFFFFFF) + 1);
			return intResult;
		}

		return intValue;
	}

	/**
	 * Read "byte/string" data from socket
	 *
	 * @param object socket Object of the socket
	 * @return string
	 */
	protected function readByte(socket) -> string
	{
		var data;
		let data = this->readRaw(socket, 1);

		return data;
	}

	/**
	 * Read "bytes" data from socket
	 *
	 * @param object socket Object of the socket
	 * @return string
	 */
	protected function readBytes(socket) -> string|null
	{
		var size, data;
		let size = this->readInt(socket);
		if (size === -1) {
			// @todo: check if changing this for an empty string has any effect
			return null;
		}
		if (size === 0) {
			return "";
		}

		let data = this->readRaw(socket, size);

		return data;
	}

	/**
	 * Read "string" data from socket
	 *
	 * @param object socket Object of the socket
	 * @return string
	 */
	protected function readString(socket) -> string|null
	{
		var data;
		var size;
		let size = this->readInt(socket);
		if (size === -1) {
			// @todo: check if changing this for an empty string has any effect
			return null;
		}
		if (size === 0) {
			return "";
		}

		let data = this->readRaw(socket, size);

		return data;
	}

	/**
	 * Read "boolean" data from socket
	 *
	 * @param object socket Object of the socket
	 * @return boolean
	 */
	protected function readBoolean(socket) -> boolean
	{
		var data;
		let data = this->readRaw(socket, 1);

		return (boolean)ord(data);
	}

	/**
	 * Read "long" data from socket
	 *
	 * @param object socket Object of the socket
	 * @return uint
	 */
	protected function readLong(socket) -> uint
	{
		var hi, low;

		// First of all, read 8 bytes, divided into hi and low parts
		let hi = unpack("N", this->readRaw(socket, 4));
		let hi = reset(hi);
		let low = unpack("N", this->readRaw(socket, 4));
		let low = reset(low);

		// Unpack 64-bit signed long
		return Math::unpackI64(hi, low);
	}

	/**
	 * Add "short" data to sockets message
	 *
	 * @param int	 shortValue value to add
	 * @param boolean store	  store value on message, true by default
	 * @return string
	 */
	protected function addShort(int shortValue, store = true) -> string
	{
		var data;
		let data = pack("n", shortValue);
		if (store) {
			//let this->requestMessage .= data;
			let this->requestMessage = this->requestMessage . data;
		}

		return data;
	}

	/**
	 * Add "int" data to sockets message
	 *
	 * @param int	 intValue value to add
	 * @param boolean store	store value on message, true by default
	 * @return string
	 */
	protected function addInt(int intValue, store = true) -> string
	{
		var data;
		let data = pack("N", intValue);
		if (store) {
			//let this->requestMessage .= data;
			let this->requestMessage = this->requestMessage . data;
		}

		return data;
	}

	/**
	 * Add "byte" data to sockets message
	 *
	 * @param string  intValue value to add
	 * @param boolean store	store value on message, true by default
	 * @return string
	 */
	protected function addByte(string byteValue, store = true) -> string
	{
		if (store) {
			//let this->requestMessage .= byteValue;
			let this->requestMessage = this->requestMessage . byteValue;
		}

		return byteValue;
	}

	/**
	 * Add "bytes" data to sockets message
	 *
	 * @param string  intValue value to add
	 * @param boolean store	store value on message, true by default
	 * @return string
	 */
	protected function addBytes(string bytesValue, boolean store = true) -> string
	{
		var data;
		let data = this->addInt(strlen(bytesValue), store);
		let data .= bytesValue;
		if (store) {
			//let this->requestMessage .= bytesValue;
			let this->requestMessage = this->requestMessage . bytesValue;
		}

		return data;
	}

	/**
	 * Add "string" data to sockets message
	 *
	 * @param string  intValue value to add
	 * @param boolean store	store value on message, true by default
	 * @return string
	 */
	protected function addString(string stringValue, boolean store = true) -> string
	{
		var data;
		let data = this->addInt(strlen(stringValue), store);
		let data .= stringValue;
		if (store) {
			//let this->requestMessage .= stringValue;
			let this->requestMessage = this->requestMessage . stringValue;
		}

		return data;
	}

	/**
	 * Add "Long" data to sockets message
	 * 
	 * @TODO: 32 bits not supported yet, code commented due to some warnings
	 *
	 * @param long	longValue value to add
	 * @param boolean store	 store value on message, true by default
	 * @return string
	 */
	protected function addLong(long longValue, store = true) -> string
	{
		var data;
		
		if ( PHP_INT_SIZE > 4 ) {
			let data = chr(longValue >> 56) . 
				chr(longValue >> 48) .
				chr(longValue >> 40) .
				chr(longValue >> 32) .
				chr(longValue >> 24) .
				chr(longValue >> 16) .
				chr(longValue >> 8) .
				chr(longValue & 0xFF);

		}
		else {
			/*
			var isNegative, bitString, tmpValue;
			var hi, lo, hiBin, loBin;

			let bitString = "";
			let tmpValue = longValue;
			let isNegative = (tmpValue < 0 )? true : false;

			if (function_exists("bcmod")) {
				if (isNegative == true) {
					let tmpValue = bcadd(tmpValue, "1");
				}

				while(tmpValue !== "0") {
					let bitString = (string)abs( (int)bcmod( tmpValue, "2")) . bitString;
					let tmpValue	 = bcdiv( tmpValue, "2" );
				}
			}
			elseif (function_exists("gmp_mod")) {
				if (isNegative == true) {
					let tmpValue = gmp_strval(gmp_add(tmpValue, "1"));
				}

				while(tmpValue !== "0") {
					let bitString = gmp_strval( gmp_abs( gmp_mod(tmpValue, "2"))) . bitString;
					let tmpValue = gmp_strval( gmp_div_q( tmpValue, "2"));
				}
			}
			else {
				throw new OrientdbException("bcmod or gmp_mod are required", 500);
			}

			if (isNegative == true) {
				int lenght, idx;
				let lenght = strlen(bitString) - 1;

				for idx in range(0, lenght) {
					let bitString[idx] = (bitString[idx] == "1")? "0" : "1";
				}
			}

			if (bitString != "" && isNegative == true) {
				let bitString = str_pad(bitString, 64, "1", STR_PAD_LEFT);
			}
			else {
				let bitString = str_pad(bitString, 64, "0", STR_PAD_LEFT);
			}

			let hi = substr(bitString, 0, 32);
			let lo = substr(bitString, 32, 32);
			let hiBin = pack( "H*", str_pad(base_convert( hi, 2, 16 ), 8, 0, STR_PAD_LEFT));
			let loBin = pack( "H*", str_pad(base_convert( lo, 2, 16 ), 8, 0, STR_PAD_LEFT));
			let data = hiBin . loBin;
			*/
			let data = "";
		}

		if (store) {
			let this->requestMessage = this->requestMessage . data;
		}

		return data;
	}

	/**
	 * Add "boolean" data to sockets message
	 *
	 * @param string  booleanValue value to add
	 * @param boolean store		store value on message, true by default
	 * @return string
	 */
	protected function addBoolean(string booleanValue, store = true) -> string
	{
		var boolVal;
		let boolVal = pack("C", booleanValue);
		if (store) {
			let this->requestMessage = this->requestMessage . boolVal;
		}

		return boolVal;
	}


	/**
	 * Get exception class and exception message from socket and throws new exception
	 *
	 * @param int code Error code, 400 by default
	 * @return void
	 */
	protected function handleException(int code = 400) -> void
	{
		// [(1)(exception-class:string)(exception-message:string)]*(0)(serialized-exception:bytes)
		// (1)(com.orientechnologies.orient.core.exception.OStorageException)(Can"t open the storage 'demo')(0)
		// (1)(com.orientechnologies.orient.core.exception.OStorageException)(Can't open the storage 'demo')(1)(com.orientechnologies.orient.core.exception.OStorageException)(File not found)(0)
		var exceptionStatus;
		var exceptionClass;
		var exceptionMessage = "";

		let exceptionStatus = this->readByte(this->socket);
		while (exceptionStatus == (chr(self::EXCEPTION_FOUND))) {
			let exceptionClass = this->readString(this->socket);
			let exceptionMessage = this->readString(this->socket);

			let exceptionStatus = this->readByte(this->socket);
			if (exceptionStatus == (chr(OperationAbstract::EXCEPTION_FOUND))) {
				let exceptionMessage .= "; ";
			}
		}

		if (this->parent->debug == true) {
			syslog(LOG_DEBUG, "Exception: " . exceptionMessage);
		}

		throw new OrientdbException(exceptionMessage, code);
	}

}