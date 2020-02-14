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

(straight-use-package 'use-package)
(setq straight-use-package-by-default 1)
(setq backup-directory-alist '(("" . "~/.emacs.d/backup")))
(setq auto-save-default nil)
(global-linum-mode 1)
(setq scroll-step 1)
(setq scroll-conservatively 10000)
(setq scroll-preserve-screen-position 1)
(electric-pair-mode 1)

;; Splash Screen
(setq inhibit-startup-screen t)
(setq initial-scratch-message ";; Go nuts")

;; Show matching parens
(setq show-paren-delay 0)
(show-paren-mode  1)

(eval-after-load 'smartparens
  '(progn
     (sp-pair "`" nil :actions :rem)))

(add-hook 'after-change-major-mode-hook
  (lambda ()
    (modify-syntax-entry ?_ "w")))

;; PATH
(let ((path (shell-command-to-string ". ~/.zshrc; echo -n $PATH")))
  (setenv "PATH" path)
  (setq exec-path 
        (append
         (split-string-and-unquote path ":")
         exec-path)))

;; Minimal UI
(scroll-bar-mode -1)
(tool-bar-mode   -1)
(tooltip-mode    -1)
(menu-bar-mode   -1)

;; Fancy titlebar for MacOS
(add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
(add-to-list 'default-frame-alist '(ns-appearance . dark))
(setq ns-use-proxy-icon  nil)
(setq frame-title-format nil)

;; Vim mode
(use-package evil
  :config
  (evil-mode 1))
(use-package evil-commentary
  :config
  (evil-commentary-mode))
(use-package evil-surround
  :config
  (global-evil-surround-mode 1))
(use-package evil-leader
  :config
  (global-evil-leader-mode))

;; Themes
(use-package doom-themes
  :config
  (setq doom-themes-enable-bold t
	doom-themes-enable-italic t)
  (load-theme 'doom-one t)
  (doom-themes-visual-bell-config)
  (doom-themes-neotree-config))
(use-package all-the-icons)

(set-face-attribute 'default nil
		    :family "JetBrains Mono" :height 140)

;; Ivy
(use-package flx)
(use-package counsel)
(use-package ivy
  :config
  (ivy-mode 1))
(setq ivy-re-builders-alist
      '((ivy-switch-buffer . ivy--regex-plus)
	(counsel-ag . ivy--regex-plus)
        (t . ivy--regex-fuzzy)))
(setq ivy-initial-inputs-alist nil)

;; Company
(use-package company
  :config
  (progn
    (add-hook 'after-init-hook 'global-company-mode)))

(setq company-dabbrev-downcase 0)
(setq company-idle-delay 0)

(define-key company-active-map (kbd "TAB") 'company-complete-common-or-cycle)
(define-key company-active-map (kbd "<tab>") 'company-complete-common-or-cycle)
(define-key company-active-map (kbd "S-TAB") 'company-select-previous)
(define-key company-active-map (kbd "<backtab>") 'company-select-previous)
(define-key company-mode-map [remap indent-for-tab-command] 'company-indent-for-tab-command)

;; Which key
(use-package which-key
  :init
  (setq which-key-separator " ")
  (setq which-key-prefix-prefix "+")
  :config
  (which-key-mode))

;; vterm
(use-package vterm)

;; magit
(use-package magit)
(use-package evil-magit)

;; Projectile
(use-package projectile
  :config
  (projectile-mode 1))
(use-package counsel-projectile
  :config
  (counsel-projectile-mode 1))

(setq projectile-completion-system 'ivy)

;; NeoTree
(use-package neotree)
(setq neo-smart-open t)
(setq projectile-switch-project-action 'neotree-projectile-action)

(defun neotree-project-dir ()
  "Open NeoTree using the git root."
  (interactive)
  (let ((project-dir (projectile-project-root))
	(file-name (buffer-file-name)))
    (neotree-toggle)
    (if project-dir
	(if (neo-global--window-exists-p)
	    (progn
	      (neotree-dir project-dir)
	      (neotree-find file-name)))
      (message "Could not find git project root."))))

(evil-define-key 'normal neotree-mode-map (kbd "q") 'neotree-hide)
(evil-define-key 'normal neotree-mode-map (kbd "RET") 'neotree-enter)
(evil-define-key 'normal neotree-mode-map (kbd "TAB") 'neotree-stretch-toggle)
(evil-define-key 'normal neotree-mode-map (kbd "l") 'neotree-enter)
(evil-define-key 'normal neotree-mode-map (kbd "g") 'neotree-refresh)
(evil-define-key 'normal neotree-mode-map (kbd "H") 'neotree-hidden-file-toggle)


;; Reason setup
(defun shell-cmd (cmd)
  "Returns the stdout output of a shell command or nil if the command returned
   an error"
  (car (ignore-errors (apply 'process-lines (split-string cmd)))))

(defun reason-cmd-where (cmd)
  (let ((where (shell-cmd cmd)))
    (if (not (string-equal "unknown flag ----where" where))
      where)))

(let* ((refmt-bin (or (reason-cmd-where "refmt ----where")
                      (shell-cmd "which refmt")
                      (shell-cmd "which bsrefmt")))
       (merlin-bin (or (reason-cmd-where "ocamlmerlin ----where")

                       (shell-cmd "which ocamlmerlin")))
       (merlin-base-dir (when merlin-bin
                          (replace-regexp-in-string "bin/ocamlmerlin$" "" merlin-bin))))
  ;; Add merlin.el to the emacs load path and tell emacs where to find ocamlmerlin
(when merlin-bin
  (add-to-list 'load-path (concat merlin-base-dir "share/emacs/site-lisp/"))
  (setq merlin-command merlin-bin))

(when refmt-bin
  (setq refmt-command refmt-bin)))

(use-package merlin)

(use-package reason-mode
  :config
  (add-hook 'reason-mode-hook (lambda ()
                              (add-hook 'before-save-hook 'refmt-before-save)
                              (merlin-mode))))

(use-package utop)

(setq utop-command "opam config exec -- rtop -emacs")
(add-hook 'reason-mode-hook #'utop-minor-mode) 
(setq merlin-completion-with-doc t)

;; JavaScript
(use-package js2-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
  (add-hook 'js2-mode-hook #'js2-imenu-extras-mode)
  )
(use-package prettier-js
  :init
  (add-hook 'js2-mode-hook 'prettier-js-mode))
(use-package xref-js2
  :config
  (add-hook 'js2-mode-hook (lambda ()
			     (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t))))
  (setq-default js2-basic-offset 2)

;; undo tree
(use-package undo-tree
  :config
  (global-undo-tree-mode 1))

;; dockerfile
(use-package dockerfile-mode
  :config
  (add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode)))

(use-package docker)

;; Rust and cargo
(use-package rust-mode)

(use-package lsp-mode
  :init (setq lsp-keymap-prefix "C-l")
  :hook (
         (rust-mode . lsp)
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)

(use-package cargo
  :config
  (add-hook 'rust-mode-hook 'cargo-minor-mode))

;; window management
(use-package winum
  :config
  (winum-mode 1))

;; Taken from spacemacs code
(defun alternate-buffer (&optional window)
  "Switch back and forth between current and last buffer in the
current window."
  (interactive)
  (let ((current-buffer (window-buffer window))
        (buffer-predicate
         (frame-parameter (window-frame window) 'buffer-predicate)))
    ;; switch to first buffer previously shown in this window that matches
    ;; frame-parameter `buffer-predicate'
    (switch-to-buffer
     (or (cl-find-if (lambda (buffer)
                       (and (not (eq buffer current-buffer))
                            (or (null buffer-predicate)
                                (funcall buffer-predicate buffer))))
                     (mapcar #'car (window-prev-buffers window)))
         ;; `other-buffer' honors `buffer-predicate' so no need to filter
         (other-buffer current-buffer t)))))

;; Git prepending
  (defun my-extract-branch-tag (branch-name)
    (let ((TICKET-PATTERN "\\(?:[[:alpha:]]+-\\)?\\([[:alpha:]]+-[[:digit:]]+\\)-.*"))
      (when (string-match-p TICKET-PATTERN branch-name)
        (s-upcase (replace-regexp-in-string TICKET-PATTERN "\\1 " branch-name)))))

  (defun my-git-commit-insert-branch ()
    (insert (my-extract-branch-tag (magit-get-current-branch))))

  (add-hook 'git-commit-setup-hook 'my-git-commit-insert-branch)

;; iedit
(use-package iedit)
(use-package evil-iedit-state)

;; Alt keybinding
(when (eq system-type 'darwin)
  (setq-default mac-option-modifier 'none))

;; Custom keybinding
(use-package general
  :config (general-define-key
  :states '(normal visual insert emacs)
  :prefix "SPC"
  :non-normal-prefix "M-SPC"
  "SPC" '(counsel-M-x :which-key "Show all commands")
  "TAB" '(alternate-buffer :which-key "Alternate buffer")
  "0" '(neotree-project-dir :which-key "Show Neotree")
  "1" '(winum-select-window-1 :which-key "Window 1")
  "2" '(winum-select-window-2 :which-key "Window 2")
  "3" '(winum-select-window-3 :which-key "Window 3")
  "4" '(winum-select-window-4 :which-key "Window 4")
  "5" '(winum-select-window-5 :which-key "Window 5")
  "6" '(winum-select-window-6 :which-key "Window 6")
  "7" '(winum-select-window-7 :which-key "Window 7")
  "8" '(winum-select-window-8 :which-key "Window 8")
  "9" '(winum-select-window-9 :which-key "Window 9")
  ;; Files
  "f" '(:ignore t :wk "Files")
  "fs" '(save-buffer :which-key "Save")
  "ff" '(find-file :which-key "Find file")
  ;; Buffers
  "b" '(:ignore t :wk "Buffers")
  "bd" '(evil-delete-buffer :which-key "Delete buffer")
  "bb" '(ivy-switch-buffer :which-key "Switch to buffer")
  "qq" '(evil-quit-all :which-key "Quit")
  ;; Magit
  "g" '(:ignore t :wk "Git")
  "gs" '(magit :which-key "Git status")
  ;; Misc
  "cl" '(evil-commentary-line :which-key "Comment line")
  "au" '(undo-tree-visualize :which-key "Undo tree")
  "fed" '((lambda () (interactive) (find-file "~/.dotfiles/emacs/init.el")) :which-key "Open emacs config")
  "fer" '((lambda () (interactive) (load-file "~/.dotfiles/emacs/init.el")) :which-key "Reload config")
  ;; Projectile
  "p" '(:keymap projectile-command-map :wk "Projectile")
  ;; Search
  "s" '(:ignore t :wk "Search")
  "sa" '(:ignore t :wk "Search projectile")
  "sap" '(counsel-ag :wk "Search in project")
  "sas" '(swiper :wk "Swiper")
  "se" '(evil-iedit-state/iedit-mode :wk "Edit buffer")
  "sc" '(iedit-quit :wk "Clear search buffer")
  ;; Windows
  "w" '(:ignore t :wk "Windows")
  "wd" '(delete-window :wk "Delete current window")
  "wv" '(split-window-right :wk "Split window right")
  "wh" '(split-window-below :wk "Split window below")
  "wS" '(window-swap-states :wk "Swap windows")
  "w=" '(maximize-window :wk "Maximize window")
  "w-" '(minimize-window :wk "Minimize window")
  "wb" '(balance-windows :wk "Balance windows")
))

;; Reason keybindings
(general-define-key
  :states '(normal visual insert emacs)
  :prefix ","
  :major-modes '(reason-mode)
  :non-normal-prefix "M-,"
  "h" '(:ignore t :wk "Types")
  "ht" '(merlin-type-enclosing :wk "Show type under cursor")
  "g" '(:ignore t :wk "Navigation")
  "gg" '(merlin-locate :wk "Go to definition")
  "gi" '(merlin-switch-to-ml :wk "Switch to ml")
  "gI" '(merlin-switch-to-mli :wk "Switch to mli")
  "e" '(:ignore t :wk "Errors")
  "en" '(merlin-error-next :wk "Next error")
  "eN" '(merlin-error-prev :wk "Previous error")
)

;; Docker keybindings
(general-define-key
  :states '(normal visual insert emacs)
  :prefix ","
  :major-modes '(dockerfile-mode)
  :non-normal-prefix "M-,"
  "c" '(:ignore t :wk "Compile")
  "cb" '(dockerfile-build-buffer :wk "Build buffer")
  "cB" '(dockerfile-build-no-cache-buffer :wk "Build buffer without cache")
)

;; Javascript keybindings
(general-define-key
 :states '(normal visual insert emacs)
 :prefix ","
 :major-modes '(js2-mode)
 :non-normal-prefix "M-,"
 "gg" '(xref-find-definitions-other-window :wk "Find definition")
 "gr" '(xref-find-references :wk "Find references")
)
