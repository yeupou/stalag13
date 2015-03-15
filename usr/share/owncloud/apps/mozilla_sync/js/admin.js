$(document).ready(function(){
    // restrict group ajax
    $('#restrictgroup,#groupselect').change(function() {
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

    // auto create ajax
    $('#msautocreate').change(function() {
        $.post(OC.filePath('mozilla_sync', 'ajax', 'setautocreate.php'),
            { autocreate: $('#msautocreate[type=checkbox]').is(':checked') },
            function(result){
                showNotification(result.data.message);
            });
    });
});
