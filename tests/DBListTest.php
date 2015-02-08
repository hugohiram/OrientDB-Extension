<?php

class DBListTest extends \PHPUnit_Framework_TestCase {

	protected $host = '192.168.0.198';
	protected $port = 2424;
	protected $user = 'admin';
	protected $pass = 'admin';


	/**
	 * Test initializing OrientDB object
	 */
	public function testdblistOk()
	{
		$orient = new Orientdb\Orientdb($this->host, $this->port);

		$orient->Connect($this->user, $this->pass, true);

		$dbs = $orient->DBList();

		$this->assertTrue(is_array($dbs));
	}

	/**
	 * Test initializing OrientDB object with wrong data
	 */
	public function testWithoutConnectingKo()
	{
		try {
			$orient = new Orientdb\Orientdb($this->host, $this->port);
			
			$dbs = $orient->DBList();
		}
		catch (\Exception $e) {
			// Check the exception thrown is an instance clientException
			$this->assertEquals($e->GetMessage(), "Cannot perform the 'DBList' operation if not connected to a server");
		}
	}
}