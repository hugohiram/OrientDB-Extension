<?php

class DBCreateTest extends \PHPUnit_Framework_TestCase {

	protected $host = '192.168.0.198';
	protected $port = 2424;
	protected $user = 'admin';
	protected $pass = 'admin';
	protected $db   = 'test';
	protected $type = 'document';
	protected $storage = 'plocal';

	/**
	 * Test initializing OrientDB object
	 */
	public function testDbCreateOk()
	{
		try {
			$db = $this->db + time();

			$orient = new Orientdb\Orientdb($this->host, $this->port);
			
			$orient->Connect($this->user, $this->pass, true);

			$created = $orient->DBCreate($db, $this->type, $this->storage);

			$this->assertTrue($created);

			$orient->DBCreate($db, $this->type, $this->storage);
		}
		catch (\Exception $e) {
			// Check the exception thrown is an instance clientException
			$this->assertStringStartsWith("Database named '".$db."' already exists:", $e->GetMessage());

			$orient->DBDrop($db, $this->storage);
			//$this->assertEquals($e->getCode(), 400);
		}
	}

	/**
	 * Test initializing OrientDB object with wrong data
	 */
	public function testNotConnectedToServerKo()
	{
		try {
			$db = $this->db + time();

			$orient = new Orientdb\Orientdb($this->host, $this->port);

			$orient->DBCreate($db, $this->type, $this->storage);
		}
		catch (\Exception $e) {
			// Check the exception thrown is an instance clientException
			$this->assertEquals($e->GetMessage(), "Cannot perform the 'DBCreate' operation if not connected to a server");
		}
	}
}