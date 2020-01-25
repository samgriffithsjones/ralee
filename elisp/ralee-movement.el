;;; ralee-movement

; Copyright (c) 2004-2014 Sam Griffiths-Jones
; Author: Sam Griffiths-Jones <sam.griffiths-jones@manchester.ac.uk>
;
; This is part of RALEE -- see http://sgjlab.org/ralee/
; and the 00README file that should accompany this file.
;
; RALEE is free software; you can redistribute it and/or modify it
; under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; RALEE is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with RALEE; if not, write to the Free Software Foundation,
; Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


(defun jump-right ()
  "move the pointer a screen to the right"
  (interactive)
  (move-to-column (+ (current-column) (/ (* (window-width) 2) 3)))
  (show-current-residue-number)
  )


(defun jump-left ()
  "move the pointer a screen to the left"
  (interactive)
  (let ((col (- (current-column) (/ (* (window-width) 2) 3))))
    (if (< col 0)
	(setq col 0)
      )
    (move-to-column col)
    )
  (show-current-residue-number)
  )


(defun jump-up ()
  "move the pointer a screen up"
  (interactive)
  (let ((column (current-column)))
    (goto-line (- (current-line) (/ (* (window-height) 2) 3)))
    (end-of-line)
    (while (< (current-column) column)
      (forward-line)
      (move-to-column column)
      )
    (move-to-column column)
    )
  (show-current-residue-number)
  )


(defun jump-down ()
  "move the pointer a screen down"
  (interactive)
  (let ((column (current-column)))
    (goto-line (+ (current-line) (/ (* (window-height) 2) 3)))
    (end-of-line)
    (while (< (current-column) column)
      (forward-line -1)
      (move-to-column column)
      )
    (move-to-column column)
    )
  (show-current-residue-number)
  )


(defun pointer-right ()
  "move the pointer one char right"
  (interactive)
  (move-to-column (1+ (current-column)))
  (show-current-residue-number)
  )


(defun pointer-left ()
  "move the pointer one char left"
  (interactive)
  (move-to-column (1- (current-column)))
  (show-current-residue-number)
  )


(defun pointer-up ()
  "move the pointer one char up"
  (interactive)
  (let ((column (current-column))
	(line (current-line)))
    (goto-line line) ;; why isn't this line-1?
    (move-to-column column)
    )
  (show-current-residue-number)
  )


(defun pointer-down ()
  "move the pointer one char down"
  (interactive)
  (let ((column (current-column))
	(line (current-line)))
    (goto-line (+ line 2)) ;; why isn't this line+1?
    (move-to-column column)
    )
  (show-current-residue-number)
  )


(defun center-on-point ()
  "center the screen on the current point"
  (interactive)
  (recenter)
  (let ((center (- (/ (window-width) 2) (window-hscroll))))
    (if (> (current-column) center)
	(scroll-left (- (current-column) center))
      (scroll-right (- center (current-column)))
      )
    )
  )


(defun jump-to-pair ()
  "jump to the pairing base"
  (interactive)
  (let (paired-column)
    (setq paired-column (ralee-paired-column (current-column)))
    (if paired-column
	(progn
	  (message "column %s pairs with column %s" (current-column) paired-column)
	  (move-to-column paired-column)
	  (show-current-residue-number)
	  )
      (message "No pair!"))))


(defun jump-to-pair-in-other-window ()
  "jump the cursor to the pairing base in other window
- make the other window if necessary"
  (interactive)
  (let (paired-column
	line
	bname)
    (setq line (current-line))
    (setq paired-column (ralee-paired-column (current-column)))
    (if paired-column
	(progn
	  (setq bname (buffer-name))
	  ;; fix for bug if other window is already another buffer
	  ;; from Zhenjiang Xu.
	  (if (< (safe-length (get-buffer-window-list)) 2)
	      (split-window))  ; make another window if there isn't already one
	  (message "column %s pairs with column %s" (current-column) paired-column)
	  (select-window (nth 1 (get-buffer-window-list)))
	  (switch-to-buffer bname)
	  (goto-line (1+ line)) ;; not sure why 1+, but seems to work
	  (move-to-column paired-column)
	  (show-current-residue-number)
	  (recenter))
      (message "No pair!"))))


(defun ralee-handle-mouse-click ()
  "handle mouse click"
  (interactive)
  (toggle-highlight-current-line)
  (show-current-residue-number)
  (check-sscons)
  )



(provide 'ralee-movement)
