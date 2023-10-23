(load-file "~/.emacs.d/my-playground/ical2org-config.el")
(setq org-file "~/.emacs.d/calendar/planning.org")
(setq ical-file "~/.emacs.d/calendar/raw.ical")
(setq planning_url url)

(defun sanitize-line (line preserve_linefeed) (replace-regexp-in-string "\\\\," "," (if preserve_linefeed (replace-regexp-in-string "\\\\n" "\n" line) (replace-regexp-in-string "\\\\n" "-" line))))
(defun iso8601-to-org (date) (format-time-string "%Y-%m-%d %a %H:%M" (date-to-time date)))
(defun write (string overwrite) (write-region string nil org-file overwrite))
(defun read-lines (path)
  (with-temp-buffer
    (insert-file-contents path)
    (split-string (buffer-string) "\n" t)))
(defun print-event (dtstart dtend uid summary location description)
  (write
   (concat
    (format "* %s" summary)
    (if (not (eq location nil))
	(format "- %s" location))
    "\n\t:PROPERTIES:\n"
    (format "\t:ID:\t%s\n" uid)
    (format "\t:LOCATION:\t%s\n" location)
    "\t:END:\n"
    "\t:LOGBOOK:\n"
    (format "\tCLOCK:\t[%s]--[%s] => 0:00\n" dtstart dtend)
    "\t:END:\n"
    (format "<%s>--<%s>\n" dtstart dtend)
    (format "\n%s\n" description))
   t))

(defun edt-iut ()
  (interactive)
  (if (not (file-exists-p "~/.emacs.d/calendar"))
      (make-directory "~/.emacs.d/calendar"))
  (url-copy-file planning_url ical-file t)
  (write
   (concat
    (format "#+TITLE: %s\n" title)
    (format "#+AUTHOR: %s\n" name)
    (format "#+EMAIL: %s\n" email)
    "#+DESCRIPTION: conversion d'un fichier .ical en .org\n"
    (format "#+CATEGORY: %s\n" category)
    "#+STARTUP: hidestars\n"
    "#+STARTUP: overview\n"
    (format "#+FILETAGS: %s\n\n" filetag))
   nil)
  (let ((dtstart nil) (dtend nil) (uid nil) (summary nil) (location nil) (description nil) (stored_uid '()))
    (dolist (line (read-lines ical-file))
      (cond
       ((equal           "BEGIN:VEVENT" line) (setq dtstart     (setq uid       (setq dtend (setq summary (setq location (setq description nil)))))))
       ((string-prefix-p "UID" line)          (setq uid         (sanitize-line  (replace-regexp-in-string "^UID:" "" line) t)))
       ((string-prefix-p "DTSTART" line)      (setq dtstart     (iso8601-to-org (replace-regexp-in-string "^DTSTART[A-Z;=]*:" "" line))))
       ((string-prefix-p "DTEND" line)        (setq dtend       (iso8601-to-org (replace-regexp-in-string "^DTEND[A-Z;=]*:" "" line))))
       ((string-prefix-p "SUMMARY" line)      (setq summary     (sanitize-line  (replace-regexp-in-string "^SUMMARY;LANGUAGE=fr:" "" line) t)))
       ((string-prefix-p "LOCATION" line)     (setq location    (sanitize-line  (replace-regexp-in-string "^LOCATION;LANGUAGE=fr:" "" line) t)))
       ((string-prefix-p "DESCRIPTION" line)  (setq description (sanitize-line  (replace-regexp-in-string "^DESCRIPTION;LANGUAGE=fr:" "" line) t)))
       ((equal           "END:VEVENT" line)
	(if (not (member uid stored_uid))
	    (progn
	      (push uid stored_uid)
	      (print-event dtstart dtend uid summary location description)))))))
  (org-agenda org-file))
