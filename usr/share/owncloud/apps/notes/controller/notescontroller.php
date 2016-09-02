#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/controller/notescontroller.php
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

namespace OCA\Notes\Controller;

use \OCP\AppFramework\Controller;
use \OCP\IRequest;
use \OCP\IConfig;
use \OCP\AppFramework\Http\JSONResponse;
use \OCP\AppFramework\Http;

use \OCA\Notes\Service\NotesService;
use \OCA\Notes\Service\NoteDoesNotExistException;


class NotesController extends Controller {

	private $notesService;
	private $settings;
	private $userId;

	public function __construct($appName, 
	                            IRequest $request,
		                        NotesService $notesService,
		                        IConfig $settings,
		                        $userId){
		parent::__construct($appName, $request);
		$this->notesService = $notesService;
		$this->settings = $settings;
		$this->userId = $userId;
	}


	/**
	 * @NoAdminRequired
	 */
	public function index() {
		$notes = $this->notesService->getAll();
		return new JSONResponse($notes);
	}


	/**
	 * @NoAdminRequired
	 */
	public function get() {
		$id = (int) $this->params('id');

		//var_dump($this->request);

		// save the last viewed note
		$this->settings->setUserValue($this->userId, $this->appName, 
			'notesLastViewedNote', $id);
		try {
			return new JSONResponse($this->notesService->get($id));
		} catch(NoteDoesNotExistException $ex) {
			return new JSONResponse(array(), Http::STATUS_NOT_FOUND);
		}
	}


	/**
	 * @NoAdminRequired
	 */
	public function create() {
		$note = $this->notesService->create();
		return new JSONResponse($note);
	}


	/**
	 * @NoAdminRequired
	 */
	public function update() {
		$id = (int) $this->params('id');
		$content = $this->params('content');

		try {
			return new JSONResponse($this->notesService->update($id, $content));
		} catch(NoteDoesNotExistException $ex) {
			return new JSONResponse(array(), Http::STATUS_NOT_FOUND);
		}
	}


	/**
	 * @NoAdminRequired
	 */
	public function destroy() {
		$id = (int) $this->params('id');
		try {
			$this->notesService->delete($id);
			return new JSONResponse();
		} catch(NoteDoesNotExistException $ex) {
			return new JSONResponse(array(), Http::STATUS_NOT_FOUND);
		}
	}


	/**
	 * @NoAdminRequired
	 */
	public function getConfig() {
		$markdown = $this->settings->getUserValue($this->userId,
			$this->appName, 'notesMarkdown') === '1';
		$config = array(
			'markdown' => $markdown
		);
		
		return new JSONResponse($config);
	}


	/**
	 * @NoAdminRequired
	 */
	public function setConfig() {
		$markdown = $this->settings->setUserValue($this->userId,
			$this->appName, 'notesMarkdown', 
			$this->params('markdown'));
		
		return new JSONResponse();
	}


}