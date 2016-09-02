#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/templates/note.php
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
<!--<div class="utils">
    <label>
        <input type="checkbox"
            ng-model="markdown"
            name="markdown"
            ng-change="sync(markdown)"> Markdown
    </label>
</div>-->
<textarea
	ng-model="note.content"
    ng-class="{markdown: config.isMarkdown()}"
	ng-change="updateTitle()"
	notes-timeout-change="save()"
	autofocus tabindex="-1"></textarea>
<!--<div markdown="note.content" class="markdown" ng-show="config.isMarkdown()">
</div>-->