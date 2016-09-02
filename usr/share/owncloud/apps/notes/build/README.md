#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/notes/build/README.md
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
# Notes development instructions

## Dependencies

The following dependencies are required to build the project:

* gzip
* tar
* make
* node.js >= 0.8


## Build the project

To build the whole project run:

	make

To build the project when a javascript file changes run:

	make watch

## Running the test suites

The following make commands are available:

	make tests  # runs all tests
	make unit-tests  # runs only unit tests
	make js-unit-tests
	make php-unit-tests
	make php-integration-tests
	make php-acceptance-tests

The following make commands are available for TDD which run the unit tests once a file changes

	make watch-php-unit-tests
	make watch-js-unit-tests

## Distributing the app on the appstore

To package the app for the appstore run:

	make appstore

The package is then available in **build/artifacts/appstore/**