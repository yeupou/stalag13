<?php

// Check if user is admin, redirect to home if not
\OCP\User::checkAdminUser();

// Load JavaScript file
\OCP\Util::addScript("mozilla_sync", "admin");

// Assign admin template
$tmpl = new \OCP\Template('mozilla_sync', 'admin');

$tmpl->assign('mozillaSyncRestrictGroupEnabled', \OCA\mozilla_sync\User::getAuthorizedGroup());
$tmpl->assign('mozillaSyncQuota', \OCA\mozilla_sync\User::getQuota());
$tmpl->assign('mozillaSyncVersion', \OCP\App::getAppVersion('mozilla_sync'));

return $tmpl->fetchPage();

/* vim: set ts=4 sw=4 tw=80 noet : */

