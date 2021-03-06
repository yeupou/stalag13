#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/tests/php/unit/middleware/CORSMiddlewareTest.php
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

namespace OCA\Notes\Middleware;

use OCP\IRequest;
use OCP\AppFramework\Http\Response;

use OCA\Notes\Utility\ControllerTestUtility;

class CORSMiddlewareTest extends ControllerTestUtility {


	/**
	 * @API
	 */
	public function testSetCORSAPIHeader() {
		$request = $this->getRequest(
			array('server' => array('HTTP_ORIGIN' => 'test'))
		);
		$middleware = new CORSMiddleware($request);
		$response = $middleware->afterController('\OCA\Notes\Middleware\CORSMiddlewareTest',
			'testSetCORSAPIHeader',
			new Response());
		$headers = $response->getHeaders();

		$this->assertEquals('test', $headers['Access-Control-Allow-Origin']);
	}


	public function testNoAPINoCORSHEADER() {
		$request = $this->getRequest();
		$middleware = new CORSMiddleware($request);
		$response = $middleware->afterController('\OCA\Notes\Middleware\CORSMiddlewareTest',
			'testNoAPINoCORSHEADER',
			new Response());
		$headers = $response->getHeaders();
		$this->assertFalse(array_key_exists('Access-Control-Allow-Origin', $headers));
	}


	/**
	 * @API
	 */
	public function testNoOriginHeaderNoCORSHEADER() {
		$request = $this->getRequest();
		$middleware = new CORSMiddleware($request);
		$response = $middleware->afterController('\OCA\Notes\Middleware\CORSMiddlewareTest',
			'testNoOriginHeaderNoCORSHEADER',
			new Response());
		$headers = $response->getHeaders();
		$this->assertFalse(array_key_exists('Access-Control-Allow-Origin', $headers));
	}

}
