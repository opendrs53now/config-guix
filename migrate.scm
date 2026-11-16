#!/usr/bin/env guile
!#

(use-modules (ice-9 ftw)
             (ice-9 format)
             (srfi srfi-1))

(define source-root "/home/don")
(define dest "/home/don/org")

(define (ensure-dir dir)
  (unless (file-exists? dir)
    (system* "mkdir" "-p" dir)))

(define (odt-files-in dir)
  (filter (lambda (f) (string-suffix? ".odt" f))
          (map (lambda (f) (string-append dir "/" f))
               (or (scandir dir (lambda (f) (not (member f '("." ".."))))) '()))))

(define (migrate-file odt-path)
  (let* ((base (basename odt-path ".odt"))
         (target-dir (cond
                       ((string-contains-ci base "C_") (string-append dest "/C"))
                       ((or (string-contains-ci base "guile") (string-contains-ci base "scheme")) (string-append dest "/Guile_Scheme"))
                       ((or (string-contains-ci base "elisp") (string-contains-ci base "emacs")) (string-append dest "/Elisp_Emacs"))
                       (else (string-append dest "/Guile_Scheme"))))
         (org-file (string-append target-dir "/" base ".org")))
    (ensure-dir target-dir)
    (format #t "Converting ~a -> ~a~%" odt-path org-file)
    (system* "pandoc" "-f" "odt" "-t" "org" "-o" org-file odt-path)))

(define (migrate)
  (format #t "=== Polaris X ODT -> Org Migration ===~%")
  (format #t "Source: ~a~%Dest: ~a~%~%" source-root dest)
  (ensure-dir dest)
  (ensure-dir (string-append dest "/C"))
  (ensure-dir (string-append dest "/Guile_Scheme"))
  (ensure-dir (string-append dest "/Elisp_Emacs"))
  (ensure-dir "/home/don/org/finished/pdf/2026/11")
  ;; Top-level 3 .odt in open
  (for-each migrate-file (odt-files-in source-root))
  ;; Scan subdirs for .odt dialogs
  (let ((dirs (scandir source-root (lambda (f) (and (not (member f '("." ".."))) (file-exists? (string-append source-root "/" f)) (eq? 'directory (stat:type (stat (string-append source-root "/" f)))))))))
    (for-each (lambda (d)
                (for-each migrate-file (odt-files-in (string-append source-root "/" d))))
              dirs))
  (format #t "~%Done.~%"))

(migrate)
