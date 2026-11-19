;;; -*- lexical-binding: t; -*-
;;; init.el --- Polaris init - Guix 22.5 + λ 
(require 'package)
(require 'dired-x)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(setq gc-cons-threshold (* 16 1024 1024))
(setq inhibit-startup-screen t)
(show-paren-mode 1)
(setq org-src-fontify-natively t)
(setq org-src-tab-acts-natively t)
(setq x-select-enable-clipboard t x-select-enable-primary t save-interactivity-history t)
(setq select-enable-clipboard t select-enable-primary nil)
(cua-mode 0)
(global-set-key (kbd "C-c c") 'org-capture)
(global-set-key [mouse-2] 'x-yank)

(require 'ox-latex)
(setq org-latex-compiler "xelatex")
(setq org-latex-pdf-process
      '("xelatex -interaction nonstopmode -output-directory %o %f"
        "xelatex -interaction nonstopmode -output-directory %o %f"))
(setq org-latex-default-packages-alist
      '(("" "fontspec" t) ("" "graphicx" t) ("" "longtable" nil) ("" "wrapfig" nil) ("" "rotating" nil) ("normalem" "ulem" t) ("" "amsmath" t) ("" "amssymb" t) ("" "capt-of" nil) ("" "hyperref" nil)))
(add-to-list 'org-latex-packages-alist '("" "xunicode" t))
(setq org-latex-classes
      '(("article"
         "\\documentclass[11pt]{article}\n\\usepackage{fontspec}\n\\setmainfont{DejaVu Sans}\n\\setmonofont{DejaVu Sans Mono}\n[NO-DEFAULT-PACKAGES]\n[PACKAGES]\n[EXTRA]"
         ("\\section{%s}" . "\\section*{%s}")
         ("\\subsection{%s}" . "\\subsection*{%s}")
         ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
         ("\\paragraph{%s}" . "\\paragraph*{%s}")
         ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))
(setq eshell-prompt-function (lambda () (concat "λ ")))

(when (require 'geiser nil t)
  (setq geiser-active-implementations '(guile) geiser-guile-binary "guile" geiser-repl-history-filename "~/.cache/geiser-history")
  (when (boundp 'geiser-guile-load-path)
    (add-to-list 'geiser-guile-load-path "~/dotfiles/config-guix")
    (add-to-list 'geiser-guile-load-path "~/dotfiles/config-guix/orgcube")
    (add-to-list 'geiser-guile-load-path "~/dotfiles/config-guix/my-packages")))

(setq dired-listing-switches "-alh --group-directories-first" dired-dwim-target t dired-recursive-copies 'always dired-recursive-deletes 'always)
(put 'dired-find-alternate-file 'disabled nil)
(setq-default c-basic-offset 4 indent-tabs-mode nil)
(add-hook 'c-mode-hook (lambda () (c-set-style "linux")))
(add-hook 'prog-mode-hook 'display-line-numbers-mode)
(when (require 'projectile nil t) (projectile-mode +1) (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")) company-minimum-prefix-length 1 printer-name "Brother_HL-2800DW")

(custom-set-variables
 '(custom-enabled-themes '(wheatgrass))
 '(package-selected-packages '(projectile company paredit)))
  (load-theme 'wheatgrass t)

;; OrgCube Ring2
(add-to-list 'load-path "~/dotfiles/config-guix/my-packages")
(add-to-list 'load-path "~/dotfiles/config-guix/orgcube")
(defvar org-babel-default-header-args:orgcube '())
(defun org-babel-execute:orgcube (body params)
  (let ((query (string-trim body)))
    (if (string-empty-p query) (format "EIGEN OK — cube-dir: %s — empty query" (expand-file-name "~/dotfiles/config-guix/orgcube"))
      (with-temp-buffer
        (let ((exit-code (call-process "guile" nil t nil "-L" (expand-file-name "~/dotfiles/config-guix/orgcube") "-L" (expand-file-name "~/dotfiles/config-guix/my-packages") "-c" (format "(use-modules (orgcube eigencube)) (let ((hits (eigencube-query %S))) (if (null? hits) (format #t \"EIGEN OK — 0 hits — cube-dir: %%s — query: '%%s'\" %s %S) (for-each (lambda (r) (format #t \"~a:~a: ~a~%%\" (car r) (cadr r) (caddr r))) hits)))" query (expand-file-name "~/dotfiles/config-guix/orgcube") query))))
          (if (zerop exit-code) (buffer-string) (format "EIGEN ERR — guile exit %d: %s" exit-code (buffer-string))))))))
(with-eval-after-load 'org (add-to-list 'org-babel-load-languages '(orgcube . t)) (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages))

;; NOTE: babel orgcube executor + load-path already defined in Block 3 - do not duplicate
(defvar orgcube-root (expand-file-name "~/OrgCube/") "OrgCube root")
(defvar orgcube-inbox (concat orgcube-root "inbox/inbox.org"))
(defvar orgcube-clip-min 1 "Min chars")
(defvar orgcube-clip-max 150000 "Max chars — 150K")
(defvar orgcube-mode t "Inbox-only blackbox enabled")

;; Compat globals — kept so Block 5 clear still works, but watcher no longer uses them
(defvar orgcube-whatsapp-clipboard-watcher-last-clip "")
(defvar orgcube-last-clip "" "Compat alias")

;; PRIMARY handling: never auto-capture, ask only
(defvar orgcube-primary-seen "" "Last PRIMARY we already asked about")
(defvar orgcube-primary-denied "" "Last PRIMARY user said no to")

(defun orgcube-ensure ()
  (unless (file-directory-p orgcube-root) (make-directory orgcube-root t))
  (unless (file-directory-p (concat orgcube-root "inbox")) (make-directory (concat orgcube-root "inbox") t))
  (unless (file-directory-p (concat orgcube-root "manual")) (make-directory (concat orgcube-root "manual") t))
  (unless (file-exists-p orgcube-inbox)
    (with-temp-file orgcube-inbox (insert "#+TITLE: OrgCube Inbox\n")))
  (unless (file-exists-p (concat orgcube-root "manual/manual.org"))
    (with-temp-file (concat orgcube-root "manual/manual.org")
      (insert "#+TITLE: OrgCube Manual — Polaris λ — Don\n"))))

(defun orgcube-count-blocks ()
  (if (file-exists-p orgcube-inbox)
      (with-temp-buffer (insert-file-contents orgcube-inbox) (count-matches "^\* "))
    0))

(defun orgcube--capture (clip tag src)
  "Write CLIP to inbox.org. Watcher is read-only — never touches XFCE clipboard."
  (let ((len (length clip)))
    (with-temp-buffer
      (insert (format "\n* %s — %s — BLOCK [%d chars]\n:PROPERTIES:\n:CREATED: %s\n:BLOCK: auto\n:CHARS: %d\n:SOURCE: %s\n:END:\n#+BEGIN_SRC text\n%s\n#+END_SRC\n"
                      tag (format-time-string "%Y-%m-%d %H:%M:%S") len
                      (format-time-string "%Y-%m-%d %H:%M:%S") len src clip))
      (append-to-file (point-min) (point-max) orgcube-inbox))
    (message "CAPTURED BLOCK %d chars [%s] -> inbox.org" len tag)))

;; --- THE ENCLOSURE ---
(defun make-orgcube-watcher (interval)
  "Return a closure box. All state lives inside this LET."
  (let ((timer nil)
        (last-clip "")
        (running nil)
        (last-state nil)
        (last-toggle-time 0))
    (lambda (cmd &rest args)
      (pcase cmd
        ('tick
         (when (and running orgcube-mode
                    (not (minibufferp))) ; never prompt while typing in minibuffer
           (let* ((clipboard (ignore-errors (or (gui-get-selection 'CLIPBOARD 'UTF8_STRING) (x-get-clipboard) "")))
                  (primary (ignore-errors (or (gui-get-selection 'PRIMARY 'UTF8_STRING) "")))
                  (clipboard-new (and (stringp clipboard)
                                      (> (length clipboard) orgcube-clip-min)
                                      (< (length clipboard) orgcube-clip-max)
                                      (not (string= clipboard last-clip))
                                      (not (string-prefix-p "#+TITLE: OrgCube Inbox" (string-trim clipboard)))
                                      (not (string-prefix-p "% Created" (string-trim clipboard)))))
                  (primary-new (and (stringp primary)
                                    (> (length primary) orgcube-clip-min)
                                    (< (length primary) orgcube-clip-max)
                                    (not (string= primary last-clip))
                                    (not (string= primary orgcube-primary-seen))
                                    (not (string= primary orgcube-primary-denied))
                                    (not (string-prefix-p "#+TITLE: OrgCube Inbox" (string-trim primary)))
                                    (not (string-prefix-p "% Created" (string-trim primary))))))
             ;; 1. CLIPBOARD = Default ONLY, auto-capture, no prompt
             (cond
              (clipboard-new
               (setq last-clip clipboard)
               (setq orgcube-whatsapp-clipboard-watcher-last-clip clipboard)
               (setq orgcube-last-clip clipboard)
               ;; Mark PRIMARY as seen so same text doesn't ask later
               (setq orgcube-primary-seen primary)
               (let* ((src (if (string-match-p "WhatsApp\\|Meta_A" clipboard) "WhatsAppForLinux" "Clipboard"))
                      (tag (if (string-match-p "WhatsApp\\|Meta_A" clipboard) "META" "MIN")))
                 (orgcube--capture clipboard tag src)))

              ;; 2. PRIMARY = ask only, never auto, y or n
              (primary-new
               (setq orgcube-primary-seen primary)
               (if (y-or-n-p (format "CAPTURE FOR INBOX.org? PRIMARY %d chars " (length primary)))
                   (progn
                     (setq last-clip primary)
                     (setq orgcube-whatsapp-clipboard-watcher-last-clip primary)
                     (setq orgcube-last-clip primary)
                     (let* ((src (if (string-match-p "WhatsApp\\|Meta_A" primary) "WhatsAppForLinux" "Clipboard"))
                            (tag (if (string-match-p "WhatsApp\\|Meta_A" primary) "META" "MIN")))
                       (orgcube--capture primary tag src)))
                 ;; n = never ask again for this exact text
                 (setq orgcube-primary-denied primary)
                 (message "PRIMARY ignored - not captured")))))))
        ('start
         (let ((now (float-time)))
           (cond
            ((< (- now last-toggle-time) 1.0)
             (message "Already STARTED - bounce ignored, no new block"))
            ((eq last-state 'started)
             (message "Already STARTED - no new block BLOCK=%d" (orgcube-count-blocks)))
            (t
             (setq last-toggle-time now)
             (setq last-state 'started)
             (unless running
               (setq running t)
               (setq timer (run-with-timer 10 interval (lambda () (funcall orgcube--watcher-box 'tick)))))
             (message "v9 ENCLOSURE STARTED BLOCK=%d" (orgcube-count-blocks))))))
        ('stop
         (let ((now (float-time)))
           (cond
            ((< (- now last-toggle-time) 1.0)
             (message "Already STOPPED - bounce ignored, no new block"))
            ((eq last-state 'stopped)
             (message "Already STOPPED - no new block BLOCK=%d" (orgcube-count-blocks)))
            (t
             (setq last-toggle-time now)
             (setq last-state 'stopped)
             (when (timerp timer) (cancel-timer timer))
             (setq timer nil running nil)
             (message "STOPPED BLOCK=%d" (orgcube-count-blocks))))))
        ('clear
         (setq last-clip "")
         (setq orgcube-whatsapp-clipboard-watcher-last-clip "")
         (setq orgcube-last-clip "")
         (setq orgcube-primary-seen "")
         (setq orgcube-primary-denied ""))
        ('running-p running)
        ('timer timer)
        (_ (error "Unknown watcher cmd: %s" cmd))))))

(defun orgcube-sanitize-for-inbox (text)
  "Escape Org markup so code stays text"
  (let ((s text))
    (setq s (replace-regexp-in-string "#\\+BEGIN_SRC" "#+BEGIN_EXAMPLE" s t))
    s))

(defun orgcube-capture (tag text)
  (orgcube-ensure)
  (let ((clean (orgcube-sanitize-for-inbox text)))
    (with-current-buffer (find-file-noselect orgcube-inbox)
      (goto-char (point-max))
      (insert (format "\n* %s  :%s:\n:PROPERTIES:\n:CREATED: %s\n:END:\n#+BEGIN_SRC text\n%s\n#+END_SRC\n"
                      (format-time-string "%Y-%m-%d %H:%M:%S") tag (format-time-string "%Y-%m-%d %H:%M:%S") clean))
      (save-buffer))))

(defun orgcube-clear-inbox ()
  "C-c o c — archive + clear — and force buffer revert"
  (interactive)
  (orgcube-ensure)
  (let* ((bak-dir (concat orgcube-root "inbox/.bak/"))
         (bak-file (concat bak-dir (format-time-string "inbox-%Y-%m-%d-%H%M.org"))))
    (make-directory bak-dir t)
    (copy-file orgcube-inbox bak-file t)
    (with-temp-file orgcube-inbox (insert "#+TITLE: OrgCube Inbox\n"))
    (setq orgcube-whatsapp-clipboard-watcher-last-clip "")
    ;; FORCE any open inbox.org buffer to match disk (250 bytes)
    (when (get-buffer "inbox.org")
      (with-current-buffer "inbox.org"
        (set-buffer-modified-p nil)
        (revert-buffer t t t)))
    (when (get-file-buffer orgcube-inbox)
      (with-current-buffer (get-file-buffer orgcube-inbox)
        (set-buffer-modified-p nil)
        (revert-buffer t t t)))
    (message "Inbox cleared - backup: %s - Inbox: 3 lines / 250 bytes - buffer reverted" bak-file)))

(defun orgcube-export-pdf-txt ()
  "Manual export only — C-c C-e l p — no auto to avoid loop"
  (interactive) (orgcube-ensure)
  (let* ((root orgcube-root) (inbox-dir (expand-file-name "inbox" root)) (inbox-org (expand-file-name "inbox.org" inbox-dir)))
    (with-current-buffer (find-file-noselect inbox-org)
      (let ((org-latex-compiler "xelatex") (org-latex-pdf-process '("xelatex -interaction nonstopmode -output-directory %o %f" "xelatex -interaction nonstopmode -output-directory %o %f")))
        (org-latex-export-to-pdf) (org-ascii-export-to-ascii)
        (shell-command (format "cd %s && pdftotext inbox.pdf inbox.txt 2>/dev/null; true" inbox-dir))))
    (message "OrgCube exported to %s/ trio" inbox-dir)))

;; BLOCK 7 — safe terminal check — never open via Thunar
;; Use: M-! cat ~/OrgCube/inbox/inbox.org | wc -l  — 100% safe
;; If you DO open via Thunar, auto-revert keeps buffer = disk
(add-hook 'find-file-hook (lambda () (when (and buffer-file-name (string-match-p "inbox.org" buffer-file-name)) (auto-revert-mode 1))))

(global-set-key (kbd "C-c o c") #'orgcube-clear-inbox)
(global-set-key (kbd "C-c o w") #'orgcube-whatsapp-clipboard-watcher-start)
(global-set-key (kbd "C-c o W") #'orgcube-whatsapp-clipboard-watcher-stop)

;; BLOCK 9 — boring global timer holder — safety net, do not delete
;; This is the ONLY global that touches the watcher box.
;; Timer + last-clip + running live INSIDE the box in Block 4, not here.
(defvar orgcube--watcher-box nil "The one OrgCube watcher box.")

(defun orgcube--ensure-box ()
  (unless orgcube--watcher-box
    (setq orgcube--watcher-box (make-orgcube-watcher 2)))
  orgcube--watcher-box)

(defun orgcube-whatsapp-clipboard-watcher-start ()
  (interactive)
  (funcall (orgcube--ensure-box) 'start))

(defun orgcube-whatsapp-clipboard-watcher-stop ()
  (interactive)
  (when orgcube--watcher-box
    (funcall orgcube--watcher-box 'stop)))

;; DO NOT auto-start. Old bug: after-init-hook restarted after you stopped.
;; Box is created on first manual C-c o w. If you want it on boot, uncomment ONE line:
;; (add-hook 'after-init-hook #'orgcube--ensure-box)
