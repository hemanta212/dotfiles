;; -*- lexical-binding: t; -*-
  (defun startup/display-startup-time ()
    (message "Emacs loaded in %s with %d garbage collections."
             (format "%.2f seconds"
                     (float-time
                       (time-subtract after-init-time before-init-time)))
             gcs-done))


  (add-hook 'emacs-startup-hook #'startup/display-startup-time)

  ;; automatically generate the natively compiled files when Emacs loads a new .elc file.
  ;; might freeze emacs for some time
  (setq comp-deferred-compilation t)

  ;; The default is 800 kilobytes.  Measured in bytes.
  (setq gc-cons-threshold most-positive-fixnum)

  ;; Debug errors with more info
  (setq debug-on-error nil)

  ;; supress native comp warnings
  (setq native-comp-async-report-warnings-errors nil)
  ;; (setq native-comp-async-report-warnings-errors 'silent)
  (when (eq system-type 'darwin) (customize-set-variable 'native-comp-driver-options '("-Wl,-w")))

  ;; Suppress “ad-handle-definition: .. redefined” warnings during Emacs startup.
  (custom-set-variables '(ad-redefinition-action (quote accept)))

(require 'subr-x)
(setq efs/is-termux
      (string-suffix-p "Android" (string-trim (shell-command-to-string "uname -a"))))
(setq efs/is-fedora
      (string-prefix-p "Linux fedora" (string-trim (shell-command-to-string "uname -a"))))

;; Initialize package sources
(require 'package)
(custom-set-variables '(package-archives
                      '(("melpa"     . "https://melpa.org/packages/")
                        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                        ("elpa"      . "https://elpa.gnu.org/packages/"))))

(package-initialize)

(when (not package-archive-contents)
(package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(when (not (package-installed-p 'use-package))
(package-install 'use-package))

;; load use-package
(require 'use-package)

(custom-set-variables '(use-package-always-ensure t))
;; unfortunately, causes problem with general custom rune/leader-keys func not defined
;; (custom-set-variables '(use-package-always-defer t))
;; To see which package load when to optimize the startup time
(custom-set-variables '(use-package-verbose t))

(custom-set-variables '(load-prefer-newer t))
(use-package auto-compile
:defer nil
:config (auto-compile-on-load-mode))

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; tells use-package to use straight as an installer
(straight-use-package 'use-package)
(straight-use-package 'org)
;; If using the use-package-always-ensure customization, equivalent variable is
(setq straight-use-package-by-default t)

;; Define variables section
 (if efs/is-fedora
     (progn
       (defvar efs/default-font-size 100)
       (defvar efs/default-variable-font-size 120)
       (defvar efs/special-small-font-size 80))
   (progn
     (defvar efs/default-font-size 140)
     (defvar efs/special-small-font-size 100)
     (defvar efs/default-variable-font-size 165)))

 ;; Make frame transparency overridable
 (if (display-graphic-p)
 (defvar efs/frame-transparency '(90 . 90))
 (defvar efs/frame-transparency '(100 . 100)))

 (setq inhibit-startup-message t)

 (menu-bar-mode -1)            ; Disable the menu bar
 (display-battery-mode 1)
 (if (display-graphic-p)
     (progn
       (set-fringe-mode 10)        ; Give some breathing room
       (tooltip-mode -1)           ; Disable tooltips
       (tool-bar-mode -1)
       (menu-bar-mode 1)
       (scroll-bar-mode -1)))

 (set-face-attribute 'default nil :font "Fira Code" :height efs/default-font-size)
 ;; Set the fixed pitch face
 (set-face-attribute 'fixed-pitch nil :font "Fira Code" :height efs/default-font-size)
 ;; Set the variable pitch face
 (set-face-attribute 'variable-pitch nil :font "Segoe UI" :height efs/default-variable-font-size :weight 'regular)

 ;; Set up the visible bell
 (setq visible-bell nil)
 ;; Disable line numbers globally for everything
 (setq display-line-numbers-type nil)
 ;; Change cursor color
 ;;(set-cursor-color "#000000")
 ;; (dolist (mode '(org-mode-hook
 ;;                 term-mode-hook
 ;;                 shell-mode-hook
 ;;                 vterm-mode-hook
 ;;                 eww-mode-hook
 ;;                 treemacs-mode-hook
 ;;                 nov-mode-hook
 ;;                 pdf-view-mode-hook
 ;;                 lsp-ui-imenu-hook
 ;;                 eshell-mode-hook))
 ;;   (add-hook mode (lambda () (display-line-numbers-mode 0))))

 ;; (column-number-mode)

 ;; Prevent asking for confirmation to kill processes when exiting.
 (custom-set-variables '(confirm-kill-processes nil))

 ;; set default encoding
 (set-language-environment "UTF-8")
 (prefer-coding-system       'utf-8)
 (set-default-coding-systems 'utf-8)
 (set-terminal-coding-system 'utf-8)
 (set-keyboard-coding-system 'utf-8)
 (setq default-buffer-file-coding-system 'utf-8)
 ;; Force org mode to open any org file in utf 8
 (add-to-list 'file-coding-system-alist '("\\.org\\'" . utf-8))

 ;; Treat clipboard input as UTF-8 string first; compound text next, etc.
 (setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

 ;; line numbers
 (when (>= emacs-major-version 26)
   (use-package display-line-numbers
     :defer nil
     :straight nil
     :config
     (global-display-line-numbers-mode)))

 ;; Highlight trailing whitespace in red, so it’s easily visible
 ;;(disabled for now as it created a lot of noise in some modes, e.g. the org-mode export screen)
 (custom-set-variables '(show-trailing-whitespace nil))

 (unless efs/is-termux
   (set-frame-parameter (selected-frame) 'alpha '(100 . 100))
   (add-to-list 'default-frame-alist '(alpha . (100 . 100)))
   (set-frame-parameter (selected-frame) 'fullscreen 'maximized)
   (add-to-list 'default-frame-alist '(fullscreen . maximized)))


 ;; Highlight matching parenthesis
 (show-paren-mode)


 ;; Small fonts for compilation buffers
 ;; Use variable width font faces in current buffer
(defun my-buffer-face-mode-variable ()
  "Set font to a variable width (proportional) fonts in current buffer"
  (interactive)
  (setq buffer-face-mode-face '(:family "Consolas" :height 120 :width semi-condensed))
  (buffer-face-mode))

;; Use monospaced font faces in current buffer
(defun my-buffer-face-mode-fixed ()
  "Sets a fixed width (monospace) font in current buffer"
  (interactive)
  (setq buffer-face-mode-face '(:height 120))
  (buffer-face-mode))

(add-hook 'compilation-mode-hook 'my-buffer-face-mode-variable)
;;(add-hook 'compilation-mode-hook 'my-buffer-face-mode-variable)

;; Make Asynchronous operations loaded to use later
(use-package async)

;; dont pollute system clipboard X-clipboard
;; with evil use the + to copy/paste
;; visual select + shift ' + shift = + y or p
(setq select-enable-clipboard nil)

;; Start the emacs server
;; (server-start)

(add-hook 'before-save-hook 'time-stamp)

;; When at the beginning of the line, make Ctrl-K remove the whole line, instead of just emptying it.
(custom-set-variables '(kill-whole-line t))

;; Paste text where the cursor is, not where the mouse is.
(custom-set-variables '(mouse-yank-at-point t))

;; Make completion case-insensitive.
(setq completion-ignore-case t)
(custom-set-variables
 '(read-buffer-completion-ignore-case t)
 '(read-file-name-completion-ignore-case t))

;; Don’t use hard tabs
(custom-set-variables '(indent-tabs-mode nil))

;; Emacs automatically creates backup files, by default in the same folder as the original file, which often leaves backup files behind. This tells Emacs to put all backups in ~/.emacs.d/backups.
;; creates problem with magit commit C-c C-c
;; (custom-set-variables
;;   '(backup-directory-alist
;;    `(("." . ,(concat user-emacs-directory "backups")))))

;; WinnerMode makes it possible to cycle and undo window configuration changes
(when (fboundp 'winner-mode) (winner-mode))

;; Delete trailing whitespace before saving a file.
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; NOTE: If you want to move everything out of the ~/.emacs.d folder
;; reliably, set `user-emacs-directory` before loading no-littering!
;(setq user-emacs-directory "~/.cache/emacs")

(use-package no-littering)
;; no-littering doesn't set this by default so we must place
;; auto save files in the same path as it uses for sessions
(setq auto-save-file-name-transforms
      `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))

(use-package dired
  :straight (:type built-in)
  :commands (dired dired-jump)
  :hook
  (dired-mode . dired-hide-details-mode)
  :config
  (setq dired-dwim-target t)
  (setq dired-listing-switches "-Alh1vD --group-directories-first")
  (setq wdired-allow-to-change-permissions t)
  (setq wdired-create-parent-directories t)
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-single-up-directory
    "l" 'dired-single-buffer)
 :bind (("C-x C-j" . dired-jump)
            :map dired-mode-map
             ("C-c o" . dired-open-file)))

(use-package dired-single
  :commands (dired dired-jump))

(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

(use-package dired-open
  :commands (dired dired-jump)
  :config
  ;; Doesn't work as expected!
  ;; (add-to-list 'dired-open-functions #'dired-open-xdg t)
  (setq dired-open-extensions '(("png" . "termux-open")
                                ("jpg" . "termux-open")
                                ("wav" . "termux-open")
                                ("mp3" . "termux-open")
                                ("mp4" . "mpv"))))

(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))

(use-package dired-rainbow
  :after dired
  :config
 (dired-rainbow-define-chmod directory "#6cb2eb" "d.*")
 (dired-rainbow-define html "#eb5286" ("css" "less" "sass" "scss" "htm" "html" "jhtm" "mht" "eml" "mustache" "xhtml"))
 (dired-rainbow-define xml "#f2d024" ("xml" "xsd" "xsl" "xslt" "wsdl" "bib" "json" "msg" "pgn" "rss" "yaml" "yml" "rdata"))
 (dired-rainbow-define document "#9561e2" ("docm" "doc" "docx" "odb" "odt" "pdb" "pdf" "ps" "rtf" "djvu" "epub" "odp" "ppt" "pptx"))
 (dired-rainbow-define markdown "#ffed4a" ("org" "etx" "info" "markdown" "md" "mkd" "nfo" "pod" "rst" "tex" "textfile" "txt"))
 (dired-rainbow-define database "#6574cd" ("xlsx" "xls" "csv" "accdb" "db" "mdb" "sqlite" "nc"))
 (dired-rainbow-define media "#de751f" ("mp3" "mp4" "mkv" "MP3" "MP4" "avi" "mpeg" "mpg" "flv" "ogg" "mov" "mid" "midi" "wav" "aiff" "flac"))
 (dired-rainbow-define image "#f66d9b" ("tiff" "tif" "cdr" "gif" "ico" "jpeg" "jpg" "png" "psd" "eps" "svg"))
 (dired-rainbow-define log "#c17d11" ("log"))
 (dired-rainbow-define shell "#f6993f" ("awk" "bash" "bat" "sed" "sh" "zsh" "vim"))
 (dired-rainbow-define interpreted "#38c172" ("py" "ipynb" "rb" "pl" "t" "msql" "mysql" "pgsql" "sql" "r" "clj" "cljs" "scala" "js"))
 (dired-rainbow-define compiled "#4dc0b5" ("asm" "cl" "lisp" "el" "c" "h" "c++" "h++" "hpp" "hxx" "m" "cc" "cs" "cp" "cpp" "go" "f" "for" "ftn" "f90" "f95" "f03" "f08" "s" "rs" "hi" "hs" "pyc" ".java"))
 (dired-rainbow-define executable "#8cc4ff" ("exe" "msi"))
 (dired-rainbow-define compressed "#51d88a" ("7z" "zip" "bz2" "tgz" "txz" "gz" "xz" "z" "Z" "jar" "war" "ear" "rar" "sar" "xpi" "apk" "xz" "tar"))
 (dired-rainbow-define packaged "#faad63" ("deb" "rpm" "apk" "jad" "jar" "cab" "pak" "pk3" "vdf" "vpk" "bsp"))
 (dired-rainbow-define encrypted "#ffed4a" ("gpg" "pgp" "asc" "bfe" "enc" "signature" "sig" "p12" "pem"))
 (dired-rainbow-define fonts "#6cb2eb" ("afm" "fon" "fnt" "pfb" "pfm" "ttf" "otf"))
 (dired-rainbow-define partition "#e3342f" ("dmg" "iso" "bin" "nrg" "qcow" "toast" "vcd" "vmdk" "bak"))
 (dired-rainbow-define vc "#0074d9" ("git" "gitignore" "gitattributes" "gitmodules"))
 (dired-rainbow-define-chmod executable-unix "#38c172" "-.*x.*"))

(defun xah-open-in-external-app (&optional @fname)
  "Open the current file or dired marked files in external app.
When called in emacs lisp, if @fname is given, open that.
URL `http://xahlee.info/emacs/emacs/emacs_dired_open_file_in_ext_apps.html'
Version 2019-11-04 2021-02-16"
  (interactive)
  (let* (
         ($file-list
          (if @fname
              (progn (list @fname))
            (if (string-equal major-mode "dired-mode")
                (dired-get-marked-files)
              (list (buffer-file-name)))))
         ($do-it-p (if (<= (length $file-list) 5)
                       t
                     (y-or-n-p "Open more than 5 files? "))))
    (when $do-it-p
      (cond
       ((string-equal system-type "windows-nt")
        (mapc
         (lambda ($fpath)
           (shell-command (concat "PowerShell -Command \"Invoke-Item -LiteralPath\" " "'" (shell-quote-argument (expand-file-name $fpath )) "'")))
         $file-list))
       ((string-equal system-type "darwin")
        (mapc
         (lambda ($fpath)
           (shell-command
            (concat "open " (shell-quote-argument $fpath))))  $file-list))
       ((string-equal system-type "gnu/linux")
        (mapc
         (lambda ($fpath) (let ((process-connection-type nil))
                            (start-process "" nil "xdg-open" $fpath))) $file-list))))))

;; Repeat mode set to on (C-x o o o) or (C-x { { {) to resize
;; Helps with window switching/resizing
(repeat-mode 1)

;; Load the which key compatible bind-key
(require 'bind-key)
;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
;; Remap  Imenu to M-i
(global-set-key (kbd "M-i") 'imenu)
(global-set-key (kbd "C-c C-x s") 'org-search-view)
(global-set-key (kbd "M-w") 'scroll-other-window)
(global-set-key (kbd "M-W") 'scroll-other-window-down)

(use-package general
  :after evil
  :config
  (general-create-definer rune/leader-keys
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")

  (rune/leader-keys
    "t"  '(:ignore t :which-key "toggles")
    "tt" '(counsel-load-theme :which-key "choose theme")
    "f"  '(:ignore t :which-key "Imp Files")
    "fo" '(lambda () (interactive) (find-file (expand-file-name "~/dev/personal/org/track.org"))) :which-key "track org"

    "fe" '(lambda ()
            (interactive)
            (progn
             (other-window 1)
             (delete-other-windows)
            )) :which-key "Focus other window"


    "fr" '(lambda ()
            (interactive)
            (progn
             (winner-undo)
             (other-window 1)
            )) :which-key "Focus reset"

    "ff" '(lambda ()
            (interactive)
            (progn
             (delete-other-windows)
            )) :which-key "Focus this window"


    "fd"  '(:ignore t :which-key "Dot files")
    "fdv" '(lambda () (interactive) (find-file (expand-file-name "~/dev/dotfiles/neovim/init.org")) :which-key "Neovim Config")
    "fde" '(lambda () (interactive) (find-file (expand-file-name "~/dev/dotfiles/emacs/.emacs.d/config.org")) :which-key "emacs config")))


(use-package evil
  :init
  ;; use emacs keybinding in insert state
  (setq evil-disable-insert-state-bindings t)
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  (setq evil-want-minibuffer t)
  :config
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)

  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

(defun evil-init-minibuffer ()
  (set (make-local-variable 'evil-echo-state) nil)
  (evil-emacs-state))

 (add-hook 'minibuffer-setup-hook 'evil-init-minibuffer 90)

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package evil-escape
  :after evil
  :config
  (evil-escape-mode)
  (setq evil-escape-key-sequence "kj"))

;; Already installed by org-download
(use-package async
  :config
  (autoload 'dired-async-mode "dired-async.el" nil t)
  (dired-async-mode 1)
  ;; async compilation of melpa packages
  (async-bytecomp-package-mode 1)
  :custom
  (setq async-bytecomp-allowed-packages '(all)))

;;(setq message-send-mail-function 'async-smtpmail-send-it).

(use-package paradox
  :defer t
  :custom
  (paradox-github-token t)
  (paradox-column-width-package 27)
  (paradox-column-width-version 13)
  (paradox-execute-asynchronously t)
  (paradox-hide-wiki-packages t)
  :config
  (paradox-enable)
  (remove-hook 'paradox-after-execute-functions #'paradox--report-buffer-print))

(use-package tree-sitter
  :defer t)
(use-package tree-sitter-langs
  :after tree-sitter
  :config
  (global-tree-sitter-mode))

(use-package command-log-mode
  :commands command-log-mode)

(use-package spacegray-theme)

(use-package doom-themes)
(unless efs/is-termux
 (if (eq (display-graphic-p) nil)
     (load-theme 'doom-one t)
     (progn
     (load-theme 'doom-one t)
     (doom-themes-visual-bell-config))))

(use-package atom-one-dark-theme)

(use-package berrys-theme
  :straight t
  :config ;; for good measure and clarity
  (setq-default cursor-type '(bar . 2))
  (setq-default line-spacing 5))

(use-package modus-themes
  :straight t)

;; You must run (all-the-icons-install-fonts) one time after
;; installing this package!
(use-package all-the-icons)
(use-package all-the-icons-ivy
  :after (all-the-icons ivy))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))

(use-package diminish)

(use-package minions
:hook (doom-modeline-mode . minions-mode))

(use-package which-key
  :defer nil
  :diminish which-key-mode
  :config
  (which-key-mode)
  (setq which-key-idle-delay 1))

(use-package ivy
  :diminish
  :bind (("C-s" . swiper)
         :map ivy-minibuffer-map
         ("TAB" . ivy-alt-done)
         ("C-l" . ivy-alt-done)
         ("C-M-j" . ivy-immediate-done)
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-previous-line)
         ("C-l" . ivy-done)
         ("C-M-j" . ivy-immediate-done)
         ("C-d" . ivy-switch-buffer-kill)
         :map ivy-reverse-i-search-map
         ("C-k" . ivy-previous-line)
         ("C-d" . ivy-reverse-i-search-kill))
  :config
  (ivy-mode 1))

(use-package ivy-rich
  :after ivy
  :init
  (ivy-rich-mode 1))

(use-package counsel
  :bind (("C-x b" . 'persp-counsel-switch-buffer)
         :map minibuffer-local-map
         ("C-r" . 'counsel-minibuffer-history))
  :config
  (counsel-mode 1))

(use-package ivy-prescient
  :after counsel
  ;; :custom
  ;; (ivy-prescient-enable-filtering nil)
  :config
  ;; Uncomment the following line to have sorting remembered across sessions!
  (prescient-persist-mode 1)
  (ivy-prescient-mode 1))

;; replaces ivy rich
;; Enable richer annotations using the Marginalia package
;; (use-package marginalia
;;   ;; Either bind `marginalia-cycle` globally or only in the minibuffer
;;   :bind (:map minibuffer-local-map
;;          ("M-A" . marginalia-cycle))
;;   ;; The :init configuration is always executed (Not lazy!)
;;   :init
;;   ;; Must be in the :init section of use-package such that the mode gets
;;   ;; enabled right away. Note that this forces loading the package.
;;   (marginalia-mode))

(use-package avy
:straight t)

(rune/leader-keys
    "SPC" 'avy-goto-char-2
    "ac" 'avy-goto-char-word
    "aw" 'avy-goto-char-word
    "as" 'avy-goto-char-timer
    "al" 'avy-goto-line
    "ah" 'avy-org-goto-heading-timer
    )

(use-package ace-window
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  :config
  (setq aw-background nil))

;; Customize the ace-window leading char display
(set-face-attribute 'aw-leading-char-face nil :height 300 :foreground "chartreuse")

(rune/leader-keys
  "o" 'ace-window)

(use-package frog-jump-buffer
  :straight t
  :custom
  (frog-jump-buffer-use-all-the-icons-ivy t))

(rune/leader-keys
  "b" 'frog-jump-buffer)

(use-package helpful
  :commands (helpful-callable helpful-variable helpful-command helpful-key)
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

(use-package hydra
:defer t)

(defhydra hydra-text-scale (:timeout 4)
  "scale text"
  ("j" text-scale-increase "in")
  ("k" text-scale-decrease "out")
  ("f" nil "finished" :exit t))

(rune/leader-keys
  "ts" '(hydra-text-scale/body :which-key "scale text"))

(use-package visual-fill)

(use-package adaptive-wrap)

(add-hook 'eww-mode-hook 'visual-line-mode)
(add-hook 'eww-mode-hook 'adaptive-wrap-prefix-mode)

(use-package svg-lib)

(use-package nano-theme)

;; (use-package unfill
;;   :bind
;;   ("M-q" . unfill-toggle)
;;   ("A-q" . unfill-paragraph))

(use-package imenu-anywhere
  :bind
  ("M-i" . ivy-imenu-anywhere))

(use-package smooth-scrolling
  :config
  (smooth-scrolling-mode 1))

(use-package perspective
  :straight t
  :bind (("C-x k" . persp-kill-buffer*)
         ("C-M-n" . persp-next)
         ("C-M-k" . persp-switch)
         )
  :custom
  (persp-mode-prefix-key (kbd "C-x p"))  ; pick your own prefix key here
  (persp-state-default-file (expand-file-name "~/.config/emacs/persp-session-state"))
  :init
  (persp-mode)
  :config
  (add-hook 'kill-emacs-hook #'persp-state-save))

(use-package burly
:straight t)

(use-package emojify)
  ;; :hook (after-init . global-emojify-mode))

;; Set transparency of emacs
(defun transparency (value)
  "Sets the transparency of the frame window. 0=transparent/100=opaque"
  (interactive "nTransparency Value 0 - 100 opaque:")
  (set-frame-parameter (selected-frame) 'alpha value))

(use-package pulsar
  :straight t
  :config

  (setq pulsar-pulse-functions
        '(recenter-top-bottom
          move-to-window-line-top-bottom
          reposition-window
          forward-page
          backward-page
          scroll-up-command
          scroll-down-command
          org-next-visible-heading
          org-previous-visible-heading
          org-forward-heading-same-level
          org-backward-heading-same-level
          outline-backward-same-level
          outline-forward-same-level
          outline-next-visible-heading
          outline-previous-visible-heading
          outline-up-heading))

  (setq pulsar-pulse-on-window-change t)
  (setq pulsar-pulse t)
  (setq pulsar-delay 0.055)
  (setq pulsar-iterations 10)
  (setq pulsar-face 'pulsar-magenta)
  (setq pulsar-highlight-face 'pulsar-yellow)

  (pulsar-global-mode 1))

;; OR use the local mode for select mode hooks

;; (dolist (hook '(org-mode-hook emacs-lisp-mode-hook))
;;   (add-hook hook #'pulsar-mode))

;;     (info "(elisp) Key Binding Conventions")
;; You can replace `pulsar-highlight-line' with the command
;; `pulsar-highlight-dwim'.
(let ((map global-map))
  (define-key map (kbd "C-c h p") #'pulsar-pulse-line)
  (define-key map (kbd "C-c h h") #'pulsar-highlight-dwim))

;; integration with the built-in `imenu':
(add-hook 'imenu-after-jump-hook #'pulsar-recenter-top)
(add-hook 'imenu-after-jump-hook #'pulsar-reveal-entry)

(use-package beacon
  :config
  (beacon-mode 1))

(cond ((eq system-type 'darwin)
       ;; <<Mac settings>>
     (custom-set-variables
       '(mac-command-modifier 'meta)
       '(mac-option-modifier 'alt)
       '(mac-right-option-modifier 'super))
       )
      ((eq system-type 'windows-nt)
       ;; <<Windows settings>>
       )
      ((eq system-type 'gnu/linux)
       ;; <<Linux settings>>
       ))

(defun efs/org-font-setup ()
  ;; Replace list hyphen with dot
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  ;; Set faces for heading levels
  (dolist (face '((org-level-1 . 1.2)
                  (org-level-2 . 1.1)
                  (org-level-3 . 1.1)
                  (org-level-4 . 1.1)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.1)
                  (org-level-7 . 1.1)
                  (org-level-8 . 1.1)))
    (set-face-attribute (car face) nil :font "Fira Code" :weight 'regular :height (cdr face)))

  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil    :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil    :inherit 'fixed-pitch)
  (set-face-attribute 'org-formula nil  :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil     :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil    :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil  :inherit 'fixed-pitch)
  (set-face-attribute 'line-number nil :inherit 'fixed-pitch)
  (set-face-attribute 'line-number-current-line nil :inherit 'fixed-pitch)

    ;; Get rid of the background on column views
  (set-face-attribute 'org-column nil :background nil)
  (set-face-attribute 'org-column-title nil :background nil))

;; Turn on indentation and auto-fill mode for Org files
(defun efs/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (auto-fill-mode 0)
  (visual-line-mode 1)
  (setq evil-auto-indent nil)
  (diminish org-indent-mode))

(use-package org
  :commands (org-capture org-agenda)
  :hook (org-mode . efs/org-mode-setup)
  :config

  (setq org-ellipsis " ▾"
        org-hide-emphasis-markers t
        org-hide-block-startup nil
        org-fontify-quote-and-verse-blocks t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-src-preserve-indentation nil
        org-edit-src-content-indentation 2
        org-startup-folded 'content
        org-cycle-separator-lines 2
        org-log-done 'time
        org-log-into-drawer t
        org-agenda-start-with-log-mode t
        org-agenda-files
        '("~/dev/personal/org/track.org"))
  ;;(define-key org-mode-map (kbd "C-c C-r") verb-command-map)

  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-j") 'org-next-visible-heading)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-k") 'org-previous-visible-heading)

  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-j") 'org-metadown)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-k") 'org-metaup)

  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)")
          (sequence "BACKLOG(b)" "PLAN(p)" "READY(r)" "ACTIVE(a)" "REVIEW(v)" "WAIT(w@/!)" "HOLD(h)" "|" "COMPLETED(c)" "CANC(k@)")))

  (efs/org-font-setup))

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode))
  ;; Overridden by org-mordern
  ;;:custom
  ;;(org-bullets-bullet-list '("◉" "○" "✸" "✿")))
  ;; (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")

(use-package org-appear
  :hook (org-mode . org-appear-mode))

(defun efs/org-mode-visual-fill ()
  (interactive)
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook ((org-mode . efs/org-mode-visual-fill)
         (dashboard-mode . efs/org-mode-visual-fill)
         (telega-chat-mode . efs/org-mode-visual-fill)
         (telega-root-mode . efs/org-mode-visual-fill)
         (info-mode . efs/org-mode-visual-fill)))

(use-package ob-racket
  :after org
  :config
  (add-hook 'ob-racket-pre-runtime-library-load-hook
	      #'ob-racket-raco-make-runtime-library)
  :straight (ob-racket
	       :type git :host github :repo "hasu/emacs-ob-racket"
	       :files ("*.el" "*.rkt")))

(use-package ob-http
  :defer t
  :after (org-mode)
  )

(use-package ob-go
  :defer t
  :after (org-mode)
  )

(use-package geiser
  :defer t)
(use-package geiser-mit
  :defer t)
(use-package geiser-guile
  :defer t)
(use-package geiser-racket
  :defer t)

(defun org-babel-execute:json (body params)
  (let ((jq (cdr (assoc :jq params)))
        (node (cdr (assoc :node params))))
    (cond
     (jq
      (with-temp-buffer
        ;; Insert the JSON into the temp buffer
        (insert body)
        ;; Run jq command on the whole buffer, and replace the buffer
        ;; contents with the result returned from jq
        (shell-command-on-region (point-min) (point-max) (format "jq -r \"%s\"" jq) nil 't)
        ;; Return the contents of the temp buffer as the result
        (buffer-string)))
     (node
      (with-temp-buffer
        (insert (format "const it = %s;" body))
        (insert node)
        (shell-command-on-region (point-min) (point-max) "node -p" nil 't)
        (buffer-string))))))

(defcustom path-to-8085 "~/dev/pyassm"
  "Path to folder where 8085-interpreter was cloned")

(defcustom org-babel-8085-command (concat
                                   (concat path-to-8085 "/.venv/bin/python ")
                                   (concat path-to-8085 "/main.py"))
  "Name of the command for executing 8085 interpreter.")

(defun org-babel-execute:8085 (body params)
  (let ((args (cdr (assoc :args params))))
    (org-babel-eval
     (concat
      org-babel-8085-command
      (if args  (concat " -i " args) " -i " ))
     body)))

;; place holder major mode wip
;; (require 'rx)
;; (defvar 8085-mode-map
;;   (let ((map (make-sparse-keymap)))
;;     map))

;; (defconst 8085--font-lock-defaults
;;   (let (
;;         (instructions '("MVI" "MOV" "ADD" "SUB" "ADI"
;;                         "SUI" "JNZ" "JNC" "JZ" "JC" "LXI"
;;                         "LXAD" "INR" "DCR" "INX" "DCX" "OUT"
;;                         "HLT" "CPI" "CMP" "STA" "LDA"))
;;         (registers '(" A " " B " " C " " D " " E " " M ")))
;;     `(((,(rx-to-string `(: (or ,@instructions))) 0 font-lock-keyword-face)
;;        ("\\([[:word:]]+\\):" 1 font-lock-function-name-face)
;;        ;(,(rx-to-string `(: (or ,@registers))) 0 font-lock-type-face)
;;        ))))

;; ;; (defvar 8085-mode-syntax-table
;;   (let ((st (make-syntax-table)))
;;     ;; - and _ are word constituents
;;     (modify-syntax-entry ?_ "w" st)
;;     (modify-syntax-entry ?- "w" st)

;;     ;; add comments. lua-mode does something similar, so it shouldn't
;;     ;; bee *too* wrong.
;;     (modify-syntax-entry ?\; "<" st)
;;     (modify-syntax-entry ?\n ">" st)
;;     st))

(define-derived-mode 8085-mode asm-mode "8085"
  "Major mode for 8085.")

(with-eval-after-load 'org
 (org-babel-do-load-languages
   'org-babel-load-languages
   '((C . t)
     (emacs-lisp . t)
     (go . t)
     (http . t)
     (js . t)
     (python . t)
     (racket . t)
     (scheme . t)
     (shell . t)))
 (push '("conf-unix" . conf-unix) org-src-lang-modes)
 (setq org-confirm-babel-evaluate nil))

(with-eval-after-load 'org
  ;; This is needed as of Org 9.2
  (require 'org-tempo)

  (add-to-list 'org-structure-template-alist '("art" . "src artist"))
  (add-to-list 'org-structure-template-alist '("draw" . "src artist"))
  (add-to-list 'org-structure-template-alist '("clang" . "src C :results output :exports both"))
  (add-to-list 'org-structure-template-alist '("cpp" . "src C++ :results output :exports both"))
  (add-to-list 'org-structure-template-alist '("cppio" . "src C++ :results output :exports both :includes <iostream>"))
  (add-to-list 'org-structure-template-alist '("c++" . "src C++ :include <iostream> :main no :results output :exports both :flags -std=c++17 -Wall --pedantic -Werror"))
  (add-to-list 'org-structure-template-alist '("ex" . "example"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("eml" . "src emacs-lisp :exports both"))
  (add-to-list 'org-structure-template-alist '("go" . "src go :exports both :results output"))
  (add-to-list 'org-structure-template-alist '("ht" . "src http"))
  (add-to-list 'org-structure-template-alist '("py" . "src python :exports both :results output"))
  (add-to-list 'org-structure-template-alist '("rak" . "src racket :exports both :results output"))
  (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
  (add-to-list 'org-structure-template-alist '("lua" . "src lua"))
  (add-to-list 'org-structure-template-alist '("sh" . "src shell"))
  (add-to-list 'org-structure-template-alist '("shell" . "src shell :results output :exports both"))
  (add-to-list 'org-structure-template-alist '("sasm" . "src 8085 :export both :args -db /tmp/8085-session1"))
  (add-to-list 'org-structure-template-alist '("asm" . "src 8085")))
  ;;(setq org-structure-template-alist '())

;; Automatically tangle our Emacs.org config file when we save it
  (defun efs/org-babel-tangle-config ()
    (when (string-equal (buffer-file-name)
                        (expand-file-name "~/dev/dotfiles/emacs/.emacs.d/config.org"))
      ;; Dynamic scoping to the rescue
      (let ((org-confirm-babel-evaluate nil))
        (org-babel-tangle))))

(defun efs/org-babel-tangle-neovim-config ()
  (when (string-equal (buffer-file-name)
                      (expand-file-name "~/dev/dotfiles/neovim/init.org"))


    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

  (add-hook 'org-mode-hook
      (lambda ()
        (add-hook 'after-save-hook #'efs/org-babel-tangle-config)
        (add-hook 'after-save-hook #'efs/org-babel-tangle-neovim-config)))

(defun toggle-org-markdown-export-on-save ()
  (interactive)
  (if (memq 'org-md-export-to-markdown after-save-hook)
      (progn
        (remove-hook 'after-save-hook 'org-md-export-to-markdown t)
        (message "Disabled org markdown export on save for current buffer..."))
    (add-hook 'after-save-hook 'org-md-export-to-markdown nil t)
    (message "Enabled org markdown export on save for current buffer...")))

(defun indent-org-block-automatically ()
  (interactive)
  (when (org-in-src-block-p)
    (org-edit-special)
    (indent-region (point-min) (point-max))
    (org-edit-src-exit)))

;;  (add-hook 'org-mode-hook
;;      (lambda ()
;;        (add-hook 'after-save-hook #'indent-org-block-automatically)))

;;
;;  (run-at-time 1 10 'indent-org-block-automatically)

(use-package org-download
;; Drag-and-drop to 'dired'
 :hook (dired-mode-hook . org-download-enable)
       (org-mode-hook . org-download-enable))
;; (add-hook 'dired-mode-hook 'org-download-enable)

;; (setq org-clock-persist 'history)
;; (org-clock-persistence-insinuate)

(defun org-export-all (backend)
  "Export all subtrees that are *not* tagged with :noexport: to
separate files.

Subtrees that do not have the :EXPORT_FILE_NAME: property set
are exported to a filename derived from the headline text."
  (interactive "sEnter backend: ")
  (let ((fn (cond ((equal backend "html") 'org-html-export-to-html)
                  ((equal backend "latex") 'org-latex-export-to-latex)
                  ((equal backend "pdf") 'org-latex-export-to-pdf)))
        (modifiedp (buffer-modified-p)))
    (save-excursion
      (set-mark (point-min))
      (goto-char (point-max))
      (org-map-entries
       (lambda ()
         (let ((export-file (org-entry-get (point) "EXPORT_FILE_NAME")))
           (unless export-file
             (org-set-property
              "EXPORT_FILE_NAME"
              (replace-regexp-in-string " " "_" (nth 4 (org-heading-components)))))
           (funcall fn nil t)
           (unless export-file (org-delete-property "EXPORT_FILE_NAME"))
           (set-buffer-modified-p modifiedp)))
       "-noexport" 'region-start-level))))

(use-package org-make-toc
:defer t
:custom
(org-make-toc-insert-custom-ids t)
:hook (org-mode . org-make-toc-mode)
:commands (org-make-toc))

(use-package org-modern
  :after org
  :hook (org-mode . org-modern-mode))

(use-package org-roam
  :defer t
  :straight t
  :demand t
  :init
  (setq org-roam-v2-ack t)
  :bind
  (("C-c n l" . org-roam-buffer-toggle)
   ("C-c n f" . org-roam-node-find)
   ("C-c n c" . org-roam-capture)
   ("C-c n i" . org-roam-node-insert)
   :map org-mode-map
   ("C-M-i" . completion-at-point)
   :map org-roam-dailies-map
   ("Y" . org-roam-dailies-capture-yesterday)
   ("T" . org-roam-dailies-capture-tommorow))
  :bind-keymap
  ("C-c n d" . org-roam-dailies-map)
  :custom
  (org-roam-directory "~/dev/personal/org/roam-notes")
  (org-roam-completion-everywhere t)
  (org-roam-capture-templates
   '(("d" "default" plain
      "%?"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date:%U\n")
      :unnarrowed t)

     ("l" "Programming languages" plain
      "* Info\n\n- Family: %?\n\n* Resources:\n\n"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date:%U\n") :unnarrowed t)

      ("c" "class notes" plain
      "* ${title}\n\n- Chapter: %?"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date:%U\n#+category: %^{Subject}-Sem2\n#+filetags: Csit")
      :unnarrowed t)

     ("b" "Book Note" plain
      (file "~/dev/personal/org/roam-notes/templates/book.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date:%U\n")
      :unnarrowed t)


     ("p" "Project" plain
      (file "~/dev/personal/org/roam-notes/templates/project.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date:%U\n#+category: ${title}\n#+filetags: Project")
      :unnarrowed t)
     ))
  (org-roam-dailies-capture-templates
   '(("d" "default" entry "*  %?"
      :if-new (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d: %A>\n"))

     ("t" "Timed" entry "* %<%I:%M %p>: %?"
      :if-new (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d: %A>\n"))))
   :config
   (require 'org-roam-dailies) ;; Ensure the keymap is available
   (org-roam-db-autosync-mode)
   (org-roam-setup))

;; Bind this to C-c n I
  (with-eval-after-load 'org-roam
  (defun org-roam-node-insert-immediate (arg &rest args)
    (interactive "P")
    (let ((args (cons arg args))
          (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                    '(:immediate-finish t)))))
      (apply #'org-roam-node-insert args)))

(global-set-key (kbd "C-c n I") #'org-roam-node-insert-immediate))

;; The buffer you put this code in must have lexical-binding set to t!
;; See the final configuration at the end for more details.

(with-eval-after-load 'org-roam
(defun my/org-roam-filter-by-tag (tag-name)
  (lambda (node)
    (member tag-name (org-roam-node-tags node))))

(defun my/org-roam-list-notes-by-tag (tag-name)
  (mapcar #'org-roam-node-file
          (seq-filter
           (my/org-roam-filter-by-tag tag-name)
           (org-roam-node-list))))

(defun my/org-roam-refresh-agenda-list ()
  (interactive)
  (setq org-agenda-files (my/org-roam-list-notes-by-tag "Project")))

;; Build the agenda list the first time for the session
(my/org-roam-refresh-agenda-list))

(defun my/org-roam-project-finalize-hook ()
  "Adds the captured project file to `org-agenda-files' if the
capture was not aborted."
  ;; Remove the hook since it was added temporarily
  (remove-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)

  ;; Add project file to the agenda list if the capture was confirmed
  (unless org-note-abort
    (with-current-buffer (org-capture-get :buffer)
      (add-to-list 'org-agenda-files (buffer-file-name)))))

(defun my/org-roam-find-project ()
  (interactive)
  ;; Add the project file to the agenda after capture is finished
  (add-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)

  ;; Select a project file to open, creating it if necessary
  (org-roam-node-find
   nil
   nil
   (my/org-roam-filter-by-tag "Project")
   :templates
   '(("p" "project" plain "* Goals\n\n%?\n\n* Tasks\n\n** TODO Add initial tasks\n\n* Dates\n\n"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+category: ${title}\n#+filetags: Project")
      :unnarrowed t))))

(global-set-key (kbd "C-c n p") #'my/org-roam-find-project)

(defun my/org-roam-capture-inbox ()
  (interactive)
  (org-roam-capture- :node (org-roam-node-create)
                     :templates '(("i" "inbox" plain "* %?"
                                  :if-new (file+head "Inbox.org" "#+title: Inbox\n")))))

(global-set-key (kbd "C-c n b") #'my/org-roam-capture-inbox)

(defun my/org-roam-capture-task ()
  (interactive)
  ;; Add the project file to the agenda after capture is finished
  (add-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)

  ;; Capture the new task, creating the project file if necessary
  (org-roam-capture- :node (org-roam-node-read
                            nil
                            (my/org-roam-filter-by-tag "Project"))
                     :templates '(("p" "project" plain "** TODO %?"
                                   :if-new (file+head+olp "%<%Y%m%d%H%M%S>-${slug}.org"
                                                          "#+title: ${title}\n#+category: ${title}\n#+filetags: Project"
                                                          ("Tasks"))))))

(global-set-key (kbd "C-c n t") #'my/org-roam-capture-task)

(defun my/org-roam-copy-todo-to-today ()
  (interactive)
  (let ((org-refile-keep t) ;; Set this to nil to delete the original!
        (org-roam-dailies-capture-templates
          '(("t" "tasks" entry "%?"
             :if-new (file+head+olp "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d: %A>\n" ("Tasks")))))
        (org-after-refile-insert-hook #'save-buffer)
        today-file
        pos)
    (save-window-excursion
      (org-roam-dailies--capture (current-time) t)
      (setq today-file (buffer-file-name))
      (setq pos (point)))

    ;; Only refile if the target file is different than the current file
    (unless (equal (file-truename today-file)
                   (file-truename (buffer-file-name)))
      (org-refile nil nil (list "Tasks" today-file nil pos)))))

(with-eval-after-load 'org-roam
(add-to-list 'org-after-todo-state-change-hook
             (lambda ()
               (when (equal org-state "DONE")
                 (my/org-roam-copy-todo-to-today)))))

;; DOt execute taskes over default capture Argghhh!
;; (setq org-roam-capture-templates '(("d" "default" plain "%?"
     ;; :target (file+head "${slug}.org.gpg"
                        ;; "#+title: ${title}\n")
     ;; :unnarrowed t)))

(use-package pdf-tools
:defer t
:commands (pdf-view-mode pdf-tools-install)
:mode ("\\.[pP][dD][fF]\\'" . pdf-view-mode)
:magic ("%PDF" . pdf-view-mode)
:config
(pdf-tools-install)
(define-pdf-cache-function pagelabels)
:hook ((pdf-view-mode-hook . (lambda () (display-line-numbers-mode nil)))
       (pdf-view-mode-hook . pdf-tools-enable-minor-mode)
       (pdf-view-mode-hook . pdf-annot-list-follow-minor-mode)
))

(use-package org-noter
  :after pdftools
  :config
  ;; Your org-noter config ........
  (require 'org-noter-pdftools))

(use-package org-pdftools
  :hook (org-mode . org-pdftools-setup-link))

(use-package org-noter-pdftools
  :after org-noter
  :config
  ;; Add a function to ensure precise note is inserted
  (defun org-noter-pdftools-insert-precise-note (&optional toggle-no-questions)
    (interactive "P")
    (org-noter--with-valid-session
     (let ((org-noter-insert-note-no-questions (if toggle-no-questions
                                                   (not org-noter-insert-note-no-questions)
                                                 org-noter-insert-note-no-questions))
           (org-pdftools-use-isearch-link t)
           (org-pdftools-use-freestyle-annot t))
       (org-noter-insert-note (org-noter--get-precise-info)))))

  ;; fix https://github.com/weirdNox/org-noter/pull/93/commits/f8349ae7575e599f375de1be6be2d0d5de4e6cbf
  (defun org-noter-set-start-location (&optional arg)
    "When opening a session with this document, go to the current location.
With a prefix ARG, remove start location."
    (interactive "P")
    (org-noter--with-valid-session
     (let ((inhibit-read-only t)
           (ast (org-noter--parse-root))
           (location (org-noter--doc-approx-location (when (called-interactively-p 'any) 'interactive))))
       (with-current-buffer (org-noter--session-notes-buffer session)
         (org-with-wide-buffer
          (goto-char (org-element-property :begin ast))
          (if arg
              (org-entry-delete nil org-noter-property-note-location)
            (org-entry-put nil org-noter-property-note-location
                           (org-noter--pretty-print-location location))))))))
  (with-eval-after-load 'pdf-annot
    (add-hook 'pdf-annot-activate-handler-functions #'org-noter-pdftools-jump-to-note)))

;; TODO
;;(use-package pdf-continuous-scroll-mode
;;  :quelpa (pdf-continuous-scroll-mode :fetcher git
;;                              :repo "dalanicolai/pdf-continuous-scroll-mode.el")
;;  :hook (pdf-view-mode-hook . pdf-continuous-scroll-mode))

;; Configure Elfeed
 (use-package elfeed
   :straight t
   :config
   (setq elfeed-db-directory (expand-file-name "elfeed" user-emacs-directory)
         elfeed-show-entry-switch 'display-buffer)
   (setq elfeed-feeds
        '("https://nullprogram.com/feed/"
          "https://ambrevar.xyz/atom.xml"
          "https://guix.gnu.org/feeds/blog.atom"
          "https://valdyas.org/fading/feed/"
          "https://lucidmanager.org/tags/emacs/index.xml"
          "https://blog.tecosaur.com/tmio/rss.xml"
          "https://www.reddit.com/r/emacs/.rss"))
   :bind
   ("C-x w" . elfeed ))

;; Configure Elfeed with org mode
(use-package elfeed-org
  :defer t
  :after (org-mode)
  :straight t
  :config
 (setq elfeed-show-entry-switch 'display-buffer)
 (setq rmh-elfeed-org-files (list "~/dev/personal/org/track.org")))

(use-package nov
  :defer t
  :commands nov-mode
  :config
  (evil-set-initial-state 'nov-mode 'emacs)
  (setq nov-text-width t)
  (setq visual-fill-column-center-text t)
  (add-hook 'nov-mode-hook 'visual-line-mode)
  (add-hook 'nov-mode-hook 'visual-fill-column-mode)
  :mode ("\\.epub\\'" . nov-mode))

(use-package wiki-summary
  :defer 1
  :bind ("C-c W" . wiki-summary))
;;   :preface
;;   (defun my/format-summary-in-buffer (summary)
;;     "Given a summary, stick it in the *wiki-summary* buffer and display the buffer"
;;     (let ((buf (generate-new-buffer "*wiki-summary*")))
;;       (with-current-buffer buf
;;         (princ summary buf)
;;         (fill-paragraph)
;;         (goto-char (point-min))
;;         (text-mode)
;;         (view-mode))
;;       (pop-to-buffer buf))))
;; (advice-add 'wiki-summary/format-summary-in-buffer :override #'my/format-summary-in-buffer)

(defun efs/lsp-mode-setup ()
    (setq lspheaderline-breadcumb-segments '(path-up-to-project file symbols))
    (lsp-headerline-breadcrumb-mode))

    (use-package lsp-mode
    :commands (lsp lsp-deferred)
    :hook (lsp-mode . efs/lsp-mode-setup)
    :init
    (setq lsp-keymap-prefix "C-c l")
    (setq lsp-lens-enable t)
    (setq lsp-signature-auto-activate nil)
    ;; (setq lsp-enable-file-watchers nil)
    :config
    (lsp-enable-which-key-integration t))

(use-package dap-mode
:after lsp-mode)

(rune/leader-keys
  "D"  'dap-hydra :which-key "dap hydra")

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-doc-position 'bottom))

(use-package lsp-treemacs
  :after lsp)
  (with-eval-after-load 'treemacs
  (treemacs-resize-icons 15))

(use-package lsp-ivy
:after lsp)

(use-package poetry
:after python-mode)
;;  :config
;; (poetry-tracking-mode))
;; (message "Poetry loaded")

;; (use-package lsp-pyright
;;   :defer t
;;   :straight t
;;   :hook (python-mode . (lambda ()
;;                           (require 'lsp-pyright)
;;                           (lsp)  ; lsp or lsp-deferred
;;                           (poetry-tracking-mode)))

;;   (ein:ipynb-mode . poetry-tracking-mode))

;; (use-package blacken
;;   :demand t
;;   :after poetry
;;   :hook (poetry-tracking-mode . blacken-mode))
  ;;:customize
  ;;(blacken-only-if-project-is-blackened))

(defun manim-build-img ()
     "Build manim image after saving a file"
     (save-buffer)
     (when (or (string-equal (buffer-file-name)
                         (expand-file-name "~/dev/tutero-math/tutero/test.py"))
            (string-equal (file-name-directory buffer-file-name)
                         (expand-file-name "~/dev/tutero-math/tutero/scripts/")))
       (async-shell-command (format "cd ~/dev/tutero-math/tutero && poetry run manim -ql -r 1920,1080 %s" buffer-file-name))))

 (defun kivy-build ()
   "Build kivy app after saving a file"
     (when (string-equal (file-name-directory buffer-file-name)
                         (expand-file-name "~/dev/kivy/test/"))
     (shell-command-to-string "cp main.py /mnt/d/projects/kivy/test/ && cd /mnt/d/projects/kivy/test && poetry.exe run python main.py")))

 (defun sphinx-build ()
     "Build sphinx html builds after saving a file"
     (when (string-equal (file-name-directory buffer-file-name)
                         (expand-file-name "~/dev/c-practice/cipher-site/"))
       (async-shell-command (format "rm -rf _build/html && poetry run make html" buffer-file-name))))

(defun python-mr-builds ()
  "Build function checks to bind to M-r key"
      (interactive)
  (manim-build-img)
      (sphinx-build))

(use-package python-mode
  :straight t
  :hook ((python-mode . lsp-deferred)
         (python-mode . poetry-tracking-mode))
  :custom
  (python-shell-interpreter "python3")
  (dap-python-executable "python3")
  (dap-python-debugger 'ptvsd)
  :config
  (require 'dap-python))

   ;; C-c r doesnot bind for some reason ugly global keymap hack
  ;; (define-key global-map (kbd "C-c r") 'python-mr-builds)

(use-package ein
:defer t
:custom
(ein:output-area-inlined-images nil))

;;(use-package jupyter)

(use-package dart-mode
  :defer t
  :custom
  (dart-sdk-path (concat (getenv "HOME") "/local/flutter/bin/cache/dark-sdk/")
  dart-format-on-save t))

(use-package lsp-dart
    :defer t
    :straight t
    :hook (dart-mode . (lambda ()
                          (require 'lsp-dart)
                          (lsp))))  ; lsp or lsp-deferred

(use-package hover
    :after dart-mode
;;    :bind (:map dart-mode-map
;;                ("C-M-z" . #'hover-run-or-hot-reload)
 ;;               ("C-M-x" . #'hover-run-or-hot-restart)
  ;;              ("C-M-p" . #'hover-take-screenshot'))
    :init
    (setq hover-flutter-sdk-path (concat (getenv "HOME") "/local/flutter")
          hover-command-path (concat (getenv "GOPATH") "/bin/hover")
          hover-hot-reload-on-save t
          hover-screenshot-path (concat "/mnt/d/" "images/flutter")
          hover-screenshot-prefix "emacs-"
          hover-observatory-uri "http://0.0.0.0:50300"
          hover-clear-buffer-on-hot-restart t))

(with-eval-after-load 'lsp-mode
 (add-hook 'lsp-mode-hook #'lsp-enable-which-key-integration)
 (require 'dap-cpptools)
 (yas-global-mode))
(add-hook 'c-mode-hook 'lsp)
(add-hook 'c++-mode-hook 'lsp)

;; TODO
;;(use-package gdb-mi :quelpa (gdb-mi :fetcher git
;;                                    :url "https://github.com/weirdNox/emacs-gdb.git"
;;                                    :files ("*.el" "*.c" "*.h" "Makefile"))
;;  :init
;;  (fmakunbound 'gdb)
;;  (fmakunbound 'gdb-enable-debug))

(defun lsp-go-install-save-hooks ()
  (add-hook 'after-save-hook #'lsp-format-buffer t t)
  (add-hook 'after-save-hook #'lsp-organize-imports t t))

(use-package go-mode
  :mode "\\.go\\'"
  :hook ((go-mode . lsp-deferred)
         (go-mode . lsp-go-install-save-hooks)))


(define-key global-map (kbd "C-c l R") '(lambda () (interactive)
                                          (progn
                                            (save-buffer)
                                            (recompile))))

;; go install github.com/josharian/impl@latest
(use-package go-impl
  :defer t)

;; go install github.com/go-delve/delve/cmd/dlv@latest
(use-package go-dlv
  :defer t)
(use-package gotest
:defer t
:config
(define-key go-mode-map (kbd "C-c l t f") 'go-test-current-file)
(define-key go-mode-map (kbd "C-c l t t") 'go-test-current-test)
(define-key go-mode-map (kbd "C-c l t p") 'go-test-current-project)
(define-key go-mode-map (kbd "C-c l t b") 'go-test-current-benchmark)
(define-key go-mode-map (kbd "C-c l t r") 'go-run))

;; go install github.com/haya14busa/goplay/cmd/goplay@latest
(use-package go-playground
  :defer t)

;; GO111MODULE=off go get -v github.com/cweill/gotests/...
(use-package go-gen-test
  :defer t)
;; :config
;; (defun my-go-gen-test-setup ()
;;   "My keybindings for generating go tests."
;;   (interactive)
;;   (local-set-key (kbd "C-c C-g") #'go-gen-test-dwim))

;; (add-hook 'go-mode-hook #'my-go-gen-test-setup))

(use-package go-eldoc
  :defer t)
;; go install github.com/kisielk/errcheck@latest
(use-package go-errcheck
  :defer t)

(add-hook 'js-mode-hook 'lsp)
(add-hook 'js-jsx-mode 'lsp)

(use-package js2-mode
  :hook (js2-minor-mode . lsp-deferred))

(use-package typescript-mode
    :mode "\\.ts\\'" ;; only load/open for .ts file
    :hook (typescript-mode . lsp-deferred)
    :config
    (setq typescript-indent-level 2))

(use-package yaml-mode
  :mode "\\.ya?ml\\'")

(use-package math-preview
:defer t
:custom
(math-preview-command "/home/pykancha/.config/nvm/versions/node/v14.17.6/bin/math-preview"))

(use-package lua-mode
    :mode "\\.lua\\'" ;; only load/open for .ts file
    :hook (lua-mode . lsp-deferred)
    :config
    (setq lua-indent-level 3)
    (setq lua-documentation-function 'browse-web))

(use-package racket-mode
:hook ((racket-xp-mode . racket-mode)
       (racket-mode . lsp-deferred)))

(use-package elixir-mode)

(use-package counsel-dash
 :config
 (setq counsel-dash-common-docsets '("Go", "Emacs Lisp", "Python_3"))
 (setq counsel-dash-docsets-path "~/.local/share/dasht/docsets")
 (setq counsel-dash-browser-func 'eww)
 ;; when using dasht for docset download error popups up just disable it
 (setq dash-docs-enable-debugging nil)
 (rune/leader-keys
    "d"  '(:ignore t :which-key "Dash Docs")
    "ds"  'counsel-dash :which-key "Dash search"
    "dd"  'counsel-dash-at-point :which-key "Dash at point")
 :hook ((emacs-lisp-mode . (lambda () (setq-local counsel-dash-docsets '("Emacs Lisp"))))
        (python-mode . (lambda () (setq-local counsel-dash-docsets '("Python_3"))))
        (go-mode . (lambda () (setq-local counsel-dash-docsets '("Go"))))
        (c-mode . (lambda () (setq-local counsel-dash-docsets '("C"))))))

(use-package private-comments-mode)

(use-package flycheck
  :straight t
  :defer t
  :config
  ;;(setq flycheck-python-pyright-executable "~/.emacs.d/var/lsp/server/npm/pyright")
  :init (global-flycheck-mode))

(use-package smartparens)
(require 'smartparens-config)

(use-package apheleia
:config
;; for python
(setf (alist-get 'isort apheleia-formatters)
    '("isort" "--stdout" "-"))
(setf (alist-get 'black apheleia-formatters)
    '("black" "-"))
(setf (alist-get 'prettierd apheleia-formatters)
    '("prettierd" filepath))
(setf (alist-get 'python-mode apheleia-mode-alist)
    '(isort black))
(setf (alist-get 'js-mode apheleia-mode-alist)
    '(prettierd))
(apheleia-global-mode))

(use-package company
  :after lsp-mode
  :hook (lsp-mode . company-mode)
  :bind ;;(:map company-active-map
         ;;("<tab>" . company-complete-selection))
        (:map lsp-mode-map
         ("<tab>" . company-indent-or-complete-common))
  :custom
  (company-minimum-prefix-length 1)
  (company-idle-delay 0.5))

(use-package company-box
  :hook (company-mode . company-box-mode))

(use-package company-tabnine
  :straight t
  :config
  ;; Trigger completion immediately.
  (setq company-idle-delay 0)
  ;; Number the candidates (use M-1, M-2 etc to select completions).
  (setq company-show-numbers t)
  )
;; (add-to-list 'company-backends #'company-tabnine)

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  ;; NOTE: Set this to the folder where you keep your Git repos!
  (when (file-directory-p "~/dev")
    (setq projectile-project-search-path '("~/dev")))
  (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :after projectile
  :config
  (define-key projectile-command-map (kbd "C-c p f") 'counsel-fzf)
  (counsel-projectile-mode))

(use-package magit
  :defer t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; (use-package forge
;; :after magit)

;; (use-package magit-delta
;; :after magit
;; :config
;; (add-hook 'magit-mode-hook (lambda () (magit-delta-mode +1))))

(use-package magit-todos
  :after magit)

;; Show + - icons for git changes in gutter/fringe
;; git-gutter-fringe -> works in gui only (supports along with linum mode)
;; git-gutter -> works in both (doesnot go along with linum mode :(
;; Just not useful ig
(use-package git-gutter
 :defer t)
;; disable on org buffers (interferes with drop down arrow makes look like big space)
;; @Just not useful ig
;; (defun activate-gutter ()
;;   (unless (eq major-mode 'org-mode)
;;     (git-gutter-mode 1)))
;; (add-hook 'prog-mode-hook 'activate-gutter)
;; (add-hook 'text-mode-hook 'activate-gutter)

(use-package evil-nerd-commenter
  :bind ("M-/" . evilnc-comment-or-uncomment-lines))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package yasnippet
:defer t
:config
(setq yas-snippet-dirs '("~/dev/dotfiles/emacs/snippets/"))
(yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)
(use-package react-snippets
  :after yasnippet)

(use-package webpaste
  ;; :bind (("C-c C-p C-b" . webpaste-paste-buffer)
         ;; ("C-c C-p C-r" . webpaste-paste-region))
  :custom (webpaste-provider-priority '("ix.io" "dpaste.com")))

(use-package undo-fu
  :after evil
  :config
      (setq evil-undo-system 'undo-fu))

(use-package undo-fu-session
  :after undo-fu
  :config
  (setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'"))
      (global-undo-fu-session-mode))

;; (use-package undo-tree
;; :straight t
;; :config
;; (global-undo-tree-mode))

(use-package verb
 :after org-mode
 :straight t)

(use-package harpoon
  :config
    (rune/leader-keys
      "hf" 'harpoon-toggle-file
      "ha" 'harpoon-add-file
      "hh" 'harpoon-toggle-quick-menu
      "hd" 'harpoon-clear
      "h1" 'harpoon-go-to-1
      "h2" 'harpoon-go-to-2
      "h3" 'harpoon-go-to-3
      "h4" 'harpoon-go-to-4
      "h5" 'harpoon-go-to-5
      "h6" 'harpoon-go-to-6
      "h7" 'harpoon-go-to-7
      "h8" 'harpoon-go-to-8
      "h9" 'harpoon-go-to-9
      ))

(setq display-time-world-list
  '(
    ("Australia/Melbourne" "Melbourne")
    ("Asia/Calcutta" "India")
    ("America/Chicago" "Chicago")
    ("Asia/Kathmandu" "Kathmandu")
    ("Etc/UTC" "UTC")))

(setq display-time-world-time-format "%a, %d %b %I:%M %p %Z")

(use-package origami
  :defer t
  :config
  (global-origami-mode 1)
  :bind (("C-c l o T" . origami-toggle-all-nodes)
         ("C-c l o t" . origami-toggle-node)
         ("C-c l o n" . origami-next-fold)
         ("C-c l o p" . origami-previous-fold)
         ("C-c l o r t" . origami-recursively-toggle-node)
         ("C-c l o r o" . origami-open-node-recursively)
         ("C-c l o r c" . origami-close-node-recursively)
         ("C-c l o O" . origami-open-all-nodes)
         ("C-c l o C" . origami-close-all-nodes)))

(use-package lsp-origami
  :hook (lsp-after-open-hook . lsp-origami-try-enable))

(use-package savehist
:custom
(history-length 25)
(savehist-mode 1))
;; Individual history elements can be configured separately
;;(put 'minibuffer-history 'history-length 25)
;;(put 'evil-ex-history 'history-length 50)
;;(put 'kill-ring 'history-length 25))

(use-package term
:commands term
:config
(setq explicit-shell-file-name "zsh"))
;; Change this to zsh, etc
;;(setq explicit-zsh-args '())
;; Use 'explicit-<shell>-args for shell-specific args

  ;; Match the default Bash shell prompt.  Update this if you have a custom prompt
  ;; (setq term-prompt-regexp "^[^#$%>\n]*[#$%>] *"))

;; Bad support in WSL with X11 server
;;  (use-package eterm-256color
;;    :hook (term-mode . eterm-256color-mode))

;; (use-package vterm
;;   :commands vterm
;;   :config
;;   (setq term-prompt-regexp "^[^#$%>\n]*[#$%>] *")  ;; Set this to match your custom shell prompt
  ;;(setq vterm-shell "zsh")                       ;; Set this to customize the shell to launch
  ;; (setq vterm-max-scrollback 10000))

(when (eq system-type 'windows-nt)
  (setq explicit-shell-file-name "powershell.exe")
  (setq explicit-powershell.exe-args '()))

(defun efs/configure-eshell ()
  ;; Save command history when commands are entered
  (add-hook 'eshell-pre-command-hook 'eshell-save-some-history)

  ;; Truncate buffer for performance
  (add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)

  ;; Bind some useful keys for evil-mode
  (evil-define-key '(normal insert visual) eshell-mode-map (kbd "C-r") 'counsel-esh-history)
  (evil-define-key '(normal insert visual) eshell-mode-map (kbd "<home>") 'eshell-bol)
  (evil-normalize-keymaps)

  (setq eshell-history-size         10000
        eshell-buffer-maximum-lines 10000
        eshell-hist-ignoredups t
        eshell-scroll-to-bottom-on-input t))

(use-package eshell-git-prompt
  :after eshell)

(use-package eshell
  :hook (eshell-first-time-mode . efs/configure-eshell)
  :config

  (with-eval-after-load 'esh-opt
    (setq eshell-destroy-buffer-when-process-dies t)
    (setq eshell-visual-commands '("htop" "zsh" "vim")))
  (eshell-git-prompt-use-theme 'powerline))

(use-package dashboard
  :straight t
  :if (< (length command-line-args) 2)
  :init
  (dashboard-setup-startup-hook)
  :config
  (setq initial-buffer-choice (lambda () (get-buffer "*dashboard*")))

  ;; Set the title
(setq dashboard-banner-logo-title "Pykancha eMacs")
;; Set the banner
(setq dashboard-startup-banner 'logo)
;; Value can be
;; 'official which displays the official emacs logo
;; 'logo which displays an alternative emacs logo
;; 1, 2 or 3 which displays one of the text banners
;; "path/to/your/image.gif", "path/to/your/image.png" or "path/to/your/text.txt" which displays whatever gif/image/text you would prefer

;; Content is not centered by default. To center, set
(setq dashboard-center-content t)

;; To disable shortcut "jump" indicators for each section, set
(setq dashboard-show-shortcuts nil)

(setq dashboard-items '((recents  . 5)
                      (bookmarks . 5)
                      (agenda . 5)
                      ))
)

;; Sent alert in emacs (useful for telegram alerts)
(use-package alert
  :defer t
  )
;; detect language automatically (telegram chats code highlight)
(use-package language-detection)

(use-package telega
  :defer t
  :commands (telega)
  :config
(telega-mode-line-mode 1)
;; Attach org links to-fro telega chats
(require 'ol-telega)

;; Highlight telegram code blocks in emacs
(require 'telega-mnz)
(global-telega-mnz-mode 1)

;; Open telega chat buffer and dired side by side and execute dired-do-copy after selecting files it will be sent
(require 'telega-dired-dwim)

;; Send alerts using alert.el
(require 'telega-alert)
(telega-alert-mode 1)

;; beautify and shorted urls in chat eg: githubusername/repo
(require 'telega-url-shorten)
(global-telega-url-shorten-mode)
(setq telega-url-shorten-use-images t)

;; Block channel ads promotion
(require 'telega-adblock)
(telega-adblock-mode 1)

;; Magit style transiet key
(require 'telega-transient)
(telega-transient-mode 1))

;; (require 'telega-stories)
;; (telega-stories-mode 1)
;; "Emacs Stories" rootview
;; (define-key telega-root-mode-map (kbd "v e") 'telega-view-emacs-stories)
;; Emacs Dashboard
;; (add-to-list 'dashboard-items '(telega-stories . 5))
;; )
(define-key global-map (kbd "C-c t") telega-prefix-map)

(use-package speed-type
  :defer t)

(use-package ascii-art-to-unicode :straight t)

(use-package osm
  :bind (("C-c m h" . osm-home)
         ("C-c m s" . osm-search)
         ("C-c m v" . osm-server)
         ("C-c m t" . osm-goto)
         ("C-c m x" . osm-gpx-show)
         ("C-c m j" . osm-bookmark-jump))

  :custom
  ;; Take a look at the customization group `osm' for more options.
  (osm-server 'default) ;; Configure the tile server
  (osm-copyright t)     ;; Display the copyright information

  :init
  ;; Load Org link support
  ;;(with-eval-after-load 'org
    ;;(require 'osm-ol))
    )

(use-package nepali-romanized
    :straight (nepali-romanized
             :type git :host github :repo "bishesh/emacs-nepali-romanized"
             :files ("nepali-romanized.el")))

(use-package redacted
  :defer t
  :commands (redacted-mode))

(setq erc-server "irc.libera.chat"
      erc-nick "hemanta212"
      erc-user-full-name " "
      erc-track-shorten-start 8
      erc-autojoin-channel-alist '(("irc.libera.chat" "#systemcrafters" "#emacs"))
      erc-kill-buffer-on-part t
      erc-auto-query 'bury)

(defun dw/org-present-prepare-slide ()
  (org-overview)
  (org-show-entry)
  (org-show-children))

(defun dw/org-present-hook ()
  (setq-local face-remapping-alist '((default (:height 1.5) variable-pitch)
                                     (header-line (:height 4.5) variable-pitch)
                                     (org-code (:height 1.55) org-code)
                                     (org-verbatim (:height 1.55) org-verbatim)
                                     (org-block (:height 1.25) org-block)
                                     (org-block-begin-line (:height 0.7) org-block)))
  (setq header-line-format " ")
  (org-display-inline-images)
  (dw/org-present-prepare-slide))

(defun dw/org-present-quit-hook ()
  (setq-local face-remapping-alist '((default variable-pitch default)))
  (setq header-line-format nil)
  (org-present-small)
  (org-remove-inline-images))

(defun dw/org-present-prev ()
  (interactive)
  (org-present-prev)
  (dw/org-present-prepare-slide))

(defun dw/org-present-next ()
  (interactive)
  (org-present-next)
  (dw/org-present-prepare-slide))

(use-package org-present
  :bind (:map org-present-mode-keymap
         ("C-c C-j" . dw/org-present-next)
         ("C-c C-k" . dw/org-present-prev))
  :hook ((org-present-mode . dw/org-present-hook)
         (org-present-mode-quit . dw/org-present-quit-hook)))

(defun dw/org-start-presentation ()
  (interactive)
  (org-tree-slide-mode 1)
  (setq text-scale-mode-amount 3)
  (text-scale-mode 1))

(defun dw/org-end-presentation ()
  (interactive)
  (text-scale-mode 0)
  (org-tree-slide-mode 0))

(use-package org-tree-slide
  :defer t
  :after org
  :commands org-tree-slide-mode
  :config
  (evil-define-key 'normal org-tree-slide-mode-map
    (kbd "q") 'dw/org-end-presentation
    (kbd "C-j") 'org-tree-slide-move-next-tree
    (kbd "C-k") 'org-tree-slide-move-previous-tree)
  (setq org-tree-slide-slide-in-effect nil
        org-tree-slide-activate-message "Presentation started."
        org-tree-slide-deactivate-message "Presentation ended."
        org-tree-slide-header t))

;; dependency imgur
(use-package imgur :straight t
  :defer t)

(use-package meme
  :defer t
  :straight (:host github :repo "larsmagne/meme"))

(use-package elcord
  :defer t
  :config
  (defun myelcord-buffer-details-format ()
    "Return the buffer details string shown on discord."
    (if (equal (substring (buffer-name) 0 1) "!")
    (format "%s [%s]" (substring (buffer-name) 1) (car (persp-ibuffer-name (current-buffer))))
    (format "Editing %s [%s]" (buffer-name) (car (persp-ibuffer-name (current-buffer))))))

  (setq elcord-buffer-details-format-function 'myelcord-buffer-details-format)
  (setq elcord-idle-timer 5000)
  )

;; (load-file "~/.cache/emacs/.emacs.custom/misc-exts/byte-run.el")
;; (add-to-list 'load-path "/usr/share/emacs/site-lisp/mu4e")
;; (require 'mu4e)

;;   (use-package mu4e
;;     :load-path "/usr/share/emacs/site-lisp/mu4e"
;;     :config
;;   ;; list of your email adresses:
;;   (setq mu4e-personal-addresses '("hemantasharma.212@gmail.com"))

;;   (setq mu4e-maildir (expand-file-name "~/Mail"))

;;   (setq mu4e-contexts
;;         `(,(make-mu4e-context
;;             :name "Gmail" ;; Give it a unique name. I recommend they start with a different letter than the second one.
;;             :enter-func (lambda () (mu4e-message "Entering gmail context"))
;;             :leave-func (lambda () (mu4e-message "Leaving gmail context"))
;;             :match-func (lambda (msg)
;;                           (when msg
;;                             (string= (mu4e-message-field msg :maildir) "/hemantasharma.212@gmail")))
;;             :vars '((user-mail-address . "hemantasharma.212@gmail.com")
;;                     (user-full-name . "Hemanta Sharma")
;;                     (mu4e-drafts-folder . "/hemantasharma.212@gmail/[Gmail].Drafts")
;;                     (mu4e-refile-folder . "/hemantasharma.212@gmail/[Gmail].All Mail")
;;                     (mu4e-sent-folder . "/hemantasharma.212@gmail/[Gmail].Sent Mail")
;;                     (mu4e-trash-folder . "/hemantasharma.212@gmail/[Gmail].Bin")
;;                     ;; SMTP configuration
;;                     (starttls-use-gnutls . t)
;;                     (smtpmail-starttls-credentials . '(("smtp.gmail.com" 587 nil nil)))
;;                     (smtpmail-smtp-user . "hemantasharma.212@gmail.com")
;;                     (smtpmail-auth-credentials .
;;                                                '(("smtp.gmail.com" 587 "hemantasharma.212@gmail.com" nil)))
;;                     (smtpmail-default-smtp-server . "smtp.gmail.com")
;;                     (smtpmail-smtp-server . "smtp.gmail.com")
;;                     (smtpmail-smtp-service . 587)))
;;           ;; ,(make-mu4e-context
;;           ;;   :name "Business Address" ;; Or any other name you like.
;;           ;;   :enter-func (lambda () (mu4e-message "Entering cablecar context"))
;;           ;;   :leave-func (lambda () (mu4e-message "Leaving cablecar context"))

;;           ;;   :match-func (lambda (msg)
;;           ;;                 (when msg
;;           ;;                   (string= (mu4e-message-field msg :maildir) "/address2@gmail")))
;;           ;;   :vars '((user-mail-address . "address2@gmail.com")
;;           ;;           (user-full-name . "Your Name Here")
;;           ;;           (mu4e-drafts-folder . "/address2@gmail/[Gmail].Drafts")
;;           ;;           (mu4e-refile-folder . "/address2@gmail/[Gmail].All Mail")
;;           ;;           (mu4e-sent-folder . "/address2@gmail/[Gmail].Sent Mail")
;;           ;;           (mu4e-trash-folder . "/address2@gmail/[Gmail].Bin")
;;           ;;           ;; SMTP configuration
;;           ;;           (starttls-use-gnutls . t)
;;           ;;           (smtpmail-starttls-credentials . '(("smtp.gmail.com" 587 nil nil)))
;;           ;;           (smtpmail-smtp-user . "address2@gmail.com")
;;           ;;           (smtpmail-auth-credentials .
;;           ;;                                      '(("smtp.gmail.com" 587 "address2@gmail.com" nil)))
;;           ;;           (smtpmail-default-smtp-server . "smtp.gmail.com")
;;           ;;           (smtpmail-smtp-server . "smtp.gmail.com")
;;           ;;           (smtpmail-smtp-service . 587)))
;;           ))

;;   (setq mu4e-maildir-shortcuts  '((:maildir "/hemantasharma.212@gmail/INBOX"               :key ?i)
;;                                   (:maildir "/hemantasharma.212@gmail/[Gmail].Sent Mail"   :key ?s)
;;                                   (:maildir "/hemantasharma.212@gmail/[Gmail].Drafts"      :key ?d)
;;                                   (:maildir "/hemantasharma.212@gmail/[Gmail].Bin"       :key ?t)
;;                                   (:maildir "/hemantasharma.212@gmail/[Gmail].All Mail"    :key ?a))))

(use-package copilot
  :straight (:host github :repo "zerolfx/copilot.el" :files ("dist" "*.el"))
  :ensure t
  :hook
  (prog-mode . copilot-mode)
  :config
  (define-key copilot-completion-map (kbd "<tab>") 'copilot-accept-completion)
  (define-key copilot-completion-map (kbd "TAB") 'copilot-accept-completion))
;; you can utilize :map :hook and :config to customize copilot

(use-package codespaces
  :config (codespaces-setup)
  (setq vc-handled-backends '(Git))
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path)
  (setq tramp-ssh-controlmaster-options "")
  :bind ("C-c S" . #'codespaces-connect))

(use-package edit-server
  :defer t
 :config
  (edit-server-start))

;; Make gc pauses faster by decreasing the threshold.
(setq gc-cons-threshold (* 1 1000 1000))

(fset 'sh\ and\ example\ decorate
   (kmacro-lambda-form [escape ?k ?j ?\" ?2 escape ?@ ?q ?2 ?@ ?q ?@ ?q ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?k ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j ?j] 0 "%d"))

(fset 'around_literal_equal
   (kmacro-lambda-form [?v ?i ?o escape ?b ?i ?= escape ?e ?a ?= escape] 0 "%d"))

(if (daemonp)
    (with-temp-buffer
      "~/dev/dotfiles/emacs/.emacs.d/init.el"
  (eval-buffer)
  ))

;; Emacs 29 ships with an improved global minor mode for scrolling with a mouse or a touchpad,
;; that you might want to enable as well:
(when (>= emacs-major-version 29)
  (pixel-scroll-precision-mode))

;; (unless efs/is-termux
;; (use-package eaf
;;   :load-path "~/.cache/emacs/.emacs.custom/site-lisp/emacs-application-framework/"
;;   :custom
;;   ; See https://github.com/emacs-eaf/emacs-application-framework/wiki/Customization
;;   (eaf-browser-continue-where-left-off t)
;;   (eaf-browser-enable-adblocker t)
;;   :config
;;   (setq eaf-apps-to-install '(browser image-viewer pdf-viewer rss-reader markdown-previewer
;;                               org-previewer))
;;   (require 'eaf-image-viewer)
;;   (require 'eaf-pdf-viewer)
;;   (require 'eaf-org-previewer)
;;   (require 'eaf-markdown-previewer)
;;   (require 'eaf-rss-reader)
;;   (require 'eaf-browser)))

(setq my-state nil)
(defun efs/my-toggle()
  (interactive)
    (if (eq my-state nil)
        (setq my-state 't)
    (setq my-state nil))
  (message "%s" my-state))

(defun reload-emacs()
    (interactive)
    (load-file (expand-file-name "~/dev/dotfiles/emacs/.emacs.d/init.el")))

(define-key global-map (kbd "C-c e r r") 'reload-emacs)
