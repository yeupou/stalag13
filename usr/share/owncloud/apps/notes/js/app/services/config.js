#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/js/app/services/config.js
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

app.factory('Config', ['Restangular', function (Restangular) {
    var Config = function (Restangular) {
        this._markdown = false;
        this._Restangular = Restangular;
    };

    Config.prototype.load = function () {
        var self = this;
        this._Restangular.one('config').get().then(function (config) {
            self._markdown = config.markdown;
        });
    };

    Config.prototype.isMarkdown = function () {
        return this._markdown;
    };

    Config.prototype.setIsMarkdown = function (isMarkdown) {
        this._markdown = isMarkdown;
    };

    Config.prototype.sync = function () {
        return this._Restangular.one('config').customPOST({
            markdown: this._markdown
        });
    };

    return new Config(Restangular);
}]);