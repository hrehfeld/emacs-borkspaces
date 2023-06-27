;;; borkspaces.el --- Borked workspaces using burly -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Hauke Rehfeld

;; Author: Hauke Rehfeld <emacs@haukerehfeld.de>
;; Version: 0.0.1
;; Package-Requires: ((emacs "27.1") (burly "0.1.0"))
;; Keywords: convenience
;; URL: https://github.com/hrehfeld/emacs-borkspaces

;;; Commentary:

;; This package provides a simplistic workspaces implementation that relies on burly to save window configurations
;; Workspaces ("borkspaces") apply to each frame individually, but are shared between them and saved to bookmarks.

;;; Code:

;;;; Requirements
(require 'burly)

(defvar borkspaces-mode-map (define-keymap :name 'borkspaces-mode-map))

(defvar borkspaces--burly-prefix "--borkspaces--" "Prefix used when saving burly bookmarks.")

(defun borkspaces--burly-name (space-name)
  (concat borkspaces--burly-prefix space-name))

(defun borkspaces--current-space (&optional frame)
  (frame-parameter frame 'borkspaces--current-space))

(defun borkspaces--set-current-space (space &optional frame)
  (set-frame-parameter frame 'borkspaces--current-space space))


(defun borkspaces--saved-spaces ()
  (cl-loop for space-name in (burly-bookmark-names)
           when (string-prefix-p borkspaces--burly-prefix space-name)
           collect (s-chop-prefix borkspaces--burly-prefix space-name)))

;;;###autoload
(defun borkspaces-save (&optional space-name)
  (interactive (or (borkspaces--current-space) (completing-read "New borkspace name: " nil nil nil nil #'borkspaces--saved-spaces)))
  (if-let ((space-name (or space-name (borkspaces--current-space))))
      (progn
        (message "Saved borkspace %s as %s." space-name (borkspaces--burly-name space-name))
        (burly-bookmark-windows (borkspaces--burly-name space-name))
        space-name)))

;;;###autoload
(defun borkspaces-load (space-name)
  (cl-assert space-name)
  (let ((burly-name (borkspaces--burly-name space-name)))
    (message "Loading %s." burly-name)
    (burly-open-bookmark burly-name)))

;;;###autoload
(defun borkspaces-switch (arg space-name)
  (interactive (list
                (if current-prefix-arg ; <=== User provided arg
                    (prefix-numeric-value current-prefix-arg)
                  0)
                (completing-read "Switch to borkspace: " (borkspaces--saved-spaces) (lambda (candidate) (not (string-equal candidate (borkspaces--current-space)))))
                ))
  ;;(message "borkspaces-switch: %S %S" arg space-name)
  (let ((space-exists? (member space-name (borkspaces--saved-spaces))))
    (unless arg
      (borkspaces-save (borkspaces--current-space)))
    (borkspaces--set-current-space space-name)

    (if space-exists?
        (progn
          ;;(message "%S" (borkspaces--saved-spaces))
          (borkspaces-load space-name)
          ))))

(provide 'borkspaces)
;;; borkspaces.el ends here

;; Local Variables:
;; indent-tabs-mode: nil
