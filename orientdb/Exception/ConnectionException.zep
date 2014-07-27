namespace Orientdb\Exception;

use Exception;

/**
* Client exception
*
* @package Orientdb
* @author Hugo Hiram <hugo@hugohiram.com>
*/
class ConnectionException
{
	private _code;
	private _message;

	/**
	* Construct Exception
	*
	* @param int code Code
	* @param string message Message
	*/
    public function __construct(int code, string message)
    {
		let this->_code = code;
		let this->_message = message;
    }

    /**
	* Exception Code getter
	*
	* @return int code Code
	*/
	public function getCode()
	{
		return this->_code;
	}

	/**
	* Exception Message getter
	*
	* @return string message Message
	*/
	public function getMessage()
	{
		return this->_message;
	}

}