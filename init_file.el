;; Symlink this file to "~/.emacs". In this directory, you would use
;; "ln -s init_file.el ~/.emacs". Your current directory should be 
;; "~/.emacs.d".

;; Slick function to get us out of file name trouble:
;; Source: http://ergoemacs.org/emacs/elisp_relative_path.html
(defun fullpath-relative-to-current-file (file-relative-path)
  "Returns the full path of FILE-RELATIVE-PATH, relative to file location where this function is called.

Example: If you have this line
 (fullpath-relative-to-current-file \"../xyz.el\")
in the file at
 /home/mary/emacs/emacs_lib.el
then the return value is
 /home/mary/xyz.el
Regardless how or where emacs_lib.el is called.

This function solves 2 problems.

 ① If you have file A, that calls the `load' on a file at B, and
B calls “load” on file C using a relative path, then Emacs will
complain about unable to find C. Because, emacs does not switch
current directory with “load”.

 To solve this problem, when your code only knows the relative
path of another file C, you can use the variable `load-file-name'
to get the current file's full path, then use that with the
relative path to get a full path of the file you are interested.

 ② To know the current file's full path, emacs has 2 ways:
`load-file-name' and `buffer-file-name'. If the file is loaded
by “load”, then load-file-name works but buffer-file-name
doesn't. If the file is called by `eval-buffer', then
load-file-name is nil. You want to be able to get the current
file's full path regardless the file is run by “load” or
interactively by “eval-buffer”."
  (concat (file-name-directory (or load-file-name buffer-file-name)) file-relative-path)
)

;; In order to make this file nice and tidy (and compatible with both
;; OS X and Linux without doing anything too too complicated!) just
;; load from ~/.emacs.d (obviously, in Windows, the directory will be
;; something different...
(load "~/.emacs.d/emacs_init.el")

;; TODO(goxberry@gmail.com): Make this load command more Windows-
;; compatible!
