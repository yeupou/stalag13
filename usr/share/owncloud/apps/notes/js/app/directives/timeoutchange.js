#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/js/app/directives/timeoutchange.js
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

/**
 * Like ng-change only that it does not fire when you type faster than
 * 300 ms
 */
app.directive('notesTimeoutChange', ['$timeout', function ($timeout) {
	return {
		restrict: 'A',
		link: function (scope, element, attributes) {
			var interval = 300;  // 300 miliseconds timeout after typing
			var timeout;

			$(element).bind('input propertychange', function () {
				$timeout.cancel(timeout);

				timeout = $timeout(function () {
					scope.$apply(attributes.notesTimeoutChange);
				}, interval);
			});
		}
	};
}]);
