#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/etc/emacs/site-start.d/99stalag13.el
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
;; -*- emacs-lisp -*-
;; System-wide configuration for Emacs 2x.
;; /etc/emacs/site-start.d/99cgn.el
;; Copyright 2000-2015 (c) Mathieu Roy <yeupou -- gnu.org>
;;
;; "Emacs is not built by hate of vi.  vi is irrelevant.  It is no more 
;; then a strange punishment that the unbelievers submit themselves to.
;;
;; To truly worship thy Emacs, one must come to it with Love: Love for The
;; Extensible One, Love for The Customizable One, and finally, Love for The
;; Self-Documenting One.  To serve Emacs one dose not do things of hate,
;; but of love.  One read from the Grate Book of Elisp, and uses this
;; knowledge to Extend the and Expand Emacs.  One learns a new function
;; form that Grate Book, and customizes his .emacs to refer to it and ease
;; it's use.  One reads throw the Manuals and if one comes upon a patch of
;; text that has not been well kept, one cleans the weeds of it, waters the
;; instructions and sends the patch to The Maintainers.  
;; 
;; And in this way, one serves The One True Emacs."

;;*******************
;; FACES, DISPLAY

;; First we want the non-FQDN hostname, for the frame title
(setq hostname (let ((hostname (downcase (system-name))))
		 (save-match-data
		   (substring hostname (string-match "^[^.]+" hostname) (match-end 0)))))

;; Frame title like my aterm one: user@hostname: buffer [mode]
;; <http://www.emacswiki.org/cgi-bin/wiki/FrameTitle>
(setq frame-title-format (list user-real-login-name 
				"@" 
				hostname
				": %b [%m]" ))

;;**********************
;; SHORTCUFS, PREFS

;; Custom set vars
(custom-set-variables
 '(case-fold-search t)
 '(display-time-24hr-format t)
 '(delete-selection-mode 1)
 '(global-font-lock-mode t nil (font-lock))
 '(message-directory "~/.Mail/")
 '(mouse-wheel-mode t nil (mwheel))
 '(read-mail-command (quote gnus))
 '(save-place t nil (saveplace))
 '(show-paren-mode t nil (paren))
 '(text-mode-hook (quote (turn-on-auto-fill text-mode-hook-identify)))
 '(transient-mark-mode t)
 '(uniquify-buffer-name-style (quote forward) nil (uniquify))
 '(x-select-enable-clipboard nil))

;; We use $BROWSER environment variable to define the appropriate
;; browser
(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program (getenv "BROWSER"))

;; Same idea with printer
(setq printer-name (getenv "PRINTER"))

;; It's a pain to type "yes" instead of "y"
(fset 'yes-or-no-p 'y-or-n-p)

;; I want easy killing buffy no! buffers, what if Buffy can't defeat it?
;; Hum, I use to type M-k 
(global-set-key "\M-k" 'kill-this-buffer)

;; Cant stand beep beep all along
(setq visible-bell 1)

;; More logs !
(setq message-log-max 2048)

;; Remove toolbar with ugly icons
(tool-bar-mode -1)

;; French i18n
(setq calendar-week-start-day 1)
(setq calendar-day-name-array ["Dimanche" "Lundi" "Mardi" "Mercredi" "Jeudi" "Vendredi" "Samedi"])
(setq calendar-month-name-array ["Janvier" "Février" "Mars" "Avril" "Mai" "Juin" "Juillet" "Août" "Septembre" "Octobre" "Novembre" "Décembre"])
(setq ispell-local-dictionary "francais")

;;*******************
;; MODES
;; You should comment-out modes not installed on your computer.

;; Extend load path.
(setq load-path (cons "~/.my_lisp" load-path))

;; I like to see recent files.
(require 'recentf)
(recentf-mode 1)
 
;; Why not opening compressed files? 
(auto-compression-mode 1)

;; We run auctex, a mode for LaTeX. I would prefer yatex menus
;; but the colorization is better.
;(require 'tex-site)

;; Well, it's good to have such an hash, if someone forget shebang
(setq auto-mode-alist
      '( 
        ("\\ChangeLog.*$" . change-log-mode)
        ("\\changelog$" . debian-changelog-mode)
        ("\\control$" . debian-control-mode)
        ("\\Makefile.*$" . makefile-mode)
        ("\\.css$"  . css-mode) 
        ("\\.c$"  . c-mode) 
        ("\\.h$"  . c-mode)
        ("\\.C$"  . c++-mode) 
        ("\\.cc$" . c++-mode) 
        ("\\.sgml$" . sgml-mode)
        ("\\.xml$" . sgml-mode)
        ("\\.xsl$" . sgml-mode)
        ("\\.dtd$" . sgml-mode)
        ("\\.tex$" . latex-mode)
        ("\\.lastgen$" . latex-mode)
        ("\\.cls$" . latex-mode)
        ("\\.html$" . html-mode)
        ("\\.xhtml$" . html-mode)
        ("\\.fr$" . html-mode)
        ("\\.en$" . html-mode)
        ("\\.shtml$" . php-mode)
        ("\\.pl$" . perl-mode)
        ("\\.pm$" . perl-mode)
        ("\\.po$" . po-mode)
        ("\\.py$" . python-mode)
        ("\\.php3$" . php-mode)
        ("\\.php$" . php-mode)
	("\\.class$" . php-mode)
	("\\.sh$" . sh-mode)
	("\\.i$" . sh-mode)
        ("\\.l$" . lisp-mode)
        ("\\.lisp$" . lisp-mode) 
        ("\\.f$" . fortran-mode) 
        ("\\.awk$" . awk-mode)
        ("\\.org$" . org-mode)
        ("\\.el$" . emacs-lisp-mode) 
        ("\\.emacs$" . emacs-lisp-mode) 
        ("\\.gnus$" . emacs-lisp-mode))
)


(message "Loading stalag13.el... done")
