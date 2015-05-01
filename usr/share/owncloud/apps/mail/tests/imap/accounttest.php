<?php

namespace OCA\Mail\Tests\Imap;

class AccountTest extends AbstractTest {

	/**
	 * @dataProvider providesMailBoxNames
	 * @param $name
	 */
	public function testCreateAndDelete($name) {
		$name = uniqid($name);
		$this->createMailBox($name);
		$this->assertMailBoxExists($name);

		$this->getTestAccount()->deleteMailbox($name);
		$this->assertMailBoxNotExists($name);
	}

	public function providesMailBoxNames() {
		return [
			['boxbox'],
			['box box'],
			['äöü']
		];
	}

	/**
	 * @dataProvider providesMailBoxNames
	 * @param $name
	 */
	public function testListMailBoxes($name) {
		$name = uniqid($name);
		$this->createMailBox($name);
		$mailBoxes = $this->getTestAccount()->getListArray();
		$this->assertInternalType('array', $mailBoxes);

		$m = array_filter($mailBoxes['folders'], function($item) use ($name) {
			return $item['name'] === $name;
		});
		$this->assertTrue(count($m) === 1);
	}

	/**
	 * @dataProvider providesMailBoxNames
	 * @param $name
	 */
	public function testListMessages($name) {
		$name = uniqid($name);
		$newMailBox = parent::createMailBox($name);
		$count = $newMailBox->getTotalMessages();
		$this->assertEquals(0, $count);
		$messages = $newMailBox->getMessages();
		$this->assertInternalType('array', $messages);
		$this->assertEquals(0, count($messages));
		$this->createTestMessage($newMailBox);
		$count = $newMailBox->getTotalMessages();
		$this->assertEquals(1, $count);
		$messages = $newMailBox->getMessages();
		$this->assertInternalType('array', $messages);
		$this->assertEquals(1, count($messages));
	}

	/**
	 * @dataProvider providesMailBoxNames
	 * @param $name
	 */
	public function testGetChangedMailboxes($name) {
		$name = uniqid($name);
		$newMailBox = parent::createMailBox($name);
		$status = $newMailBox->getStatus();
		$changedMailBoxes = $this->getTestAccount()->getChangedMailboxes([
			$newMailBox->getFolderId() => [ 'uidvalidity' => $status['uidvalidity'], 'uidnext' => $status['uidnext'] ]
		]);

		$this->assertEquals(0, count($changedMailBoxes));

		$this->createTestMessage($newMailBox);

		$changedMailBoxes = $this->getTestAccount()->getChangedMailboxes([
			$newMailBox->getFolderId() => [ 'uidvalidity' => $status['uidvalidity'], 'uidnext' => $status['uidnext'] ]
		]);

		$this->assertEquals(1, count($changedMailBoxes));
		$this->assertEquals(1, count($changedMailBoxes[$newMailBox->getFolderId()]['messages']));
	}

	public function testGetChangedMailboxesForNotExisting() {
		$changedMailBoxes = $this->getTestAccount()->getChangedMailboxes([
			'you-dont-know-me' => ['uidvalidity' => 0, 'uidnext' => 0]
		]);

		$this->assertEquals(0, count($changedMailBoxes));
	}
}
