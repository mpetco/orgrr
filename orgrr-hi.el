;;; orgrr-hi.el

;; Maintainer: Martin Petkovski <https://github.com/mpetco>
;; URL: https://github.com/mpetco/orgrr
;; Package-Requires: ((emacs "27.2"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;
;; Just a few tweaked functions for my personal use. If you are a better lisper then me feel free to open up a pull request.
;; I'm still a novice
;;

(defun orgrr-hi-change-zettel (&optional new-zettel old-zettel)
  "Change the prefix of a zettel across all notes"
  (interactive)
  ;; grab the the value of zettel and the value the user wishes to change it to
  (let ((current-buffer (buffer-string)))
    (when (not old-zettel)
      (string-match "#\\+zettel: \\(.*\\)" current-buffer)
      (setq old-zettel (match-string 1 current-buffer)))
    (when (not new-zettel)
      (setq new-zettel
            (read-from-minibuffer "New zettel: " old-zettel))))
  ;; creates a hash table with the files of an orgrr container
  (let*
      ((old-zettel-mentions '())
       (orgrr-name-container (orgrr-get-list-of-containers))
       (containers
        (nreverse (hash-table-values orgrr-name-container)))
       (lines)
       (concat-old-zettel (concat "zettel: " old-zettel))
       (concat-new-zettel (concat "zettel: " new-zettel))
       (trim-concat-old-zettel
        (string-trim-right concat-old-zettel "/[^/]+$"))
       (trim-concat-new-zettel
        (string-trim-right concat-new-zettel "/[^/]+$"))) ;; make this maybe a bit more general? some ppl might not wish to use /
    ;; creates a temporary buffer in which we will list all the files matching the old-zettel pattern
    (dolist (container containers)
      (with-temp-buffer
        (insert
         (shell-command-to-string
          (concat "rg -l -F \"" old-zettel "\" -n -g \"*.org\"")))
        (insert
         (shell-command-to-string
          (concat
           "rg -l -F \""
           trim-concat-old-zettel
           "\" -n -g \"*.org\"")))
        (setq lines (split-string (buffer-string) "\n" t)))
      ;; change mentions into new zettel
      (dolist
          (filename lines) ;; why do we need a do list loop when we are just changing it once? is it so we find the proper line?
        (with-current-buffer (find-file-noselect filename)
          (goto-char (point-min))
          (while (re-search-forward concat-old-zettel nil t)
            (replace-match concat-new-zettel))
          (while (re-search-forward trim-concat-old-zettel nil t)
            (replace-match trim-concat-new-zettel)))))
    (save-some-buffers t)))

;; run outside org bug
;; double characters bug on the current buffer
;; process runnning bug
;; test thrice bug

(defun orgrr-hi-read-roam-keys ()
  "Reads out multiple #+roam_key values."
  (let* ((current-entry nil)
         (roam-key '())
         (buffer
          (buffer-substring-no-properties (point-min) (point-max))))
    (with-temp-buffer
      (insert buffer)
      (goto-char (point-min))
      (while (not (eobp))
        (setq current-entry
              (buffer-substring
               (line-beginning-position) (line-end-position)))
        (when (string-match
               "\\(#\\+roam_key:\\|#+ROAM_KEY:\\)\\s-*\\(.+\\)"
               current-entry)
          (let* ((line (split-string current-entry "\\: " t))
                 (key (car (cdr line)))
                 (key (string-trim-left key)))
            (add-to-list 'roam-key key)))
        (forward-line)))
    roam-key))

(defun orgrr-hi-open-ref-url ()
  "Open and select a #+roam_key line link from the minibuffer. If it's just one link it opens that link."
  (interactive)
  (let ((roam-keys (orgrr-hi-read-roam-keys)))
    (if (equal (length roam-keys) 1)
        (browse-url (car roam-keys))
      (browse-url
       (completing-read "Select link to open: " roam-keys)))))

(provide 'orgrr-hi)
;; a frined property perhaps? roam_friend? and a show friends functions?

;; orgrr-hi.el ends here
