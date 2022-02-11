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
  (setq debug-on-error t)
  ;; supress native comp warnings
  (setq native-comp-async-report-warnings-errors 'silent)
  ;; Suppress “ad-handle-definition: .. redefined” warnings during Emacs startup.
  (custom-set-variables '(ad-redefinition-action (quote accept)))

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

;; Bootstrapping quelpa
;; (unless (package-installed-p 'quelpa)
;;   (with-temp-buffer
;;     (url-insert-file-contents "https://raw.githubusercontent.com/quelpa/quelpa/master/quelpa.el")
;;     (eval-buffer)
;;     (quelpa-self-upgrade)))
(use-package quelpa
  :defer nil
  :custom
  (quelpa-checkout-melpa-p nil)
  :config
  (quelpa
   '(quelpa-use-package
     :fetcher git
     :url "https://github.com/quelpa/quelpa-use-package.git"))
  (require 'quelpa-use-package))
(require 'quelpa)
(quelpa-use-package-activate-advice)

;; Define variables section
(defvar efs/default-font-size 160)
(defvar efs/default-variable-font-size 160)

;; Make frame transparency overridable
(defvar efs/frame-transparency '(90 . 90))


(setq inhibit-startup-message t)

(if (display-graphic-p)
    (progn
      (set-fringe-mode 10)        ; Give some breathing room
      (tooltip-mode -1)           ; Disable tooltips
      (tool-bar-mode -1)
      (scroll-bar-mode -1)))

(set-face-attribute 'default nil :font "Fira Code Retina" :height efs/default-font-size)
;; Set the fixed pitch face
(set-face-attribute 'fixed-pitch nil :font "Fira Code Retina" :height efs/default-font-size)
;; Set the variable pitch face
(set-face-attribute 'variable-pitch nil :font "Cantarell" :height efs/default-variable-font-size :weight 'regular)

(menu-bar-mode -1)            ; Disable the menu bar
;; Set up the visible bell
(setq visible-bell nil)
;; Change cursor color
;;(set-cursor-color "#000000")

(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                vterm-mode-hook
                eww-mode-hook
                treemacs-mode-hook
                nov-mode-hook
                pdf-view-mode-hook
                lsp-ui-imenu-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(column-number-mode)

;; Prevent asking for confirmation to kill processes when exiting.
(custom-set-variables '(confirm-kill-processes nil))

;; set default encoding
(set-language-environment "UTF-8")
(prefer-coding-system       'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)

;; line numbers
(when (>= emacs-major-version 26)
(use-package display-line-numbers
  :defer nil
  :ensure nil
  :config
  (global-display-line-numbers-mode)))

;; Highlight trailing whitespace in red, so it’s easily visible
;;(disabled for now as it created a lot of noise in some modes, e.g. the org-mode export screen)
 (custom-set-variables '(show-trailing-whitespace nil))

;; Highlight matching parenthesis
(show-paren-mode)

;; Make Asynchronous operations loaded to use later
(use-package async)

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
  :ensure nil
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

;; Load the which key compatible bind-key
(require 'bind-key)
;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
;; Remap  Imenu to M-i
(global-set-key (kbd "M-i") 'imenu)
(global-set-key (kbd "C-c p f") 'counsel-fzf)
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
    "fd"  '(:ignore t :which-key "Dot files")
    "fde" '(lambda () (interactive) (find-file (expand-file-name "~/dev/dotfiles/emacs/.emacs.d/config.org")) :which-key "emacs config")))


(use-package evil
  :init
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
  :defer nil
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

(use-package doom-themes
  :init (load-theme 'doom-gruvbox t))

(use-package berrys-theme
  :ensure t
  :config ;; for good measure and clarity
  (setq-default cursor-type '(bar . 2))
  (setq-default line-spacing 5))

(use-package all-the-icons)
(use-package all-the-icons-ivy
  :after (all-the-icons ivy))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))

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

(use-package avy
:ensure t)

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
  :ensure t
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
:ensure t
:bind (("C-x k" . persp-kill-buffer*))
:init
(persp-mode))

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
  (dolist (face '((org-level-1 . 1.4)
                  (org-level-2 . 1.2)
                  (org-level-3 . 1.2)
                  (org-level-4 . 1.2)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.1)
                  (org-level-7 . 1.1)
                  (org-level-8 . 1.1)))
    (set-face-attribute (car face) nil :font "Cantarell" :weight 'regular :height (cdr face)))

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
  (set-face-attribute 'line-number-current-line nil :inherit 'fixed-pitch))

(defun efs/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1))

(use-package org
  ;; :defer t
  ;;:pin org
  :commands (org-capture org-agenda)
  :hook (org-mode . efs/org-mode-setup)
  :config
  (setq org-ellipsis " ▾")
  (setq org-agenda-start-with-log-mode t)
  (setq org-src-tab-acts-natively t)
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)
  (setq org-agenda-files
        '("~/dev/personal/org/track.org"))
  (define-key org-mode-map (kbd "C-c C-r") verb-command-map)

  (setq org-todo-keywords
  '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)")
    (sequence "BACKLOG(b)" "PLAN(p)" "READY(r)" "ACTIVE(a)" "REVIEW(v)" "WAIT(w@/!)" "HOLD(h)" "|" "COMPLETED(c)" "CANC(k@)")))

  (efs/org-font-setup))

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "✸" "✿")))
  ;; (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")

(defun efs/org-mode-visual-fill ()
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook (org-mode . efs/org-mode-visual-fill))

(use-package ob-http
  :defer t
  :after (org-mode)
  )

(with-eval-after-load 'org
 (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (C . t)
     (scheme . t)
     (shell . t)
     (http . t)
     (ein . t)
     (js . t)
     (python . t)))

 (push '("conf-unix" . conf-unix) org-src-lang-modes)
 (setq org-confirm-babel-evaluate nil))

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
  ;; This is needed as of Org 9.2
  (require 'org-tempo)

  (add-to-list 'org-structure-template-alist '("draw" . "src artist"))
  (add-to-list 'org-structure-template-alist '("art" . "src artist"))
  (add-to-list 'org-structure-template-alist '("ex" . "example"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("sh" . "src shell"))
  (add-to-list 'org-structure-template-alist '("clang" . "src C :results output :exports both"))
  (add-to-list 'org-structure-template-alist '("cpp" . "src C++ :results output :exports both"))
  (add-to-list 'org-structure-template-alist '("c++" . "src C++ :include <iostream> :main no :results output :exports both :flags -std=c++17 -Wall --pedantic -Werror"))
  (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
  (add-to-list 'org-structure-template-alist '("sasm" . "src 8085 :export both :args -db /tmp/8085-session1"))
  (add-to-list 'org-structure-template-alist '("asm" . "src 8085"))
  (add-to-list 'org-structure-template-alist '("py" . "src python :exports both :results output"))
  (add-to-list 'org-structure-template-alist '("ein" . "src ein-python :session localhost :results output"))
  (add-to-list 'org-structure-template-alist '("ht" . "src http")))
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
:commands (org-make-toc)
)

(use-package org-roam
  :ensure t
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
  (defun org-roam-node-insert-immediate (arg &rest args)
    (interactive "P")
    (let ((args (cons arg args))
          (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                    '(:immediate-finish t)))))
      (apply #'org-roam-node-insert args)))

(global-set-key (kbd "C-c n I") #'org-roam-node-insert-immediate)

;; The buffer you put this code in must have lexical-binding set to t!
;; See the final configuration at the end for more details.

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
(my/org-roam-refresh-agenda-list)

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

(add-to-list 'org-after-todo-state-change-hook
             (lambda ()
               (when (equal org-state "DONE")
                 (my/org-roam-copy-todo-to-today))))

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

(use-package pdf-continuous-scroll-mode
  :quelpa (pdf-continuous-scroll-mode :fetcher git
                              :repo "dalanicolai/pdf-continuous-scroll-mode.el")
  :hook (pdf-view-mode-hook . pdf-continuous-scroll-mode))

;; Configure Elfeed
 (use-package elfeed
   :ensure t
   :config
   (setq elfeed-db-directory (expand-file-name "elfeed" user-emacs-directory)
         elfeed-show-entry-switch 'display-buffer)
   :bind
   ("C-x w" . elfeed ))

;; Configure Elfeed with org mode
(use-package elfeed-org
  :defer t
  :after (org-mode)
  :ensure t
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
  "d"  'dap-hydra :which-key "dap hydra")

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

(use-package flycheck
  :ensure t
  :defer t
  :config
   (setq flycheck-python-pyright-executable "~/.emacs.d/var/lsp/server/npm/pyright")
  :init (global-flycheck-mode))

(use-package smartparens)
(require 'smartparens-config)

(use-package python-mode
:ensure t
:hook (python-mode . lsp-deferred)
:custom
(python-shell-interpreter "python3")
(dap-python-executable "python3")
(dap-python-debugger 'ptvsd)
:config
(require 'dap-python)
)

(use-package poetry
:after python-mode)
;; :config
;; (message "Poetry loaded")
;; (poetry-tracking-mode))

(use-package lsp-pyright
  :defer t
  :ensure t
  :hook (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp)  ; lsp or lsp-deferred
                          (poetry-tracking-mode)))

  (ein:ipynb-mode . poetry-tracking-mode))

(use-package blacken
  :demand t
  :after poetry
  :hook (poetry-tracking-mode . blacken-mode))
  ;;:customize
  ;;(blacken-only-if-project-is-blackened))

(defun manim-build-img ()
    "Build manim image after saving a file"
    (when (or (string-equal (buffer-file-name)
                        (expand-file-name "~/dev/manim/manim/mathgaps/test.py"))
           (string-equal (file-name-directory buffer-file-name)
                        (expand-file-name "~/dev/manim/manim/mathgaps/scripts/")))
      (async-shell-command (format "cd ~/dev/manim/manim/mathgaps && poetry run python -m manim -ql -r 1920,1080 %s" buffer-file-name))))

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

  (add-hook 'after-save-hook #'manim-build-img)
  (add-hook 'after-save-hook #'sphinx-build)

(use-package dart-mode
  :defer t
  :custom
  (dart-sdk-path (concat (getenv "HOME") "/local/flutter/bin/cache/dark-sdk/")
  dart-format-on-save t))

(use-package lsp-dart
    :defer t
    :ensure t
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

(use-package gdb-mi :quelpa (gdb-mi :fetcher git
                                    :url "https://github.com/weirdNox/emacs-gdb.git"
                                    :files ("*.el" "*.c" "*.h" "Makefile"))
  :init
  (fmakunbound 'gdb)
  (fmakunbound 'gdb-enable-debug))

(use-package lua-mode
    :mode "\\.lua\\'" ;; only load/open for .ts file
    :hook (lua-mode . lsp-deferred)
    :config
    (setq lua-indent-level 3)
    (setq lua-documentation-function 'browse-web))

(use-package racket-mode
:hook (racket-xp-mode . racket-mode))

(use-package ein
:defer t
:custom
(ein:output-area-inlined-images nil))

;;(use-package jupyter)

(use-package math-preview
:defer t
:custom
(math-preview-command "/home/pykancha/.config/nvm/versions/node/v14.17.6/bin/math-preview"))

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
  :ensure t
  :config
  ;; Trigger completion immediately.
  (setq company-idle-delay 0)
  ;; Number the candidates (use M-1, M-2 etc to select completions).
  (setq company-show-numbers t)
  )
(add-to-list 'company-backends #'company-tabnine)

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
  :config (counsel-projectile-mode))

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

(use-package webpaste
  ;; :bind (("C-c C-p C-b" . webpaste-paste-buffer)
         ;; ("C-c C-p C-r" . webpaste-paste-region))
  :custom (webpaste-provider-priority '("ix.io" "dpaste.com")))

(use-package undo-tree
:ensure t
:config
(global-undo-tree-mode))

(use-package verb
:ensure t)

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
  :ensure t
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
(telega-transient-mode 1)

(require 'telega-stories)
(telega-stories-mode 1)
;; "Emacs Stories" rootview
;; (define-key telega-root-mode-map (kbd "v e") 'telega-view-emacs-stories)
;; Emacs Dashboard
(add-to-list 'dashboard-items '(telega-stories . 5))
)
(define-key global-map (kbd "C-c t") telega-prefix-map)

(use-package speed-type)

(use-package ascii-art-to-unicode)

(use-package edit-server
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
