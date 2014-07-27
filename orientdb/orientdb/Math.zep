/**
 * OrientDB Math class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @copyright Hugo Hiram 2014
 * @license MIT License (MIT) https://github.com/hugohiram/OrientDB-Extension/blob/master/LICENSE
 * @link https://github.com/hugohiram/OrientDB-Extension
 * @package OrientDB
 */

namespace Orientdb;

use Exception;

/**
 * Math class
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package OrientDB
 * @subpackage Math
 */
class Math
{

	/**
	 * Convert twos-complement integer after unpack() on x64 systems.
	 *
	 * @param int intValue The integer to convert.
	 * @return int The converted integer.
	 */
	public static function convertComplementInt(intValue)
	{
		/*
		 *  Valid 32-bit signed integer is -2147483648 <= x <= 2147483647
		 *  -2^(n-1) < x < 2^(n-1) -1 where n = 32
		 */
		if (intValue > 2147483647) {
			return -((intValue ^ 0xFFFFFFFF) + 1);
		}
		return intValue;
	}

	/**
	 * Convert twos-complement short after unpack() on x64 systems.
	 *
	 * @param int data The short to convert.
	 * @return int The converted short.
	 */
	public static function convertComplementShort(data)
	{
		/*
		 *  Valid 32-bit signed integer is -32768 <= x <= 32767
		 *  -2^(n-1) < x < 2^(n-1) -1 where n = 16
		 */
		int shortValue;
		let shortValue = (is_array(data))? data[1] : data;
		if (shortValue > 32767) {
			return -((shortValue ^ 0xFFFF) + 1);
		}

		return shortValue;
	}

	/**
	 * Unpacks 64 bits signed long
	 *
	 * @param int hi Hi bytes of long
	 * @param int low Low bytes of long
	 * @return mixed
	 */
	public static function unpackI64(hi, low)
	{
		var hiComplement;
		string sign = "";
		int lastBit = 0;
		var temp;

		// If x64 system, just shift hi bytes to the left, add low bytes. Piece of cake.
		if (PHP_INT_SIZE === 8) {
			return (hi << 32) + low;
		}

		// x32
		// Check if long could fit into int
		let hiComplement = self::convertComplementInt(hi);
		if (hiComplement === 0) {
			// Hi part is 0, low will fit in x32 int
			return low;
		}
		else {
			if (hiComplement === -1) {
				// Hi part is negative, so we just can convert low part
				if (low >= 0x80000000) {
					// Check if low part is lesser than minimum 32 bit signed integer
					return self::convertComplementInt(low);
				}
			}
		}

		// This is negative number
		if (hiComplement < 0) {
//			let hi = ~hi;
//			let low = ~low;
			let lastBit = 1;
			let sign = "-";
		}

		// Format bytes properly
		let hi = sprintf("%u", hi);
		let low = sprintf("u", low);

		// Do math
		let temp = hi * 4294967296;
		let temp = low + temp;
		let temp = lastBit + temp;
		settype(temp, "string");

		//let temp = bcmul(hi, "4294967296");
		//let temp = bcadd(low, temp);
		//let temp = bcadd(temp, lastBit);

		return sign . temp;
	}
}