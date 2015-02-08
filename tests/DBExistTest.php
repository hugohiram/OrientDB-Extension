<?php

class DBExistTest extends \PHPUnit_Framework_TestCase {

	protected $host = '192.168.0.198';
	protected $port = 2424;
	protected $user = 'admin';
	protected $pass = 'admin';


	/**
	 * Test initializing OrientDB object
	 */
	public function testDbDoesExistsOk()
	{
		$orient = new Orientdb\Orientdb($this->host, $this->port);

		$orient->Connect($this->user, $this->pass, true);

		$exist = $orient->DBExist('test');

		$this->assertTrue($exist);
	}

	/**
	 * Test initializing OrientDB object
	 */
	public function testDbDoesNotExistsOk()
	{
		$orient = new Orientdb\Orientdb($this->host, $this->port);

		$orient->Connect($this->user, $this->pass, true);

		$exist = $orient->DBExist('anydb');

		$this->assertFalse($exist);
	}

	/**
	 * Test initializing OrientDB object with wrong data
	 */
	public function testWithoutConnectingKo()
	{
		try {
			$orient = new Orientdb\Orientdb($this->host, $this->port);
			
			$exist = $orient->DBExist('dbtest');
		}
		catch (\Exception $e) {
			// Check the exception thrown is an instance clientException
			$this->assertEquals($e->GetMessage(), "Cannot perform the 'DBExist' operation if not connected to a server");
		}
	}
}