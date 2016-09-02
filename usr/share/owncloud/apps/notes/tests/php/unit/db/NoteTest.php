#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/tests/php/unit/db/NoteTest.php
#
#                                 |     |
#                                 \_V_//
#                                 \/=|=\/
#                                  [=v=]
#                                __\___/_____
#                               /..[  _____  ]
#                              /_  [ [  M /] ]
#                             /../.[ [ M /@] ]
#                            <-->[_[ [M /@/] ]
#                           /../ [.[ [ /@/ ] ]
#      _________________]\ /__/  [_[ [/@/ C] ]
#     <_________________>>0---]  [=\ \@/ C / /
#        ___      ___   ]/000o   /__\ \ C / /
#           \    /              /....\ \_/ /
#        ....\||/....           [___/=\___/
#       .    .  .    .          [...] [...]
#      .      ..      .         [___/ \___]
#      .    0 .. 0    .         <---> <--->
#   /\/\.    .  .    ./\/\      [..]   [..]
#
<?php
/**
 * ownCloud - Notes
 *
 * This file is licensed under the Affero General Public License version 3 or
 * later. See the COPYING file.
 *
 * @author Bernhard Posselt <dev@bernhard-posselt.com>
 * @copyright Bernhard Posselt 2012, 2014
 */

namespace OCA\Notes\Db;

class NoteTest extends \PHPUnit_Framework_TestCase {


	public function testFromFile(){
		$file = array(
			'fileid' => 1,
			'type' => 'file',
			'mtime' => 50,
			'name' => 'hi.txt',
			'content' => 'hehe'
		);

		$note = Note::fromFile($file);

		$this->assertEquals($file['fileid'], $note->getId());
		$this->assertEquals($file['mtime'], $note->getModified());
		$this->assertEquals('hi', $note->getTitle());
		$this->assertEquals($file['content'], $note->getContent());
	}


}
