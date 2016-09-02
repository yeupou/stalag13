#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/js/vendor/markdown/bin/md2html.js
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
#!/usr/bin/env node
(function () {
  "use strict";

  var fs = require("fs")
    , markdown = require("markdown").markdown
    , nopt = require("nopt")
    , stream
    , opts
    , buffer = ""
    ;

  opts = nopt(
    { "dialect": [ "Gruber", "Maruku"]
    , "help": Boolean
    }
  );

  if (opts.help) {
    var name = process.argv[1].split("/").pop()
    console.warn( require("util").format(
      "usage: %s [--dialect=DIALECT] FILE\n\nValid dialects are Gruber (the default) or Maruku",
      name
    ) );
    process.exit(0);
  }

  var fullpath = opts.argv.remain[0];

  if (fullpath && fullpath !== "-") {
    stream = fs.createReadStream(fullpath);
  } else {
    stream = process.stdin;
  }
  stream.resume();
  stream.setEncoding("utf8");

  stream.on("error", function(error) {
    console.error(error.toString());
    process.exit(1);
  });

  stream.on("data", function(data) {
    buffer += data;
  });

  stream.on("end", function() {
    var html = markdown.toHTML(buffer, opts.dialect);
    console.log(html);
  });

}())
