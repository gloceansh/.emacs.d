;; -*- lexical-binding: t; -*-

;; --- init.el ---
;; The main configuration, this is where all the settings, keybindings, and packages are configured.

;; -----------------------------------------------------------------------------
;; PACKAGE MANAGER SETUP
;; -----------------------------------------------------------------------------

;; Bootstrap straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Make straight.el work with use-package
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;; -----------------------------------------------------------------------------
;; DIRECTORY CLEANUP WITH NO-LITTERING
;; -----------------------------------------------------------------------------

;; Use no-littering to keep Emacs configuration directories clean
(use-package no-littering
  :demand t
  :config
  ;; Redirect backup files
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))

;; Keep recentf clean
(use-package recentf
  :config
  (add-to-list 'recentf-exclude (recentf-expand-file-name no-littering-var-directory))
  (add-to-list 'recentf-exclude (recentf-expand-file-name no-littering-etc-directory))
  (add-to-list 'recentf-exclude "/opt/homebrew/")
  (add-to-list 'recentf-exclude "/usr/local/Cellar/")
  (recentf-mode 1))

;; -----------------------------------------------------------------------------
;; GENERAL SETTINGS
;; -----------------------------------------------------------------------------

;; Basic UI and editing preferences
(setq-default cursor-type '(box . 2) ; Set cursor to a blinking box
              fill-column 80 ; Set a line-wrap guide at 80 chars
              tab-width 4 ; Set tab width to 4 spaces
              indent-tabs-mode nil) ; Use spaces, not tabs

(setq blink-cursor-blinks 0) ; Make the blinks not stop
(global-display-line-numbers-mode t) ; Enable line numbers globally
(setq display-line-numbers-type 'relative) ; And make them relative
(global-hl-line-mode t) ; Highlight the current line
(column-number-mode t) ; Show column number in modeline

;; System and performance settings
(setq native-comp-async-report-warnings-errors 'silent) ; Silence native compilation warnings
(setq make-backup-files nil ; Disable backup files
      auto-save-default nil) ; Disable auto-save files

;; Auto-revert buffers when files change on disk (useful for Syncthing)
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)
(global-visual-line-mode 1)

;; macOS specific fixes
(setq locate-command "mdfind") ; Use spotlight's search backend
(setq ns-use-native-fullscreen nil) ; Disable native fullscreen to avoid issues
(setq ns-pop-up-frames nil) ; Make files opened outside of emacs open in an existing window
(setq mac-redisplay-dont-reset-vscroll t
      mac-mouse-wheel-smooth-scroll nil) ; Smooth scrolling fixes
(setq delete-by-moving-to-trash (not noninteractive)) ; Delete files to the macOS trashcan

(with-eval-after-load 'auth-source
  (add-to-list 'auth-sources 'macos-keychain-internet)
  (add-to-list 'auth-sources 'macos-keychain-generic)) ; Keychain integration

;; Shell fixes
(setq shell-file-name (executable-find "bash")) ; Make emacs use bash internally
(setq-default vterm-shell "/opt/homebrew/bin/fish") ; Use fish for vterm
(setq-default explicit-shell-file-name "/opt/homebrew/bin/fish") ; And for explicit shells

;; -----------------------------------------------------------------------------
;; CORE PACKAGES AND EVIL MODE
;; -----------------------------------------------------------------------------

;; Fix emacs launched from the .app file not seeing your environment variables
(use-package exec-path-from-shell
  :custom
  (exec-path-from-shell-shell-name "/opt/homebrew/bin/fish")
  (exec-path-from-shell-arguments '("-l"))
  :config
  (when (string-equal system-type "darwin")
    (exec-path-from-shell-initialize)))

;; Package for easier keybindings
(use-package general
  :config
  (general-evil-setup t))

;; Better undo/redo
(use-package undo-fu
  :after evil)

;; Save undo history between sessions.
(use-package undo-fu-session
  :init
  (undo-fu-session-global-mode))

;; Join the dark side
(use-package evil
  :init
  (setq evil-want-keybinding nil)
  (setq evil-undo-system 'undo-fu)
  (setq evil-want-integration t)
  (setq evil-respect-visual-line-mode t)
  :config
  (evil-mode 1)
  (define-key evil-normal-state-map (kbd "SPC") nil)
  (define-key evil-visual-state-map (kbd "SPC") nil)
  (define-key evil-motion-state-map (kbd "SPC") nil))

;; Join the dark side, but EVERYWHERE
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; Visualize yank/change/delete etc.
(use-package evil-goggles
  :after evil
  :config
  (evil-goggles-mode 1))

;; Easily delete surrounding quotes, parentheses, etc.
(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

;; Work with comments in evil mode
(use-package evil-nerd-commenter
  :after evil)

;; -----------------------------------------------------------------------------
;; UI ENHANCEMENTS AND APPEARANCE
;; -----------------------------------------------------------------------------

;; Autothemer, dependency for the theme below
(use-package autothemer)

;; Rose Pine theme
(use-package rose-pine-theme
  :straight (rose-pine-theme :type git :host github :repo "konrad1977/pinerose-emacs")
  :config
  (load-theme 'rose-pine t))

;; Nerd icons
(use-package nerd-icons)

;; Startup dashboard
(use-package dashboard
  :after (nerd-icons projectile)
  :init
  (setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))
  :config
  (defun dashboard-resize-on-hook (&optional _)
    (let ((space-win (get-buffer-window dashboard-buffer-name))
          (frame-win (frame-selected-window)))
      (when (and space-win
                 (not (window-minibuffer-p frame-win)))
        (with-selected-window space-win
          (dashboard-insert-startupify-lists t)))))
  (dashboard-setup-startup-hook)
  (add-hook 'dashboard-mode-hook (lambda () 
                                   (setq-local global-hl-line-mode nil)
                                   (hl-line-mode -1)))
  (setq dashboard-startup-banner (expand-file-name "assets/xemacs_color_pine.svg" user-emacs-directory)
        dashboard-banner-logo-title "Welcome to Emacs!"
        dashboard-items '((recents   . 5)
                          (projects  . 5)
                          (bookmarks . 5)))
  :custom
  (dashboard-center-content t)
  (dashboard-vertically-center-content t)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-icon-type 'nerd-icons)
  (dashboard-projects-backend 'projectile))

;; Indent guides
(use-package highlight-indent-guides
  :hook (prog-mode . highlight-indent-guides-mode)
  :config
  (setq highlight-indent-guides-method 'character)
  (setq highlight-indent-guides-character ?│)
  (setq highlight-indent-guides-responsive 'top)
  (setq highlight-indent-guides-delay 0)
  (setq highlight-indent-guides-auto-enabled nil))

;; Smooth scroll
(use-package ultra-scroll
  :init
  (setq scroll-conservatively 3
        scroll-margin 0)
  :config
  (ultra-scroll-mode 1))

;; Modern modeline
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon t)
  (doom-modeline-major-mode-color-icon t)
  (doom-modeline-buffer-state-icon t)
  (doom-modeline-buffer-modification-icon t)
  (doom-modeline-minor-modes nil)
  (doom-modeline-enable-word-count t)
  (doom-modeline-buffer-file-name-style 'relative-from-project)
  (doom-modeline-project-name t))

;; Brainrot
;; (use-package brainrot
;;   :straight (brainrot :type git :host github :repo "gloceansh/brainrot.el"
;;                       :files ("*.el" "boom.ogg" "images" "phonks"))
;;   :custom
;;   (brainrot-phonk-duration 2.5)
;;   (brainrot-min-error-duration 0.5)
;;   (brainrot-boom-volume 50)
;;   (brainrot-phonk-volume 50)
;;   :config
;;   (brainrot-mode 1))

;; -----------------------------------------------------------------------------
;; COMPLETION AND SEARCHING
;; -----------------------------------------------------------------------------

;; Which-key for displaying available keybindings
(use-package which-key
  :straight (:type built-in)
  :init
  (setq which-key-idle-delay 0.0)
  (which-key-mode))

;; Projectile for project management
(use-package projectile
  :init
  (projectile-mode +1)
  :config
  (setq projectile-project-search-path '("~/Projects/" "~/University/Current/"))
  (setq projectile-switch-project-action #'projectile-dired)
  (add-to-list 'projectile-ignored-projects "/opt/homebrew/")
  (add-to-list 'projectile-ignored-projects (expand-file-name user-emacs-directory)))

;; Completion with vertico
(use-package vertico
  :init
  (vertico-mode 1)
  :config
  (setq vertico-resize t
        vertico-cycle t
        vertico-count 15))

;; Save minibuffer history
(use-package savehist
  :init
  (savehist-mode))

;; Orderless completion and sorting
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion)))))

;; Rich annotations in the minibuffer
(use-package marginalia
  :after vertico
  :init
  (marginalia-mode))

;; In-buffer completion with corfu
(use-package corfu
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-quit-no-match 'separator)
  (corfu-auto-delay 0)
  (corfu-auto-prefix 1)
  (corfu-popupinfo-mode t)
  (corfu-popupinfo-delay 0)
  :bind
  (:map corfu-map
        ("S-RET" . (lambda () (interactive) (corfu-quit) (newline-and-indent)))
        ("S-<return>" . (lambda () (interactive) (corfu-quit) (newline-and-indent)))))

;; Nerd icons for corfu
(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)
  (add-to-list 'nerd-icons-corfu-mapping
               '(snippet :style "cod" :icon "insert" :face font-lock-constant-face)))

;; Completion extensions with cape
(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

;; Consult for enhanced searching
(use-package consult)

;; Custom function to toggle bookmarks for a file
(defun my/toggle-file-bookmark ()
  "Toggle a bookmark for the current file."
  (interactive)
  (require 'bookmark)
  (bookmark-maybe-load-default-file)
  (let ((curr-file (buffer-file-name)))
    (if (not curr-file)
        (message "Not visiting a file.")
      (let ((name (file-name-nondirectory curr-file)))
        (if (bookmark-get-bookmark name t)
            (progn
              (bookmark-delete name)
              (message "Deleted bookmark: %s" name))
          (save-excursion
            (goto-char (point-min))
            (bookmark-set name)
            (bookmark-set-filename name (expand-file-name curr-file))
            (message "Set bookmark: %s" name)))))))

;; -----------------------------------------------------------------------------
;; DEVELOPMENT TOOLS AND UTILITIES
;; -----------------------------------------------------------------------------

;; Modern terminal emulator
(use-package vterm
  :custom
  (vterm-max-scrollback 10000)
  (vterm-timer-delay 0.1)
  :config
  (add-hook 'vterm-mode-hook (lambda ()
                               (display-line-numbers-mode -1)
                               (evil-local-mode -1)))
  (evil-initial-state 'vterm-mode 'emacs)
  (with-eval-after-load 'vterm
    (define-key vterm-mode-map (kbd "<escape>") 'vterm-send-escape)))

;; Vterm-toggle for easy terminal toggling
(use-package vterm-toggle
  :after vterm
  :config
  (setq vterm-toggle-fullscreen-p nil)
  (add-to-list 'display-buffer-alist
               '((lambda (buffer-or-name _) 
                   (let ((buffer (get-buffer buffer-or-name)))
                     (with-current-buffer buffer
                       (or (equal major-mode 'vterm-mode)
                           (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (reusable-frames . visible)
                 (window-height . 0.3))))

;; Quickrun with modifications to run in vterm
(use-package quickrun
  :commands (quickrun)
  :init
  (defun my/quickrun-in-vterm (&optional _prefix)
    (interactive "P")
    (save-buffer)
    (require 'quickrun)
    (quickrun--set-executed-file)
    (let* ((orig    quickrun--executed-file)
           (beg     (if (use-region-p) (region-beginning) (point-min)))
           (end     (if (use-region-p) (region-end)        (point-max)))
           (cmdkey  (quickrun--command-key orig))
           (src     (if (quickrun--use-tempfile-p cmdkey)
                        (let ((dst (quickrun--temp-name (or orig ""))))
                          (quickrun--copy-region-to-tempfile beg end dst)
                          dst)
                      orig))
           (info    (quickrun--fill-templates cmdkey src))
           (exec    (gethash :exec info))
           (default-directory (or quickrun-option-default-directory
                                  default-directory))
           (buf     (if (get-buffer "*quickrun-vterm*")
                        (pop-to-buffer "*quickrun-vterm*")
                      (vterm "*quickrun-vterm*"))))
      (with-current-buffer buf
        (dolist (cmd (if (listp exec) exec (list exec))) 
          (vterm-send-string cmd)
          (vterm-send-return)))))

  (add-to-list 'display-buffer-alist
               '("^\*quickrun-vterm\*.*"
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (reusable-frames . visible)
                 (window-height . 0.3))))

;; Show git diffs in the gutter
(use-package diff-hl
  :init
  (global-diff-hl-mode)
  :config
  (diff-hl-flydiff-mode)
  (diff-hl-margin-mode)
  :hook
  (dired-mode . diff-hl-dired-mode)
  (magit-pre-refresh . diff-hl-magit-pre-refresh)
  (magit-post-refresh . diff-hl-magit-post-refresh))

;; Highlight TODO/FIXME comments
(use-package hl-todo
  :init
  (global-hl-todo-mode 1)
  :config
  (setq hl-todo-highlight-punctuation ":"
        hl-todo-keyword-faces
        '(("TODO"   . "#eb6f92")
          ("FIXME"  . "#f6c177")
          ("DEBUG"  . "#31748f")
          ("GOTCHA" . "#c4a7e7")
          ("NOTE"   . "#9ccfd8"))))

;; Treemacs file explorer
(use-package treemacs
  :defer t
  :hook (treemacs-mode . (lambda () (display-line-numbers-mode -1)))
  :config
  (setq treemacs-position 'right)
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode 'always)
  (treemacs-project-follow-mode t)
  (treemacs-hide-gitignored-files-mode nil))

;; Evil integration for treemacs
(use-package treemacs-evil
  :after (evil treemacs))

;; Projectile integration for treemacs
(use-package treemacs-projectile
  :after (treemacs projectile))

;; Nerd icons for treemacs
(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

;; Auto-format code on save
(use-package apheleia
  :init
  (apheleia-global-mode +1))

;; Automatically close matching parentheses, brackets, quotes, etc.
(use-package smartparens
  :init
  (smartparens-global-mode 1)
  :config
  (require 'smartparens-config)
  (show-paren-mode 1))

;; IRC Client
(use-package circe
  :hook (circe-chat-mode . (lambda ()
                             (display-line-numbers-mode -1)
                             (setq-local global-hl-line-mode nil)
                             (hl-line-mode -1)))
  :config
  (setq circe-network-options
        '(("Libera Chat"
           :tls t
           :nick "Glocean"
           :user "Glocean"
           :realname "Glass Ocean"
           :sasl-username "Glocean"
           :sasl-password (lambda (&rest _)
                            (funcall (plist-get (car (auth-source-search
                                                      :host "irc.libera.chat"
                                                      :user "Glocean"))
                                                :secret)))))))

;; -----------------------------------------------------------------------------
;; LANGUAGES AND CODING
;; -----------------------------------------------------------------------------

;; Tree-sitter for better syntax highlighting
(use-package tree-sitter
  :config
  (defun my/enable-tree-sitter-maybe ()
    (unless (derived-mode-p 'emacs-lisp-mode)
      (tree-sitter-mode)))
  :hook
  (prog-mode . my/enable-tree-sitter-maybe)
  (tree-sitter-after-on-hook . tree-sitter-hl-mode))

;; Language definitions for tree-sitter
(use-package tree-sitter-langs
  :after tree-sitter)

;; Hooks for specific languages
(add-hook 'java-mode-hook #'tree-sitter-mode)
(add-hook 'java-mode-hook #'tree-sitter-hl-mode)

;; Programming language snippets with yasnippet
(use-package yasnippet
  :config
  (setq yas-snippet-dirs (list (no-littering-expand-etc-file-name "yasnippet/snippets")))
  :init
  (yas-global-mode 1))

;; Pre-made yasnippet collections
(use-package yasnippet-snippets
  :after yasnippet)

;; Bridge between yasnippet and cape
(use-package yasnippet-capf
  :straight (:host github :repo "elken/yasnippet-capf")
  :after (yasnippet cape)
  :config
  (add-to-list 'completion-at-point-functions #'yasnippet-capf))

;; Spellcheck with linx
(use-package jinx
  :hook (emacs-startup . global-jinx-mode)
  :bind (("M-$" . jinx-correct)
         ("C-M-$" . jinx-languages))
  :config
  (add-to-list 'jinx-include-faces '(prog-mode font-lock-comment-face font-lock-string-face))
  (add-to-list 'jinx-exclude-faces '(prog-mode font-lock-constant-face font-lock-keyword-face font-lock-function-name-face font-lock-variable-name-face)))

;; Linting with flycheck
(use-package flycheck
  :init
  (global-flycheck-mode)
  :config
  (setq flycheck-global-modes '(not emacs-lisp-mode)))

;; Language server support
(use-package lsp-mode
  :hook (
         (java-mode . lsp-deferred)
         (lsp-mode  . lsp-enable-which-key-integration))
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-completion-provider :none)
  :config
  (setq lsp-idle-delay 0.5)
  (setq lsp-log-io nil)
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-modeline-code-action-fallback-icon (nerd-icons-codicon "nf-cod-lightbulb")))

;; Lsp-ui
(use-package lsp-ui
  :commands lsp-ui-mode
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-doc-enable t)
  (lsp-ui-doc-delay 0.5)
  (lsp-ui-doc-position 'at-point)
  (lsp-ui-sideline-show-diagnostics t)
  (lsp-ui-sideline-show-hover t)
  (lsp-ui-sideline-show-code-actions t))

;; Java support
(use-package lsp-java
  :after lsp-mode
  :init
  (add-hook 'java-mode-hook 'lsp-deferred))

;; Debugger
(use-package dap-mode
  :after lsp-mode
  :init
  (setq dap-ui-locals-expand-depth t)
  :config
  (dap-ui-mode 1)
  (dap-tooltip-mode 1)
  (tooltip-mode 1)
  (require 'dap-java)
  (setq dap-auto-configure-features '(sessions locals controls tooltip))

  ;; Override refresh to ensure locals stay expanded and view is reset to top
  (with-eval-after-load 'dap-ui
    (defun my/dap-ui-expand-all-nodes ()
      (goto-char (point-min))
      (while (forward-button 1 nil nil t)
        (let ((btn (button-at (point))))
          (when (and btn (treemacs-is-node-collapsed? btn))
            (treemacs-expand-extension-node 999)))))

    (defun my/dap-ui-scroll-locals-to-top ()
      (let ((win (get-buffer-window dap-ui--locals-buffer t)))
        (when win
          (with-selected-window win
            (goto-char (point-min))
            (set-window-start win (point-min))))))

    (defun dap-ui-locals--refresh (&rest _)
      (save-excursion
        (setq dap-ui--locals-timer nil)
        (lsp-treemacs-wcb-unless-killed dap-ui--locals-buffer
                                        (lsp-treemacs-generic-update (dap-ui-locals-get-data))
                                        (when (eq dap-ui-locals-expand-depth t)
                                          (my/dap-ui-expand-all-nodes))))
      (run-with-timer 0 nil #'my/dap-ui-scroll-locals-to-top))))

;; -----------------------------------------------------------------------------
;; ORG-MODE
;; -----------------------------------------------------------------------------

;; Main org configuration
(use-package org
  :hook (org-mode . org-indent-mode)
  :config
  (setq org-directory "~/University")
  (setq org-default-notes-file (concat org-directory "/notes.org"))
  (setq org-preview-latex-image-directory (expand-file-name "ltximg/" user-emacs-directory))

  ;; Use dvisvgm for high-quality SVG previews
  (setq org-preview-latex-default-process 'dvisvgm)
  
  ;; This function updates the agenda list by finding all .org files in Current
  (defun my/update-agenda-files ()
    (interactive)
    (when (file-directory-p "~/University/Current")
      (setq org-agenda-files (directory-files-recursively "~/University/Current" "\\.org$"))))
  
  ;; Update agenda files on startup
  (my/update-agenda-files)

  ;; Modern appearance settings
  (setq org-ellipsis ""
        org-hide-emphasis-markers t
        org-pretty-entities t
        org-startup-with-latex-preview nil
        org-auto-align-tags nil
        org-tags-column 0
        org-catch-invisible-edits 'show-and-error
        org-insert-heading-respect-content t)

  ;; Manual Latex preview for daemon compatibility
  (defun my/org-enable-latex-preview ()
    "Enable latex preview if in a graphical environment."
    (when (display-graphic-p)
      (org-latex-preview '(16))))

  (add-hook 'org-mode-hook #'my/org-enable-latex-preview)

  (add-hook 'server-after-make-frame-hook
            (lambda ()
              (dolist (buf (buffer-list))
                (with-current-buffer buf
                  (when (eq major-mode 'org-mode)
                    (org-latex-preview '(16)))))))

  ;; TODOs and Logging
  (setq org-todo-keywords
        '((sequence "TODO(t)" "PROJ(p)" "WAIT(w)" "|" "DONE(d)" "CANCELLED(c)")))
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)

  ;; Agenda styling
  (setq org-agenda-start-with-log-mode t)
  (setq org-agenda-tags-column 0)
  (setq org-agenda-block-separator ?─)
  (setq org-agenda-time-grid
        '((daily today require-timed)
          (800 1000 1200 1400 1600 1800 2000)
          " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"))
  (setq org-agenda-current-time-string
        "◄ NOW ─────────────────────────────────────────────────"))

;; Automatically continue lists with when pressing RET
(use-package org-autolist
  :after org
  :hook (org-mode . org-autolist-mode))

;; Automatically toggle org-mode latex previews
(use-package org-fragtog
  :after org
  :hook (org-mode . org-fragtog-mode))

;; Toggle emphasis markers when the cursor is over them
(use-package org-appear
  :after org
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autoemphasis t
        org-appear-autosubmarkers t
        org-appear-autolinks t))

;; Modern look for org-mode
(use-package org-modern
  :after org
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :config
  (setq org-modern-star '("◉" "○" "◈" "◇" "✳"))
  (setq org-modern-table-vertical 1)
  (setq org-modern-table-horizontal 0.2)
  (setq org-modern-todo-faces
        '(("WAIT" :background "#6e6a86" :foreground "#e0def4")
          ("PROJ" :background "#c4a7e7" :foreground "#191724"))))

;; Center the content for a better reading experience
(use-package visual-fill-column
  :hook ((org-mode . visual-fill-column-mode)
         (circe-chat-mode . visual-fill-column-mode))
  :config
  (setq-default visual-fill-column-width 100
                visual-fill-column-center-text t))

;; Enable visual line mode and disable line numbers for org mode
(add-hook 'org-mode-hook (lambda ()
                           (display-line-numbers-mode -1)
                           (setq-local global-hl-line-mode nil)
                           (hl-line-mode -1)))
;; -----------------------------------------------------------------------------
;; KEYBINDINGS
;; -----------------------------------------------------------------------------

;; macOS specific bindings
(when (string-equal system-type "darwin")

  (general-define-key
   :keymaps 'global
   "s-`" #'other-frame
   "s-w" #'delete-window
   "s-W" #'delete-frame
   "s-n" #'make-frame
   "s-l" #'goto-line
   "s-q" (if (daemonp) #'delete-frame #'save-buffers-kill-terminal)
   "s-s" #'save-buffer
   "s-a" #'mark-whole-buffer
   "s-z" #'undo))

;; Evil normal mode binds
(general-define-key
 :states 'normal
 "gcc" #'evilnc-comment-or-uncomment-lines
 "gc"  #'evilnc-comment-operator
 "K"   #'jinx-correct)

;; Evil visual mode binds
(general-define-key
 :states 'visual
 "gc" #'evilnc-comment-or-uncomment-lines)

;; Leader key definition
(general-create-definer my-leader-def
  :prefix "SPC"
  :states '(normal visual motion)
  :keymaps 'override)

;; Leader keybindings
(my-leader-def
  "SPC" '(consult-buffer :which-key "Switch Buffer")
  "."   '(find-file :which-key "Find File")
  "r"   '(my/quickrun-in-vterm :which-key "Run Code")
  "e"   '(treemacs :which-key "File Explorer")
  "k"   '(jinx-correct :which-key "Correct Word")

  ;; Buffer Management
  "b"   '(:ignore t :which-key "Buffer")
  "bb"  '(consult-buffer :which-key "Switch Buffer")
  "bm"  '(consult-bookmark :which-key "Jump to Bookmark")
  "bk"  '(kill-current-buffer :which-key "Kill Buffer")
  "bn"  '(next-buffer :which-key "Next Buffer")
  "bp"  '(previous-buffer :which-key "Prev Buffer")
  "be"  '(eval-buffer :which-key "Eval Buffer")
  "bK"  '(kill-buffer-and-window :which-key "Kill Buffer & Window")

  ;; Window Management
  "w"   '(:ignore t :which-key "Window")
  "wh"  '(evil-window-left :which-key "Left")
  "wj"  '(evil-window-down :which-key "Down")
  "wk"  '(evil-window-up :which-key "Up")
  "wl"  '(evil-window-right :which-key "Right")
  "wv"  '(evil-window-vsplit :which-key "Split Vertical")
  "ws"  '(evil-window-split :which-key "Split Horizontal")
  "ww"  '(other-window :which-key "Cycle Window")
  "wc"  '(evil-window-delete :which-key "Close Window")
  "wo"  '(delete-other-windows :which-key "Close Others")
  "we"  '(balance-windows :which-key "Equalize Windows")

  ;; File Management
  "f"   '(:ignore t :which-key "Files")
  "ff"  '(find-file :which-key "Find File")
  "fr"  '(consult-recent-file :which-key "Recent Files")
  "fs"  '(save-buffer :which-key "Save File")
  "fd"  '(delete-file :which-key "Delete File")
  "fp"  '((lambda () (interactive) (find-file (expand-file-name "init.el" user-emacs-directory))) :which-key "Open Config")

  ;; Toggle
  "t"   '(:ignore t :which-key "Toggle")
  "tb"  '(my/toggle-file-bookmark :which-key "Toggle File Bookmark")
  "tt"  '(vterm-toggle-cd :which-key "Toggle VTerm")
  "te"  '(treemacs :which-key "File Explorer")
  "tl"  '(display-line-numbers-mode :which-key "Toggle Line Numbers")

  ;; Projectile
  "p"   '(:ignore t :which-key "Project")
  "pa"  '(projectile-add-known-project :which-key "Add New Project")
  "pf"  '(projectile-find-file :which-key "Find File")
  "pp"  '(projectile-switch-project :which-key "Switch Project")
  "pr"  '(projectile-recentf :which-key "Recent Project Files")
  "pk"  '(projectile-kill-buffers :which-key "Kill Project Buffers")

  ;; Org-mode
  "o"   '(:ignore t :which-key "Org-mode")
  "oa"  '(org-agenda-list :which-key "Weekly Agenda")
  "oc"  '(org-capture :which-key "Capture Task")
  "ol"  '(org-store-link :which-key "Store Link")
  "ot"  '(org-todo-list :which-key "Global TODOs")
  "on"  '((lambda () (interactive) (find-file (concat org-directory "/notes.org"))) :which-key "Open Notes")
  "oC"  '((lambda () (interactive) (find-file "~/University/Current/")) :which-key "Browse Classes")

  ;; Code/LSP
  "c"   '(:ignore t :which-key "Code")
  "ca"  '(lsp-execute-code-action :which-key "Code Actions")
  "cd"  '(lsp-find-definition :which-key "Jump to Definition")
  "cr"  '(lsp-rename :which-key "Rename Variable")
  "cf"  '(lsp-format-buffer :which-key "Format Buffer")
  "cQ"  '(lsp-workspace-restart :which-key "Restart LSP Server")

  ;; Debugger
  "d"   '(:ignore t :which-key "Debug")
  "dd"  '(dap-debug :which-key "Start Debugging")
  "db"  '(dap-breakpoint-toggle :which-key "Toggle Breakpoint")
  "dr"  '(dap-debug-restart :which-key "Restart")
  "dq"  '(dap-disconnect :which-key "Quit Debugger")
  "dn"  '(dap-next :which-key "Next Line")
  "di"  '(dap-step-in :which-key "Step In")
  "do"  '(dap-step-out :which-key "Step Out")
  "dK"  '(dap-ui-repl :which-key "REPL"))

;; -----------------------------------------------------------------------------
;; FACE CHANGES
;; -----------------------------------------------------------------------------

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :extend nil :stipple nil :background "#191724" :foreground "#e0def4" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight regular :height 140 :width normal :foundry "nil" :family "JetBrainsMono Nerd Font"))))
 '(breakpoint-disabled ((t (:foreground "#eb6f92"))))
 '(button ((t (:foreground "#c4a7e7"))))
 '(comint-highlight-prompt ((t (:background "#191724" :foreground "#c4a7e7"))))
 '(corfu-bar ((t (:background "#c4a7e7"))))
 '(corfu-border ((t (:background "#524f67"))))
 '(cursor ((t (:background "#e0def4" :foreground "#191724"))))
 '(dap-ui-breakpoint-verified-fringe ((t (:foreground "#31748f" :weight bold))))
 '(diff-added ((t (:extend t :background "#191724" :foreground "#9ccfd8"))))
 '(diff-hl-change ((t (:background "#191724" :foreground "#ebbcba"))))
 '(diff-hl-delete ((t (:inherit diff-removed :background "#191724" :foreground "#eb6f92"))))
 '(diff-hl-dired-ignored ((t (:inherit dired-ignored :background "#191724" :foreground "#6e6a86"))))
 '(diff-hl-dired-unknown ((t (:inherit dired-ignored :background "#191724" :foreground "#6e6a86"))))
 '(diff-hl-insert ((t (:inherit diff-added :foreground "#9ccfd8"))))
 '(dired-ignored ((t (:background "#191724" :foreground "#6e6a86"))))
 '(doom-modeline-bar ((t (:background "#c4a7e7"))))
 '(doom-modeline-debug-visual ((t (:inherit doom-modeline :foreground "#eb6f92"))))
 '(doom-modeline-highlight ((t (:inherit mode-line-highlight :foreground "#191724"))))
 '(evil-goggles--pulse-face ((t (:background "#eb6f92" :foreground "#191724"))) t)
 '(evil-goggles-change-face ((t (:background "#f6c177" :foreground "#191724"))))
 '(evil-goggles-delete-face ((t (:background "#eb6f92" :foreground "#191724"))))
 '(evil-goggles-nerd-commenter-face ((t (:background "#ebbcba" :foreground "#191724"))))
 '(evil-goggles-paste-face ((t (:background "#9ccfd8" :foreground "#191724"))))
 '(evil-goggles-yank-face ((t (:background "#c4a7e7" :foreground "#191724"))))
 '(font-lock-comment-face ((t (:foreground "#908caa"))))
 '(highlight ((t (:background "#403d52" :foreground "#e0def4"))))
 '(highlight-indent-guides-character-face ((t (:background "#191724" :foreground "#403d52"))))
 '(highlight-indent-guides-top-character-face ((t (:background "#191724" :foreground "#908caa"))))
 '(line-number-current-line ((t (:inherit default :background "#191724" :foreground "#c4a7e7" :weight bold))))
 '(mode-line ((t (:background "#1f1d2e" :foreground "#6e6a86"))))
 '(mode-line-active ((t (:background "#1f1d2e" :foreground "#6e6a86"))))
 '(mode-line-buffer-id ((t (:foreground "#c4a7e7" :weight bold))))
 '(mode-line-highlight ((t (:background "#c4a7e7" :foreground "#1f1d2e"))))
 '(mouse-drag-and-drop-region ((t (:inherit region :background "#403d52" :foreground "#e0def4"))))
 '(org-level-1 ((t (:inherit outline-1 :extend nil :foreground "#c4a7e7"))))
 '(org-level-2 ((t (:inherit outline-2 :extend nil :foreground "#ebbcba"))))
 '(org-level-3 ((t (:inherit outline-3 :extend nil :foreground "#9ccfd8"))))
 '(org-level-4 ((t (:extend nil :foreground "#31748f"))))
 '(org-level-6 ((t (:inherit outline-6 :extend nil :foreground "#f6c177"))))
 '(org-level-7 ((t (:inherit outline-7 :extend nil :foreground "#908caa"))))
 '(org-level-8 ((t (:inherit outline-8 :extend nil :foreground "#524f67"))))
 '(region ((t (:extend t :background "#403d52" :foreground "#e0def4"))))
 '(show-paren-match ((t (:background "#26233a" :foreground "#eb6f92" :weight bold))))
 '(sp-pair-overlay-face ((t (:inherit highlight :background "#26233a"))))
 '(term-color-black ((t (:inherit ansi-color-black :background "#25233a" :foreground "#25233a"))))
 '(treemacs-file-face ((t (:foreground "#908caa"))))
 '(treemacs-fringe-indicator-face ((t (:foreground "#c4a7e7"))))
 '(treemacs-nerd-icons-file-face ((t (:foreground "#6e6a86"))))
 '(treemacs-nerd-icons-root-face ((t (:inherit nerd-icons-dorange :foreground "#c4a7e7"))))
 '(treemacs-root-face ((t (:inherit font-lock-constant-face :foreground "#c4a7e7" :underline t :weight bold :height 1.2))))
 '(vterm-color-black ((t (:background "#26233a" :foreground "#26233a"))))
 '(vterm-color-blue ((t (:background "#9ccfd8" :foreground "#9ccfd8"))))
 '(vterm-color-bright-black ((t (:background "#6e6a86" :foreground "#6e6a86"))))
 '(vterm-color-bright-blue ((t (:background "#9ccfd8" :foreground "#9ccfd8"))))
 '(vterm-color-bright-cyan ((t (:background "#ebbcba" :foreground "#ebbcba"))))
 '(vterm-color-bright-green ((t (:background "#31748f" :foreground "#31748f"))))
 '(vterm-color-bright-magenta ((t (:background "#c4a7e7" :foreground "#c4a7e7"))))
 '(vterm-color-bright-red ((t (:background "#eb6f92" :foreground "#eb6f92"))))
 '(vterm-color-bright-white ((t (:background "#e0def4" :foreground "#e0def4"))))
 '(vterm-color-bright-yellow ((t (:background "#f6c177" :foreground "#f6c177"))))
 '(vterm-color-cyan ((t (:background "#ebbcba" :foreground "#ebbcba"))))
 '(vterm-color-green ((t (:background "#31748f" :foreground "#31748f"))))
 '(vterm-color-magenta ((t (:background "#c4a7e7" :foreground "#c4a7e7"))))
 '(vterm-color-red ((t (:background "#eb6f92" :foreground "#eb6f92"))))
 '(vterm-color-white ((t (:background "#e0def4" :foreground "#e0def4"))))
 '(vterm-color-yellow ((t (:background "#f6c177" :foreground "#f6c177"))))
 '(widget-button-pressed ((t (:foreground "#6e6a86")))))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
