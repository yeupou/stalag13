#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/js/vendor/markdown/test/interface.t.js
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
var markdown = require("../lib/markdown"),
    test = require("tap").test;

// var markdown = require('Markdown');

function clone_array( input ) {
  // Helper method. Since the objects are plain round trip through JSON to get
  // a clone
  return JSON.parse( JSON.stringify( input ) );
}

test("arguments untouched", function(t) {
  var input = "A [link][id] by id.\n\n[id]: http://google.com",
      tree = markdown.parse( input ),
      clone = clone_array( tree ),
      output = markdown.toHTML( tree );

  t.equivalent( tree, clone, "tree isn't modified" );
  // We had a problem where we would accidentally remove the references
  // property from the root. We want to check the output is the same when
  // called twice.
  t.equivalent( markdown.toHTML( tree ), output, "output is consistent" );

  t.end();
});
