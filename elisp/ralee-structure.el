;;; ralee-structure

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



(defun ralee-helix-map (pairs)
  "Calculate helix boundaries based on pairs."
  (let ((helix 0)
	(lastopen 0)
	(lastclose 9999999)
	pair
	open
	(i (length pairs))
	j
	close
	helices)

    (while (>= i 1)
      (setq i (1- i))
      (setq pair (nth i pairs))
      (setq open (car pair))
      (setq close (cdr pair))

      ; we're moving from right to left based on closing pair
      ;
      ; catch things like
      ; <<..>>..<<..>>
      ;          *
      (if (> open lastclose)
	  (setq helix (+ helix 1))
	)

      ; catch things like
      ; <<..<<..>>..<<..>>>>
      ;                   *
      (setq j 0)
      (while (nth j pairs)
	(setq p (nth j pairs))
	(setq j (1+ j))
	(if (and (< (car p) lastopen)
		 (> (car p) open))
	    (if (equal (assoc (car p) helices) helix)
		()
	      (setq helix (+ helix 2)) ;; don't know why, but +1 doesn't always work!
	      )
	  )
	)

      (setq helices (cons (cons close helix) helices))
      (setq helices (cons (cons open helix) helices))

      (setq lastopen open)
      (setq lastclose close)

      )
    helices
    )
  )


(defun ralee-get-ss-line (&optional curr-line)
  "Get the SS_cons line or current structure line"
  (save-excursion
    (let (beg end do-it)
      (if (and (ralee-is-markup-line) curr-line)
	  (setq do-it t)
	;; else
	(goto-char (point-min))
	(if (search-forward "#=GC SS_cons")
	    (setq do-it t)
	  )
	)
      (if do-it
	  (progn
	    (beginning-of-line) (setq beg (point))
	    (end-of-line) (setq end (point))
	    (copy-region-as-kill beg end)
	    (car kill-ring)
	    )
	)
      )
    )
  )


(defun seedify-structure-line ()
  "Make the current structure line look like it should
in an Rfam seed alignment"
  (interactive)
  (save-excursion
    (end-of-line)
    (let ((eol (point)))
      (ralee-find-first-column)
      ;; perform-replace should set limits but I can't get it to work
      (save-restriction
	(narrow-to-region (point) eol)
	(goto-char (point-min))	(perform-replace ":" "." nil nil nil)
	(goto-char (point-min))	(perform-replace "_" "." nil nil nil)
	(goto-char (point-min))	(perform-replace "-" "." nil nil nil)
	(goto-char (point-min))	(perform-replace "," "." nil nil nil)
	(goto-char (point-min))	(perform-replace "(" "<" nil nil nil)
	(goto-char (point-min))	(perform-replace "[" "<" nil nil nil)
	(goto-char (point-min))	(perform-replace "{" "<" nil nil nil)
	(goto-char (point-min))	(perform-replace ")" ">" nil nil nil)
	(goto-char (point-min))	(perform-replace "]" ">" nil nil nil)
	(goto-char (point-min))	(perform-replace "}" ">" nil nil nil)
	)
      )
    )
  )

 

(defun ralee-get-current-ss-line ()
  "Get the current SS line"
  (save-excursion
    (let (beg end)
      (beginning-of-line) (setq beg (point))
      (if (or (looking-at (concat "#=GR " ralee-seqid-regex " SS "))
	      (looking-at "#=GC SS_cons"))
	  (progn
	    (end-of-line) (setq end (point))
	    (copy-region-as-kill beg end)
	    (car kill-ring)
	    )
	nil
	)
      )
    )
  )


(defun copy-current-ss-to-cons () 
  "Grab the current SS line, and copy it to the SS_cons line"
  (interactive)
  (save-excursion
    (if (ralee-is-markup-line)
	(let ((ssline (ralee-get-seq-string))
	      (col (ralee-find-first-column)))
	  ;; remove the old SS_cons line
	  (if (search-forward "#=GC SS_cons" nil t nil)
	      (progn
		(beginning-of-line)
		(kill-line)
		)
	    (search-forward "//")
	    (beginning-of-line)
	    (insert "\n")
	    (forward-line -1)
	    )
	  
	  (beginning-of-line)
	  (insert "#=GC SS_cons")
	  (while (< (current-column) col)
	    (insert " ")
	    )
	  (insert ssline)
	  )
      )
    )
  )


(defun ralee-structure-has-changed (structure-line)
  "check if the structure has changed"
  (if (equal structure-line ralee-structure-cache)
      nil
    t
    )
  )


(defun ralee-get-base-pairs (structure-line)
  "Parse the secondary structure markup.
Returns a list of pairs in order of increasing closing base."
  (save-excursion
    (let ((stack ())
	  (pairs ())
	  base
	  )

      ; only recalculate the base pairing structure if structure has changed
      (if (ralee-structure-has-changed structure-line)
	  (progn
	    (setq split (split-string structure-line ""))
	    (let ((i 0))

	      ; Grrr
	      ; GNU emacs: (split-string "AACC" "") => ("A" "A" "C" "C")
	      ; xemacs:    (split-string "AACC" "") => ("" "A" "A" "C" "C" "")
	      (if (equal (nth 0 split) "")
		  (setq split (cdr split))
		)

	      (while (< i (length split))
		(setq base (string-to-char (nth i split)))
		(if (and base (or (char-equal base ?\<)
				  (char-equal base ?\()
				  (char-equal base ?\[)
				  (char-equal base ?\{)))
		    (setq stack (cons i stack))
		  )
		(if (and base (or (char-equal base ?\>)
				  (char-equal base ?\))
				  (char-equal base ?\])
				  (char-equal base ?\})))
		    (progn
		      (setq pairs (cons (cons (car stack) i) pairs))
		      (setq stack (cdr stack)))
		  )
		(setq i (1+ i))
		)
	      )
	    (setq ralee-structure-cache structure-line)   ; cache these for speed
	    (setq ralee-base-pairs-cache pairs)
	    )
	)
      ralee-base-pairs-cache
      )
    )
  )


(defun check-sscons (&optional quiet)
  "Check the SS_cons line has matching open and closed parentheses"
  (interactive)
  (let ((structure-line (ralee-get-ss-line))
	opencount closecount)
    (setq opencount (ralee-count-str ralee-base-open-regex structure-line))
    (setq closecount (ralee-count-str ralee-base-close-regex structure-line))
    (if (= opencount closecount)
	nil
      (if quiet
	  ()
	(message "WARNING: Your SS_cons line is invalid [%s open, %s close]" opencount closecount)
	)
      t
      )
    )
  )

(defun ralee-paired-column (column &optional curr-line)
  "return the pair of <column> in consensus"
  (let (structure-line)
    (setq structure-line (ralee-get-ss-line curr-line))
    (ralee-paired-column-by-ss-line structure-line column)
    )
  )

(defun ralee-paired-column-by-ss-line (structure-line column)
  "return the pair of <column>"
  (let (paired-column
	pairs
	pair)
    (setq pairs (ralee-get-base-pairs structure-line))
    (setq pair (assoc column pairs))
    (if pair
	(setq paired-column (cdr pair))
      (progn
	(setq pair (rassoc column pairs))
	(if pair
	    (setq paired-column (car pair)))))
    
    (if paired-column
	paired-column
      nil)))


(defun remove-base-pair ()
  "delete the base pair involving the current column"
  (interactive)
  (let (c2 
	(to-current-line nil))
    (if (ralee-is-markup-line)
	(setq to-current-line t)
      )
    (setq c2 (ralee-paired-column (current-column) to-current-line))
    (if c2
	(progn
	  (remove-base-pair-by-column-number (current-column) to-current-line)
	  ;(message "Removed pair between columns %s and %s" (current-column) c2)
	  )
      ;(message "No pair!")
      )
    )
  )


(defun remove-base-pair-by-column-number (c1 &optional to-current-line)
  "delete the base pair by column number"
  (interactive)
  (save-excursion
    (let ((c2 (ralee-paired-column (current-column) to-current-line)))
      (if c2
	  (progn
	    (if (and (ralee-is-markup-line) to-current-line)
		()
	      ;else
	      (goto-char (point-min))
	      (search-forward "#=GC SS_cons")
	      )
	    (move-to-column c1)
	    (delete-char 1)
	    (insert ".")
	    (move-to-column c2)
	    (delete-char 1)
	    (insert ".")
	    (message "Removed pair between columns %s and %s" c1 c2)
	    )
	(message "No pair!")
	)
      )
    )
  )


(defun add-base-pair-by-column-numbers (c1 c2 &optional to-current-line)
  "add a base pair between specified columns"
  (interactive)
  (save-excursion
    (let ((cols (sort (list c1 c2) '<)))
      (if (and (ralee-is-markup-line) to-current-line)
	  ()
	;else
	(goto-char (point-min))
	(search-forward "#=GC SS_cons")
	)
      (move-to-column (car cols))
      (delete-char 1)
      (insert "(")
      ;; (cdr cols) doesn't work here -- wrong type?
      (move-to-column (nth 1 cols))
      (delete-char 1)
      (insert ")")
      (message "Added pair between columns %s and %s" c1 c2)
      )
    )
  )



(defun add-base-pair ()
  "add a base pair between current and marked columns"
  (interactive)
  (save-excursion
    (let ((to-current-line nil)
	  c1 c2)
      (if (ralee-is-markup-line)
	  (setq to-current-line t)
	)
      (if (ralee-is-alignment-column)
	  (setq c1 (current-column))
	)
      (goto-char (mark))
      (if (ralee-is-alignment-column)
	  (progn
	    (setq c2 (current-column))
	    (pop-mark)
	    )
	)
      (if (and c1 c2)
	  (add-base-pair-by-column-numbers c1 c2 to-current-line)
	(message "Pairing column is undefined - define with C-space")
	)
      )
    )
  )


(defun copy-base-pair-to-cons ()
  "copy the current base pair into the consensus structure"
  (interactive)
  (save-excursion)
  (if (ralee-is-markup-line)
      (progn
	(let ((structure-line (ralee-get-current-ss-line))
	      (c1 (current-column))
	      c2)
	  (setq c2 (ralee-paired-column-by-ss-line structure-line c1))
	  (if c2
	      (add-base-pair-by-column-numbers c1 c2)
	    (message "No pair!")
	    )
	  )
	)
    (message "This isn't a structure line")
    )
  )


(provide 'ralee-structure)
