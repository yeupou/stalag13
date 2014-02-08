<?php

/**
 * ownCloud
 *
 * @author Michal Jaskurzynski
 * @copyright 2012 Michal Jaskurzynski mjaskurzynski@gmail.com
 *
 */

OC::$CLASSPATH['OCA\mozilla_sync\InputData'] = 'mozilla_sync/lib/inputdata.php';
OC::$CLASSPATH['OCA\mozilla_sync\OutputData'] = 'mozilla_sync/lib/outputdata.php';
OC::$CLASSPATH['OCA\mozilla_sync\User'] = 'mozilla_sync/lib/user.php';
OC::$CLASSPATH['OCA\mozilla_sync\UrlParser'] = 'mozilla_sync/lib/urlparser.php';
OC::$CLASSPATH['OCA\mozilla_sync\Utils'] = 'mozilla_sync/lib/utils.php';
OC::$CLASSPATH['OCA\mozilla_sync\Storage'] = 'mozilla_sync/lib/storage.php';

OC::$CLASSPATH['OCA\mozilla_sync\Service'] = 'mozilla_sync/lib/service.php';
OC::$CLASSPATH['OCA\mozilla_sync\StorageService'] = 'mozilla_sync/lib/storageservice.php';
OC::$CLASSPATH['OCA\mozilla_sync\UserService'] = 'mozilla_sync/lib/userservice.php';

// Register Mozilla Sync for personal page
\OCP\App::registerPersonal('mozilla_sync', 'settings');

// Register Mozilla Sync for the admin page
\OCP\App::registerAdmin('mozilla_sync', 'admin');

/* vim: set ts=4 sw=4 tw=80 noet : */
