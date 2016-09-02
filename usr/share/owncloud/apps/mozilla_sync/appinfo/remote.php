#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/mozilla_sync/appinfo/remote.php
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
 * This is called by Sync clients when they access the Sync API
 * on this ownCloud server.
 *
 * @author Michal Jaskurzynski
 * @author Oliver Gasser
 */

// Get Sync URL
$url = OCA\mozilla_sync\Utils::getSyncUrl();
if ($url === false) {
	OCA\mozilla_sync\Utils::changeHttpStatus(404);
	exit();
}

// Parse and validate the URL accessed by the client
$urlParser = new OCA\mozilla_sync\UrlParser($url);
if (!$urlParser->isValid()) {
	OCA\mozilla_sync\Utils::changeHttpStatus(404);
	exit();
}

// Get service type based on URL and determine whether to start user or storage service
$service = OCA\mozilla_sync\Utils::getServiceType();

if ($service === 'userapi') {
	// Send a timestamp header
	OCA\mozilla_sync\Utils::sendMozillaTimestampHeader();
	$userService = new OCA\mozilla_sync\UserService($urlParser);
	$userService->run();
} else if ($service === 'storageapi') {
	// Note: Timestamp header will be sent later by storage API service
	$storageService = new OCA\mozilla_sync\StorageService($urlParser);
	$storageService->run();
}

/* vim: set ts=4 sw=4 tw=80 noet : */
