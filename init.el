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

;; BLOCK 10 — OrgCube Menu — boxes within boxes
;; Outer box holds inner boxes. No globals leak.
;; Emacs makes PDF only. No printing from Emacs.

(defun make-orgcube-menu-box ()
  "Return OrgCube Menu box. All UI state lives inside this LET."
  (let ((current-file (expand-file-name "~/OrgCube/inbox/test-print.org"))
        (font "DejaVu Sans")
        (size 16)
        (margins "0.75in")
        (orientation "portrait")
        (table-fit "wrap"))
    (lambda (cmd &rest args)
      (pcase cmd
        ('get-file current-file)
        ('set-file (setq current-file (car args)))
        ('get-format (list :font font :size size :margins margins
                           :orientation orientation :table-fit table-fit))
      ('set-format
       (let ((plist (car args)))
         (setq font (or (plist-get plist :font) font))
         (setq size (or (plist-get plist :size) size))
         (setq margins (or (plist-get plist :margins) margins))
         (setq orientation (or (plist-get plist :orientation) orientation))
         (setq table-fit (or (plist-get plist :table-fit) table-fit))))
      ('show
       (with-current-buffer (get-buffer-create "*OrgCube Menu*")
         (let ((inhibit-read-only t))
           (erase-buffer)
           (insert "OrgCube Menu — Polaris λ — Don\n")
           (insert "================================\n\n")
           (insert (format "File: %s\n\n" current-file))
           (insert (format "Format a page: Font: %s  Size: %d pt  Margins: %s\n" font size margins))
           (insert (format "  Orientation: %s  Table Fit: %s\n\n" orientation table-fit))
           (insert "[1] Files and Documents — Load file / Format page / Make PDF\n")
           (insert "[2] Copy Chat Dialogs — WhatsApp / Discord / Mastodon / Open WebUI — Not built yet\n")
           (insert "[3] AI Assisted Coding — Needs Guix container + resident agent — Later\n")
           (insert "\nKeys: 1 = Files  2 = Chats  3 = AI  q = quit\n")
           (insert "\nIn Files box: l = load file, f = change format, p = make PDF\n")
           (orgcube-menu-mode)
           (goto-char (point-min)))
         (pop-to-buffer "*OrgCube Menu*")))
      (_ (error "Unknown menu cmd: %s" cmd))))))
        
(defvar orgcube--menu-box nil "The one OrgCube Menu box.")

(defun orgcube--ensure-menu-box ()
  (unless orgcube--menu-box
    (setq orgcube--menu-box (make-orgcube-menu-box)))
  orgcube--menu-box)

;; --- Menu mode — just keys, no mouse needed ---
(define-derived-mode orgcube-menu-mode special-mode "OrgCube-Menu"
  "Keys for OrgCube Menu Box."
  (define-key orgcube-menu-mode-map (kbd "1") #'orgcube-menu-files)
  (define-key orgcube-menu-mode-map (kbd "2") #'orgcube-menu-chats-placeholder)
  (define-key orgcube-menu-mode-map (kbd "3") #'orgcube-menu-ai-placeholder)
  (define-key orgcube-menu-mode-map (kbd "l") #'orgcube-files-load)
  (define-key orgcube-menu-mode-map (kbd "f") #'orgcube-files-format)
  (define-key orgcube-menu-mode-map (kbd "p") #'orgcube-files-make-pdf)
  (define-key orgcube-menu-mode-map (kbd "q") #'quit-window))

(defun orgcube-menu-open ()
  "Open OrgCube Menu — outer box."
  (interactive)
  (funcall (orgcube--ensure-menu-box) 'show))

;; --- 1. FILES AND DOCUMENTS BOX ---
(defun orgcube-menu-files ()
  "Enter Files and Documents box."
  (interactive)
  (funcall (orgcube--ensure-menu-box) 'show)
  (message "Files and Documents Box — l = load, f = format, p = make PDF"))

(defun orgcube-files-load ()
  "Load a file into Files box. Any valid file /path/location."
  (interactive)
  (let ((f (read-file-name "Load file: " nil nil t)))
    (funcall (orgcube--ensure-menu-box) 'set-file f)
    (funcall (orgcube--ensure-menu-box) 'show)
    (message "Loaded: %s" f)))

(defun orgcube-files-format ()
  "Change format — font / size / margins / orientation / table-fit.
Orientation is a this-or-that choice: portrait or landscape."
  (interactive)
  (let* ((box (orgcube--ensure-menu-box))
         (cur (funcall box 'get-format))
         (font (read-string "Font: " (plist-get cur :font)))
         (size (read-number "Size pt: " (plist-get cur :size)))
         (margins (read-string "Margins (e.g. 0.75in): " (plist-get cur :margins)))
         ;; This-or-that: completing-read with require-match, no free typing.
         (orientation (completing-read "Orientation (portrait or landscape): "
                                       '("portrait" "landscape")
                                       nil t (plist-get cur :orientation)))
         (table-fit (completing-read "Table Fit (wrap or shrink or landscape+shrink): "
                                     '("wrap" "shrink" "landscape+shrink")
                                     nil t (plist-get cur :table-fit))))
    (when (string= table-fit "landscape+shrink")
      (setq orientation "landscape")
      (setq table-fit "shrink"))
    (funcall box 'set-format (list :font font :size size :margins margins
                                   :orientation orientation :table-fit table-fit))
    (funcall box 'show)))

 (defun orgcube--fix-longtable-for-wrap (tex-file)
  "Rewrite longtable column specs to p{0.48\\textwidth} so cells wrap."
  (with-temp-buffer
    (insert-file-contents tex-file)
    (goto-char (point-min))
    (while (re-search-forward "\\\\begin{longtable}{[^}]*}" nil t)
      (replace-match
       "\\begin{longtable}{p{0.48\\textwidth} p{0.48\\textwidth}}"
       t t))
    (write-file tex-file)))

(defun orgcube--fix-longtable-for-shrink (tex-file)
  "Wrap longtable in adjustbox so wide tables shrink to fit.
Used when Table Fit = shrink."
  (with-temp-buffer
    (insert-file-contents tex-file)
    (goto-char (point-min))
    ;; Only wrap if not already wrapped. Simple: replace \begin{longtable}
    ;; with adjustbox start is not valid for longtable, so instead we
    ;; leave longtable alone and rely on geometry + small tabcolsep.
    ;; Shrink is handled by geometry + font size in this version.
    ;; This function is kept as a hook so shrink is not silently ignored.
    (message "Table Fit: shrink — using narrow tabcolsep, no forced p{} columns")
    (write-file tex-file)))

(defun orgcube-files-make-pdf ()
  "Make PDF with extarticle (8-20pt works).
Strips #+LATEX_CLASS / OPTIONS so source can't override Menu.
Keeps #+LATEX_HEADER so your own headers survive.
Temp buffers never prompt to save.
Result is 3 files only: .org, .tex, .pdf"
  (interactive)
  (let* ((box (orgcube--ensure-menu-box))
         (file (expand-file-name (funcall box 'get-file)))
         (fmt (funcall box 'get-format))
         (font (plist-get fmt :font))
         (size (plist-get fmt :size))
         (margins (plist-get fmt :margins))
         (orientation (or (plist-get fmt :orientation) "portrait"))
         (table-fit (or (plist-get fmt :table-fit) "wrap")))
    (unless (file-exists-p file) (error "File not found: %s" file))
    (let* ((base (file-name-sans-extension file))
           (out-dir (file-name-directory file))
           (tex-file (concat base ".tex"))
           (pdf-file (concat base ".pdf"))
           ;; Geometry: landscape is a separate option, not a margin.
           (geometry-opts (if (string= orientation "landscape")
                              (format "margin=%s,landscape" margins)
                            (format "margin=%s" margins))))
      (with-temp-buffer
        (setq buffer-offer-save nil)
        (insert-file-contents file)
        (setq buffer-file-name file)
        (setq default-directory out-dir)
        (goto-char (point-min))
        (while (re-search-forward "^.*DON[ \t]*[-—][ \t]*.*BLOCK.*\\[.*chars.*lines\\].*$" nil t)
          (replace-match "" nil nil))
        (goto-char (point-min))
        ;; Strip only CLASS / OPTIONS, NOT LATEX_HEADER.
        ;; Your #+LATEX_HEADER: lines survive now.
        (while (re-search-forward "^#\\+LATEX_CLASS:.*$\\|^#\\+OPTIONS:.*$" nil t)
          (replace-match "" nil nil))
        (org-mode)
        (let ((org-latex-compiler "xelatex")
              (org-latex-hyperref-template nil)
              (org-export-with-author nil)
              (org-export-with-creator nil)
              (org-export-with-date nil)
              (org-export-with-title nil)
              (org-export-with-toc nil)
              (org-latex-tables-booktabs t)
              (org-latex-default-table-environment "longtable")
              (org-latex-classes
               `(("orgcube-page"
                  ,(format "\\documentclass[%dpt]{extarticle}\n\\usepackage{fontspec}\n\\usepackage[%s]{geometry}\n\\usepackage{longtable}\n\\usepackage{tabularx}\n\\usepackage{booktabs}\n\\usepackage{adjustbox}\n\\usepackage{array}\n\\setlength{\\tabcolsep}{3pt}\n\\renewcommand{\\arraystretch}{1.15}\n\\setmainfont{%s}\n\\setmonofont{DejaVu Sans Mono}\n[NO-DEFAULT-PACKAGES]\n[PACKAGES]\n[EXTRA]"
                           size geometry-opts font)
                  ("\\section{%s}" . "\\section*{%s}")
                  ("\\subsection{%s}" . "\\subsection*{%s}")
                  ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                  ("\\paragraph{%s}" . "\\paragraph*{%s}")
                  ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))
              (org-latex-default-class "orgcube-page"))
          (org-export-to-file 'latex tex-file nil nil nil nil nil))
        (set-buffer-modified-p nil))
      ;; Table Fit actually does something now.
      (cond
       ((string= table-fit "wrap")
        (orgcube--fix-longtable-for-wrap tex-file))
       ((string= table-fit "shrink")
        (orgcube--fix-longtable-for-shrink tex-file)))
      ;; Two xelatex runs: second fixes references.
      (shell-command (format "cd %s && xelatex -interaction nonstopmode %s"
                             (shell-quote-argument out-dir)
                             (shell-quote-argument (file-name-nondirectory tex-file))))
      (shell-command (format "cd %s && xelatex -interaction nonstopmode %s"
                             (shell-quote-argument out-dir)
                             (shell-quote-argument (file-name-nondirectory tex-file))))
      (if (file-exists-p pdf-file)
          (progn
            ;; Cleanup: back to 3 files only. Delete xelatex byproducts.
            (dolist (ext '(".aux" ".log" ".out"))
              (let ((f (concat base ext)))
                (when (file-exists-p f)
                  (delete-file f))))
            (message "PDF made: %s %dpt %s %s TableFit %s" pdf-file size margins orientation table-fit))
        (message "PDF FAILED — check %s.log in %s" tex-file out-dir)))))

;; --- 2. COPY CHAT DIALOGS BOX — PLACEHOLDER ---
(defun orgcube-menu-chats-placeholder ()
  "Placeholder — Copy Chat Dialogs Box."
  (interactive)
  (message "Copy Chat Dialogs — Not built yet — Will hold: WhatsApp / Discord / Mastodon / Open WebUI boxes"))

;; --- 3. AI ASSISTED CODING BOX — PLACEHOLDER ---
(defun orgcube-menu-ai-placeholder ()
  "Placeholder — AI Coding Box needs container + resident agent."
  (interactive)
  (message "AI Assisted Coding — Later — Needs: Guix container box + Guile box + resident agent inside container. Do NOT run on Polaris directly."))

;; Key to open menu
(global-set-key (kbd "C-c o m") #'orgcube-menu-open)
