#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/tests/js/unit/controllers/appcontrollerSpec.js
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
/**
 * Copyright (c) 2013, Bernhard Posselt <dev@bernhard-posselt.com>
 * This file is licensed under the Affero General Public License version 3 or later.
 * See the COPYING file.
 */


describe('AppController', function() {

	var controller,
		scope,
		location;

	// use the Notes container
	beforeEach(module('Notes'));

	beforeEach(inject(function ($controller, $rootScope) {
		scope = $rootScope.$new();
		controller = $controller;
		location = {
			path: jasmine.createSpy('path')
		};
	}));


	it('should bind loading global to scope', function () {
		var is = 'test';

		controller('AppController', {
			$scope: scope,
			$location: location,
			is: is
		});

		expect(scope.is).toBe(is);
	});


	it('should redirect if last viewed note is not 0', function () {
		controller('AppController', {
			$scope: scope,
			$location: location
		});

		scope.init(3);
		expect(location.path).toHaveBeenCalledWith('/notes/3');

	});


	it('should not redirect if last viewed note is 0', function () {
		controller('AppController', {
			$scope: scope,
			$location: location
		});

		scope.init(0);
		expect(location.path).not.toHaveBeenCalled();

	});

});