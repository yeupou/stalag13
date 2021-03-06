#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/js/app/controllers/notecontroller.js
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

app.controller('NoteController', ['$routeParams', '$scope', 'NotesModel',
	'SaveQueue', 'note', 'Config',
	function($routeParams, $scope, NotesModel, SaveQueue, note, Config) {

	NotesModel.updateIfExists(note);

	$scope.note = NotesModel.get($routeParams.noteId);
	$scope.config = Config;
	$scope.markdown = Config.isMarkdown();

	$scope.updateTitle = function () {
		$scope.note.title = $scope.note.content.split('\n')[0] ||
			$scope.translations['New note'];
	};

	$scope.save = function() {
		var note = $scope.note;
		SaveQueue.add(note);
	};

	$scope.sync = function (markdown) {
		Config.setIsMarkdown(markdown);
		Config.sync();
	};

}]);