$(document).ready(function(){
    // restrict group ajax
    $('#restrictgroup,#group').change(function() {
        $.post(OC.filePath('mozilla_sync', 'ajax', 'restrictgroup.php'),
            { restrictgroup: $('#restrictgroup[type=checkbox]').is(':checked'),
            groupselect: $('#groupselect').val()},
            function(result){
                showNotification(result.data.message);
            });
    });

    // quota ajax
    $('#syncquotainput').change(function() {
        var my_quota = $('#syncquotainput').val();
        // Empty string is interpreted as quota zero
        if (my_quota === "") {
            my_quota = "0";
        }
        $.post(OC.filePath('mozilla_sync', 'ajax', 'setquota.php'),
            { quota: my_quota },
            function(result){
                showNotification(result.data.message);
            });

    });
});

// Shows a notification and hides it after 3 seconds
showNotification = function(text) {
    clearInterval(notification_timer);
    OC.Notification.hide();
    OC.Notification.show(text);
    var notification_timer = setInterval(function() {
        OC.Notification.hide();
        clearInterval(notification_timer);
    }, 3000);
}
