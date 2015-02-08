<?php

class DBCloseTest extends \PHPUnit_Framework_TestCase {

	protected $host = '192.168.0.198';
	protected $port = 2424;
	protected $user = 'admin';
	protected $pass = 'admin';
	protected $db   = 'test';
	protected $type = 'document';


	/**
	 * Test initializing OrientDB object
	 */
	public function testDbCloseOk()
	{
		$orient = new Orientdb\Orientdb($this->host, $this->port);

		$orient->DBOpen($this->db, $this->type, $this->pass, $this->pass);

		$close = $orient->DBClose();

		$this->assertTrue($close);
	}

	/**
	 * Test initializing OrientDB object with wrong data
	 */
	public function testWithoutConnectingKo()
	{
		try {
			$orient = new Orientdb\Orientdb($this->host, $this->port);
			
			$orient->DBClose();
		}
		catch (\Exception $e) {
			// Check the exception thrown is an instance clientException
			$this->assertEquals($e->GetMessage(), "Cannot perform the 'DBClose' operation if not connected to a database");
		}
	}
}