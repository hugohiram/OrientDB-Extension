/**
 * OrientDB socket class
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
 * OrientDB
 *
 * @author Hugo Hiram <hugo@hugohiram.com>
 * @package Orientdb
 * @subpackage Socket
 */
class OrientDBSocket
{
	protected host;
	protected port;
	protected protocol;
	protected remote;

	//public errno;
	//public errstr;

	public timeout = 10;
	public buffer  = 16384;
	public socket;

	/**
	 * Orientdb\OrientDBSocket constructor
	 *
	 * @param string host Hostname or IP of the OrientDB Server
	 * @param int    port Port number of the OrientDB Server, 2424 by default
	 * @param string protocol Type of protocol, "tcp" by default
	 */
	public function __construct(string host, int port = 2424, string protocol = "tcp")
	{
		let this->host = host;
		let this->port = port;
		let this->protocol = protocol;
		let this->remote = this->protocol . "://" . this->host . ":" . this->port;

		//let this->socket = stream_socket_client(this->remote, this->errno, this->errstr, this->timeout);
		let this->socket = stream_socket_client(this->remote);
		//let this->socket = fsockopen(protocol . "://" . this->host, this->port, this->errno);

		if this->socket == false {
			throw new OrientdbException("unable to connect to Server", 500);
		}

		stream_set_blocking(this->socket, true);
		stream_set_timeout(this->socket, this->timeout, 0);
	}

	/**
	 * Read from socket
	 *
	 * @param int length length to read, null by default
	 * @return string
	 */
	public function read(int length = null) -> string
	{
		var data;
		var ilength;
		let ilength = length;
		let ilength = empty ilength ? this->buffer : ilength;
		let data = fread(this->socket, ilength);

		return data;
	}

	/**
	 * Send to socket
	 *
	 * @param string data data to send
	 */
	public function send(string data) -> void
	{
		fwrite(this->socket, data);
	}

	/**
	 * Read basic data from socket
	 *
	 * @param int length length to read, 7 by default
	 * @return string
	 */
	public function stream(int length = 7)
	{
		var data;
		let data = stream_get_contents(this->socket, length);

		return data;
	}

}