#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/mozilla_sync/ajax/restrictgroup.php
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
* ownCloud
*
* @author Oliver Gasser
* @copyright 2013 Oliver Gasser
*
*/

// Check if this file is called by admin user, otherwise send JSON error
\OCP\JSON::checkAdminUser();

// Check if valid requesttoken was sent
\OCP\JSON::callCheck();

// Load translations
$l = OC_L10N::get('mozilla_sync');

// Get inputs and set correct settings
$restrictGroup = filter_var($_POST['restrictgroup'], FILTER_VALIDATE_BOOLEAN);
if ($restrictGroup === true) {
    $group = filter_var($_POST['groupselect'], FILTER_SANITIZE_STRING);
} else {
    $group = null;
}

// Update settings value
\OCA\mozilla_sync\User::setAuthorizedGroup($group);

// Send success message
\OCP\JSON::success(array( "data" => array( "message" => $l->t("Restriction saved") )));

/* vim: set ts=4 sw=4 tw=80 noet : */

