;; -*- lexical-binding: t; -*-

;; --- early-init.el ---
;; Runs before emacs starts up, used for disabling UI elements and improving startup times.

;; Disable unnecessary UI elements.
(setq inhibit-startup-screen t)
(add-to-list 'default-frame-alist '(undecorated-round . t))
(push '(vertical-scroll-bars) default-frame-alist)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(tooltip-mode -1)

;; Improve startup performance by adjusting garbage collection thresholds.
(setq gc-cons-threshold 100000000
      gc-cons-percentage 0.6)
(setq read-process-output-max (* 1024 1024))

;; Redirect native-compilation cache to var/eln-cache.
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (expand-file-name "var/eln-cache/" user-emacs-directory)))

;; Allow frame resizing to be pixelwise.
(setq frame-resize-pixelwise t)
