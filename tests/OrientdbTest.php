<?php

//namespace orientdb\tests;

class OrientdbTest extends \PHPUnit_Framework_TestCase {

	protected $host = '192.168.0.198';
	protected $port = 2424;
	protected $user = 'admin';
	protected $pass = 'admin';


	/**
	 * Test initializing OrientDB object
	 */
	public function testInitializationOk()
	{
		$orient = new Orientdb\Orientdb($this->host, $this->port);

		$this->assertInstanceOf('Orientdb\Orientdb', $orient);

		$this->assertInstanceOf('Orientdb\OrientDBSocket', $orient->socket);

		$this->assertTrue(!empty($orient->socket));
	}

	/**
	 * Test initializing OrientDB object with wrong data
	 */
	public function testInitializationKo()
	{
		try {
			$orient = new Orientdb\Orientdb($this->host, 1111);
		}
		catch (\Exception $e) {
			// Check the exception thrown is an instance clientException
			$this->assertInstanceOf('Exception', $e);
		}
	}
}