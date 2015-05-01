<script id="mail-account-manager" type="text/x-handlebars-template">
	<select class="mail_account">
		{{#each this}}
		<option value="{{accountId}}"><?php p($l->t('from')); ?> {{name}} &lt;{{emailAddress}}&gt;</option>
		{{/each}}
	</select>
</script>

<script id="mail-attachment-template" type="text/x-handlebars-template">
	<span>{{displayName}}</span>
	<div class="new-message-attachments-action svg icon-delete" data-attachment-id="{{id}}"></div>
</script>

<script id="new-message-template" type="text/x-handlebars-template">
	<div id="new-message">
		<select class="mail_account">
			{{#each aliases}}
			<option value="{{accountId}}"><?php p($l->t('from')); ?> {{name}} &lt;{{emailAddress}}&gt;</option>
			{{/each}}
		</select>

		<div id="new-message-fields">
			<a href="#" id="new-message-cc-bcc-toggle"
				class="transparency"><?php p($l->t('+ cc/bcc')); ?></a>
			<input type="text" name="to" id="to" class="recipient-autocomplete"
				value="<?php p($_['mailto']) ?>"/>
			<label id="to-label" for="to" class="transparency"><?php p($l->t('to')); ?></label>

			<div id="new-message-cc-bcc">
				<input type="text" name="cc" id="cc" class="recipient-autocomplete"
					value="<?php p($_['cc']) ?>"/>
				<label id="cc-label" for="cc" class="transparency"><?php p($l->t('cc')); ?></label>
				<input type="text" name="bcc" id="bcc" class="recipient-autocomplete"
					value="<?php p($_['bcc']) ?>"/>
				<label id="bcc-label" for="bcc" class="transparency"><?php p($l->t('bcc')); ?></label>
			</div>

			<input type="text" name="subject" id="subject"
				placeholder="<?php p($l->t('Subject')); ?>"
				value="<?php p($_['subject']) ?>"/>
			<textarea name="body" id="new-message-body"
				placeholder="<?php p($l->t('Message …')); ?>"></textarea>
			<input id="new-message-send" class="send primary" type="submit" value="<?php p($l->t('Send')) ?>">
		</div>

		<div id="new-message-attachments">
			<ul></ul>
			<input type="button" id="mail_new_attachment" value="<?php p($l->t('Add attachment from Files')); ?>">
		</div>
		<div><span id="new-message-msg" class="msg"></div>
		<div id="nav-buttons" class="hidden">
			<input type="button" id="nav-to-mail" value="<?php p($l->t('Open Mail App')); ?>">
			<input type="button" id="back-in-time" value="<?php p($l->t('Back to website')); ?>">
		</div>
	</div>
</script>

<div id="app">
	<div id="app-content" class="compose">
	</div>
</div>
