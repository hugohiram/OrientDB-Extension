<?php

//namespace orientdb\tests;

class ConnectTest extends \PHPUnit_Framework_TestCase {

	protected $host = '192.168.0.198';
	protected $port = 2424;
	protected $user = 'admin';
	protected $pass = 'admin';


	/**
	 * Test Server connection
	 */
	public function testConnectionWithCoorectCredentialsOk()
	{
		$orient = new Orientdb\Orientdb($this->host, $this->port);

		$connect = $orient->Connect($this->user, $this->pass, true);

		$this->assertEquals(null, $connect);
	}

	/**
	 * Test Server connection with wrong data
	 */
	public function testConnectionWithIncorrectPortKo()
	{
		try {
			$orient = new Orientdb\Orientdb($this->host, $this->port);
			$orient->Connect($this->user, '', true);
		}
		catch (\Exception $e) {
			// Check the exception thrown is an instance clientException
			$this->assertInstanceOf('Orientdb\Exception\OrientdbException', $e);
			// Check for correct exception message
			$this->assertEquals($e->getCode(), 401);
		}
	}
}