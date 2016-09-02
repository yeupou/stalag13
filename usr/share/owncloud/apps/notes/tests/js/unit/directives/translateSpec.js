#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/tests/js/unit/directives/translateSpec.js
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


describe('notesTranslate', function() {

	var host,
		rootScope,
		compile;

	beforeEach(module('Notes'));

	beforeEach(inject(function($rootScope, $compile) {
		rootScope = $rootScope;
		compile = $compile;
		host = $('<div id="host"></div>');
		$('body').append(host);

	}));


	it ('should be set the translated string on scope', function () {
		var element = angular.element(
			'<notes-translate key="is">translated</notes-translate>'
		);
		compile(element)(rootScope);
		rootScope.$digest();
		host.append(element);

		expect(rootScope.translations.is).toBe('translated');
	});


	afterEach(function () {
		host.remove();
	});


});