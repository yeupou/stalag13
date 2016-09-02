#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/mozilla_sync/settings.php
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

// Determines which template will be shown on the personal page
$tmpl = null;

$email = OCA\mozilla_sync\User::userNameToEmail();

// No email address set
if ($email === false) {
	$email = "";
}

// Load JavaScript files
\OCP\Util::addScript("mozilla_sync", "settings");
\OCP\Util::addScript("mozilla_sync", "show_notification");

$tmpl = new \OCP\Template('mozilla_sync', 'settings');
$tmpl->assign('mozillaSyncEmail', $email);
$tmpl->assign('syncaddress', OCA\mozilla_sync\Utils::getServerAddress());

return $tmpl->fetchPage();

/* vim: set ts=4 sw=4 tw=80 noet : */
