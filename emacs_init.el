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

;; Some emacs behaviors

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(inhibit-startup-screen t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Modified version of script and instructions to use Solarized 
;; (http://ethanschoonover.com/solarized) theme to Emacs
;; see http://codefork.com/blog/index.php/2011/11/27/ \
;; getting-the-solarized-theme-to-work-in-emacs/ for details
(add-to-list 'load-path 
	     (fullpath-relative-to-current-file "emacs-color-theme-solarized"))
(if
    (equal 0 (string-match "^24" emacs-version))
    ;; it's emacs24, so use built-in theme 
    (require 'solarized-dark-theme)
  ;; it's NOT emacs24, so use color-theme
  (progn
    (require 'color-theme)
    (color-theme-initialize)
    (require 'color-theme-solarized)
    (color-theme-solarized-dark)))

;; Force emacs to display column number upon start.
(column-number-mode)

;; Set up the keyboard so the <delete> key on both the regular keyboard
;; and the keypad delete the character under the cursor and to the right
;; under X, instead of the default, backspace behavior.
(global-set-key [delete] 'delete-char)

;; Emacs will not automatically add new lines
(setq next-line-add-newlines nil)

;; Force syntax highlighting by default
(global-font-lock-mode 1)

;; Changes all yes/no questions to y/n type
(fset 'yes-or-no-p 'y-or-n-p)

;; Scroll down with the cursor,move down the buffer one
;; line at a time, instead of in larger amounts.
(setq scroll-step 1)

; add the dir of this file to load path
(add-to-list 'load-path (fullpath-relative-to-current-file ""))

; Now, load a bunch of modes
;; Markdown-mode, from Jason Blevins
;; See http://jblevins.org/git/markdown-mode.git/
;; TODO(goxberry@gmail.com): Figure out a nice way to subtree merge or
;; submodule this beast.
(load (fullpath-relative-to-current-file "markdown-mode"))
;; Use markdown-mode by default on certain file names
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
;; Add on-the-fly spell checking for Markdown files, which are usually
;; documentation (not always, but usually).
(add-hook 'markdown-mode-hook 'turn-on-flyspell)

;; Git-commit mode, from: https://github.com/rafl/git-commit-mode
(load (fullpath-relative-to-current-file "git-commit"))
;; Add on-the-fly spell checking for Git commit messages
;; See http://petereisentraut.blogspot.com/2011/01/git-commit-mode.html
(add-hook 'git-commit-mode-hook 'turn-on-flyspell)

;; Automatically use shell-script-mode on .gitignore files
(add-to-list 'auto-mode-alist '("\\.gitignore\\'" . shell-script-mode))

;; Add on-the-fly spell checking for Org-mode files (usually notes)
(add-hook 'org-mode-hook 'turn-on-flyspell)

;; TODO(goxberry@gmail.com): Add
;; - cython-mode
;; - gams-mode
;; - pandoc-mode
;; - puppet-mode
;; - auto-mode-alist commands for the above modes
;; - an auto-mode-alist command for Vagrantfiles (use ruby-mode)
