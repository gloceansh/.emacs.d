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
(setq straight-check-for-modifications '(not-at-startup))

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

;; Autothemer, dependency for the rose pine theme
(use-package autothemer)

;; Old theme (konrad1977/pinerose-emacs) — replaced, no dawn variant and required too many overrides
;; (use-package rose-pine-theme
;;   :straight (rose-pine-theme :type git :host github :repo "konrad1977/pinerose-emacs")
;;   :config
;;   (load-theme 'rose-pine t))

;; Rose Pine theme — thongpv87/rose-pine-emacs, all three variants, comprehensive face coverage
;; Dark: rose-pine-color  Moon: rose-pine-moon  Light: rose-pine-dawn
(use-package rose-pine-color-theme
  :straight (rose-pine-color-theme :type git :host github :repo "thongpv87/rose-pine-emacs"
                                   :files ("*.el")))

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
  :hook ((prog-mode . highlight-indent-guides-mode)
         (prog-mode . (lambda () (setq-local line-spacing 0.18)))) ; increase line height
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
  (setq projectile-project-search-path '("~/Projects/"))
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
        ("TAB" . nil)
        ("[tab]" . nil)
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
  (show-paren-mode 1)
  (sp-local-pair 'org-mode "$" "$"))

;; IRC Client
(use-package erc
  :custom
  (erc-server "irc.libera.chat")
  (erc-nick "Glocean")
  (erc-user-full-name "Glass Ocean")
  (erc-track-shorten-start 8)
  (erc-kill-buffer-on-part t)
  (erc-auto-query 'bury)
  (erc-fill-column 100)
  (erc-fill-function 'erc-fill-static)
  (erc-fill-static-center 20)
  (erc-header-line-format "%n on %t (%m)")
  (erc-hide-list '("JOIN" "PART" "QUIT"))
  :config
  (add-to-list 'erc-modules 'spelling)
  (add-to-list 'erc-modules 'scrolltobottom)
  (erc-update-modules)
  
  (evil-set-initial-state 'erc-mode 'emacs)

  (add-hook 'erc-mode-hook (lambda ()
                             (display-line-numbers-mode -1)
                             (setq-local global-hl-line-mode nil)
                             (hl-line-mode -1)
                             (visual-fill-column-mode))))

(use-package erc-hl-nicks
  :after erc
  :config
  (erc-hl-nicks-mode 1))

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

;; AI assistant with gptel
(use-package gptel
  :config
  (setq-default gptel-model 'gpt-5-mini)
  (setq-default gptel-backend
                (gptel-make-gh-copilot "Copilot"))
  (add-to-list 'gptel-directives
               '(notes . "You are an Org-mode note-autocomplete assistant for Emacs. When given an org buffer context and the current heading, produce only the org-mode text that should be inserted at the cursor (no explanation or meta commentary). Follow these rules:

- Match the user's existing voice, tone, sentence length, and structure by analyzing surrounding headings and previous notes in the buffer; mimic formatting choices (bullet style, checkbox style, timestamp style, code-block style, TODO keywords, tags, LaTeX code).
- Keep output valid org-mode syntax (lists, checkboxes [ ] or [-], property drawers, timestamps <...>, SCHEDULED/DEADLINE lines, src blocks).
- DO NOT generate any Org-mode headings (lines starting with asterisks like *, **, ***). Only produce the body content that should go under the current heading.
- When writing math, use inline LaTeX $...$ instead of the unicode math characters, and math blocks $$ ... $$ for equations, definitions, etc.
- When writing code, use the proper emacs org mode code block structe, and include the language next to #+BEGIN_SRC for proper syntax highlighting.
- Do not change existing text outside what you output.
- Keep content tightly focused on the meaning/intent of the current heading and its parent/project context. If the heading is a TODO or action, include a clear next action line and optional small checklist if appropriate.
- Prefer concise, actionable lines. Default to producing 3–12 lines unless the context shows longer notes are typical.
- When facts are missing, use inline placeholders like <TODO: specify>, <DATE?>, or <who?> rather than inventing specifics.
- Output must be plain org text only (what to insert). Never add surrounding explanation, JSON wrappers, or commentary.")))

;; GitHub Copilot 
(use-package copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . copilot-accept-completion)
              ("TAB" . copilot-accept-completion)
              ("C-TAB" . copilot-accept-completion-by-word)
              ("C-<tab>" . copilot-accept-completion-by-word))
  :config
  (setq copilot-indent-offset-alist '((prog-mode . 4) (emacs-lisp-mode . 2)))
  (setq copilot-indent-offset-warning-disable t))

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
  :hook ((org-mode . org-indent-mode)
         (org-mode . (lambda () (electric-indent-local-mode -1))))
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (java . t)))

  (setq org-adapt-indentation nil)
  (setq org-directory "~/org")
  (setq org-default-notes-file (expand-file-name "agenda/inbox.org" org-directory))
  (setq org-capture-bookmark nil)
  (setq org-preview-latex-image-directory
        (expand-file-name "ltximg/" user-emacs-directory))

  (setq org-agenda-files (list (expand-file-name "agenda" org-directory)))

  ;; Modern appearance settings
  (setq org-ellipsis ""
        org-cycle-hide-drawer-startup nil
        org-hide-emphasis-markers t
        org-pretty-entities nil
        org-use-sub-superscripts nil
        org-startup-with-latex-preview nil
        org-auto-align-tags nil
        org-tags-column 0
        org-catch-invisible-edits 'show-and-error
        org-insert-heading-respect-content t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 0
        org-src-preserve-indentation t)

  (setq org-preview-latex-default-process 'dvisvgm)

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
        "◄ NOW ─────────────────────────────────────────────────")

  ;; Force Org Agenda to the right
  (setq org-agenda-window-setup 'current-window)
  (add-to-list 'display-buffer-alist
               '("\\*Org Agenda\\*"
                 (display-buffer-in-side-window)
                 (side . right)
                 (slot . 0)
                 (window-width . 0.4)
                 (preserve-size . (t . nil))
                 (window-parameters . ((no-delete-other-windows . t)))))

  (setq org-capture-templates
        '(("i" "Inbox" entry
           (file (lambda () (expand-file-name "agenda/inbox.org" org-directory)))
           "* TODO %?\n%U\n"
           :empty-lines 1)

          ("s" "Schedule" entry
           (file (lambda () (expand-file-name "agenda/schedule.org" org-directory)))
           "* %^{Title}\n%^t\n%?"
           :empty-lines 1)

          ("e" "Event" entry
           (file (lambda () (expand-file-name "agenda/events.org" org-directory)))
           "* %^{Event}\n%^t\n%?"
           :empty-lines 1)

          ("h" "Homework" entry
           (file (lambda () (expand-file-name "agenda/events.org" org-directory)))
           "* TODO %^{Course} - %^{Assignment}\nDEADLINE: %^t\n:PROPERTIES:\n:TYPE: %^{Type|Homework|Quiz|Exam|Project}\n:END:\n\n%?"
           :empty-lines 1))))

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
  (setq org-modern-block-fringe nil)
  (setq org-modern-todo-faces
        '(("WAIT" :background "#6e6a86" :foreground "#e0def4")
          ("PROJ" :background "#c4a7e7" :foreground "#191724"))))

;; Center the content for a better reading experience
(use-package visual-fill-column
  :hook ((org-mode . visual-fill-column-mode))
  :config
  (setq-default visual-fill-column-width 100
                visual-fill-column-center-text t))

;; Powerful LaTeX editing environment
(use-package auctex
  :defer t
  :config
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)
  (setq TeX-master nil))

;; Fast LaTeX math entry
(use-package cdlatex
  :hook ((org-mode . turn-on-org-cdlatex)
         (LaTeX-mode . turn-on-cdlatex))
  :config
  (add-to-list 'cdlatex-command-alist
               '("lim" "Limit n to infinity"
                 "\\lim\\limits_{n \\to \\infty} ?"
                 cdlatex-position-cursor nil nil t))
  (add-to-list 'cdlatex-command-alist
               '("neglim" "Limit n to minus infinity"
                 "\\lim\\limits_{n \\to -\\infty} ?"
                 cdlatex-position-cursor nil nil t))
  (add-to-list 'cdlatex-command-alist
               '("funclim" "Function limit"
                 "\\lim\\limits_{x \\to ?}"
                 cdlatex-position-cursor nil nil t)))

;; Org-roam for atomic notes
(use-package org-roam
  :after org
  :custom
  (org-roam-directory (expand-file-name "roam" org-directory))
  (org-roam-dailies-directory "daily/")
  (org-roam-completion-everywhere t)
  :config
  (org-roam-db-autosync-mode)

  (setq org-roam-node-display-template
        (concat "${title:*} "
                (propertize "${tags:30}" 'face 'org-tag)))

  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags:\n\n")
           :unnarrowed t)
          ("u" "uni" plain "%?"
           :target (file+head "uni/${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :uni:\n\n")
           :unnarrowed t)
          ("l" "lecture" plain
           "* meta\n:PROPERTIES:\n:course:   %^{Course Code}\n:lecture:  %^{Lecture Number}\n:slides:   [[file:%^{Slides Path}][  Slides]]\n:END:\n\n* notes\n%?"
           :target (file+head "uni/${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :uni:lecture:\n\n")
           :unnarrowed t)
          ("h" "homelab" plain "%?"
           :target (file+head "homelab/${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :homelab:\n\n")
           :unnarrowed t)
          ("m" "music" plain "%?"
           :target (file+head "music/${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :music:\n\n")
           :unnarrowed t)
          ("p" "personal" plain "%?"
           :target (file+head "personal/${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :personal:\n\n")
           :unnarrowed t)))

  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry "* %<%H:%M>  %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%A, %d %B %Y>\n#+filetags: :daily:\n\n")))))

;; Graph UI — opens in browser
(use-package org-roam-ui
  :after org-roam
  :custom
  (org-roam-ui-sync-theme t)
  (org-roam-ui-follow t)
  (org-roam-ui-update-on-save t)
  (org-roam-ui-open-on-start nil))

;; Enable visual line mode and disable line numbers for org mode
(add-hook 'org-mode-hook (lambda ()
                           (display-line-numbers-mode -1)
                           (setq-local global-hl-line-mode nil)
                           (hl-line-mode -1)
                           (setq-local line-spacing 0.18))) ; increase line height

;; Super secret project
;; (add-to-list 'load-path "/Users/glocean/Projects/org-typst-preview")
;; (require 'org-typst-preview)

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

  ;; Apps
  "a"   '(:ignore t :which-key "Apps")
  "ae"  '((lambda () (interactive) (erc-tls :server "irc.libera.chat" :port 6697 :nick "Glocean")) :which-key "ERC (Libera)")

  ;; Buffer Management
  "b"   '(:ignore t :which-key "Buffer")
  "bb"  '(consult-buffer :which-key "Switch Buffer")
  "bm"  '(consult-bookmark :which-key "Jump to Bookmark")
  "bd"  '(bookmark-delete :which-key "Delete Bookmark")
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
  "oi"  '((lambda () (interactive) (find-file (expand-file-name "agenda/inbox.org" org-directory))) :which-key "Inbox")
  "os"  '((lambda () (interactive) (find-file (expand-file-name "agenda/schedule.org" org-directory))) :which-key "Schedule")

  ;; Org-roam bindings
  "or"  '(:ignore t :which-key "Roam")
  "orf" '(org-roam-node-find :which-key "Find/Create Note")
  "ori" '(org-roam-node-insert :which-key "Insert Link")
  "orc" '(org-roam-capture :which-key "Capture Note")
  "ord" '(org-roam-dailies-goto-today :which-key "Today's Journal")
  "orD" '(org-roam-dailies-goto-date :which-key "Journal by Date")
  "org" '(org-roam-ui-open :which-key "Graph View")
  "orb" '(org-roam-buffer-toggle :which-key "Backlinks Buffer")

  ;; Code/LSP
  "c"   '(:ignore t :which-key "Code")
  "ca"  '(lsp-execute-code-action :which-key "Code Actions")
  "cd"  '(lsp-find-definition :which-key "Jump to Definition")
  "cr"  '(lsp-rename :which-key "Rename Variable")
  "cf"  '(lsp-format-buffer :which-key "Format Buffer")
  "cQ"  '(lsp-workspace-restart :which-key "Restart LSP Server")

  ;; GPTel
  "g"   '(:ignore t :which-key "GPTel")
  "gg"  '(gptel-send :which-key "Send")
  "gc"  '(gptel :which-key "Chat")
  "gr"  '(gptel-rewrite :which-key "Rewrite")
  "gm"  '(gptel-menu :which-key "Menu")

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
;; THEME SWITCHING — Rose Pine (dark) / Rose Pine Dawn (light)
;; Follows macOS system appearance automatically via ns-system-appearance-change-functions
;; -----------------------------------------------------------------------------

;; Safely set a face — skips faces that haven't been defined yet (package not loaded)
(defun my/safe-set-face (face _frame &rest args)
  (when (facep face)
    (apply #'set-face-attribute face nil args)))

(defun my/apply-dark-faces ()
  (my/safe-set-face 'default nil
                      :background "#191724" :foreground "#e0def4"
                      :height 140 :family "JetBrainsMono Nerd Font")
  (my/safe-set-face 'breakpoint-disabled nil :foreground "#eb6f92")
  (my/safe-set-face 'button nil :foreground "#c4a7e7")
  (my/safe-set-face 'comint-highlight-prompt nil :background "#191724" :foreground "#c4a7e7")
  (my/safe-set-face 'copilot-overlay-face nil :background "#26233a")
  (my/safe-set-face 'corfu-bar nil :background "#c4a7e7")
  (my/safe-set-face 'corfu-border nil :background "#524f67")
  (my/safe-set-face 'cursor nil :background "#e0def4" :foreground "#191724")
  (my/safe-set-face 'dap-ui-breakpoint-verified-fringe nil :foreground "#31748f" :weight 'bold)
  (my/safe-set-face 'dashboard-banner-logo-title nil :weight 'thin :height 320)
  (my/safe-set-face 'dashboard-heading nil :weight 'thin :height 170)
  (my/safe-set-face 'nerd-icons-blue nil :foreground "#9ccfd8")
  (my/safe-set-face 'nerd-icons-blue-alt nil :foreground "#9ccfd8")
  (my/safe-set-face 'nerd-icons-cyan nil :foreground "#9ccfd8")
  (my/safe-set-face 'nerd-icons-cyan-alt nil :foreground "#9ccfd8")
  (my/safe-set-face 'nerd-icons-green nil :foreground "#31748f")
  (my/safe-set-face 'nerd-icons-green-alt nil :foreground "#9ccfd8")
  (my/safe-set-face 'nerd-icons-yellow nil :foreground "#f6c177")
  (my/safe-set-face 'nerd-icons-orange nil :foreground "#f6c177")
  (my/safe-set-face 'nerd-icons-orange-alt nil :foreground "#ebbcba")
  (my/safe-set-face 'nerd-icons-red nil :foreground "#eb6f92")
  (my/safe-set-face 'nerd-icons-red-alt nil :foreground "#eb6f92")
  (my/safe-set-face 'nerd-icons-pink nil :foreground "#eb6f92")
  (my/safe-set-face 'nerd-icons-purple nil :foreground "#c4a7e7")
  (my/safe-set-face 'nerd-icons-purple-alt nil :foreground "#c4a7e7")
  (my/safe-set-face 'nerd-icons-maroon nil :foreground "#eb6f92")
  (my/safe-set-face 'nerd-icons-silver nil :foreground "#908caa")
  (my/safe-set-face 'nerd-icons-dsilver nil :foreground "#6e6a86")
  (setq dashboard-startup-banner
        (expand-file-name "assets/xemacs_color_pine.svg" user-emacs-directory))
  (when (get-buffer "*dashboard*") (dashboard-refresh-buffer))
  (my/safe-set-face 'diff-added nil :extend t :background "#191724" :foreground "#9ccfd8")
  (my/safe-set-face 'diff-hl-change nil :background "#191724" :foreground "#ebbcba")
  (my/safe-set-face 'diff-hl-delete nil :background "#191724" :foreground "#eb6f92")
  (my/safe-set-face 'diff-hl-dired-ignored nil :background "#191724" :foreground "#6e6a86")
  (my/safe-set-face 'diff-hl-dired-unknown nil :background "#191724" :foreground "#6e6a86")
  (my/safe-set-face 'diff-hl-insert nil :foreground "#9ccfd8")
  (my/safe-set-face 'dired-ignored nil :background "#191724" :foreground "#6e6a86")
  (my/safe-set-face 'doom-modeline-bar nil :background "#c4a7e7")
  (my/safe-set-face 'doom-modeline-debug-visual nil :foreground "#eb6f92")
  (my/safe-set-face 'doom-modeline-highlight nil :foreground "#191724")
  (my/safe-set-face 'erc-direct-msg-face nil :foreground "#9ccfd8")
  (my/safe-set-face 'erc-input-face nil :foreground "#c4a7e7")
  (my/safe-set-face 'erc-my-nick-face nil :foreground "#c4a7e7" :weight 'bold)
  (my/safe-set-face 'erc-notice-face nil :foreground "#6e6a86" :weight 'semi-bold)
  (my/safe-set-face 'erc-prompt-face nil :foreground "#c4a7e7" :weight 'bold)
  (my/safe-set-face 'erc-timestamp-face nil :foreground "#f6c177" :weight 'bold)
  (my/safe-set-face 'evil-goggles--pulse-face nil :background "#eb6f92" :foreground "#191724")
  (my/safe-set-face 'evil-goggles-change-face nil :background "#f6c177" :foreground "#191724")
  (my/safe-set-face 'evil-goggles-delete-face nil :background "#eb6f92" :foreground "#191724")
  (my/safe-set-face 'evil-goggles-nerd-commenter-face nil :background "#ebbcba" :foreground "#191724")
  (my/safe-set-face 'evil-goggles-paste-face nil :background "#9ccfd8" :foreground "#191724")
  (my/safe-set-face 'evil-goggles-yank-face nil :background "#c4a7e7" :foreground "#191724")
  (my/safe-set-face 'font-lock-comment-face nil :foreground "#908caa")
  (my/safe-set-face 'gptel-context-deletion-face nil :extend t :background "#eb6f92")
  (my/safe-set-face 'gptel-context-highlight-face nil :extend t :background "#26233a")
  (my/safe-set-face 'gptel-response-highlight nil :background "#1f1d2e" :foreground "#e0def4")
  (my/safe-set-face 'gptel-rewrite-highlight-face nil :background "#403d52" :foreground "#9ccfd8")
  (my/safe-set-face 'highlight nil :background "#403d52" :foreground "#e0def4")
  (my/safe-set-face 'highlight-indent-guides-character-face nil :background "#191724" :foreground "#403d52")
  (my/safe-set-face 'highlight-indent-guides-top-character-face nil :background "#191724" :foreground "#908caa")
  (my/safe-set-face 'line-number-current-line nil :background "#191724" :foreground "#c4a7e7" :weight 'bold)
  (my/safe-set-face 'mode-line nil :background "#1f1d2e" :foreground "#6e6a86")
  (my/safe-set-face 'mode-line-active nil :background "#1f1d2e" :foreground "#6e6a86")
  (my/safe-set-face 'mode-line-buffer-id nil :foreground "#c4a7e7" :weight 'bold)
  (my/safe-set-face 'mode-line-highlight nil :background "#c4a7e7" :foreground "#1f1d2e")
  (my/safe-set-face 'mouse-drag-and-drop-region nil :background "#403d52" :foreground "#e0def4")
  (my/safe-set-face 'org-block nil :extend t :foreground "#e0def4")
  (my/safe-set-face 'org-level-1 nil :extend nil :foreground "#c4a7e7")
  (my/safe-set-face 'org-level-2 nil :extend nil :foreground "#ebbcba")
  (my/safe-set-face 'org-level-3 nil :extend nil :foreground "#9ccfd8")
  (my/safe-set-face 'org-level-4 nil :extend nil :foreground "#31748f")
  (my/safe-set-face 'org-level-6 nil :extend nil :foreground "#f6c177")
  (my/safe-set-face 'org-level-7 nil :extend nil :foreground "#908caa")
  (my/safe-set-face 'org-level-8 nil :extend nil :foreground "#524f67")
  (my/safe-set-face 'region nil :extend t :background "#403d52" :foreground "#e0def4")
  (my/safe-set-face 'show-paren-match nil :background "#26233a" :foreground "#eb6f92" :weight 'bold)
  (my/safe-set-face 'sp-pair-overlay-face nil :background "#26233a")
  (my/safe-set-face 'term-color-black nil :background "#25233a" :foreground "#25233a")
  (my/safe-set-face 'treemacs-file-face nil :foreground "#908caa")
  (my/safe-set-face 'treemacs-fringe-indicator-face nil :foreground "#c4a7e7")
  (my/safe-set-face 'treemacs-nerd-icons-file-face nil :foreground "#6e6a86")
  (my/safe-set-face 'treemacs-nerd-icons-root-face nil :foreground "#c4a7e7")
  (my/safe-set-face 'treemacs-root-face nil :foreground "#c4a7e7" :underline t :weight 'bold :height 1.2)
  (my/safe-set-face 'vterm-color-black nil :background "#26233a" :foreground "#26233a")
  (my/safe-set-face 'vterm-color-blue nil :background "#9ccfd8" :foreground "#9ccfd8")
  (my/safe-set-face 'vterm-color-bright-black nil :background "#6e6a86" :foreground "#6e6a86")
  (my/safe-set-face 'vterm-color-bright-blue nil :background "#9ccfd8" :foreground "#9ccfd8")
  (my/safe-set-face 'vterm-color-bright-cyan nil :background "#ebbcba" :foreground "#ebbcba")
  (my/safe-set-face 'vterm-color-bright-green nil :background "#31748f" :foreground "#31748f")
  (my/safe-set-face 'vterm-color-bright-magenta nil :background "#c4a7e7" :foreground "#c4a7e7")
  (my/safe-set-face 'vterm-color-bright-red nil :background "#eb6f92" :foreground "#eb6f92")
  (my/safe-set-face 'vterm-color-bright-white nil :background "#e0def4" :foreground "#e0def4")
  (my/safe-set-face 'vterm-color-bright-yellow nil :background "#f6c177" :foreground "#f6c177")
  (my/safe-set-face 'vterm-color-cyan nil :background "#ebbcba" :foreground "#ebbcba")
  (my/safe-set-face 'vterm-color-green nil :background "#31748f" :foreground "#31748f")
  (my/safe-set-face 'vterm-color-magenta nil :background "#c4a7e7" :foreground "#c4a7e7")
  (my/safe-set-face 'vterm-color-red nil :background "#eb6f92" :foreground "#eb6f92")
  (my/safe-set-face 'vterm-color-white nil :background "#e0def4" :foreground "#e0def4")
  (my/safe-set-face 'vterm-color-yellow nil :background "#f6c177" :foreground "#f6c177")
  (my/safe-set-face 'widget-button-pressed nil :foreground "#6e6a86")
  (setq hl-todo-keyword-faces
        '(("TODO"   . "#eb6f92")
          ("FIXME"  . "#f6c177")
          ("DEBUG"  . "#31748f")
          ("GOTCHA" . "#c4a7e7")
          ("NOTE"   . "#9ccfd8")))
  (setq org-modern-todo-faces
        '(("WAIT" :background "#6e6a86" :foreground "#e0def4")
          ("PROJ" :background "#c4a7e7" :foreground "#191724"))))

(defun my/apply-dawn-faces ()
  (my/safe-set-face 'default nil
                      :background "#faf4ed" :foreground "#575279"
                      :height 140 :family "JetBrainsMono Nerd Font")
  (my/safe-set-face 'breakpoint-disabled nil :foreground "#b4637a")
  (my/safe-set-face 'button nil :foreground "#907aa9")
  (my/safe-set-face 'comint-highlight-prompt nil :background "#faf4ed" :foreground "#907aa9")
  (my/safe-set-face 'copilot-overlay-face nil :background "#f2e9e1")
  (my/safe-set-face 'corfu-bar nil :background "#907aa9")
  (my/safe-set-face 'corfu-border nil :background "#cecacd")
  (my/safe-set-face 'cursor nil :background "#575279" :foreground "#faf4ed")
  (my/safe-set-face 'dap-ui-breakpoint-verified-fringe nil :foreground "#286983" :weight 'bold)
  (my/safe-set-face 'dashboard-banner-logo-title nil :weight 'thin :height 320)
  (my/safe-set-face 'dashboard-footer-face nil :foreground "#797593")
  (my/safe-set-face 'dashboard-heading nil :weight 'thin :height 170)
  (my/safe-set-face 'nerd-icons-blue nil :foreground "#286983")
  (my/safe-set-face 'nerd-icons-blue-alt nil :foreground "#56949f")
  (my/safe-set-face 'nerd-icons-cyan nil :foreground "#56949f")
  (my/safe-set-face 'nerd-icons-cyan-alt nil :foreground "#56949f")
  (my/safe-set-face 'nerd-icons-green nil :foreground "#286983")
  (my/safe-set-face 'nerd-icons-green-alt nil :foreground "#56949f")
  (my/safe-set-face 'nerd-icons-yellow nil :foreground "#ea9d34")
  (my/safe-set-face 'nerd-icons-orange nil :foreground "#ea9d34")
  (my/safe-set-face 'nerd-icons-orange-alt nil :foreground "#d7827e")
  (my/safe-set-face 'nerd-icons-red nil :foreground "#b4637a")
  (my/safe-set-face 'nerd-icons-red-alt nil :foreground "#b4637a")
  (my/safe-set-face 'nerd-icons-pink nil :foreground "#b4637a")
  (my/safe-set-face 'nerd-icons-purple nil :foreground "#907aa9")
  (my/safe-set-face 'nerd-icons-purple-alt nil :foreground "#907aa9")
  (my/safe-set-face 'nerd-icons-maroon nil :foreground "#b4637a")
  (my/safe-set-face 'nerd-icons-silver nil :foreground "#9893a5")
  (my/safe-set-face 'nerd-icons-dsilver nil :foreground "#797593")
  (setq dashboard-startup-banner
        (expand-file-name "assets/xemacs_color_pine_dawn.svg" user-emacs-directory))
  (when (get-buffer "*dashboard*") (dashboard-refresh-buffer))
  (my/safe-set-face 'diff-added nil :extend t :background "#faf4ed" :foreground "#56949f")
  (my/safe-set-face 'diff-hl-change nil :background "#faf4ed" :foreground "#d7827e")
  (my/safe-set-face 'diff-hl-delete nil :background "#faf4ed" :foreground "#b4637a")
  (my/safe-set-face 'diff-hl-dired-ignored nil :background "#faf4ed" :foreground "#9893a5")
  (my/safe-set-face 'diff-hl-dired-unknown nil :background "#faf4ed" :foreground "#9893a5")
  (my/safe-set-face 'diff-hl-insert nil :foreground "#56949f")
  (my/safe-set-face 'dired-ignored nil :background "#faf4ed" :foreground "#9893a5")
  (my/safe-set-face 'doom-modeline-bar nil :background "#907aa9")
  (my/safe-set-face 'doom-modeline-debug-visual nil :foreground "#b4637a")
  (my/safe-set-face 'doom-modeline-highlight nil :foreground "#faf4ed")
  (my/safe-set-face 'erc-direct-msg-face nil :foreground "#56949f")
  (my/safe-set-face 'erc-input-face nil :foreground "#907aa9")
  (my/safe-set-face 'erc-my-nick-face nil :foreground "#907aa9" :weight 'bold)
  (my/safe-set-face 'erc-notice-face nil :foreground "#9893a5" :weight 'semi-bold)
  (my/safe-set-face 'erc-prompt-face nil :foreground "#907aa9" :weight 'bold)
  (my/safe-set-face 'erc-timestamp-face nil :foreground "#ea9d34" :weight 'bold)
  (my/safe-set-face 'evil-goggles--pulse-face nil :background "#b4637a" :foreground "#faf4ed")
  (my/safe-set-face 'evil-goggles-change-face nil :background "#ea9d34" :foreground "#faf4ed")
  (my/safe-set-face 'evil-goggles-delete-face nil :background "#b4637a" :foreground "#faf4ed")
  (my/safe-set-face 'evil-goggles-nerd-commenter-face nil :background "#d7827e" :foreground "#faf4ed")
  (my/safe-set-face 'evil-goggles-paste-face nil :background "#56949f" :foreground "#faf4ed")
  (my/safe-set-face 'evil-goggles-yank-face nil :background "#907aa9" :foreground "#faf4ed")
  (my/safe-set-face 'font-lock-comment-face nil :foreground "#797593")
  (my/safe-set-face 'gptel-context-deletion-face nil :extend t :background "#b4637a")
  (my/safe-set-face 'gptel-context-highlight-face nil :extend t :background "#f2e9e1")
  (my/safe-set-face 'gptel-response-highlight nil :background "#fffaf3" :foreground "#575279")
  (my/safe-set-face 'gptel-rewrite-highlight-face nil :background "#dfdad9" :foreground "#56949f")
  (my/safe-set-face 'highlight nil :background "#dfdad9" :foreground "#575279")
  (my/safe-set-face 'highlight-indent-guides-character-face nil :background "#faf4ed" :foreground "#dfdad9")
  (my/safe-set-face 'highlight-indent-guides-top-character-face nil :background "#faf4ed" :foreground "#797593")
  (my/safe-set-face 'line-number-current-line nil :background "#faf4ed" :foreground "#907aa9" :weight 'bold)
  (my/safe-set-face 'mode-line nil :background "#fffaf3" :foreground "#9893a5")
  (my/safe-set-face 'mode-line-active nil :background "#fffaf3" :foreground "#9893a5")
  (my/safe-set-face 'mode-line-buffer-id nil :foreground "#907aa9" :weight 'bold)
  (my/safe-set-face 'mode-line-highlight nil :background "#907aa9" :foreground "#fffaf3")
  (my/safe-set-face 'mouse-drag-and-drop-region nil :background "#dfdad9" :foreground "#575279")
  (my/safe-set-face 'org-block nil :extend t :foreground "#575279")
  (my/safe-set-face 'org-level-1 nil :extend nil :foreground "#907aa9")
  (my/safe-set-face 'org-level-2 nil :extend nil :foreground "#d7827e")
  (my/safe-set-face 'org-level-3 nil :extend nil :foreground "#56949f")
  (my/safe-set-face 'org-level-4 nil :extend nil :foreground "#286983")
  (my/safe-set-face 'org-level-6 nil :extend nil :foreground "#ea9d34")
  (my/safe-set-face 'org-level-7 nil :extend nil :foreground "#797593")
  (my/safe-set-face 'org-level-8 nil :extend nil :foreground "#cecacd")
  (my/safe-set-face 'region nil :extend t :background "#dfdad9" :foreground "#575279")
  (my/safe-set-face 'show-paren-match nil :background "#f2e9e1" :foreground "#b4637a" :weight 'bold)
  (my/safe-set-face 'sp-pair-overlay-face nil :background "#f2e9e1")
  (my/safe-set-face 'term-color-black nil :background "#f2e9e1" :foreground "#f2e9e1")
  (my/safe-set-face 'treemacs-file-face nil :foreground "#797593")
  (my/safe-set-face 'treemacs-fringe-indicator-face nil :foreground "#907aa9")
  (my/safe-set-face 'treemacs-nerd-icons-file-face nil :foreground "#9893a5")
  (my/safe-set-face 'treemacs-nerd-icons-root-face nil :foreground "#907aa9")
  (my/safe-set-face 'treemacs-root-face nil :foreground "#907aa9" :underline t :weight 'bold :height 1.2)
  (my/safe-set-face 'vterm-color-black nil :background "#f2e9e1" :foreground "#f2e9e1")
  (my/safe-set-face 'vterm-color-blue nil :background "#56949f" :foreground "#56949f")
  (my/safe-set-face 'vterm-color-bright-black nil :background "#9893a5" :foreground "#9893a5")
  (my/safe-set-face 'vterm-color-bright-blue nil :background "#56949f" :foreground "#56949f")
  (my/safe-set-face 'vterm-color-bright-cyan nil :background "#d7827e" :foreground "#d7827e")
  (my/safe-set-face 'vterm-color-bright-green nil :background "#286983" :foreground "#286983")
  (my/safe-set-face 'vterm-color-bright-magenta nil :background "#907aa9" :foreground "#907aa9")
  (my/safe-set-face 'vterm-color-bright-red nil :background "#b4637a" :foreground "#b4637a")
  (my/safe-set-face 'vterm-color-bright-white nil :background "#575279" :foreground "#575279")
  (my/safe-set-face 'vterm-color-bright-yellow nil :background "#ea9d34" :foreground "#ea9d34")
  (my/safe-set-face 'vterm-color-cyan nil :background "#d7827e" :foreground "#d7827e")
  (my/safe-set-face 'vterm-color-green nil :background "#286983" :foreground "#286983")
  (my/safe-set-face 'vterm-color-magenta nil :background "#907aa9" :foreground "#907aa9")
  (my/safe-set-face 'vterm-color-red nil :background "#b4637a" :foreground "#b4637a")
  (my/safe-set-face 'vterm-color-white nil :background "#575279" :foreground "#575279")
  (my/safe-set-face 'vterm-color-yellow nil :background "#ea9d34" :foreground "#ea9d34")
  (my/safe-set-face 'widget-button-pressed nil :foreground "#9893a5")
  (setq hl-todo-keyword-faces
        '(("TODO"   . "#b4637a")
          ("FIXME"  . "#ea9d34")
          ("DEBUG"  . "#286983")
          ("GOTCHA" . "#907aa9")
          ("NOTE"   . "#56949f")))
  (setq org-modern-todo-faces
        '(("WAIT" :background "#9893a5" :foreground "#faf4ed")
          ("PROJ" :background "#907aa9" :foreground "#faf4ed"))))

(defun my/apply-theme (appearance)
  (mapc #'disable-theme custom-enabled-themes)
  (pcase appearance
    ('dark  (load-theme 'rose-pine-color t) (my/apply-dark-faces))
    ('light (load-theme 'rose-pine-dawn  t) (my/apply-dawn-faces))))

(add-hook 'ns-system-appearance-change-functions #'my/apply-theme)
(my/apply-theme (or (bound-and-true-p ns-system-appearance) 'dark))
