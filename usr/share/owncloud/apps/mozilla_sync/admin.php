#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/mozilla_sync/admin.php
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

// Check if user is admin, redirect to home if not
\OCP\User::checkAdminUser();

// Load JavaScript files
\OCP\Util::addScript("mozilla_sync", "admin");
\OCP\Util::addScript("mozilla_sync", "show_notification");

// Assign admin template
$tmpl = new \OCP\Template('mozilla_sync', 'admin');

$tmpl->assign('mozillaSyncRestrictGroup', \OCA\mozilla_sync\User::getAuthorizedGroup());
$tmpl->assign('mozillaSyncQuota', \OCA\mozilla_sync\User::getQuota());
$tmpl->assign('mozillaSyncAutoCreateUser', \OCA\mozilla_sync\User::isAutoCreateUser());

return $tmpl->fetchPage();

/* vim: set ts=4 sw=4 tw=80 noet : */

