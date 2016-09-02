#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/owncloud/apps/mozilla_sync/js/settings.js
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
$(document).ready(function(){
	// delete storage ajax
	$('#deletestorage').click(function() {
		$.post(OC.filePath('mozilla_sync','ajax','deletestorage.php'), {},
			function(result){
				if(result) {
					OC.Notification.show(result.data.message);
				}
			});
	});

    // sync email ajax
    $('#syncemailinput').change(function() {
        var my_email = $('#syncemailinput').val();
        $.post(OC.filePath('mozilla_sync', 'ajax', 'setemail.php'),
            { email: my_email },
            function(result){
                showNotification(result.data.message);
            });

    });
});
