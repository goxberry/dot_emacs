;;; GAMS.EL --- Major mode for editing GAMS program files.

;; Copyright (C) 2001-2008 Shiro Takeda
;; Version: 3.1.1
;; svn:$Id:$ 
;; Time-stamp: <2009-10-11 19:42:01 Shiro Takeda>

;; Author: Shiro Takeda
;; Maintainer: Shiro Takeda
;; First Created: Sun Aug 19, 2001 12:48 PM

;; This file is not part of any Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; A copy of the GNU General Public License can be obtained from this
;; program's author or from the Free Software Foundation,
;; Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;;
;; 			See README file!
;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Code starts here.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(eval-and-compile
  (require 'easymenu))

;; From cl.el.
(unless (fboundp 'oddp)
  (defun oddp (x)
    "T if INTEGER is odd."
    (eq (logand x 1) 1)))
(unless (fboundp 'evenp)
  (defun evenp (x)
    "T if INTEGER is even."
    (eq (logand x 1) 0)))
(unless (fboundp 'list-length)
  (defun list-length (x)
    "Return the length of a list.  Return nil if list is circular."
    (let ((n 0) (fast x) (slow x))
      (while (and (cdr fast) (not (and (eq fast slow) (> n 0))))
	(setq n (+ n 2) fast (cdr (cdr fast)) slow (cdr slow)))
      (if fast (if (cdr fast) nil (1+ n)) n))))
;; 
(eval-and-compile
  ;; If customize isn't available just use defvar instead.
  (unless (fboundp 'defgroup)
    (defmacro defgroup  (&rest rest) nil)
    (defmacro defcustom (symbol init docstring &rest rest)
      `(defvar ,symbol ,init ,docstring)))
  
  ;; If `line-beginning-position' isn't available provide one.
  (unless (fboundp 'line-beginning-position)
    (defun line-beginning-position (&optional n)
      "Return the `point' of the beginning of the current line."
      (save-excursion
        (beginning-of-line n)
        (point))))

  ;; If `line-end-position' isn't available provide one.
  (unless (fboundp 'line-end-position)
    (defun line-end-position (&optional n)
      "Return the `point' of the end of the current line."
      (save-excursion
        (end-of-line n)
        (point))))
  ) ;; eval-and-compile ends.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Define variables.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst gams-mode-version "3.1.1"
  "Version of GAMS mode.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Define customizable variables.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;; Define groups.

(defgroup gams nil
  "Group of GAMS mode for Emacs."
  :group 'applications)

(defgroup gams-faces nil
  "Group of faces for GAMS mode."
  :group 'gams
  :group 'faces)

(defgroup gams-keys nil
  "Group of keybindings for GAMS mode."
  :group 'gams
  :group 'keyboard)

;;;;; Customizable variables start here.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Variables for GAMS mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcustom gams:process-command-name "gams"
  "*GAMS program file name.

If you do not include the GAMS system directory in PATH environmental
variable, you must set the full path to GAMS in this variable like

\"c:/GAMS20.0/gams.exe.\"."
  :type 'file
  :group 'gams)

(defcustom gams:process-command-option "ll=0 lo=3 pw=90 ps=9999"
  "*The command line options passed to GAMS.

If you are NTEmacs user, lo=3 option is necessary to show the GAMS
process."
  :type 'string
  :group 'gams)

(defcustom gams-statement-file "~/.gams-statement"
  "*The name of the file in which user specific statements are stored.
If you register new statements and dollar control options, they are saved
in the file specified by this variable."
  :type 'file
  :group 'gams)

(defcustom gams-system-directory "c:/GAMS20.0/"
  "*The GAMS system directory (the directory where GAMS is installed).
This must be assigned the proper value if you want to use
`gams-view-docs' and `gams-modlib'."
  :type 'file
  :group 'gams)

(defcustom gams-statement-upcase nil
  "*Non-nil means that statement is inserted in upper case.
If you want to use lower case, set nil to this variable."
  :type 'boolean
  :group 'gams)

(defcustom gams-dollar-control-upcase nil
  "*Non-nil means that dollar control option is inserted in upper case.
If you want to use lower case, set nil to this variable."
  :type 'boolean
  :group 'gams)

(defcustom gams-use-mpsge nil
  "*If you use MPSGE, set non-nil to this variable."
  :type 'boolean
  :group 'gams)

(defcustom gams-fill-column 74
  "*The column number used for fill-paragraph and auto-fill-mode."
  :type 'integer
  :group 'gams)

(defcustom gams-recenter-font-lock t
  "*If non-nil, font-lock-fontify-block when recentering.
If your computer is slow, you may better set this to nil."
  :type 'boolean
  :group 'gams)

(defcustom gams-file-extension '("gms")
  "*List of gams program file extensions.
If you open a file with an extension included in this list, GAMS mode
starts automatically.  It doen't matter whether upper case or lower
case.  For example,

(setq gams-file-extension '(\"gms\" \"dat\"))
"
  :type '(repeat (string :tag "value"))
  :group 'gams)

(defcustom gams-multi-process t
  "*Non-nil enables multiple GAMS processes.
Non-nil means that you can run multiple GAMS processes at the same time
in an Emacs.  If you rarely run multiple processes, you had better set it
to nil."
  :type 'boolean
  :group 'gams)
 
(defcustom gams-mode-hook  nil
  "*Hook run when gams-mode starts."
  :type 'hook
  :group 'gams)

;; from yatex.el
(defcustom gams-close-paren-always t
  "*Non-nil means that close parenthesis when you type `('."
  :type 'boolean
  :group 'gams)

(defcustom gams-close-double-quotation-always t
  "*Non-nil means that close double quotation when you type `\"'."
  :type 'boolean
  :group 'gams)

(defcustom gams-close-single-quotation-always nil
  "*Non-nil means that close quotation when you type `''."
  :type 'boolean
  :group 'gams)

(defcustom gams-statement-name "set"
  "*The initial value of statement insertion."
  :type 'string
  :group 'gams)

(defcustom gams-dollar-control-name "title"
  "*The initial value of dollar control insertion."
  :type 'string
  :group 'gams)
  
(defcustom gams-user-comment
  "
*------------------------------------------------------------------------	
* %       
*------------------------------------------------------------------------
"
  "*User defined comment template.
You can insert the comment template defined in this variable by executing
`gams-insert-comment'.  `%' in the string indicates the cursor place and
will disappear after template insertion.  NB: If you want to include
double quoatations and backslashes in this variable, plese escape them
with a slash \."
  :type 'string
  :group 'gams)

(defcustom gams-comment-column 40
  "*The default value of `comment-column' in GAMS mode."
  :type 'integer
  :group 'gams)

(defcustom gams-inlinecom-symbol-start-default "/*"
  "*The default value for the inline comment start symbol.
You can insert the inline comment with `gams-comment-dwim-inline'."
  :type 'string
  :group 'gams)

(defcustom gams-inlinecom-symbol-end-default "*/"
  "*The default value for the inline comment end symbol.
You can insert the inline comment with `gams-comment-dwim-inline'."
  :type 'string
  :group 'gams)

(defcustom gams-eolcom-symbol-default "#"
  "*The default value for the end-of-line comment symbol.
  You can insert the inline comment with `gams-comment-dwim'."
  :type 'string
  :group 'gams)

;;; from epolib.el
(defcustom gams-default-pop-window-height 14
  "*The default GAMS process buffer height.
If integer, sets the window-height of process buffer.  If string, sets the
percentage of it.  If nil, use default pop-to-buffer."
  :type 'integer
  :group 'gams)

(defcustom gams-docs-view-program
  "c:/Program Files/Adobe/Acrobat 5.0/Reader/AcroRd32.exe"
  "*The name of (or path to) the manual file viewer.
Normally, set the PDF file viewer to this variable.

GAMS ver.22 includes not only PDF manuals but also manuals of
windows help file (CHM file).  If you want to view such CHM
files, use the program such as cygstart.exe and fiber.exe instead
of PDF file viewer."
  :type 'file
  :group 'gams)

(defcustom gams-docs-directory
  (concat (file-name-as-directory gams-system-directory) "docs")
  "*The GAMS document directory.  By default, it is set to
`gams-system-directory' + docs."
  :type 'file
  :group 'gams)

(defcustom gams-insert-dollar-control-on nil
  "*Non-nil means that $ key is binded to inserting dollar control options.
If nil, $ key is binded to inserting dollar itself."
  :group 'gams
  :type 'boolean)

;;; New variable.
(defcustom gams-always-popup-process-buffer t
  "*Non-nil means popup always the GAMS process buffer when you run GAMS.
If nil, the GAMS process buffer does not popup unless you type `C-cC-l'."
  :type 'boolean
  :group 'gams)

(defcustom gams-sd-included-file t
  "If non-nil, `gams-show-identifier-defintion' searches the identifier
definition also in the files included through $include or $batinclude.  If
nil, search the identifier definition only in the current files."
  :type 'boolean
  :group 'gams)

;; (defcustom gams-distrbution-version "21.2"
;;   "Version number of GAMS distribution."
;;   :type 'number
;;   :group 'gams)

;; (defvar gams-dist-20 (string-match "20" gams-distrbution-version))
;; (defvar gams-dist-21 (string-match "21" gams-distrbution-version ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Variables for GAMS-TEMPLATE mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcustom gams-template-file "~/.gams-template"
  "*The name of a file used to store templates."
  :type 'file
  :group 'gams)
  
(defcustom gams-save-template-change nil
  "*Nil means save the content of `gams-user-template-alist' into
`gams-template-file' only when you quit Emacs.  If non-nil, save
`gams-user-template-alist' every time after you made any changes.  If your
Emacs often crashes, you may had better set it to non-nil."
  :type 'boolean
  :group 'gams)

(defcustom gams-template-cont-color nil
  "*Non-nil means colorization of *Template Content* buffer.
Non-nil makes the speed of template-mode very slow."
  :type 'boolean
  :group 'gams)

(defcustom gams-template-mark "%c"
  "*The mark that indicates the point of cursor in a template."
  :type 'string
  :group 'gams)

(defcustom gams-special-comment-symbol "com:"
  "*The symbol that indicates the special comment."
  :type 'string
  :group 'gams)

(defcustom gams-display-small-logo t
  "*If non-nil, display GAMS logo in the modeline."
  :type 'boolean
  :group 'gams)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Variables for font-lock.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcustom gams-font-lock-level 2
  "*The default level of colring in GAMS mode.
0 => no color.
1 => minimum.
2 => maximize."
  :group 'gams
  :type 'integer)

(defcustom gams-lst-font-lock-level 2
  "*The default level of coloring in GAMS-LST mdoe.
0 => no color.
1 => minimum.
2 => maximize."
  :group 'gams
  :type 'integer)

(defcustom gams-ol-font-lock-level 2
  "*The default level of coloring in GAMS-OUTLINE mode.
0 => no color.
1 => minimum.
2 => maximize."
  :group 'gams
  :type 'integer)

(defcustom gams-lst-mode-hook  nil
  "*GAMS-LST mode hooks."
  :type 'hook
  :group 'gams)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Variables for GAMS-LST mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar gams-lst-gms-extention  "gms"
  "*GAMS program file extention.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Variables for automatic indent.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcustom gams-indent-on t
  "*If non-nil, automatic indent for gams mode is enabled.
If nil, automatic indent doesn't work and tab key insert tab itself."
  :type 'boolean
  :group 'gams)

(defcustom gams-indent-number 8
  "*Indent number for general statemets."
  :type 'integer
  :group 'gams)

(defcustom gams-indent-number-loop 8
  "*Indent number in loop type environment.

loop type statement means \"loop\", \"if\", \"while\", \"for\" etc."
  :type 'integer
  :group 'gams)

(defcustom gams-indent-number-mpsge 8
  "*Indent number in mpsge type environment.

MPSGE type statement means \"$sector:\", \"$commodities:\", \"$prod:\"
etc."
  :type 'integer
  :group 'gams)

(defcustom gams-indent-number-equation 8
  "*Indent number for equation definition."
  :type 'integer
  :group 'gams)

(defcustom gams-indent-equation-on t
  "*Non-nil means indent equation blocks.
If nil, already written equations are not affected by `gams-indent-line'."
  :type 'boolean
  :group 'gams)

(defcustom gams-indent-more-indent nil
  "Non-nil means more indentation."
  :type 'boolean
  :group 'gams)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Variables for GAMS-OUTLINE mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcustom gams-ol-height 15
  "*The default height of the OUTLINE buffer with one LST buffer.

You can change the height of the OUTLINE buffer with
`gams-ol-narrow-one-line' and `gams-ol-widen-one-line'."
  :type 'integer
  :group 'gams)

(defcustom gams-ol-height-two 8
  "*The default height of the OUTLINE buffer with two LST buffers.

You can change the height of the OUTLINE buffer with
`gams-ol-narrow-one-line' and `gams-ol-widen-one-line'."
  :type 'integer
  :group 'gams)

(defcustom gams-ol-external-program nil
  "*The name of external program for creating GAMS-OUTLINE buffer.

If you use external program for GAMS-OUTLINE mode, you need the proper
value to this variable.

As the external program, you can use the C program (gamsolc.exe) or the
Perl script (gamsolperl.pl).  The C program works faster than the Perl
script, but the C program is offered only for MS windows (I cannot compile
the program with gcc on Unix).  The Perl script gamsolperl.pl works both
on MS windows and Unix systems as long as Perl5 is installed in that
system.  If you are MS windows user, use gamsolc.exe and if you are Unix
user, use gamsolperl.pl.

If you use the C program (gamsolc.exe). and it is localted at the
directory \"c:/home/gams\"

(setq gams-ol-external-program \"c:/home/gams/gamsolc.exe\")

If you use the Perl script gamsolperl.pl and it is located at the
directory \"c:/home/gams\"

(setq gams-ol-external-program \"c:/home/gams/gamsperl.pl\")

Moreover, you need to set the proper value to `gams-perl-command' if you
use gamsolperl.pl.

This variable matters only if you use the command `gams-outline-external'.
See the explanation of `gams-outline-external', too."
:type 'file
:group 'gams)

(defcustom gams-perl-command nil
  "*The Perl command name.

If you assign \"gamsolperlp.pl\" to `gams-ol-external-program', set the perl
program to this variable, e.g.

(setq gams-perl-command \"c:/Perl/bin/perl.exe\")

If the directory of perl is included in PATH environmental variable, then
just set the command name in stead of the full path:

(setq gams-perl-command \"perl\")

This variable matters only if you use the command `gams-outline-external'.
See the explanation of `gams-outline-external', too."
:type 'file
:group 'gams)

(defcustom gams-ol-view-item
      '(("SUM" . t)
	("VAR" . t)
	("EQU" . t)
	("PAR" . t)
	("SET" . t)
	("VRI" . t)
	("LOO" . t)
	("OTH" . t)
	("COM" . t)
	("INF" . t)
	)
  "The default alist of viewable items.

Each list consists of a pair of the item name and its flag

(\"ITEM_NAME\" . flag)

Non-nil of flag means the item is viewable by default.

The order of items has the meaning in this alist.  Items are listed in the
SELECT-ITEM buffer according to this order.  So, if you want to show MAR
on the top, you must write MAR at the fisrt in this alist."
  :type '(repeat (cons :tag "option" (string :tag "item") (boolean :tag "flag")))
  :group 'gams)

(defcustom gams-ol-item-name-width 20
  "The width of item name field in GAMS-OUTLINE."
  :type 'integer
  :group 'gams)

(defvar gams-ol-use-mouse t
  "Non-nil means use mouse click in GAMS-OUTLINE.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Variables for GAMS-LXI mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar gams-lxi-maximum-line 500000
  "The maximum number of lines for GAMS-LXI mode.
This determines the maximum number of lines of the LST file that
GAMS LXI mode loads.  If the number of lines of the LST file
exceeds this value, GAMS-LXI mode only loads a part of it.")
;;(setq gams-lxi-maximum-line 100000)

(defcustom gams-lxi-command-name "gamslxi.exe"
  "*File name of external program for creating the LXI file.

If you want to use GAMS-LXI mode, you need to set the proper
value to this variable.  If gamslxi.exe is placed at the
directory in PATH, you don't need change the default value.  If
gamslxi.exe is not placed at the directory in PATH, you need to
set the full path to gamslxi.exe, for example,

(setq gams-lxi-command-name \"~/lisp/gams/gamslxi.exe\")
"
:type 'file
:group 'gams)

(defcustom gams-lxi-import-command-name "gamslxi-import.exe"
  "*File name of external program for importing the LST file from
GAMS-LXI mode.

If you want to use GAMS-LXI mode, you need to set the proper
value to this variable.  If gamslxi-import.exe is placed at the
directory in PATH, you don't need change the default value.  If
gamslxi-import.exe is not placed at the directory in PATH, you
need to set the full path to gamslxi-import.exe, for example,

(setq gams-lxi-command-name \"~/lisp/gams/gamslxi-import.exe\")
"
:type 'file
:group 'gams)

(defcustom gams-lxi-extension "lxi"
  "The default extention used for the LXI file."
  :type 'string
  :group 'gams
  )

(defcustom gams-lxi-width 40
"*The default width of the GAMS-LXI buffer.
You can change the width of the LXI buffer with
`gams-lxi-narrow-one-line' and `gams-lxi-widen-one-line'."
  :type 'integer
  :group 'gams)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Define customizable variables end here.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Other variables.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;

(defvar gams-manuals-alist-base
  '(("User-Manual" . "GAMSUsersGuide.pdf")
    ("Solver-Manual (Table of Content)" . "gamssolvers.pdf")
    ("Tutorial" . "Tutorial.pdf")
    ("McCarl-User-Guide" . "mccarlgamsuserguide.pdf")
    ("BDMLP-Solver" . "bdmlp.pdf")
    ("CONOPT-Solver" . "conopt.pdf")
    ("CPLEX-Solver" . "cplex.pdf")
    ("DECIS-Solver" . "decis.pdf")
    ("DICOPT-Solver" . "dicopt.pdf")
    ("GAMSBAS-Solver" . "gamsbas.pdf")
    ("GAMSCHK-Solver" . "gamschk.pdf")
    ("MILES-Solver" . "miles.pdf")
    ("MINOS-Solver" . "minos.pdf")
    ("MPSGE-Solver" . "mpsge.pdf")
    ("MPSWRITE-Solver" . "mpswrite.pdf")
    ("OSL-Solver" . "osl.pdf")
    ("OSLSE-Solver" . "oslse.pdf")
    ("PATH-Solver" . "path.pdf")
    ("SBB-Solver" . "sbb.pdf")
    ("SNOPT-Solver" . "snopt.pdf")
    ("SOLVERINTRO-Solver" . "solverintro.pdf")
    ("XA-Solver" . "xa.pdf")
    ("XPRESS-Solver" . "xpress.pdf")
    ("XPRESSLICENSING-Solver" . "xpresslicensing.pdf")
    ("Ask-Tool" . "ask.pdf")
    ("GAMSIDE-Tool" . "gamside.pdf")
    ("GDX2ACESS-Tool" . "gdx2access.pdf")
    ("GDXUTILS-Tool" . "gdxutils.pdf")
    ("GDXVIEWER-Tool" . "gdxviewer.pdf")
    ("MDB2GMS-Tool" . "mdb2gms.pdf")
    ("SHELLEXECUTE-Tool" . "shellexecute.pdf")
    ("SQL2GMS-Tool" . "sql2gms.pdf")
    ("XLS2GMS-Tool" . "xls2gms.pdf")
    ("Windows-Install" . "win-install.pdf")
    ("Unix-Install" . "unix-install.pdf")
    ("PC-Install" . "pc-install.pdf")
    )
  )

(defvar gams-statement-up
      '("SET" "SETS" "SCALAR" "SCALARS" "TABLE" "PARAMETER" "PARAMETERS"
	"EQUATION" "EQUATIONS" "VARIABLE" "VARIABLES"
	"POSITIVE VARIABLE" "POSITIVE VARIABLES"
	"NEGATIVE VARIABLE" "NEGATIVE VARIABLES"
	"INTEGER VARIABLE" "INTEGER VARIABLES"
	"BINARY VARIABLE" "BINARY VARIABLES"
	"ALIAS"
	"OPTION"
	"EXECUTE_UNLOAD"
	"SOLVE" "MODEL" "DISPLAY" "LOOP" "IF" "SUM" "PROD")
      "*The default list of GAMS statements.  Used for candidate of statement inserting.
Use upper case to register statements in this variable.")

(defvar gams-dollar-control-up
  '("BATINCLUDE" "EXIT" "INCLUDE" "LIBINCLUDE"
    "OFFTEXT" "ONTEXT" "SETGLOBAL" "SYSINCLUDE"
    "TITLE")
  "The default list of GAMS dollar control options.
Used for candidate of dollar control inserting.  Use upper case to
register dollar control options in this variable.")

(defvar gams-statement-mpsge
    ; MPSGE
  '("MODEL:" "COMMODITIES:" "CONSUMERS:" "CONSUMER:" "SECTORS:" "SECTOR:" "PROD:"
    "DEMAND:" "REPORT:" "CONSTRAINT:" "AUXILIARY:")
  "The default list of MPSGE statements.
Used for candidate of MPSGE dollar control inserting.  Use upper case to
register mpsge statements in this variable.")

(defvar gams-run-key ?s
  "*Key to run GAMS in the process menu.")
(defvar gams-kill-key ?k
  "*Key to kill GAMS process in the process menu.")
(defvar gams-option-key ?o
  "*Key to select command option in the process menu.")
(defvar gams-change-command-key ?c
  "*Key to select GAMS command in the process menu.")

;;;;; Key bindgings.
(defcustom gams-olk-1 "?"
  "*Key for `gams-ol-help'."
  :type 'string
  :group 'gams-keys)

(defcustom gams-olk-4 "t"
  "*Key for `gams-ol-select-item'."
  :type 'string
  :group 'gams-keys)

(defcustom gams-olk-5 " "
  "*Key for `gams-ol-view-base'."
  :type 'string
  :group 'gams-keys)

(defcustom gams-olk-6 "q"
  "*Key for `gams-ol-quit'."
  :type 'string
  :group 'gams-keys)

(defcustom gams-olk-7 "m"
  "*Key for `gams-ol-mark'."
  :type 'string
  :group 'gams-keys)

(defcustom gams-olk-8 "T"
  "*Key for `gams-ol-item'."
  :type 'string
  :group 'gams-keys)

;;; Key for GAMS-LST mode.
(defcustom gams-lk-1 "i"
  "Key for `gams-lst-jump-to-input-file'."
  :type 'string
  :group 'gams-keys)

(defcustom gams-lk-2 "u"
  "Key for `gams-lst-jump-to-error-file'."
  :type 'string
  :group 'gams-keys)

(defcustom gams-lk-3 "y"
  "Key for `gams-lst-view-error'."
  :type 'string
  :group 'gams-keys)

(defcustom gams-lk-4 "b"
  "Key for `gams-lst-jump-to-input-file-2'."
  :type 'string
  :group 'gams-keys)

(defcustom gams-lk-5 "l"
  "Key for `gams-lst-jump-to-line'."
  :type 'string
  :group 'gams-keys)

(defcustom gams-choose-font-lock-level-key "\C-c\C-f"
  "*The keybinding for `gams-choose-font-lock-level'."
  :type 'string
  :group 'gams-keys)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Non-customizable variables.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	It is not recommended to change the values of variables below.
;;	They are basically intended to be used internally.
;;

;;; Buffer local variables for end-of-line and inline comments
;;;###autoload
(defvar gams-inlinecom-symbol-start nil
  "*The inline comment start symbol (buffer local.
You can insert the inline comment with `gams-comment-dwim-inline'.")
;;;###autoload(put 'gams-inlinecom-symbol-start 'safe-local-variable 'string-or-null-p)

;;;###autoload
(defvar gams-inlinecom-symbol-end nil
  "*The value for the inline comment end symbol.
You can insert the inline comment with `gams-comment-dwim-inline'.")
;;;###autoload(put 'gams-inlinecom-symbol-end 'safe-local-variable 'string-or-null-p)

;;;###autoload
(defvar gams-eolcom-symbol nil
  "*The value for the end-of-line comment symbol.
  You can insert the inline comment with `gams-comment-dwim'.")
;;;###autoload(put 'gams-eolcom-symbol 'safe-local-variable 'string-or-null-p)

(setq-default gams-eolcom-symbol nil)
(setq-default gams-inlinecom-symbol-start nil)
(setq-default gams-inlinecom-symbol-end nil)

(defvar gams-statement-file-already-read nil)
(if (and (not gams-statement-file-already-read)
	 (file-exists-p gams-statement-file))
    (condition-case err
	(progn
	  (load-file gams-statement-file)
	  (setq gams-statement-file-already-read t))
      (error
       (message "Error(s) in %s!  Need to check; %s"
	    gams-statement-file (error-message-string err))
       (sleep-for 1))))

;; Variables for representing (X)Emacs versions.
(defvar gams-xemacs (string-match "XEmacs" emacs-version))
(defvar gams-emacs (if gams-xemacs nil t))
(defvar gams-win32 (memq system-type '(ms-dos windows-nt)))
(defvar gams-dos (memq system-type '(ms-dos windows-nt OS/2)))
(defvar gams-emacs-19 (and gams-emacs (= emacs-major-version 19)))
(defvar gams-emacs-20 (and gams-emacs (= emacs-major-version 20)))
(defvar gams-emacs-21 (and gams-emacs (= emacs-major-version 21)))
(defvar gams-emacs-21.2 (and gams-emacs (string-match "21.2" emacs-version)))
(defvar gams-emacs-21.3 (and gams-emacs (string-match "21.3" emacs-version)))
(defvar gams-emacs-22 (and gams-emacs (= emacs-major-version 22)))
(defvar gams-emacs-23 (and gams-emacs (= emacs-major-version 23)))
(defvar gams-xemacs-21 (and gams-xemacs (= emacs-major-version 21)))

;;; If Emacs 20, define `gams-replace-regexp-in-string'.  This code is
;;; `replace-regexp-in-string' from subr.el in the Emacs 21 distribution.
(if (fboundp 'replace-regexp-in-string)
    (fset 'gams-replace-regexp-in-string 'replace-regexp-in-string)
  (defun gams-replace-regexp-in-string (regexp rep string &optional
						 fixedcase literal subexp start)
      "Replace all matches for REGEXP with REP in STRING.

This code is from subr.el in Emacs 21 distribution.

Return a new string containing the replacements.

Optional arguments FIXEDCASE, LITERAL and SUBEXP are like the
arguments with the same names of function `replace-match'.  If START
is non-nil, start replacements at that index in STRING.

REP is either a string used as the NEWTEXT arg of `replace-match' or a
function.  If it is a function it is applied to each match to generate
the replacement passed to `replace-match'; the match-data at this
point are such that match 0 is the function's argument.

To replace only the first match (if any), make REGEXP match up to \\'
and replace a sub-expression, e.g.
  (replace-regexp-in-string \"\\(foo\\).*\\'\" \"bar\" \" foo foo\" nil nil 1)
    => \" bar foo\"
"
      ;; To avoid excessive consing from multiple matches in long strings,
      ;; don't just call `replace-match' continually.  Walk down the
      ;; string looking for matches of REGEXP and building up a (reversed)
      ;; list MATCHES.  This comprises segments of STRING which weren't
      ;; matched interspersed with replacements for segments that were.
      ;; [For a `large' number of replacments it's more efficient to
      ;; operate in a temporary buffer; we can't tell from the function's
      ;; args whether to choose the buffer-based implementation, though it
      ;; might be reasonable to do so for long enough STRING.]
      (let ((l (length string))
	    (start (or start 0))
	    matches str mb me)
	(save-match-data
	  (while (and (< start l) (string-match regexp string start))
	    (setq mb (match-beginning 0)
		  me (match-end 0))
	    ;; If we matched the empty string, make sure we advance by one char
	    (when (= me mb) (setq me (min l (1+ mb))))
	    ;; Generate a replacement for the matched substring.
	    ;; Operate only on the substring to minimize string consing.
	    ;; Set up match data for the substring for replacement;
	    ;; presumably this is likely to be faster than munging the
	    ;; match data directly in Lisp.
	    (string-match regexp (setq str (substring string mb me)))
	    (setq matches
		  (cons (replace-match (if (stringp rep)
					   rep
					 (funcall rep (match-string 0 str)))
				       fixedcase literal str subexp)
			(cons (substring string start mb) ; unmatched prefix
			      matches)))
	    (setq start me))
	  ;; Reconstruct a string from the pieces.
	  (setq matches (cons (substring string start l) matches)) ; leftover
	  (apply #'concat (nreverse matches))))))

;; For `make-overlay'.
(eval-and-compile
  (when gams-xemacs
    (require 'overlay)))

;; For `find-lisp-find-files'.
(eval-and-compile
  (require 'find-lisp))

(defvar gams-lst-extention "lst"
  "GAMS LST file extention.")

(defvar gams-fill-prefix nil
  "fill-prefix used for auto-fill-mode.
The default value is nil.")

(defvar gams-user-statement-list nil)
(defvar gams-user-dollar-control-list nil)
;; (defvar gams-paragraph-start "[ \t]*$\\|^[\f\n]")
(setq-default gams-paragraph-start "^\f\\|$\\|^[*]")
(defvar gams*command-process-buffer "*GAMS")
(defvar gams-statement-down
  (mapcar 'downcase gams-statement-up))
(defvar gams-dollar-control-down
  (mapcar 'downcase gams-dollar-control-up))
(defvar gams-statement-alist nil "?")
(defvar gams-dollar-control-alist nil "?")
(defvar gams-statement-regexp nil)

;;; From EPO. 
(defconst gams:frame-feature-p
  (and (fboundp 'make-frame) window-system))

;; This regular expression
(defun gams-regexp-opt (strings &optional paren)
  (if gams-xemacs
      (regexp-opt strings paren)
;      (regexp-opt strings paren t) ;; For old XEmacs.
    (regexp-opt strings paren)))
   
(if (boundp 'w32-system-shells)
    (setq gams:w32-system-shells
	  (gams-regexp-opt w32-system-shells))
  (setq gams:w32-system-shells "command.com\\|cmd.exe\\|start.exe"))

;;; From yatexprc.el.
(defvar gams:shell-c
  (or (and (boundp 'shell-command-option) shell-command-option)
      (and (boundp 'shell-command-switch) shell-command-switch)
      (if (string-match gams:w32-system-shells shell-file-name)
	  "/c" "-c"))
  "Return shell option for command execution.")

;; Set `gams*buffer-substring' to `buffer-substring-no-properties' if it
;; exits.  Otherwise set to `buffer-substring'.
(if (fboundp 'buffer-substring-no-properties)
    (fset 'gams*buffer-substring 'buffer-substring-no-properties)
  (fset 'gams*buffer-substring 'buffer-substring))

(cond
 ((fboundp 'screen-height)
  (fset 'gams*screen-height 'screen-height)
  (fset 'gams*screen-width 'screen-width))
 ((fboundp 'frame-height)
  (fset 'gams*screen-height 'frame-height)
  (fset 'gams*screen-width 'frame-width))
 (t (error "I don't know how to run GAMS on this Emacs...")))

;;; (defvar gams-mode-syntax-table nil
;;;   "Syntax table for gams-mode.")

;;; Autoload setting.
; For autoloading of GAMS mode.
(setq auto-mode-alist
	(cons
	 (cons
	  (format "\\.\\(xyz\\|%s\\)$"
		  (regexp-opt (append (mapcar 'downcase gams-file-extension)
					   (mapcar 'upcase gams-file-extension))))
	  'gams-mode) auto-mode-alist))
(autoload 'gams-mode "gams" "Enter GAMS mode" t)

; For GAMS-LST mode.
(setq auto-mode-alist
	(cons (cons "\\.\\(LST\\|lst\\)$" 'gams-lst-mode) auto-mode-alist))
(autoload 'gams-lst-mode "gams" "Enter GAMS-LST mode" t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Code for font-lock.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;; Define faces.
(defvar gams-mpsge-face 'gams-mpsge-face
  "Face for MPSGE statements.")
(defvar gams-misc-face	'gams-misc-face
  "Face for misc.")
(defvar gams-comment-face 'gams-comment-face
  "Face for comment.")
(defvar gams-dollar-face 'gams-dollar-face
  "Face for dollar control options.")
(defvar gams-statement-face 'gams-statement-face
  "Face for GAMS statments.")
(defvar gams-lst-par-face 'gams-lst-par-face
  "Face for PARAMETER in GAMS-LST mode.")
(defvar gams-lst-set-face 'gams-lst-set-face
  "Face for PARAMETER in GAMS-LST mode.")
(defvar gams-lst-var-face 'gams-lst-var-face
  "Face for VAR in GAMS-LST mode.")
(defvar gams-lst-equ-face 'gams-lst-equ-face
  "Face for EQU in GAMS-LST mode.")
(defvar gams-lst-vri-face 'gams-lst-vri-face
  "Face for VARIABEL in GAMS-LST mode.")
(defvar gams-lst-oth-face 'gams-lst-oth-face
  "Face for OTH entry in GAMS-OUTLINE mode.")
(defvar gams-lst-warning-face 'gams-lst-warning-face
  "Face for warning in GAMS-LST mode.")
(defvar gams-lst-program-face 'gams-lst-program-face
  "Face for program listing in GAMS-LST mode.")
(defvar gams-ol-loo-face 'gams-ol-loo-face
  "Face for program listing in GAMS-LST mode.")
(defvar gams-string-face 'gams-string-face
  "Face for string.")
(defvar gams-operator-face 'gams-operator-face
  "Face for operator.")
(defvar gams-slash-face 'gams-slash-face
  "Face for set and parameter elements lying between slashes.")
(defvar gams-explanation-face 'gams-explanation-face
  "Face for explanatory texts in GAMS mode.")
(defvar gams-oth-cont-face 'gams-oth-cont-face
  "Face for the content of OTH item in GAMS-OUTLINE mode.")
(defvar gams-title-face 'gams-title-face
  "Face for $title in GAMS mode.")
(defvar gams-highline-face 'gams-highline-face
  "*Symbol face used to highlight the current line.")
(defvar gams-highline-sub-face 'gams-highline-sub-face
  "*Symbol face used to highlight the current line.")
(defvar gams-sil-mpsge-face 'gams-sil-mpsge-face)
(defvar gams-sil-dollar-face 'gams-sil-dollar-face)
(defvar gams-func-face 'gams-func-face)
(defvar gams-def-face 'gams-def-face)

(defvar gams-dollar-regexp
  (gams-regexp-opt
   (list
    "comment" "eolcom" "gdxin" "gdxout" "inlinecom" "maxcol" "mincol" "offeolcom"
    "macro" 
    "offinline" "offmargin" "offnestcom" "offtext" "onelcom" "oninline"
    "onmargin" "onnestcom" "ontext" "dollar" "offdigit" "offempty"
    "offend" "offeps" "offglobal" "offwarning" "ondigit" "onempty" "onend"
    "oneps" "onglobal" "onwarning" "use205" "use225" "use999" "double"
    "eject" "hidden" "lines" "load" "loaddc" "offdollar" "offinclude" "offlisting"
    "offupper" "ondollar" "oninclude" "onlisting" "onupper" "single"
    "stars" "stitle" "title" "offsymlist" "offsymxref" "offuellist"
    "offuelxref" "onsymlist" "onsymxref" "onuellist" "onuelxref" "abort"
    "batinclude" "call" "clear" "echo" "error" "exit" "goto" "if" "if exist"
    "include" "kill" "label" "libinclude" "onglobal" "onmulti" "offglobal"
    "offmulti" "phantom" "set" "setglobal" "setlocal" "shift" "sysinclude") t))

(defvar gams-mpsge-regexp
  (gams-regexp-opt
    gams-statement-mpsge t)
  "Regular expression for mpsge dollar control")

(defvar gams-statement-regexp-base-sub
  (gams-regexp-opt
   (list
    "abort" "acronym" "acronyms" "alias" "assign" "binary" "diag"
    "display" "equation" "equations" "execute_unload" "integer" "loop"
    "model" "models"
    "negative" "option" "options" "parameter" "parameters" "positive"
    "sameas" "scalar" "scalars" "set" "sets" "sos1" "sos2" "system"
    "table" "variable" "variables" "xor" "repeat" "until" "while" "if"
    "then" "else" "elseif" "semicont" "semiint" "file" "files" "put"
    "putpage" "puttl" "free" "solve" "for" "errorf" "floor" "mapval" "mod"
    "putclose"
    ) t)
  "Regular expression for reserved words.")

(defvar gams-statement-list-base
  (list "abort" "acronym" "acronyms" "alias" "all" "and" "assign" "binary"
	"card" "diag" "display" "eps" "eq" "equation" "equations"
	"execute_unload" "ge" "gt"
	"inf" "integer" "le" "loop" "lt" "maximising" "maximizing"
	"minimising" "minimizing" "model"
	"models" "na" "ne" "negative" "not" "option" "options" "or" "ord"
	"parameter" "parameters" "positive" "prod" "sameas" "scalar" "scalars"
	"set" "sets" "smax" "smin" "sos1" "sos2" "sum" "system" "table"
	"using" "variable" "variables" "xor" "yes" "repeat" "until" "while"
	"if" "then" "else" "elseif" "semicont" "semiint" "file" "files" "put"
	"putpage" "puttl" "free" "no" "solve" "for" "abort" "abs" "arctan"
	"ceil" "cos" "errorf" "exp" "floor" "log" "log10" "mapval" "max" "min"
	"mod" "normal" "power" "round" "sign" "sin" "sqr" "sqrt" "trunc"
	"uniform" "putclose"))

(defvar gams-statement-regexp-base
  (gams-regexp-opt gams-statement-list-base t)
  "Regular expression for statements
It is used for font-lock.")      

(defvar gams-statement-regexp-1
  (concat "^[ \t]*" gams-statement-regexp-base "[^-a-zA-Z0-9_:*]+")
  "Regular expression for GAMS statements
It is used for font-lock of level 1.")
      
(defvar gams-statement-regexp-2
  (concat "\\(^\\|[\n]\\|[^-$a-zA-Z0-9_]+\\)"
	  gams-statement-regexp-base "[^-a-zA-Z0-9_:*]+")
  "Regular expression for GAMS statements
It is used for font-lock of level 2.")

;;; GAMS mode.

(defface gams-comment-face
  '((((class color) (background light))
     (:bold nil :foreground "#009000"))
    (((class color) (background dark))
     (:bold nil :italic nil :foreground "green")))
  "Face for commented out texts."
  :group 'gams-faces)

(defface gams-mpsge-face
  '((((class color) (background light))
     (:bold nil :foreground "#2080e0"))
    (((class color) (background dark))
     (:bold nil :foreground "hot pink")))
  "Face for MPSGE statements."
  :group 'gams-faces)

(defface gams-statement-face
  '((((class color) (background light))
     (:bold nil :foreground "#0000e0"))
    (((class color) (background dark))
     (:bold nil :foreground "cyan")))
  "Face for GAMS statements."
  :group 'gams-faces)

(defface gams-dollar-face
  '((((class color) (background light))
     (:bold nil :foreground "dark orange"))
    (((class color) (background dark))
     (:bold nil :foreground "yellow")))
  "Face for dollar control options."
  :group 'gams-faces)

(defface gams-string-face
  '((((class color) (background light))
     (:bold nil :foreground "#a000a0"))
    (((class color) (background dark))
     (:bold nil :italic nil :foreground "orange")))
  "Face for quoted string in GAMS mode."
  :group 'gams-faces)

(defface gams-operator-face
  '((((class color) (background light))
     (:bold nil :foreground "#e00000"))
    (((class color) (background dark))
     (:bold nil :foreground "#ccaaff")))
  "Face for operators in GAMS mode."
  :group 'gams-faces)

(defface gams-slash-face
  '((((class color) (background light))
     (:bold nil :foreground "#f00090"))
    (((class color) (background dark))
     (:bold nil :italic nil :foreground "light pink")))
  "Face for set and parameter elements lying between slashes."
  :group 'gams-faces)

(defface gams-explanation-face
  '((((class color) (background light))
     (:bold nil :foreground "#c09000"))
    (((class color) (background dark))
     (:bold nil :italic nil :foreground "khaki")))
  "Face for explanatory texts in GAMS mode."
  :group 'gams-faces)

(defface gams-oth-cont-face
  '((((class color) (background light))
     (:bold nil :foreground "gray50"))
    (((class color) (background dark))
     (:bold nil :foreground "khaki")))
  "Face for the content of OTH item in GAMS-OUTLINE mode."
  :group 'gams-faces)

(defface gams-title-face
  '((((class color) (background light))
     (:bold nil :underline t :foreground "#0000a0" :background "#ffffd0"))
    (((class color) (background dark))
     (:bold nil :underline t :italic nil
	      :foreground "#ffd0ff" :background "#000050")))
  "Face for the content of OTH item in GAMS-OUTLINE mode."
  :group 'gams-faces)

(defface gams-highline-face
  '((((class color) (background light))
     (:bold nil :foreground "#202020" :background "PaleGreen1"))
    (((class color) (background dark))
     (:bold t :italic nil :underline t :foreground "yellow")))
  "Face for highline."
  :group 'gams-faces)

;;; GAMS-LST mode.
(defface gams-lst-par-face
  '((((class color) (background light))
     (:bold t :foreground "DodgerBlue"))
    (((class color) (background dark))
     (:bold t :foreground "yellow")))
  "Faces for PARAMETER entry in GAMS-LST mode."
  :group 'gams-faces)

(defface gams-lst-set-face
  '((((class color) (background light))
     (:bold t :foreground "light blue"))
    (((class color) (background dark))
     (:bold t :foreground "sandy brown")))
  "Face for SET entry in GAMS-LST mode."
  :group 'gams-faces)

(defface gams-lst-var-face
  '((((class color) (background light))
     (:bold t :foreground "hot pink"))
    (((class color) (background dark))
     (:bold t :foreground "cyan")))
  "Face for VAR endtry in GAMS-LST mode."
  :group 'gams-faces)

(defface gams-lst-equ-face
  '((((class color) (background light))
     (:bold t :foreground "lime green"))
    (((class color) (background dark))
     (:bold t :foreground "pink")))
  "Face for EQU entry in GAMS-LST mode."
  :group 'gams-faces)

(defface gams-lst-vri-face
  '((((class color) (background light))
     (:bold t :foreground "purple"))
    (((class color) (background dark))
     (:bold t :foreground "pale green")))
  "Face for VARIABLE entry in GAMS-LST mode."
  :group 'gams-faces)

(defface gams-lst-oth-face
  '((((class color) (background light))
     (:bold t :foreground "gray60"))
    (((class color) (background dark))
     (:bold t :italic nil :foreground "bisque")))
  "Face for ?"
  :group 'gams-faces)

(defface gams-lst-warning-face
  '((((class color) (background light))
     (:bold t :foreground "red"))
    (((class color) (background dark))
     (:bold t :foreground "red")))
  "Face for warnings in GAMS-LST mode."
  :group 'gams-faces)

(defface gams-lst-program-face
  '((((class color) (background light)) (:foreground "goldenrod"))
    (((class color) (background dark)) (:foreground "khaki")))
  "Face for copied program listing in GAMS-LST mode."
  :group 'gams-faces)

(defface gams-ol-loo-face
  '((((class color) (background light))
     (:bold t :foreground "maroon"))
    (((class color) (background dark))
     (:bold t :foreground "#7777ff")))
  "Face for LOO entry in GAMS-OUTLINE mode."
  :group 'gams-faces)

(defface gams-highline-sub-face
  '((((class color) (background light))
     (:foreground "#202020" :background "misty rose"))
    (((class color) (background dark))
     (:bold t :italic nil :underline t :foreground "pink")))
  "Face for highline."
  :group 'gams-faces)

(defface gams-sil-mpsge-face
    '((((class color) (background light))
       (:bold nil :foreground "#2080e0"))
      (((class color) (background dark))
       (:bold nil :italic nil :foreground "hot pink")))
  "Face for MPSGE statements."
  :group 'gams-faces)

(defface gams-sil-dollar-face
    '((((class color) (background light))
       (:bold nil :foreground "dark orange"))
      (((class color) (background dark))
       (:bold nil :italic nil :foreground "#ffa0ff")))
  "Face for dollar control in SIL mode."
  :group 'gams-faces)

(defface gams-func-face
    '((((class color) (background light))
       (:bold nil :foreground "pink"))
      (((class color) (background dark))
       (:bold nil :italic nil :foreground "#ff30ff")))
  "Face for ==."
  :group 'gams-faces)

(defface gams-def-face
    '((((class color) (background light))
       (:bold nil :foreground "blue" :bold t))
      (((class color) (background dark))
       (:bold t :italic nil :foreground "white")))
  "Face for equation definition part in GAMS-??."
  :group 'gams-faces)

(defvar gams-font-lock-keywords nil)
(defvar gams-lst-font-lock-keywords nil)
(defvar gams-ol-font-lock-keywords nil)

(defvar gams-regexp-declaration-2
      "\\(parameter\\|set\\|scalar\\|table\\|\\(free\\|positive\\|negative\\|binary\\|integer\\)*[ ]*variable\\|equation\\|model\\|file\\)[s]?")

;; gams-lst
(defsubst gams-store-point-sol-sum (limit)
  "Store points for font-lock for SOLVE SUMMARY in OUTLINE mode."
  (let (beg end)
    (when (re-search-forward "SUM[ \t]+\\(SOLVE SUMMARY[ \t]+SOLVER[ \t]+STATUS[ \t]+=\\( [^1]\\| [1][0-9]+\\| 1, MODEL STATUS = [^128]\\)\\)" limit t)
      (setq beg (match-beginning 1))
      (setq end (line-end-position))
      (store-match-data (list beg end))
      t)))

(defsubst gams-store-point-rep-sum (limit)
  "Store points for font-lock for REPORT SUMMARY in OUTLINE mode."
  (let (beg end)
    (when (re-search-forward "SUM[ \t]+\\(REPORT SUMMARY[ \t]+[[]\\([^0]\\|0, [^0]\\|0, 0, [^0]\\|0, 0, 0, [^0]\\|0, 0, 0, 0, [^0]\\)\\)" limit t)
      (setq beg (match-beginning 1))
      (setq end (line-end-position))
      (store-match-data (list beg end))
      t)))

;;;;; Functions for storing points for font-lock.

(defsubst gams-font-lock-commented-outp (&optional back)
  "Return t is comment character is found between bol and point."
  (save-excursion
    (let ((limit (point)))
      (save-match-data
        ;; Handle outlined code
	(if back
	    (goto-char back)
	  (re-search-backward "^\\|\C-m" (point-min) t))
	(if (re-search-forward
	     (concat "^[" gams-comment-prefix "]") limit t)
	    t nil)))))

(defun gams-font-lock-match-regexp (keywords limit beg end)
  "Search for regexp command KEYWORDS before LIMIT.
Returns nil if none of KEYWORDS is found."
  (let (bb ee flag)
    (catch 'found
      (while t
	(if (not (re-search-forward keywords limit t))
	    (progn (setq flag nil)
		   (throw 'found t))
	  (goto-char (setq bb (match-beginning 0)))
	  (setq ee (match-end 0))
	  (cond
	   ((or (gams-font-lock-commented-outp (match-beginning 0))
		(gams-in-on-off-text-p))
	    ;; Return a nul match such that we skip over this pattern.
	    ;; (Would be better to skip over internally to this function)
	    (store-match-data (list nil nil))
	    (goto-char ee))
	   (t
	    (let ((bb (match-beginning beg))
		  (ee (match-end end)))
	      (store-match-data (list bb ee))
	      (goto-char ee)
	      (setq flag t)
	      (throw 'found t)))))))
    flag))

(defun gams-store-point-statement-1 (limit)
  "Store points for font-lock for GAMS statements.  Level 1."
  (gams-font-lock-match-regexp gams-statement-regexp-1 limit 1 1))

(defun gams-store-point-statement-2 (limit)
  "Store points for font-lock for GAMS statements.  Level 2."
  (gams-font-lock-match-regexp gams-statement-regexp-2 limit 2 2))

(defun gams-store-point-dollar (limit)
  "Store points for font-lock for dollar control options."
  (gams-font-lock-match-regexp
   (concat "\\(^\\|[^a-zA-Z0-9]+\\)\\([$]\\)[ \t]*"
	   gams-dollar-regexp
	   "[^a-zA-Z0-9$*]")
   limit 2 3))

(defun gams-store-point-single-quote (limit)
  "Store points for font-lock for texts in single quotations."
  (when gams-comment-prefix
      (gams-font-lock-match-regexp "[ \t(,]?\\(\'[^\n\']+\'\\)[), ;:\t\n]" limit 1 1)))

(defun gams-store-point-double-quote (limit)
  "Store points for font-lock for texts in double quotations."
  (when gams-comment-prefix
      (gams-font-lock-match-regexp "[ \t(,]?\\(\"[^\n\"]+\"\\)[), ;:\t\n]" limit 1 1)))

(defun gams-store-point-special-comment (limit)
  "Store points for font-lock for comment."
  (let ((key
	 (concat "\\(----[ ]+[0-9]+[ ]+"
		 (regexp-quote gams-special-comment-symbol)
		 "[^\n]*\\)")))
    (when (re-search-forward key limit t)
      (let ((beg (match-beginning 1))
	    (end (match-end 1)))
	(store-match-data (list beg end))
	t))))

(defvar gams-font-lock-keywords-1
;; (setq gams-font-lock-keywords-1
      '(
	;; Conditional dollar.
	("[$]" (0 gams-dollar-face))
	;; Operator
	("=\\(e\\|g\\|l\\|n\\)=" (0 gams-operator-face))
	;; Commented out text by ! in MPSGE code
 	(gams-store-point-mpsge-comment (0 gams-comment-face t t))
	;; Standard GAMS statements.
	(gams-store-point-statement-1 (0 gams-statement-face nil t))
	;; Dollar control options.
	(gams-store-point-dollar (0 gams-dollar-face append t t))
	;; Explanatory texts.
	(gams-store-point-explanation (0 gams-explanation-face t t))
	;; Text in single quoatations.
	(gams-store-point-single-quote (0 gams-string-face t t))
	;; Text in double quoatations.
	(gams-store-point-double-quote (0 gams-string-face t t))
	;; End-of-line comment.
	(gams-store-point-eolcom (0 gams-comment-face t t))
	;; Inline comment.
	(gams-store-point-inlinecom (0 gams-comment-face t t))
	;; semicolon
	(";" (0 gams-lst-warning-face))
	;; Commented out texts by $hidden
	(gams-store-point-hidden-comment (0 gams-comment-face t t))
	;; Commented out texts by *
	(gams-store-point-comment (0 gams-comment-face t t))
	;; MPSGE dollar control options.
	("\\$\\(AUXILIARY\\|CO\\(MMODITIES\\|NS\\(TRAINT\\|UMERS?\\)\\)\\|DEMAND\\|E\\(CHOP\\|ULCHK\\)\\|FUNLOG\\|MODEL\\|P\\(EPS\\|ROD\\)\\|REPORT\\|SECTORS?\\|WALCHK\\):"
	 (0 gams-mpsge-face t t))
	;; the ontext - offtext pair.
	(gams-store-point-ontext (0 gams-comment-face t t))
	)
     "Font lock keyboards for GAMS mode.  Level 1.")
;;       )

(defvar gams-font-lock-keywords-2
;;(setq gams-font-lock-keywords-2
      '(
	;; Operator
	("=\\(e\\|g\\|l\\|n\\)=" (0 gams-operator-face))
	;; Semicolon
	(";" (0 gams-lst-warning-face))
	;; Conditional dollar.
	("[$]" (0 gams-dollar-face))
	;; Standard GAMS statements.
	(gams-store-point-statement-2
	 (0 gams-statement-face nil t))
	;; Conditional dollar.
	("[$]" (0 gams-dollar-face t t))
	;; Explanatory texts.
	(gams-store-point-explanation (0 gams-explanation-face t t))
	;; texts in slash pair.
	(gams-store-point-slash (0 gams-slash-face t t))
	;; Dollar control options.
	(gams-store-point-dollar (0 gams-dollar-face t t))
	;; Commented out text by ! in MPSGE code
 	(gams-store-point-mpsge-comment (0 gams-comment-face t t))
	;; Text in double quoatations.
	(gams-store-point-double-quote (0 gams-string-face t t))
	;; Text in single quoatations.
	(gams-store-point-single-quote (0 gams-string-face t t))
	;; Inline comment.
	(gams-store-point-inlinecom (0 gams-comment-face t t))
	;; End-of-line comment.
	(gams-store-point-eolcom (0 gams-comment-face t t))
	;; title and stitle.
	("^[$][s]?title[^\n]*$" (0 gams-title-face t t))
	;; Commented out texts by $hidden
	(gams-store-point-hidden-comment (0 gams-comment-face t t))
	;; Commented out texts by *
	(gams-store-point-comment (0 gams-comment-face t t))
	;; MPSGE dollar control options.
	("^\\$\\(AUXILIARY\\|CO\\(MMODITIES\\|NS\\(TRAINT\\|UMERS?\\)\\)\\|DATECH\\|DEMAND\\|E\\(CHOP\\|ULCHK\\)\\|FUNLOG\\|MODEL\\|P\\(EPS\\|ROD\\)\\|REPORT\\|SECTORS?\\|WALCHK\\):" (0 gams-mpsge-face t t))
	;; the ontext - offtext pair.
	(gams-store-point-ontext (0 gams-comment-face t t))
	)
      "Font-Lock keyboards.")
;;       )

(defvar gams-lst-font-lock-keywords-1
  '(("^\\*\\*\\*\\*[^\n]+" (0 gams-lst-warning-face))
    ("^\\(----\\)?[ \t]+[0-9]*[ ]PARAMETER[ ]+" (0 gams-lst-par-face))
    ("^----[ ]+[0-9]+[ ]SET[ ]+" (0 gams-lst-set-face))
    ("^\\(----\\)?[ \t]+[0-9]*[ ]VARIABLE[ ]+" (0 gams-lst-vri-face))
    )
  "Regular expression for font-lock in GAMS-LST mode.  Level 1.")

(defvar gams-lst-font-lock-keywords-2
  (append
   gams-lst-font-lock-keywords-1
   '(("\\(----[ ]+VAR[ ]+[^ ]+\\)[ ]*[^\n]+" (1 gams-lst-var-face))
     ("\\(----[ ]+EQU[ ]+[^ ]+\\)[ ]*[^\n]+" (1 gams-lst-equ-face))
     ("^Equation Listing[ \t]+SOLVE[ \t]+.+" (0 gams-lst-program-face))
     ("^Column Listing[ \t]+SOLVE[ \t]+.+" (0 gams-lst-program-face))
     (gams-store-point-special-comment (0 gams-comment-face))
     ))
  "Regular expression for font-lock in GAMS-LST mode.  Level 2.")

(defvar gams-ol-font-lock-keywords-1
  '((gams-store-point-rep-sum (0 gams-lst-warning-face))
    (gams-store-point-sol-sum (0 gams-lst-warning-face))
    ("^\\([[]\\).*" (0 gams-comment-face))
    ("^[ ]+\\(OTH\\)[ \t]+\\(.*\\)"
     (1 gams-lst-oth-face)
     (2 gams-oth-cont-face))
    ("^[ ]+\\(SUM\\)" (1 gams-lst-warning-face)))
  "Regular expression for font-lock in GAMS-OUTLINE mode.  Level 1.")

(defvar gams-ol-font-lock-keywords-2
  (append
   gams-ol-font-lock-keywords-1
   '(("^[ ]+\\(PAR\\)[ \t]+" (1 gams-lst-par-face))
     ("^[ ]+\\(SET\\)[ \t]+" (1 gams-lst-set-face))
     ("^[ ]+\\(VAR\\)[ \t]+" (1 gams-lst-var-face))
     ("^[ ]+\\(VRI\\)[ \t]+" (1 gams-lst-vri-face))
     ("^[ ]+\\(EQU\\)[ \t]+" (1 gams-lst-equ-face))
     ("^[ ]+\\(LOO\\)[ \t]+" (1 gams-ol-loo-face))
     ("^\\*[ ]?\\(.*\\)" (0 gams-mpsge-face))))
  "Regular expression for font-lock in GAMS-OUTLINE mode.  Level 2.")

(defun gams-store-point-comment (limit)
  "Store points for font-lock for comment."
  (when (re-search-forward
	 (concat "^\\([" gams-comment-prefix "].*\\)$") limit t)
    (let ((beg (match-beginning 1))
	  (end (match-end 1)))
      (store-match-data (list beg end))
      t)))

(defun gams-store-point-hidden-comment (limit)
  "Store points for font-lock for comment."
  (when (re-search-forward "^\\($hidden.*\\)$" limit t)
    (let ((beg (match-beginning 1))
	  (end (match-end 1)))
      (store-match-data (list beg end))
      t)))

(defun gams-store-point-ontext (limit)
  "Store points for font-lock for ontext-offtext."
  (let (beg end flag)
    (catch 'found
      (while t
	(if (and (<= (point) limit) (re-search-forward "^$ontext" limit t))
	    (progn
	      (setq beg (match-beginning 0))
	      (when (re-search-forward "^$offtext" limit t)
		(beginning-of-line)
		(if (gams-in-on-off-text-p)
		    (progn
		      (forward-line 1)
		      (store-match-data (list beg (point)))
		      (setq flag t)
		      (throw 'found t))
		  (forward-line 1))))
	  (when (gams-in-on-off-text-p)
	    (beginning-of-line)
	    (setq beg (point))
	    (forward-line 1)
	    (store-match-data (list beg (point)))
	    (setq flag t))
	(throw 'found t))))
    flag))

(defun gams-check-decl-eol ()
  "If there is nothing after the current point, return t.  Otherwise nil."
  (let ((cur-po (point))
	(end (line-end-position))
	flag)
    (if (re-search-forward "[^ \t\n]" end t)
	(progn
	  (goto-char cur-po)
	  (if (looking-at
	       (concat "[ \t]*\\([;]"
		       (when gams-inlinecom-symbol-start
			   (concat "\\|" (regexp-quote gams-inlinecom-symbol-start)))
		       (when gams-eolcom-symbol
			   (concat "\\|" (regexp-quote gams-eolcom-symbol)))
		       "\\)"))
	      ;; end of line.
	      (setq flag t)
	    ;; Identifier exits.
	    (setq flag nil)))
      (setq flag t))
    flag))
	    
(defun gams-store-explanation ()
  "Store the points of explanatory text if it exits."
  (let ((cur-po (point))
	(end (line-end-position))
	po-temp cont flag)
    (if (re-search-forward "[^ \t\n]" end t)
	;; if something exists.
	(progn
	  (goto-char cur-po)
	  (catch 'found
	    (while t
	      (if (re-search-forward
		   (concat "[ \t]*\\([;]\\|[/]"
			   (when gams-inlinecom-symbol-start
			       (concat "\\|" (regexp-quote gams-inlinecom-symbol-start)))
			   (when gams-eolcom-symbol
			       (concat "\\|" (regexp-quote gams-eolcom-symbol)))
			   "\\)") end t)
		  (progn (setq po-temp (match-beginning 0))
			 (when (and (not (gams-in-quote-p))
				    (not (gams-in-comment-p)))
			   ;; if eol symbol exits
			   (setq end po-temp)
			   (throw 'found t))
			 ;; if eol symbol does not exit.
			 (setq end end))
		(throw 'found t))))
	  (setq cont (gams*buffer-substring cur-po end))
	  (if (string-match "[^ \t]" cont)
	      (setq flag (list cur-po end))
	    (setq flag (list nil end))))
      (setq flag (list nil end)))
    flag))

(defun gams-store-point-slash (limit)
  "Store points for font-lock for texts in slash pair."
  (let (cur-po beg end flag beg-decl po-a)
    (catch 'found
      (while t
	(setq cur-po (point))
	;; For XEmacs
	(when (and gams-xemacs (not (equal 0 (current-column)))) ; koko dame.
	  (forward-line 1))
 	(if (and (<= cur-po limit) (re-search-forward "/" limit t))
	    ;; If / is found.
	    (if (and (not (gams-in-on-off-text-p))
		     (not (gams-check-line-type nil t))
		     (setq beg-decl (gams-in-declaration-p))
;;		     (not (gams-in-quote-p))
		     (not (gams-in-quote-p-extended))
		     (not (gams-in-comment-p)))
		;; If / is valid.
		(progn
		  (setq beg (1- (point)))
		  (if (gams-slash-end-p beg-decl)
		      ;; Outside slash pair.
		      (progn
			(goto-char cur-po)
			(setq beg (line-beginning-position))
			(setq end (line-end-position))
			(when (gams-slash-in-line-p)
 			  (search-forward "/" limit t)
			  (setq end (point)))
			(if (looking-at "^\n")
			    (store-match-data (list beg (+ 1 end)))
			  (store-match-data (list beg end)))
			(forward-line 1)
			(setq flag t)
			(throw 'found t))
		    ;; Inside slash pair.
		    (cond
 		     ((not (save-excursion (re-search-forward "/" limit t)))
		      ;; If the next slash is not found,
		      (if (> beg-decl cur-po)
			  ;; Abort.
			  (throw 'found t)
			(goto-char cur-po)
			(setq beg (line-beginning-position)
			      end (line-end-position))
			(beginning-of-line)
			(cond
			 ((gams-slash-in-line-p)
			  ;; The current line includes one slash.
			  (if (gams-slash-end-p beg-decl)
			      ;; If beginning-of-line is not in slash pair
			      (if (progn (end-of-line)
					 (gams-slash-end-p beg-decl))
				  ;; If end-of-line is not in slash pair.
				  (throw 'found t)
				;; If end-of-line is in slash pair.
				(search-backward "/" beg t)
				(store-match-data (list (point) end))
				(forward-line 1)
				(setq flag t)
				(throw 'found t))
			    ;; If beginning-of-line is in slash pair.
			    (search-forward "/" nil t)
			    (store-match-data (list beg (point)))
			    (forward-line 1)
			    (setq flag t)
			    (throw 'found t)))
			 (t
			  ;; The current line doesn't include a slash.
			  (if (gams-slash-end-p beg-decl)
			    ;; If the current point is outside slash pair.
			      (throw 'found t)
			    ;; If the current point is inside slash pair.
			    (store-match-data (list beg end))
			    (forward-line 1)
			    (setq flag t)
			    (throw 'found t))
			  ))))
		     (t
		      ;; Otherwise.
		      (catch 'foo
			(while t
			  (if (not (re-search-forward "/" nil t))
			      (progn (setq end limit)
				     (throw 'foo t))
			    (when (and (setq end (match-end 0))
				       (not (gams-in-quote-p))
				       (not (gams-in-comment-p))
				       (not (gams-check-line-type nil t)))
			      (throw 'foo t)))))
		      (store-match-data (list beg end))
		      (setq flag t)
		      (forward-line 1)
		      (throw 'found t)))))
	      ;; If conditions are not satisfied, search the next slash.
	      ;; i.e. do nothing here.
	      nil)
	  ;; If slash is not found.
	  (let ((po-match (gams-in-declaration-p)))
	    (if (not po-match)
		;; Outside declaration environement.
		(throw 'found t)
	      ;; Inside declaration environement.
	      (if (gams-slash-end-p po-match)
		  ;; Outside slash pair.
		  (throw 'found t)
		;; Inside slash pair.
		(if (looking-at "^\n")
		    (store-match-data (list (line-beginning-position)
					    (+ 1 (line-end-position))))
		  (store-match-data (list (line-beginning-position)
					  (line-end-position))))
		(forward-line 1)
		(setq flag t)
		(throw 'found t)
		))))))
    flag))

(defun gams-jump-next-slash (begin)
  "Return the point of the next slash if the current point is in a slash
pair.  If the current point is not in a slash pair, do nothing.  BEGIN is
the begin point of declaration."
  (let ((count 0) (cur-po (point)) po)
    (save-excursion
      (goto-char begin)
      (while (re-search-forward "/" cur-po t)
	(when (and (not (gams-in-comment-p))
		   (not (gams-in-quote-p)))
	  (setq count (+ 1 count))))
      (when (and (> count 0) (oddp count))
	(while (not
		(and (re-search-forward "/" nil t)
		     (not (gams-in-comment-p))
		     (not (gams-in-quote-p))))
	  t)
	(setq po (point))))
    po))

(defun gams-store-point-explanation (limit)
  "Store points for font-lock for explanatory text."
  (let ((cur-po (point))
	decl-end
	flag cont beg end ontext po-a po-b fl-table match-decl)
    (catch 'found
      (while t
	;; In an ontext-offtext pair?
	(setq ontext (gams-in-on-off-text-p))
	(cond
	 ;; If not in an ontext-offtext pair and if in declaration.
	 ((and (not ontext)
	       (setq po-b (gams-in-declaration-p)))
	  (if (not (< (point) limit))
	      ;; If the current point exceeds limit.
	      (throw 'found t)
	    ;; If the current point does not exceed limit.
	    (setq decl-end (gams-sid-return-block-end (point)))
	    (if (not (< (point) decl-end))
		;; if current point reaches the end of the declaration
		;; block, go out of it.
		(forward-char 1)
	      ;; if the current point is inside the declaration block.
	      (setq cont
		    (gams-store-point-explanation-get-explanation po-b cur-po decl-end limit))
	      (if cont
		  (store-match-data cont)
		(store-match-data (list (point) (point))))
	      ;; Even if cont is nil, set t to flag in order to continue the
	      ;; coloring for the subsequence part.
	      (setq flag t)		
	      (throw 'found t))))
	 ;; Point exceeds limit.
	 ((>= (point) limit)
	  (throw 'found t)
	  (setq flag nil))
	 
	 ;; If not in declaration block, search declaration block.
	 ((and (if (re-search-forward
		    (concat "^[ \t]*" gams-regexp-declaration-2 "[ \t\n]+") limit t)
		   (progn
		     (setq match-decl (gams*buffer-substring (match-beginning 1)
							     (match-end 1)))
		     (setq po-a (match-beginning 1)))
		 (throw 'found t))
	       (not (setq ontext (gams-in-on-off-text-p))))
	  ;; if declaration block is found.
	  (progn
	    (if (string-match "table" match-decl)
		(setq fl-table t)
	      (setq fl-table nil))
	    (setq decl-end (gams-sid-return-block-end (point)))
	    (if fl-table
		(setq cont (gams-store-point-explanation-get-explanation-table po-a cur-po limit decl-end))
	      (setq cont (gams-store-point-explanation-get-explanation po-a cur-po limit decl-end)))
	    ;; Even if cont is nil, set t to flag in order to continue the
	    ;; coloring for the subsequence part.
	    (when cont
	      (store-match-data cont)
	      (setq flag t)
	      (throw 'found t))))
	 
	 ;; In the ontext-offtext pair.
	 (ontext
	  (if (re-search-forward "^$offtext" limit t)
	      nil
	    (throw 'found t)
	    (setq flag nil)))
	 ;; Other cases.
	 (t
	  (throw 'found t)
	  (setq flag nil)))))
    ;; If item is found, flag is t.
    flag))

(defun gams-store-point-explanation-get-explanation (begin current limit end)
  "BEGIN is the beginning point of the declaration block.
CURRENT is the current point.  END is the point of the declaration block."
  (let ((lim (min limit end))
	(eol-sym (regexp-quote gams-eolcom-symbol))
	(inl-sym (regexp-quote gams-inlinecom-symbol-start))
	ex-list ex-beg ex-end iden-flag)
    (catch 'found
      (while t
	;; Skip irrelevant lines.
	(while (gams-check-line-type)
	  (forward-line 1)
	  (when (eobp) (throw 'found t)))
	(if (>= (point) lim)
	    ;; if current point exceeds limit, do nothing.
	    (throw 'found t)
	  (cond
	   ;; If reaced to the end of the buffer.
	   ((eobp) (throw 'found t))
	   ;; If the next char is space or tab.
	   ((looking-at "[ \t]")
	    (skip-chars-forward "[ \t]"))
	   ;; If the next char is end-of-line comment.
	   ((looking-at eol-sym)
	    (forward-line 1))
	   ;; If the next char is inline comment.
	   ((looking-at inl-sym)
	    (gams-sid-goto-inline-comment-end))
	   ;; If the next char is \n.
	   ((looking-at "\n")
	    (when iden-flag
	      (setq iden-flag nil))
	    (forward-char 1))
	   ;; If the next char is /.
	   ((looking-at "/")
	    (goto-char (or (gams-sid-next-slash) (line-end-position))))
	   ;; If the next char is ' or ".
	   ((or (looking-at "'\\|\""))
	    (if (not iden-flag)
		(forward-char 1)
	      (setq ex-beg (match-beginning 0)
		    ex-end (gams-sil-get-alist-exp t))
	      (goto-char ex-end)
	      (when (<= current ex-beg)
		(setq ex-list (list ex-beg ex-end))
		(throw 'found t))))
	   ;; If the next char is ",".
	   ((looking-at ",")
	    (when iden-flag (setq iden-flag nil))
	    (forward-char 1))
	   ;; If the next char is ;.
	   ((looking-at ";")
	    (forward-char 1)
	    (throw 'found t))
	   ;; If the next char is (.
	   ((looking-at "(")
	    (if (re-search-forward ")" (line-end-position) t)
		(point)
	      (end-of-line) ;; Which one is better?
	      (throw 'found t))
	    )
	   ;; Otherwise (i.e. identifier or explanatory text are found).
	   (t
	    (if iden-flag
		;; If an identifier is already found, the next string is
		;; explanatory text.
		(progn
		  (setq ex-beg (point))
		  (setq ex-end (gams-sil-get-alist-exp t))
		  (goto-char ex-end)
		  (when (<= current ex-beg)
		    (setq ex-list (list ex-beg ex-end))
		    (throw 'found t))
		  (setq iden-flag nil))
	      ;; If no identifier is yet found, then next string is an
	      ;; identifier.
	      (skip-chars-forward "[a-zA-Z0-9_]")
	      (setq iden-flag t)))))))
    ex-list))

(defun gams-store-point-explanation-get-explanation-table (begin current limit end)
  "BEGIN is the beginning point of the declaration block.
CURRENT is the current point.  END is the point of the declaration block."
  (let ((lim (min limit end))
	(eol-sym (regexp-quote gams-eolcom-symbol))
	(inl-sym (regexp-quote gams-inlinecom-symbol-start))
	ex-list ex-beg ex-end iden-flag)
    (catch 'found
      (while t
	;; Skip irrelevant lines.
	(while (gams-check-line-type)
	  (forward-line 1)
	  (when (eobp) (throw 'found t)))
	(if (>= (point) lim)
	    ;; if current point exceeds limit, do nothing.
	    (throw 'found t)
	  (cond
	   ;; If reaced to the end of the buffer.
	   ((eobp) (throw 'found t))
	   ;; If the next char is space or tab.
	   ((looking-at "[ \t]")
	    (skip-chars-forward "[ \t]"))
	   ;; If the next char is end-of-line comment.
	   ((looking-at eol-sym)
	    (forward-line 1))
	   ;; If the next char is inline comment.
	   ((looking-at inl-sym)
	    (gams-sid-goto-inline-comment-end))
	   ;; If the next char is \n.
	   ((looking-at "\n")
	    (when iden-flag
	      (goto-char lim)
	      (throw 'found t))
	    (forward-char 1))
	   ;; If the next char is /.
;;; 	   ((looking-at "/")
;;; 	    (goto-char (or (gams-sid-next-slash) (line-end-position))))
	   ;; If the next char is ' or ".
	   ((or (looking-at "'\\|\""))
	    (if (not iden-flag)
		(forward-char 1)
	      (setq ex-beg (match-beginning 0)
		    ex-end (gams-sil-get-alist-exp t))
	      (goto-char ex-end)
	      (when (<= current ex-beg)
		(setq ex-list (list ex-beg ex-end))
		(throw 'found t))))
	   ;; If the next char is ",".
;;; 	   ((looking-at ",")
;;; 	    (when iden-flag (setq iden-flag nil))
;;; 	    (forward-char 1))
	   ;; If the next char is ;.
;;; 	   ((looking-at ";")
;;; 	    (forward-char 1)
;;; 	    (throw 'found t))
	   ;; If the next char is (.
	   ((looking-at "(")
	    (if (re-search-forward ")" (line-end-position) t)
		(point)
	      (end-of-line) ;; Which one is better?
	      (throw 'found t))
	    )
	   ;; Otherwise (i.e. identifier or explanatory text are found).
	   (t
	    (if iden-flag
		;; If an identifier is already found, the next string is
		;; explanatory text.
		(progn
		  (setq ex-beg (point))
		  (setq ex-end (gams-sil-get-alist-exp t))
		  (goto-char ex-end)
		  (when (<= current ex-beg)
		    (setq ex-list (list ex-beg ex-end))
		    (throw 'found t))
		  (setq iden-flag nil))
	      ;; If no identifier is yet found, then next string is an
	      ;; identifier.
	      (skip-chars-forward "[a-zA-Z0-9_]")
	      (setq iden-flag t)))))))
    ex-list))

(defun gams-store-point-inlinecom (limit)
  "Store points for font-lock for inline comment."
  (let (beg end flag)
    (when gams-inlinecom-symbol-start
      (catch 'found
	(while t
	  (if (not (re-search-forward (regexp-quote gams-inlinecom-symbol-start) limit t))
	      (throw 'found t)
	    (setq beg (match-beginning 0))
	    (when (not (gams-in-quote-p-extended))
	      (when (re-search-forward (regexp-quote gams-inlinecom-symbol-end) limit t)
		(setq end (match-end 0))
		(when (not (gams-in-quote-p-extended))
		  (store-match-data (list beg end))
		  (setq flag t)
		  (throw 'found t))))))))
    flag))

(defun gams-store-point-eolcom (limit)
  "Store points for font-lock for end of line comment."
  (let (flag beg)
    (when gams-eolcom-symbol
      (catch 'found
	(while t
	  (if (not (re-search-forward (regexp-quote gams-eolcom-symbol) limit t))
	      (throw 'found t)
	    (setq beg (match-beginning 0))
	    (when (not (gams-in-quote-p-extended))
	      (end-of-line)
	      (store-match-data (list beg (point)))
	      (setq flag t)
	      (throw 'found t))))))
    flag))

(defun gams-store-point-mpsge-comment (limit)
  "Store points for font-lock for commented tex in MPSGE block."
  (let (flag beg)
    (catch 'found
      (while t
	(if (not (and (re-search-forward "[!]" limit t)))
	    (throw 'found t)
	  (setq beg (match-beginning 0))
	  (when (gams-in-mpsge-block-p)
	    (when (not (gams-in-quote-p-extended))
	      (end-of-line)
	      (store-match-data (list beg (point)))
	      (setq flag t)
	      (throw 'found t))))))
    flag))

(setq gams-copied-program-regexp
      (gams-regexp-opt
       (list
	"E x e c u t i o n"
	"Model Statistics"
	"Solution Report"
	"C o m p i l a t i o n"
	"Equation Listing"
	"Column Listing"
	"Include File Summary"
	) t))

(defun gams-store-point-copied-program (limit)
  "Store points for font-lock for copied program in LST mode."
  (let (flag cont)
    (when (re-search-forward "\\(^[ ]?[ ]?[ ]?[ ]?[ ]?[ ]?\\([0-9]+[ ][ ].*\\)\\|^\\(COMPILATION\\) TIME\\|^\\(Error\\) Messages\\|^\\(Include\\) File Summary\\|^\\(E x e c u t i o n\\)\\|^\\(Equation Listing\\)\\)" limit t)
      (setq cont
	    (cond
	     ((match-beginning 2)
	      (buffer-substring (match-beginning 2) (match-end 2)))
	     ((match-beginning 3)
	      (buffer-substring (match-beginning 3) (match-end 3)))
	     ((match-beginning 4)
	      (buffer-substring (match-beginning 4) (match-end 4)))
	     ((match-beginning 5)
	      (buffer-substring (match-beginning 5) (match-end 5)))
	     ((match-beginning 6)
	      (buffer-substring (match-beginning 6) (match-end 5)))))
      (if (or (equal "COMPILATION" cont)
	      (equal "Error" cont)
	      (equal "Include" cont)
	      (equal "E x e c u t i o n" cont))
	  (setq flag nil)
	(let ((beg (match-beginning 1))
	      (end (match-end 1)))
	  (store-match-data (list beg end))
	  (setq flag t))))
    flag))

;;; Functions for changing font-lock level.
(defun gams-update-font-lock-keywords (mode level)
  "Change the font lock level in MODE to LEVEL."
  (cond
   ((equal mode "g")
    (setq gams-font-lock-level level)
    (cond
     ((equal level 0) (setq gams-font-lock-keywords nil))
     ((equal level 1) (setq gams-font-lock-keywords gams-font-lock-keywords-1))
     ((equal level 2) (setq gams-font-lock-keywords gams-font-lock-keywords-2))))
   ((equal mode "l")
    (setq gams-lst-font-lock-level level)
    (cond
     ((equal level 0) (setq gams-lst-font-lock-keywords nil))
     ((equal level 1) (setq gams-lst-font-lock-keywords gams-lst-font-lock-keywords-1))
     ((equal level 2) (setq gams-lst-font-lock-keywords gams-lst-font-lock-keywords-2))))
   ((equal mode "o")
    (setq gams-ol-font-lock-level level)
    (cond
     ((equal level 0) (setq gams-ol-font-lock-keywords nil))
     ((equal level 1) (setq gams-ol-font-lock-keywords gams-ol-font-lock-keywords-1))
     ((equal level 2) (setq gams-ol-font-lock-keywords gams-ol-font-lock-keywords-2))))
   ))

(defun gams-check-font-lock-level-mode (&optional mode)
  "Check the font-lock level in MODE."
  (cond
   ((equal mode "g")
    gams-font-lock-level)
    ((equal mode "l")
    gams-lst-font-lock-level)
   ((equal mode "o")
    gams-ol-font-lock-level)
   (t
    (let ((cur-mode (gams-return-mode)))
      (cond
       ((equal cur-mode "g") gams-font-lock-level)
       ((equal cur-mode "l") gams-lst-font-lock-level)
       ((equal cur-mode "o") gams-ol-font-lock-level))))))

(defun gams-return-mode-name (&optional mode)
  "Return the mode name.
If MODE is g, return GAMS mode,
If MODE is l, return GAMS-LST mode,
If MODE is o, return GAMS-OUTLINE mode.
Otherwise, return the mode name of current buffer."
  (cond
   ((equal mode "g")
    "GAMS mode")
   ((equal mode "l")
    "GAMS-LST mode")
   ((equal mode "o")
    "GAMS-OUTLINE mode")
   (t mode-name)))

(defun gams-return-mode ()
  "Return the current mode name."
  (let ((cur-mode mode-name))
    (cond
     ((equal cur-mode "GAMS")
      "g")
     ((equal cur-mode "GAMS-LST")
      "l")
     ((equal cur-mode "GAMS-OUTLINE")
      "o"))))

(defun gams-choose-font-lock-level ()
  "Choose the level of decoralization."
  (interactive)
  (let ((cur-mode (gams-return-mode))
	(level 0)
	cur-level temp-mode)
    (message
     (format "Choose [g]ms, [l]st, [o]utline, RET = current mode."))
    (let ((mode (char-to-string (read-char))))
      (if (not (string-match "[glo\r]" mode))
	  (message "Push g, l, o, or RET!")
	(when (equal mode "\r")
	  (setq mode (gams-return-mode)))
	(setq temp-mode (gams-return-mode-name mode))
	(message (format "Current font-lock level in %s = %d:  Choose 0, 1, or 2"
			 temp-mode
			 (setq cur-level (gams-check-font-lock-level-mode mode))))
	(setq level (char-to-string (read-char)))
	(if (not (string-match "[012\r]" level))
	    (message "Type 0, 1, or 2!")
	  (if (equal level "\r")
	      (setq level (gams-check-font-lock-level-mode))
	    (setq level (string-to-number level)))
	  (gams-choose-font-lock-level-internal level mode cur-mode)
	  (message (format "The font-lock level in %s is changed from %d to %d."
			   temp-mode cur-level level)))))))

(defsubst gams-choose-font-lock-level-internal (level mode cur-mode)
  ;; Update keywords for font-lock.
  (gams-update-font-lock-keywords mode level)
  (cond 
   ((equal mode "g")
    (setq font-lock-keywords gams-font-lock-keywords)
    (setq font-lock-defaults '(gams-font-lock-keywords t t)))
   ((equal mode "l")
    (setq font-lock-keywords gams-lst-font-lock-keywords)
    (setq font-lock-defaults '(gams-lst-font-lock-keywords t t)))
   ((equal mode "o")
    (setq font-lock-keywords gams-ol-font-lock-keywords)
    (setq font-lock-defaults '(gams-ol-font-lock-keywords t t))))
  (when (equal cur-mode mode)
    (if (not (equal level 0))
	(progn (font-lock-mode -1)
	       (font-lock-mode 1)
	       (when (not font-lock-fontified)
		 (font-lock-fontify-buffer)))
      (font-lock-mode -1))))

(defun gams-in-declaration-p (&optional table)
  "Return t if the cursor is in declaration environment.
Return nil if not in declaration environment.
Return the starting point of the declaration if in declaration environment.
If TABLE is nil, table declaration is not consindered as a declaration."
  (let ((cur-po (point))
	(dummy (if table "dummy" "table"))
	temp-po	beg-po temp-con)
    (save-excursion
      ;; Search reserved expression backward.
      (if (re-search-backward
	   (concat "^[ \t]*\\("
		   gams-regexp-declaration-2
		   "\\|"
		   gams-regexp-loop
		   "\\|"
           		   gams-regexp-put
		   "\\|"
		   "[$][ \t]*" gams-regexp-mpsge
 		   "\\|$offtext\\|$ontext\\)") nil t)
	  ;; Store the matched.
	  (progn
	    (setq temp-con (gams*buffer-substring (match-beginning 0)
						  (match-end 0)))
	    (setq temp-po (point))
	    (skip-chars-forward " \t")
	    (forward-char 1)
	    (cond
	     ;; If the matched is table, do nothing.
	     ((string-match dummy temp-con) t)
	     ;; If the matched is declaration.
;;	     ((string-match (concat "[^$]+" gams-regexp-declaration-2) temp-con)
	     ((string-match gams-regexp-declaration-2 temp-con)
	      ;; Search ; forward.
	      (let (flag)
		(catch 'found
		  (while (re-search-forward ";" cur-po t)
		    (when (and (not (gams-in-comment-p))
			       (not (gams-in-quote-p)))
		      (setq flag t)))
		  (throw 'found t))
		(when (not flag)
		  ;; If not found.
		  (goto-char cur-po)
		  ;; Move to the next line.
		  (while (and (gams-check-line-type) (not (eobp)))
		    (forward-line 1))
		  (when (not (eobp))
		    (when (not (looking-at (concat "^[ \t]*" gams-regexp-declaration-2)))
		      (setq beg-po temp-po))))))))))
    beg-po))

(defun gams-font-lock-mark-block-function ()
  "The function for mark block in GAMS mode."
  (let ((cur-po (point))
	(regexp (concat "^[ \t]*\\(" gams-regexp-declaration "\\|" gams-regexp-loop "\\|"
			gams-regexp-put "\\|" "[$][ \t]*" gams-regexp-mpsge
			"\\|$offtext\\|$ontext\\)")))
    (push-mark (point))
    (if (gams-in-on-off-text-p)
	(progn (re-search-forward "^$offtext" nil t)
	       (push-mark (point) nil t)
	       (re-search-backward "^$ontext" nil t)
	       (goto-char (match-beginning 0)))
      (let ((count-1 4) (count-2 4))
	(while (< 0 count-1)
	  (if (re-search-forward regexp nil t)
	      (setq count-1 (- count-1 1))
	    (setq count-1 -1)))
	(if (equal count-1 -1)
	    (push-mark (point-max) nil t)
	  (beginning-of-line)
	  (when (gams-in-on-off-text-p)
	    (re-search-backward "^$ontext" cur-po t))
	  (push-mark (point) nil t))
	(goto-char cur-po)
	(while (< 0 count-2)
	  (if (re-search-backward regexp nil t)
	      (setq count-2 (- count-2 1))
	    (setq count-2 -1)))
	(if (equal count-2 -1)
	    (goto-char (point-min))
	  (when (gams-in-on-off-text-p)
	    (re-search-forward "^$offtext" cur-po t)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Code for GAMS mode.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gams-insert-tab ()
  "Insert a tab."
  (interactive)
  (insert "\t"))

(setq-default gams-comment-prefix-default "*")
(setq-default gams-comment-prefix gams-comment-prefix-default)
(setq-default gams-lst-file "")
(setq-default gams-lst-file-full "")

;; Key assignment.
;; from yatex.el
;; (defvar gams-prefix-key "\C-c"
;;   "*Prefix key to call GAMS mode functions.
;; You can select favorite prefix key by setq in your ~/.emacs.el")
  
(defvar gams-mode-map (make-keymap) "Keymap used in gams mode")
;; Key assignment.
(defun gams-mode-key-update ()
  (let ((map gams-mode-map))
      (define-key map "(" 'gams-insert-parens)
      (define-key map "\"" 'gams-insert-double-quotation)
      (define-key map "'" 'gams-insert-single-quotation)
      (define-key map "\C-l" 'gams-recenter)
      
      (define-key map "\C-c\C-k" 'gams-insert-statement)
      (define-key map "\C-c\C-d" 'gams-insert-dollar-control)
      (define-key map "\C-c\C-v" 'gams-view-lst)
      (define-key map "\C-c\C-j" 'gams-jump-to-lst)    
      (define-key map "\C-c\C-t" 'gams-start-menu)
      (define-key map "\C-c\C-e" 'gams-template)
      (define-key map "\C-c\C-o" 'gams-insert-comment)
      (define-key map "\C-c\C-g" 'gams-jump-on-off-text)
      (define-key map "\C-c\M-g" 'gams-remove-on-off-text)
      (define-key map "\C-c\M-c" 'gams-comment-on-off-text)
      (define-key map "\C-c\C-c" 'gams-insert-on-off-text)
      (define-key map "\C-c\C-m" 'gams-view-docs)
      (define-key map "\C-c\C-z" 'gams-modlib)
      (define-key map "\C-c\C-h" 'gams-toggle-hide/show-comment-lines)
      (define-key map "\C-c\C-x" 'gams-lxi)
      (define-key map "\C-c\C-l" 'gams-popup-process-buffer)
      (define-key map "\C-c\C-s" 'gams*start-processor)
      (define-key map [f9] 'gams*start-processor)
      (define-key map [f10] 'gams-view-lst)
      (define-key map "\C-c\C-i" 'gams-from-gms-to-outline)
      (define-key map [f11] 'gams-from-gms-to-outline)
      (define-key map [f8] 'gams-goto-matched-paren)
      (define-key map "\C-c\C-w" 'gams-open-included-file)
      (define-key map [(control c) (control \;)] 'gams-comment-region)
      (define-key map "\C-c\C-n" 'gams-insert-statement-extended)

      (define-key map [(control c) (control .)] 'gams-show-identifier)
      (define-key map [f7] 'gams-show-identifier)
      (define-key map "\C-c\C-a" 'gams-show-identifier-list)

      (define-key map gams-choose-font-lock-level-key
	'gams-choose-font-lock-level)
      (define-key map "\M-;" 'gams-comment-dwim)
      (define-key map [(control c) (control \;)] 'gams-comment-dwim-inline)))

;;; Menu for GAMS mode.
(easy-menu-define 
  gams-menu gams-mode-map "Menu keymap for GAMS mode."
  '("GAMS"
    ["Insert GAMS statement" gams-insert-statement t]
    ["Insert GAMS dollar control" gams-insert-dollar-control t]
    ["Insert GAMS statement with extended features" gams-insert-statement-extended t]
    ["Show the identifier declaration part" gams-show-identifier t]
    ["Show the identifier list" gams-show-identifier-list t]
    ["Open included file" gams-open-included-file t]
    "--"
    ["Switch to the LST file and show error" gams-view-lst t]
    ["Switch to the LST file" gams-jump-to-lst t]
    ["Switch to the GAMS-OUTLINE buffer" gams-from-gms-to-outline t]
    "--"
    ["Start GAMS-TEMPLATE mode" gams-template t]
    ["Insert a comment template" gams-insert-comment t]
    "--"
    ("Process"
     ["Run GAMS" (gams-start-menu nil ?s) t]
     ["Kill GAMS process" (gams-start-menu nil ?k) t]
     ["Process menu" (gams-start-menu) t]
     )
    ["Run GAMS" gams*start-processor t]
    ["Popup GAMS process buffer" gams-popup-process-buffer t]
    "--"
    ["Choose font-lock level" gams-choose-font-lock-level t]
    ["Fontify block" font-lock-fontify-block t]
    "--"
    ["Insert an ontext-offtext pair" gams-insert-on-off-text t]
    ["Jump between an ontext-offtext pair" gams-jump-on-off-text t]
    ["(Un)comment an ontext-offtext pair" gams-comment-on-off-text t]
    ["Remove an ontext-offtext pair" gams-remove-on-off-text t]
    "--"
    ["Recentering" gams-recenter t]
    ["Indent line" gams-indent-line t]
    ["Indent region" indent-region t]
    ["Jump to the matched parenthesis" gams-goto-matched-paren t]
    "--"
    ["Insert end-of-line comment" gams-comment-dwim t]
    ["Insert inline comment" gams-comment-dwim-inline t]
    ["Comment out region" gams-comment-region t]
    ["Toggle hide/show comment blocks" gams-toggle-hide/show-comment-lines t]
    "--"
    ["View GAMS manuals" gams-view-docs t]
    ["Extract a model from Model library" gams-modlib t]
    "--"
    ["Customize GAMS mode for Emacs" (customize-group 'gams) t]
    ))

;;; 
(defun gams-init-setting ()
  "Make various settings for gams-mode."
  ;; Behavior of $ key.
  (if gams-insert-dollar-control-on
      (define-key gams-mode-map "$" 'gams-insert-dollar-control))
  ;; Use automatic indent?
  (if gams-indent-on
      (progn
	(setq indent-line-function 'gams-indent-line)
	(define-key gams-mode-map "\t" 'gams-indent-line)
	(define-key gams-mode-map "\C-m" 'gams-newline-and-indent)
	(substitute-all-key-definition
	 'newline-and-indent 'gams-newline-and-indent gams-mode-map))
    (define-key gams-mode-map "\t" 'gams-insert-tab)
    (define-key gams-mode-map "\C-m" 'newline))
  ;; Make `gams-comment-prefix' a buffer-local variable.
  (let (temp)
    (if (setq temp (gams-search-dollar-comment))
	(setq gams-comment-prefix temp
	      comment-start temp
	      comment-start-skip (concat "^[" temp "]+[ \t]*"))
      (setq gams-comment-prefix gams-comment-prefix-default
	    comment-start-skip (concat "^[" gams-comment-prefix-default "]+[ \t]*")
	    comment-start gams-comment-prefix-default)))
  ;; Make `gams-eolcom-symbol' a buffer-local variable.
  (let (temp)
    (if (setq temp (gams-search-dollar-com t))
	(setq gams-eolcom-symbol temp)
      (setq gams-eolcom-symbol gams-eolcom-symbol-default)))
  ;; Make `gams-inlinecom-symbol-start' and `gams-inlinecom-symbol-end'
  (let (temp)
    (if (setq temp (gams-search-dollar-com))
	(progn (setq gams-inlinecom-symbol-start (car temp))
	       (setq gams-inlinecom-symbol-end (cdr temp)))
      (setq gams-inlinecom-symbol-start gams-inlinecom-symbol-start-default)
      (setq gams-inlinecom-symbol-end gams-inlinecom-symbol-end-default)))
  ;; Create the alist of statements.  Is this necessary?  See
  ;; `gams-statement-update'.
  (setq gams-statement-alist
	(gams-statement-to-alist gams-statement-up gams-statement-upcase))
  ;; Create the alist of dollar control options.  Is this necessary?  See
  ;; `gams-statement-update'.
  (if gams-use-mpsge
      ;; Use mpsge.
      (progn (setq gams-dollar-control-alist
		   (gams-statement-to-alist
		    (append gams-dollar-control-up gams-statement-mpsge)
		    gams-dollar-control-upcase)))
    ;; Not use mpsge
    (setq gams-dollar-control-alist
	  (gams-statement-to-alist gams-dollar-control-up gams-dollar-control-upcase)))

  ;; Update statements and dollar control options.
  (gams-statement-update)
  ;; Update options.
  (gams-opt-make-alist)
  ;; Update commands.
  (gams-opt-make-alist t))

(setq-default gams-temp-window nil)
(setq-default gams-ol-buffer-point nil)
(setq-default gams-lxi-buffer nil)
;;
(defun gams-mode ()
  "Major mode for editing GAMS program file.

The following commands are available in the GAMS mode:

\\[gams-insert-statement]		Insert GAMS statement with completion.
\\[gams-insert-dollar-control]		Insert GAMS dollar control option.
\\[gams-show-identifier]		Show the identifier declaration part.
\\[gams-show-identifier-list]		Show the identifier list.
\\[gams-open-included-file]		Open included file.

\\[gams-view-lst]		Switch to the LST file and show errors if exist.
\\[gams-jump-to-lst]		Switch to the LST file.
\\[gams-from-gms-to-outline]		Switch to the GAMS-OUTLINE buffer.
\\[gams-start-menu]		Run GAMS on a file you are editing or Kill GAMS process.
\\[gams*start-processor]		Run GAMS.
\\[gams-popup-process-buffer]   	Popup GAMS process buffer.
\\[gams-template]		Evoke the TEMPLATE mode.

\\[gams-recenter]		Recenter.
\\[gams-insert-comment]		Insert comment template.
\\[gams-insert-on-off-text]		Insert an ontext-offtext pair.
\\[gams-jump-on-off-text]		Jump between an ontext-offtext pair.
\\[gams-comment-on-off-text]		(Un)comment an  ontext-offtext pair.
\\[gams-remove-on-off-text]		Remove an ontext-offtext pair.
\\[gams-view-docs]		View GAMS pdf manuals.

\\[gams-comment-dwim]		Insert end-of-line comment.
\\[gams-comment-dwim-inline]		Insert inline comment."
  (interactive)
  (kill-all-local-variables)  
  (setq major-mode 'gams-mode)
  (setq mode-name "GAMS")
  (gams-mode-key-update)
  (use-local-map gams-mode-map)
  (setq fill-prefix "\t\t")
  (mapc
   'make-local-variable
   '(fill-column
     fill-prefix
     paragraph-start
     indent-line-function
     comment-start
     comment-start-skip
     comment-column
     font-lock-mark-block-function
     gams-comment-prefix
     gams-eolcom-symbol
     gams-inlinecom-symbol-start
     gams-inlinecom-symbol-end
     gams-ol-buffer-point
     gams-gms-window-configuration
     gams-gms-original-point
     gams-identifier-symbol-temp
     comment-indent-function
     gams-invisible-exist-p
     gams-invisible-areas-list
     gams-lxi-buffer
     gams-lst-file
     gams-lst-file-full
     ))
  ;; Variables.
  (setq fill-column gams-fill-column
	fill-prefix gams-fill-prefix
	paragraph-start gams-paragraph-start
	comment-indent-function 'comment-indent-default
	comment-column gams-comment-column
	comment-end ""
	comment-start-skip (concat "^[" gams-comment-prefix "]+[ \t]*"))
  ;; Various setting.
  (gams-init-setting)
  ;;
;;  (gams-create-syntax-table)
;;  (set-syntax-table gams-mode-syntax-table)
  ;; Setting for font-lock.
  (make-local-variable 'font-lock-defaults)
  (gams-update-font-lock-keywords "g" gams-font-lock-level)
  (setq font-lock-defaults '(gams-font-lock-keywords t t))
  (setq font-lock-mark-block-function 'gams-font-lock-mark-block-function)
  ;; Local variables to store window configurations.
  (make-local-variable 'gams-temp-window)
  ;; Setting for menu.
  (easy-menu-add gams-menu)
  ;;
  (gams-set-lst-filename)
  (when (and gams-display-small-logo
	     (or gams-emacs-21 gams-emacs-22 gams-emacs-23)
	     (fboundp 'find-image))
    (add-hook 'gams-mode-hook 'gams-add-mode-line))
  ;; Run hook
  (run-hooks 'gams-mode-hook)
  (add-to-invisibility-spec '(gams . t))
  (if (and (not (equal gams-font-lock-keywords nil))
	   font-lock-mode)
      (font-lock-fontify-buffer)
    (if (equal gams-font-lock-keywords nil)
	(font-lock-mode -1)))
  ) ;;; gams-mode ends.

(defun gams-list-to-alist (list)
  "Trasform a LIST to an ALIST."
  (mapcar '(lambda (x) (list x)) list))

(defun gams-alist-to-list (alist)
  "Trasform an ALIST to a LIST."
  (mapcar '(lambda (x) (car x)) alist))

(defun gams-statement-to-alist (list &optional flag)
  "Transform a LIST to an alist.
IF FLAG is non-nil, use upper case."
  (if (not flag)
      (setq list (mapcar 'downcase list))
    nil)
  (mapcar '(lambda (x) (list x)) list))

;; `gams-comment-region' is aliased as `comment-region'.
(if (fboundp 'comment-region)
    (fset 'gams-comment-region 'comment-region)
  (fset 'gams*buffer-substring 'buffer-substring))

(defvar gams-statement-alist-temp nil)
(defvar gams-dollar-alist-temp nil)
(defun gams-statement-update ()
  "Update gams-statement-alist and gams-dollar-control-alist."
  ;; Update `gams-statement-alist'.
  (setq gams-statement-alist
	(gams-statement-to-alist
	 (append gams-statement-up gams-user-statement-list) gams-statement-upcase))
  ;; Update `gams-dollar-control-alist'.
  (setq gams-dollar-control-alist
	(gams-statement-to-alist
	 ;; If you use MPSGE
	 (if gams-use-mpsge		
	     (append gams-dollar-control-up gams-statement-mpsge
		     gams-user-dollar-control-list)
	   (append gams-dollar-control-up gams-user-dollar-control-list))
	 gams-dollar-control-upcase)))

;;; From yatex.el

(defun gams-minibuffer-complete ()
  "Complete in minibuffer.
  If the symbol 'delim is bound and is string, its value is assumed to be
the character class of delimiters.  Completion will be performed on
the last field separated by those delimiters.
  If the symbol 'quick is bound and is 't, when the try-completion results
in t, exit minibuffer immediately."
  (interactive)
  (save-restriction
    (narrow-to-region
     (if (fboundp 'field-beginning) (field-beginning (point-max)) (point-min))
     (point-max))
    (let* ((md (match-data))
	  beg word comp delim compl
	  (quick (and (boundp 'quick) (eq quick t)))
	  (displist ;function to display completion-list
	   (function
	    (lambda ()
	      (with-output-to-temp-buffer "*Completions*"
		(display-completion-list
		 (all-completions word minibuffer-completion-table)))))))
      (setq beg (if (and (boundp 'delim) (stringp delim))
		    (save-excursion
		      (skip-chars-backward (concat "^" delim))
		      (point))
		  (point-min))
	    word (gams*buffer-substring beg (point-max))
	    compl (try-completion word minibuffer-completion-table))
      (cond
       ((eq compl t)
	(if quick (exit-minibuffer)
	  (let ((p (point)) (max (point-max)))
	    (unwind-protect
		(progn
		  (goto-char max)
		  (insert " [Sole completion]")
		  (goto-char p)
		  (sit-for 1))
	      (delete-region max (point-max))
	      (goto-char p)))))
       ((eq compl nil)
	(ding)
	(save-excursion
	  (let (p)
	    (unwind-protect
		(progn
		  (goto-char (setq p (point-max)))
		  (insert " [No match]")
		  (goto-char p)
		  (sit-for 2))
	      (delete-region p (point-max))))))
       ((string= compl word)
	(funcall displist))
       (t (delete-region beg (point-max))
	  (insert compl)
	  (if quick
	      (if (eq (try-completion compl minibuffer-completion-table) t)
		  (exit-minibuffer)
		(funcall displist)))))
      (store-match-data md))))

(defvar gams-statement-completion-map nil
  "*Key map used at gams completion of statements in the minibuffer.")
(if gams-statement-completion-map nil
  (setq gams-statement-completion-map
	(copy-keymap minibuffer-local-completion-map))
  (define-key gams-statement-completion-map
    " " 'minibuffer-complete)
  (define-key gams-statement-completion-map
    "\C-i" 'minibuffer-complete-word))

;;; ???
(defvar gams-read-statement-history nil "Holds history of statement.")
(put 'gams-read-statement-history 'no-default t)
(defun gams-read-statement (prompt &optional predicate initial)
  "Read a GAMS statements with completion."
;  (YaTeX-sync-local-table 'tmp-section-table)
  (let ((minibuffer-completion-table gams-statement-alist))
    (read-from-minibuffer
     prompt initial gams-statement-completion-map nil
     'gams-read-statement-history)))

(defun gams-register (name &optional flag)
  "Register a new statement or dollar-control.

NAME is the name of a new statement or dollar-control registered.  If FLAG is
non-nil, it is a dollar-control."
  (interactive)
  (let* ((curr-buff (current-buffer))
	 (temp-buff " *gams-register*")
	 (temp-file gams-statement-file)
	 (temp-list (if flag
			gams-user-dollar-control-list
		      gams-user-statement-list))
	 (old-list temp-list)
	 (list-name
	  (if flag
	      "gams-user-dollar-control-list"
	    "gams-user-statement-list"))
	 temp-cont  new-list)
    (save-excursion
      ;; Make a new list.
      (setq new-list (append (list name) temp-list))
      ;; Switch to the temporary buffer.
      (get-buffer-create temp-buff)
      (set-buffer temp-buff)
      (erase-buffer)
      ;; Write the content of the list.
      (gams-stat-write-list new-list flag)
      ;; Check whether the variable is defined correctly.
      (eval-buffer)
      ;; Store the content of buffer
      (setq temp-cont (gams*buffer-substring (point-min) (point-max)))
      ;; Delete the list-name part.
      (set-buffer (find-file-noselect temp-file))
      (goto-char (point-min))
      ;; Check whether the list-name part exists or not.
      (if (not (re-search-forward
		 (concat
		  "\\(setq\\) " list-name)
		 nil t))
	  ;; If it doesn't exists, do nothing.
	  nil
	;; If it exists, delete it.
	(let (point-beg point-en)
	  (goto-char (match-beginning 1))
	  (beginning-of-line)
	  (setq point-beg (point))
	  (forward-sexp 1)
	  (forward-line 1)
	  (setq point-en (point))
	  (delete-region point-beg point-en)))
      ;; Insert the content.
      (goto-char (point-min))
      (insert temp-cont)
      (eval-buffer)
      ;; Save buffer of gams-statement-file.
      (save-buffer (find-buffer-visiting temp-file))
      (kill-buffer (find-buffer-visiting temp-file))
      ;; kill the temporary buffer.
      (kill-buffer temp-buff)
      ;; Replace the old list with the new list.
      (setq old-list new-list)
      (gams-statement-update)
      (set-buffer curr-buff))))

(defun gams-stat-write-list (list &optional flag)
  "Write the content of LIST in a buffer.
If FLAG is non-nil, the list of dollar control."
  (let ((list-name (if flag
		       "gams-user-dollar-control-list"
		     "gams-user-statement-list")))
    (erase-buffer)
    (insert (concat "(setq " list-name " '(\n"))
    (goto-char (point-max))
    ;; Repeat.
    (while list
      (insert (concat "\"" (car list) "\"\n"))
      (goto-char (point-max))
      (setq list (cdr list)))
    ;; Last.
    (insert "))\n")))

(defun gams-insert-statement-get-name (&optional replace)
  "Get the name of satement inserted."
  (let ((mess (if replace
		  (concat "Replace `" replace "' with ")
		"Insert statement "))
	name guess)
    (setq guess
	  (if gams-statement-upcase
	      (upcase gams-statement-name)
	    (downcase gams-statement-name)))
    (setq name (gams-read-statement
		    (concat mess (format "(default = %s): " guess))))
    (if (string= name "") guess name)))

(defun gams-insert-statement (&optional arg)
  "Insert GAMS statement with completion.
List of candidates is created from elements of `gams-statement-up'
and `gams-user-statement-list'."
  (interactive "P")
  (if arg (gams-replace-statement)
    (gams-insert-statement-internal)))

(defun gams-insert-statement-internal (&optional cmd)
  "Insert GAMS statement with completion.
List of candidates is created from elements of `gams-statement-up'
and `gams-user-statement-list'."
;;  (interactive)
  (unwind-protect
      (let*
	  ((gams-alist gams-statement-alist)
	   (completion-ignore-case t)
	   key1
	   (source-window (selected-window))
	   guess
	   (statement
	    (or cmd
		(gams-insert-statement-get-name)))
	   ) ;;let
	(if gams-statement-upcase
	    (setq statement (upcase statement))
	  (setq statement (downcase statement)))
	(setq gams-statement-name statement)
	;; Register or not?
	(if (not (member (list statement) gams-statement-alist))
	    (progn
	      (message "Store `%s' for future use?  Type `y' if yes: " statement)
	      (setq key1 (read-char))
	      (if (equal key1 ?y)
		  (progn
		    (setq statement (upcase statement))
		    (gams-register statement))
		nil))
	  nil)
	;; Insert.
	(if gams-statement-upcase
	    (setq statement (upcase statement))
	  (setq statement (downcase statement)))
	(insert statement))
    (if (<= (minibuffer-depth) 0) (use-global-map global-map))
    (insert "")))

(defvar gams-dollar-completion-map nil
  "*Key map used at gams completion of dollar operation in the minibuffer.")
(if gams-dollar-completion-map nil
   (setq gams-dollar-completion-map
	 (copy-keymap minibuffer-local-completion-map))
   (define-key gams-dollar-completion-map
     " " 'minibuffer-complete)
   (define-key gams-dollar-completion-map
     "\C-i" 'minibuffer-complete-word)
   (define-key gams-dollar-completion-map
     "$" 'gams-minibuffer-insert-dollar)
   (define-key gams-dollar-completion-map
     "@" 'gams-minibuffer-insert-dollar))

(defvar gams-flag-dollar nil)
(defun gams-minibuffer-insert-dollar ()
  "???"
  (interactive)
  (setq gams-flag-dollar t)
  (exit-minibuffer))

(defvar gams-read-dollar-history nil "Holds history of dollar control.")
(put 'gams-read-dollar-history 'no-default t)
(defun gams-read-dollar-control (prompt &optional predicate initial)
  "Read a GAMS dollar control operation with completion."
  (let ((minibuffer-completion-table
	 (append gams-dollar-control-alist)))
    (read-from-minibuffer
     prompt initial gams-dollar-completion-map nil
     'gams-read-dollar-history)))

(defun gams-insert-dollar-control-get-name (&optional replace)
  "Get the name of dollar-control inserted."
  (let ((mess (if replace
		  (concat "Replace `$" replace "' with ")
		"Insert dollar control "))
	name guess)
    (setq guess
	  (if gams-dollar-control-upcase
	      (upcase gams-dollar-control-name)
	    (downcase gams-dollar-control-name)))
    (setq name (gams-read-dollar-control
		(if gams-insert-dollar-control-on
		    (concat mess (format " ($ or @ = $, default = $%s): $" guess))
		  (concat mess (format " (default = $%s): $" guess)))))
    (setq name (if (string= name "") guess name))
    (setq name (if gams-flag-dollar "" name))
    name))

(defun gams-insert-dollar-control (&optional arg)
  "Insert GAMS dollar control option with completion.
List of candidates is created from elements of `gams-dollar-control-up'
and `gams-user-dollar-control-list' (and `gams-statement-mpsge'
if `gams-use-mpsge' is non-nil)."
  (interactive "P")
  (if arg (gams-replace-statement)
    (gams-insert-dollar-control-internal)))

(defun gams-insert-dollar-control-internal (&optional cmd)
  "Insert GAMS dollar control option with completion.
List of candidates is created from elements of `gams-dollar-control-up'
and `gams-user-dollar-control-list' (and `gams-statement-mpsge'
if `gams-use-mpsge' is non-nil)."
  ;; Need to modify this.
  (setq gams-flag-dollar nil)
  (unwind-protect
      (let*
	  ((gams-alist gams-dollar-control-alist)
	   (completion-ignore-case t)
	   key1
	   (source-window (selected-window))
	   guess
	   (statement
	    (or cmd
		(gams-insert-dollar-control-get-name)))
	   );;let
	(if (not (equal statement ""))
	    (setq gams-dollar-control-name statement))
	(if gams-dollar-control-upcase
	    (setq statement (upcase statement))
	  (setq statement (downcase statement)))
	;; Register or not?
	(if (not (or (member (list statement) gams-dollar-control-alist)
		      (equal statement "")))
	    (progn
	      (message "Store `%s' for future use?  Type `y' if yes: " statement)
	      (setq key1 (read-char))
	      (if (equal key1 ?y)
		  (progn (setq statement (upcase statement))
			 (gams-register statement t))
		nil))
	  nil)
	;; Insert.
	(if gams-dollar-control-upcase
	    (setq statement (upcase statement))
	  (setq statement (downcase statement)))
	(insert (concat "$" statement)))
    (if (<= (minibuffer-depth) 0) (use-global-map global-map))
    (insert "")))	;insert dummy string to fontify(Emacs20)

(defun gams-set-lst-filename ()
  (let (fname)
    (setq fname (gams-search-lst-file))
    (setq gams-lst-file nil
	  gams-lst-file-full nil)
    (when fname
      (setq gams-lst-file fname
	    gams-lst-file-full (expand-file-name fname)))))

(defun gams-get-lst-filename ()
  (let (lst-file)
    (gams-set-lst-filename)
    (if gams-lst-file-full
	(when (file-exists-p gams-lst-file-full)
	  (setq lst-file gams-lst-file-full))
      (setq lst-file (gams-get-lst-filename-sub)))
    lst-file))

(defun gams-search-lst-file ()
  (let (reg val qstr beg end)
    (save-excursion
      (goto-char (point-min))
      (if (and (looking-at "^*#!")
	       (re-search-forward "[ \t]+\\(o\\|output\\)=\\([^ \n]+\\)"
				  (line-end-position) t))
	  (setq val (gams*buffer-substring (match-beginning 2)
					   (match-end 2)))
	(setq reg "^[*][ \t]*gams-lst-file[ \t]*:[ \t]*")
	(goto-char (point-min))
	(when (re-search-forward reg nil t)
	  (if (looking-at "[\"']")
	      (progn
		(setq qstr (gams*buffer-substring (match-beginning 0)
						  (match-end 0)))
		(forward-char 1)
		(setq beg (point))
		(if (search-forward qstr nil (line-end-position))
		    (setq end (1- (point)))
		  (setq end (line-end-position)))
		(setq val (gams*buffer-substring beg end)))
	    (setq val (gams*buffer-substring
		       (point) (line-end-position)))))))
    (when val
      (setq val (substring val 0 (string-match "[ \t]+$" val))))
    val))

(defun gams-get-lst-filename-sub ()
"Return the LST file name corresponding to the current GMS file buffer."
  (let ((file-buffer-gms (buffer-file-name))
	(ext-up (concat "." (upcase gams-lst-extention)))
	(ext-down (concat "." (downcase gams-lst-extention)))
	dir-gms	file-noext file-lst file-gms)
    ;; Store the GMS file name.
    (setq dir-gms (file-name-directory file-buffer-gms))
    (setq file-gms (file-name-nondirectory file-buffer-gms))
    (setq file-noext (file-name-sans-extension file-gms))
    ;; Search the LST file name
    (cond
     ((file-exists-p
       (concat dir-gms (upcase file-noext) ext-up))
      (setq file-lst (concat dir-gms (upcase file-noext) ext-up)))
     ((file-exists-p
       (concat dir-gms file-noext ext-down))
      (setq file-lst (concat dir-gms file-noext ext-down)))
     ((file-exists-p
       (concat dir-gms file-noext ext-up))
      (setq file-lst (concat dir-gms file-noext ext-up)))
     ((file-exists-p
       (concat dir-gms (upcase file-noext) ext-down))
      (setq file-lst (concat dir-gms (upcase file-noext) ext-down)))
     ((file-exists-p
       (concat dir-gms (downcase file-noext) ext-down))
      (setq file-lst (concat dir-gms (downcase file-noext) ext-down)))
     ((file-exists-p
       (concat dir-gms (downcase file-noext) ext-up))
      (setq file-lst (concat dir-gms (downcase file-noext) ext-up)))
     (t
      (message "LST file does not exist!")))
    ;; Return the name.
    file-lst))

(defun gams-file-attributes (file)
  (if gams-emacs-21
      (file-attributes file)
    (file-attributes file t)))

(defun gams-get-lst-modified-time (lst)
  (format-time-string "%x %H:%M" (nth 5 (gams-file-attributes lst))))

(defun gams-view-lst ()
  "Switch to the LST file buffer and show the error message."
  (interactive)
  (let ((file-lst (gams-get-lst-filename)))
    (if file-lst
	;; If the LST file exists.
	(progn
	 (let ((lst-buffer))
	   (if (find-buffer-visiting file-lst)
	       ;; If file-lst is already opened.
	       (progn
		 (set-buffer (find-buffer-visiting file-lst))
		 (if (verify-visited-file-modtime (current-buffer))
		     ;; If lst file is not changed
		     (progn
		       (switch-to-buffer (current-buffer))
		       ;; View error.
		       (gams-lst-view-error))
		   ;; If lst file is chenged, kill-buffer.
		   (set-buffer-modified-p nil)
		   (kill-buffer (find-buffer-visiting file-lst))
		   (find-file file-lst)
		   (goto-char (point-min))
		   (gams-lst-mode)
		   (gams-lst-view-error)))
	     ;; if file-lst isn't opened.
	     (find-file file-lst)
	     (goto-char (point-min))
	     (gams-lst-mode)
	     (gams-lst-view-error))))
      ;; If the LST file not exits. 
      (message "The LST file does not exist!") nil)))

(defun gams-jump-to-lst ()
  "Switch to the LST file buffer."
  (interactive)
  (let ((file-lst (gams-get-lst-filename)))
    (if file-lst
	;; If lst file exists
	(progn
	  (let ((lst-buffer))
	    ;; lst file is already opened?
	    (if (find-buffer-visiting file-lst)
		;; If file-lst is already opened.
		;; lst file is modified?
		(if (verify-visited-file-modtime
		     (find-buffer-visiting file-lst))
		    ;; If not modified.
		    (pop-to-buffer (find-buffer-visiting file-lst))
		  ;; If modified.
		  (set-buffer-modified-p nil)
		  (kill-buffer (find-buffer-visiting file-lst))
		  (find-file file-lst)
		  (gams-lst-mode))
	      ;; If file-lst isn't opened, open it.
	      (find-file file-lst)
	      (gams-lst-mode)))
	  (recenter))
      ;; LST file does not exits.
      (message "The LST file does not exist!"))))

;;; Comment insertion.
(defun gams-insert-comment ()
  "Insert a comment template defined by `gams-user-comment'."
  (interactive)
  (let ((use-comment gams-user-comment)
	point-b point-c)
    (save-excursion
      (insert gams-user-comment)
      (setq point-b (point)))
    (when (re-search-forward "%" point-b t)
      (replace-match ""))))

;;;;; fill-paragraph.

;;; Fill paragraph function.  This is from "lisp-mode.el"
;;; (`lisp-fill-paragraph').  I changed ";" in the original function to
;;; "\\(*\\)".  This function is likely not to work well in many cases.
(defun gams-fill-paragraph (&optional justify)
  "Like \\[fill-paragraph], but handle GAMS comment.
If any of the current line is a comment, fill the comment or the
paragraph of it that point is in, preserving the comment's indent
and initial *."
  (interactive "P")
  (let (
	;; Non-nil if the current line contains a comment.
	has-comment
	;; Non-nil if the current line contains code and a comment.
	has-code-and-comment
	;; If has-comment, the appropriate fill-prefix for the comment.
	comment-fill-prefix
	)
    ;; Figure out what kind of comment we are looking at.
    (setq paragraph-start gams-paragraph-start)
    (message paragraph-start)
    (save-excursion
      (beginning-of-line)
      (cond
       ;; A line with nothing but a comment on it?
       ((looking-at (concat "^\\([" gams-comment-prefix "]\\)[" gams-comment-prefix " \t]*"))
	(setq has-comment t
	      comment-fill-prefix (gams*buffer-substring (match-beginning 0)
							 (match-end 0))))
       ;; A line with some code, followed by a comment?  Remember that the
       ;; semi which starts the comment shouldn't be part of a string or
       ;; character.
;;        ((condition-case nil
;; 	    (save-restriction
;; 	      (narrow-to-region (point-min)
;; 				(save-excursion (end-of-line) (point)))
;; 	      (while (not (looking-at ";\\|$"))
;; 		(skip-chars-forward "^;\n\"\\\\?")
;; 		(cond
;; 		 ((eq (char-after (point)) ?\\) (forward-char 2))
;; 		 ((memq (char-after (point)) '(?\" ??)) (forward-sexp 1))))
;; 	      (looking-at ";+[\t ]*"))
;; 	  (error nil))
;; 	(setq has-comment t has-code-and-comment t)
;; 	(setq comment-fill-prefix
;; 	      (concat (make-string (/ (current-column) 8) ?\t)
;; 		      (make-string (% (current-column) 8) ?\ )
;; 		      (buffer-substring (match-beginning 0) (match-end 0)))))
       ))

    (if (not has-comment)
        ;; `paragraph-start' is set here (not in the buffer-local
        ;; variable so that `forward-paragraph' et al work as
        ;; expected) so that filling (doc) strings works sensibly.
        ;; Adding the opening paren to avoid the following sexp being
        ;; filled means that sexps generally aren't filled as normal
        ;; text, which is probably sensible.  The `;' and `:' stop the
        ;; filled para at following comment lines and keywords
        ;; (typically in `defcustom').
 	(let ((paragraph-start (concat paragraph-start ""))
;; 	(let ((paragraph-start "[\t\n\f]")
	      (temp-po (gams-in-on-off-text-p))
	      beg end)
	  (if temp-po
	      (save-restriction
		(narrow-to-region (car temp-po) (car (cdr temp-po)))
		(fill-paragraph justify))
          (fill-paragraph justify)))
      ;; Narrow to include only the comment, and then fill the region.
      (save-excursion
	(save-restriction
	  (beginning-of-line)
	  (narrow-to-region
	   ;; Find the first line we should include in the region to fill.
	   (save-excursion
	     (while (and (zerop (forward-line -1))
			 (looking-at (concat "^\\([" gams-comment-prefix "]\\)"))))
	     ;; We may have gone too far.  Go forward again.
	     (or (looking-at (concat "^\\([" gams-comment-prefix "]\\)"))
		 (forward-line 1))
	     (point))
	   ;; Find the beginning of the first line past the region to fill.
	   (save-excursion
	     (while (progn (forward-line 1)
			   (looking-at (concat "^\\([" gams-comment-prefix "]\\)"))))
	     (point)))
	  ;; Lines with only * on them can be paragraph boundaries.
	  (let* ((paragraph-start
		  (concat paragraph-start "\\|^\\([" gams-comment-prefix "]\\)$"))
		 (paragraph-separate
		  (concat paragraph-start "\\|^\\([" gams-comment-prefix "]\\)$"))
		 (paragraph-ignore-fill-prefix nil)
		 (fill-prefix comment-fill-prefix)
		 (after-line (if has-code-and-comment
				 (save-excursion
				   (forward-line 1) (point))))
		 (end (progn
			(forward-paragraph)
			(or (bolp) (newline 1))
			(point)))
		 ;; If this comment starts on a line with code,
		 ;; include that like in the filling.
		 (beg (progn (backward-paragraph)
			     (if (eq (point) after-line)
				 (forward-line -1))
			     (point))))
	    (fill-region-as-paragraph beg end
				      justify nil
				      (save-excursion
					(goto-char beg)
					(if (looking-at fill-prefix)
					    nil
					  (re-search-forward comment-start-skip)
					  (point))))))))
    t))

;;; Process handling.

;;; Most of the codes for process handling are from epo.el, epolib.el,
;;; epop.el in the `EPO' package written by Yuuji Hirose.  I modified
;;; them.

;;; From epolib.el
(defun gams*window-list ()
  "Return visible window list."
  (let* ((curw (selected-window))
	 (win curw)
	 (wlist (list curw)))
    (while (not (eq curw (setq win (next-window win))))
      (or (eq win (minibuffer-window))
	  (setq wlist (cons win wlist))))
    wlist))

(defun gams*smart-split-window (height)
  "Split current window wight specified HEIGHT.
If HEIGHT is number, make a new window that has HEIGHT lines.
If HEIGHT is string, make a new window that occupies HEIGT % of screen height.
Otherwise split window conventionally."
  (if (one-window-p t)
      (split-window
       (selected-window)
       (max
        (min
         (- (gams*screen-height)
            (if (numberp height)
                (+ height 2)
              (/ (* (gams*screen-height)
                    (string-to-number height))
                 100)))
         (- (gams*screen-height) window-min-height 1))
        window-min-height))))

(defun gams*process-caluculate-time (begtime)
  "Calculate time from BEGTIME to now and return it."
  (let ((curr-time
	 (floor
	  (- (string-to-number (format-time-string "%s")) begtime)))
	hour mini seco)
    (setq curr-time (or curr-time 0))
    (setq hour (number-to-string (/ curr-time 3600))
	  curr-time (% curr-time 3600)
	  mini (number-to-string (/ curr-time 60))
	  seco (number-to-string (% curr-time 60)))
    (when (equal (length hour) 1)
      (setq hour (concat "0" hour)))
    (when (equal (length mini) 1)
      (setq mini (concat "0" mini)))
    (when (equal (length seco) 1)
      (setq seco (concat "0" seco)))
    (list hour mini seco)))

(defcustom gams-process-log-to-file nil
  "If non-nil, GAMS log (the content of process buffer) is written down to log file."
  :type 'boolean
  :group 'gams)

(defcustom gams-log-file-extension "glg"
  "The extension of GAMS log file."
  :type 'string
  :group 'gams)

;;; From epop.el
(defun gams*process-sentinel (proc mess)
  "Display the end of process buffer."
  (cond
   ((memq (process-status proc) '(signal exit))
    (save-excursion
      (let ((sw (selected-window)) w err curr-time temp)
	(set-buffer (process-buffer proc))
	(goto-char (point-max))
	(insert
	 (format "\nGAMS process finished at %s\n" (current-time-string)))
	(setq temp (gams*process-caluculate-time
		    gams-ps-compile-start-time))
	(insert
	 (format "Total compilation time is %s:%s:%s.\n"
		 (car temp)
		 (nth 1 temp)
		 (nth 2 temp)))
	(setq gams-ps-compile-start-time 0)
	;; log file.
	(when gams-process-log-to-file
	  (let* ((gms-file (buffer-file-name gams-ps-gms-buffer))
		 (log-file
		  (concat (expand-file-name (file-name-sans-extension gms-file)) "." gams-log-file-extension)))
	    (write-region (point-min) (point-max) log-file)))
	(when (not gams-xemacs)
	  (modify-frame-parameters
	   gams-ps-frame (list (cons 'name gams-ps-orig-frame-title))))
	(setq err (gams-process-error-exist-p))
	(cond
	 ((and gams:frame-feature-p
	       (setq w (get-buffer-window (current-buffer) t)))
	  (select-frame (window-frame w))
	  (select-window w)
	  (goto-char (point-max))
	  (recenter -1))
	 ((setq w (get-buffer-window (current-buffer)))
	  (select-window w)
	  (goto-char (point-max))
	  (recenter -1)))
	(select-window sw)
	(if err
	    (message (concat
		      (format "GAMS ended with `%s' errors!  " err)
		      "C-cC-v or [F10]= LST file."))
	  (message (concat
		    "GAMS process has finished.  "
		    "C-cC-v or [F10]= LST file, [F11]= OUTLINE."))))))))

(defun gams-process-error-exist-p ()
  "Judge whether GAMS process ends with errors."
  (let (flag)
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "\\*\\*\\* Status: \\([a-zA-Z]+\\) error" nil t)
	(setq flag (gams*buffer-substring (match-beginning 1)
					  (match-end 1)))))
    flag))

;;; New function.
(defun gams-popup-process-buffer (&optional select)
  "Popup the GAMS process buffer.
Moreover, If you attach the universal-argument or if the process buffer is
already popped up, then move to the process buffer."
  (interactive "P")
  (let ((pbuff (gams-get-process-buffer)))
    (if (get-buffer pbuff)
	(gams*showup-buffer pbuff select)
      (message "There is no GAMS process buffer associated with this buffer!"))))


(defun gams*showup-buffer (buffer &optional select)
  "Make BUFFER show up in certain window (except selected window).
Non-nil for optional argument SELECT keeps selection to the target window."
  (let (w)
    (if (setq w (get-buffer-window buffer))
	;; Already visible, just select it.
	(select-window w)
      ;; Not visible
      (let ((sw (selected-window))
	    (wlist (gams*window-list)))
	(cond
	 ((eq (current-buffer) (get-buffer buffer)) nil)
	 ((one-window-p)
	  (gams*smart-split-window gams-default-pop-window-height)
	  (select-window (next-window nil 1))
	  (switch-to-buffer (get-buffer-create buffer))
	  (recenter -1))
	 ;; (other-window 1))
	 ((= (length wlist) 2)
	  (select-window (get-lru-window))
	  (switch-to-buffer (get-buffer-create buffer)))
	 (t				;more than 2windows
	  (select-window (next-window nil 1))
	  (switch-to-buffer (get-buffer-create buffer))))
	(or select (select-window sw))))))

(setq-default gams-ps-gms-buffer nil)
(setq-default gams-ps-compile-start-time nil)

(defun gams*start-process-other-window (name commandline)
  "Start command line (via shell) in the next window."
  (let ((sw (selected-window))
	(cur-buff (current-buffer))
	p
	(dir default-directory)
	pbuff-name)
    (setq pbuff-name (gams-get-process-buffer))
    (if gams-always-popup-process-buffer
	(gams*showup-buffer pbuff-name t) ;popup buffer and select it.
      (set-buffer (get-buffer-create pbuff-name)))
    (current-buffer) ;; for debug.
    (gams-ps-mode)
    (setq gams-ps-gms-buffer cur-buff)
    (erase-buffer)
    (cd dir)
    (setq default-directory dir)
    (insert commandline "\n")
    (insert
     (format "Start at %s\n\n " (current-time-string)))
    (setq gams-ps-compile-start-time
	  (string-to-number (format-time-string "%s")))
    (goto-char (point-max))
    (set (make-local-variable 'gams:process-command-name) name)
    (set-process-sentinel
     (setq p (start-process name pbuff-name shell-file-name
			    gams:shell-c commandline))
     'gams*process-sentinel)
    (if (and (not gams-xemacs) gams-use-process-filter)
	(set-process-filter p 'gams*process-filter)
      (set-process-filter p nil))
    (message "Running GAMS.  Type C-cC-l to popup the GAMS process buffer.")
    (set-marker (process-mark p) (1- (point)))
    (select-window sw)))

(defvar gams-ps-mode-map (make-keymap) "Keymap used in gams ps mode")
(define-key gams-ps-mode-map "\C-c\C-l" 'gams-ps-back-to-gms)

;;; New variable.
(defvar gams-use-process-filter nil
  "Non-nil means use the process output filter.")
(setq gams-use-process-filter nil)

(defun gams*process-filter (proc string)
  (let ((p-buff (process-buffer proc))
	po-beg po-end po-pair m title)
    (save-excursion
      (set-buffer p-buff)
      (setq m (point-marker))
      (goto-char (point-max))
      (backward-char 1)
      (insert string)
      (when (and (setq po-beg (string-match "[[]" string))
		 (setq po-end (string-match "[]]" string)))
	(setq title (substring string (1+ po-beg) po-end))
	(modify-frame-parameters gams-ps-frame (list (cons 'name title))))
      (goto-char (marker-position m))
      (set-marker m nil))))

(setq-default gams-ps-frame nil)
(setq-default gams-ps-orig-frame-title nil)
(define-derived-mode gams-ps-mode fundamental-mode "GAMS-PS"
  "Mode for GAMS process buffer."
  (kill-all-local-variables)
  (setq major-mode 'gams-ps-mode)
  (setq mode-name "GAMS-PS")
  (mapc
   'make-local-variable
   '(gams-ps-compile-start-time
     gams-ps-gms-buffer))
  (use-local-map gams-ps-mode-map)
  (when (not gams-xemacs)
    (make-local-variable 'gams-ps-orig-frame-title)
    (setq gams-ps-orig-frame-title (frame-parameter nil 'name))
    (make-local-variable 'gams-ps-frame)
    (setq gams-ps-frame (selected-frame)))
  (setq font-lock-mode nil)
  )

(defun gams-ps-back-to-gms ()
  "Jump back to gms buffer from GAMS process buffer."
  (interactive)
  (let ((gw (get-buffer-window gams-ps-gms-buffer)))
    (if gw
	(select-window gw)
      (delete-other-windows)
      (gams*smart-split-window gams-default-pop-window-height)
      (switch-to-buffer gams-ps-gms-buffer)
      (recenter))))
  
(defun gams*get-builtin (keyword)
  "Get built-in string specified by KEYWORD in current buffer."
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (if (re-search-forward
	   (concat
	    "^" (regexp-quote (concat comment-start keyword)))
	    (line-end-position) t)
	  (let ((peol (progn (end-of-line) (point))))
	    (gams*buffer-substring
	     (progn
	       (goto-char (match-end 0))
	       (skip-chars-forward " \t")
	       (point))
	     (if (and comment-end
		      (stringp comment-end)
		      (string< "" comment-end)
		      (re-search-forward
		       (concat (regexp-quote comment-end)
			       "\\|$")
		       peol 1))
		 (match-beginning 0)
	       peol)))))))

(defun gams*update-builtin (keyword newdef)
  "Update built-in KEYWORD to NEWDEF"
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (if (re-search-forward
	   (concat "^"
		   (regexp-quote (concat comment-start keyword)))
		   (line-end-position) t)
	  (let ((peol (progn (end-of-line) (point))))
	    (goto-char (match-end 0))
	    (skip-chars-forward " \t")
	    (delete-region
	     (point)
	     (if (and comment-end (stringp comment-end)
		      (string< "" comment-end)
		      (search-forward comment-end peol t))
		 (progn (goto-char (match-beginning 0)) (point))
	       peol))
	    (insert newdef))
	(while (and (progn (skip-chars-forward " \t")
			   (looking-at (regexp-quote comment-start)))
		    (not (eobp)))
	  (forward-line 1))
	(open-line 1)
	(insert comment-start keyword newdef comment-end)))))

(defun gams-get-program-filename (&optional nodir noext)
  ""
  (cond
   ((and nodir (not noext)
    (file-name-nondirectory (buffer-file-name (current-buffer)))))
   ((and (not nodir) noext)
    (file-name-sans-extension (buffer-file-name (current-buffer))))
   ((and nodir noext)
    (file-name-nondirectory
     (file-name-sans-extension (buffer-file-name (current-buffer)))))
   (t
    (buffer-file-name (current-buffer)))))

(defun gams-get-process-buffer ()
  "Create the name of GAMS process buffer for the current buffer."
  (if gams-multi-process
      ;; Multi-process.
      (concat gams*command-process-buffer " on "
	      (buffer-name)
	      "*")
;;	      (gams-get-program-filename t) "*")
      ;; Not multi-process.
    (concat gams*command-process-buffer "*")))

(defun gams*start-processor (&optional ask)
  "Start GAMS on the current file."
  (interactive)
  (gams-set-lst-filename)
  (let* ((builtin "#!")
	 (command "compile")
	 (fname (file-name-nondirectory buffer-file-name))
	 (qc "")
	 arg string newarg prompt out-opt)
    (when (string-match " " fname)
      (if (string-match gams:w32-system-shells shell-file-name)
	  (setq fname (concat "\"" fname "\""))
	(setq fname (concat "'" fname "'"))))
    (when gams-lst-file
      (setq out-opt (concat " o=" gams-lst-file "")))
    (setq arg
	  (or
	   ;; if built-in processor specified, use it
	   (and builtin (gams*get-builtin builtin))
	   (concat (gams-opt-return-option t) " "
		   fname " "
		   (gams-opt-return-option)
		   out-opt)))
    (basic-save-buffer)
    ;(setq arg (concat command " " arg))
    (gams*start-process-other-window
     command
     (cond
      (prompt
       (read-string "Execute: " arg))
      (ask
       (setq newarg (read-string "Edit command if you want:  " arg))
       (if (and builtin
		(not (string= newarg arg))
		(y-or-n-p "Use this command line also in the future? "))
	   (progn
	     (gams*update-builtin builtin newarg)
	     (message "The command line is inserted in the fisrt line in this file!")))
	 newarg)
      (t arg))
     )
    ))

(defun gams*kill-processor ()
  "Stop (kill) a GAMS process."
  (interactive)
  (let ((p (get-buffer-process
	    (get-buffer-create (gams-get-process-buffer)))))
    (if p (progn (kill-process p)
		(message "GAMS process was interrupted."))
      (message "GAMS process has already exited."))))

(defun gams-start-menu (&optional ask char)
  "Evoke the GAMS process menu.
Optional second argument CHAR is for non-interactive call from menu."
  (interactive "P")
  (message (format "Start GAMS (%c), Kill GAMS process (%c), Change GAMS command (%c), Change options (%c)."
		   gams-run-key gams-kill-key gams-change-command-key gams-option-key))
  (let ((c (or char (read-char))))
    (cond ((equal c gams-run-key)
	   (gams*start-processor ask))
	  ((equal c gams-kill-key)
	   (gams*kill-processor))
	  ((equal c gams-option-key)
	   (gams-option))
	  ((equal c gams-change-command-key)
	   (gams-change-gams-command))
	  (t (message "No such choice `%c'" c)))))

(defun gams-recenter ()
  "Recentering."
  (interactive)
  (when (and font-lock-mode gams-recenter-font-lock (not gams-xemacs))
    (font-lock-fontify-block))
  (recenter))
  
;;; View manuals.

(defvar gams-read-docs-history nil "Holds history of dollar control.")
(put 'gams-read-dollar-history 'no-default t)

(defvar gams-read-doc-completion-map nil
  "*Key map for gams-read-docs.")
(if gams-read-doc-completion-map nil
   (setq gams-read-doc-completion-map
	 (copy-keymap minibuffer-local-completion-map))
   (define-key gams-read-doc-completion-map
     " " 'minibuffer-complete)
   (define-key gams-read-doc-completion-map
     "\C-i" 'minibuffer-complete))

(defun gams-read-docs (prompt &optional predicate initial)
  "Read a GAMS dollar control operation with completion."
  (let ((minibuffer-completion-table
	 (append gams-manuals-alist)))
    (read-from-minibuffer
     prompt initial gams-read-doc-completion-map nil
     'gams-read-docs-history)))

(defvar gams-manuals-alist
  (if gams-win32
      (append gams-manuals-alist-base
	      '(("McCarl-User-Guide-chm" . "mccarlgamsuserguide.chm")
		("Ask-Tool-chm" . "ask.chm")
		("GAMSIDE-Tool-chm" . "gamside.chm")
		("GDX2ACESS-Tool-chm" . "gdx2access.chm")
		("GDXUTILS-Tool-chm" . "gdxutils.chm")
		("GDXVIEWER-Tool-chm" . "gdxviewer.chm")
		("MDB2GMS-Tool-chm" . "mdb2gms.chm")
		("SHELLEXECUTE-Tool-chm" . "shellexecute.chm")
		("SQL2GMS-Tool-chm" . "sql2gms.chm")
		("XLS2GMS-Tool-chm" . "xls2gms.chm")))
      gams-manuals-alist-base)
  "Alist of the name of GAMS manual files and its abbreviated name (label).
This list is created from GAMS 22.5 windows version..pdf")

(defun gams-view-docs ()
  "View GAMS manuals.

Envoke the PDF file (or windows help file) viewer and see GAMS
manuals.  The viewer is determined by the variable
`gams-docs-view-program'.  The directory of GAMS documents is
determined by the variable `gams-docs-directory'.  By default,
`gams-docs-directory' is set to `gams-system-directory' + docs.

The list of documents displayed as candidates is created from
GAMS ver 22.5 for windows.  If you use other version of GAMS,
some documents may not be available on you system."
  (interactive)
  (unwind-protect
      (let* ((completion-ignore-case t)
	     (docs-dir (file-name-as-directory gams-docs-directory))
	     (source-window (selected-window))
	     guess
	     (statement
	      (progn
		(setq guess "User-Manual")
		(gams-read-docs
		 (format "View which manual? (default = %s): " guess))))
	     (statement (if (string= statement "") guess statement))
	     file-name
	     file-name-full
	     (buf (get-buffer-create "*View GAMS manual*"))
	     proc
	     ) ;;let* ends.
	(setq file-name (assoc statement gams-manuals-alist))
	(if (not file-name)
	    (message "Enter the registered label.")
	  (setq file-name-full
		(car (find-lisp-find-files
		      docs-dir (cdr file-name))))
	  (if (not file-name-full)
	      (message (format "Manual file for %s is not found." statement))
	    ;; Start process.
	    (setq proc
		  (start-process
		   "manual" buf gams-docs-view-program file-name-full))
	    (message "Starting manual viewer...")
	    )))))

;;; New command.
(defun gams-from-gms-to-outline ()
  "Jump directly to the OUTLINE buffer from gms file buffer.
If any errors exists, just move to the LST buffer."
  (interactive)
  (when (gams-view-lst)
    (gams-outline)))

;;;;; Commands for ontext-offtext pair.
(defun gams-insert-on-off-text (arg)
  "Insert an ontext-offtext pair.
If you attach universal-argument, this encloses the specified region with
an ontext-offtext pair."
  (interactive "p")
  (let* ((up (if gams-dollar-control-upcase t nil))
	 (on-string (if up "$ONTEXT" "$ontext"))
	 (off-string (if up "$OFFTEXT" "$offtext")))
    (if (equal arg 1)
	;; No universal argument.
	(progn
	  (beginning-of-line)
	  (insert (concat on-string "\n\n" off-string "\n"))
	  (forward-line -2))
      ;; Comment out region.
      (let ((beg (mark)) (cur-po (point))
	    (cur-po2 (point))
	    po-temp)
	(when (>= beg cur-po)
	  (setq beg cur-po
		cur-po (mark)))
	(goto-char cur-po)
	(set-mark (point))
	(goto-char beg)
	(insert (concat on-string "\n"))
	(goto-char (mark))
	(insert (concat off-string "\n"))
	(when font-lock-mode
	  (font-lock-fontify-block))))))

;;; Jump between ontext and offtext.
(defun gams-judge-on-off-text ()
  "Judge whether curson is on ontext or offtext.

ontext => return on and point,
offtext => return off and point,
Otherwise => return nil and nil.

If ontext and offtext are commented out, return *on and *off respectively."
  
  (let (point-beg temp-text)
    (save-excursion
      (beginning-of-line)
;;      (skip-chars-backward "^ \t\n")
      (when (looking-at (concat "^\\([" gams-comment-prefix "]?\\)[ \t]*[$]\\(on\\|off\\)text"))
	(setq point-beg (match-beginning 0))
	(setq temp-text
	      (downcase (gams*buffer-substring (match-beginning 2)
					  (match-end 2))))
	(if (string-match gams-comment-prefix (gams*buffer-substring (match-beginning 1)
						  (match-end 1)))
	    (setq temp-text (concat "*" temp-text)))))
    (cons temp-text point-beg)))

(defun gams-search-on-off-text (cons)
  ""
  (let ((type (car cons))
	(point (cdr cons))
	(regexp (concat "^[" gams-comment-prefix "]?[ \t]*$\\(on\\|off\\)text"))
	flag match match-point)
    (save-excursion
      (cond
       ((equal type "on")
	(forward-char 1)
	(when (re-search-forward regexp nil t)
	  (setq match-point (match-beginning 0))
	  (setq match (gams*buffer-substring (match-beginning 1)
					(match-end 1)))))
       ((equal type "*on")
	(forward-char 1)
	(when (re-search-forward regexp nil t)
	  (setq match-point (match-beginning 0))
	  (setq match (concat "*" (gams*buffer-substring (match-beginning 1)
						    (match-end 1))))))
       ((equal type "off")
	(forward-char -1)
	(when (re-search-backward regexp nil t)
	  (setq match-point (match-beginning 0))
	  (setq match (gams*buffer-substring (match-beginning 1)
					(match-end 1)))))
       ((equal type "*off")
	(forward-char -1)
	(when (re-search-backward regexp nil t)
	  (setq match-point (match-beginning 0))
	  (setq match (concat "*" (gams*buffer-substring (match-beginning 1)
						    (match-end 1))))))))
    (cons match match-point)))

(defun gams-jump-on-off-text ()
  "Jump between ontext-offtext.

If you execute this command on ontext (offtext), then you jump to the
corresponding offtext (ontext)."
  (interactive)
  (let* ((temp (gams-judge-on-off-text))
	 (flag (car temp))
	 (point (cdr temp))
	 (cur-po (point))
	 (case-fold-search t)
	 match-flag match-point)
    (when flag
      (setq match-flag (car (gams-search-on-off-text temp)))
      (setq match-point (cdr (gams-search-on-off-text temp))))
  ;; ontext or offtext.
  (cond
   ((not flag)
    (message "This command is valid only if the cursor is on either ontext or offtext."))
   ((and point match-point
	 (not (equal flag match-flag)))
    (goto-char match-point)
    (if (equal flag "on")
	(message "The corresponding offtext is found!")
      (message "The corresponding ontext is found!")))
   ((and point (or (not match-point)
		   (equal flag match-flag)))
    (if (equal flag "on")
	(message "No corresponding offtext exists!")
	    (message "No corresponding ontext exists!"))))))

(defun gams-remove-on-off-text ()
  "Remove the pair of ontext-offtext.

If you evoke this command on ontext (offtext), then both ontext
(offtext) and the corresponding offtext (ontext) are removed."
  (interactive)
  (gams-modify-on-off-text t))

(defun gams-comment-on-off-text ()
  "Comment or uncomment the pair of ontext-offtext."
  (interactive)
  (gams-modify-on-off-text))

(defun gams-modify-on-off-text (&optional delete)
  "Modify the ontext-offtext pair.  If DELETE is non-nil, delte the pair.
Otherwise, comment out or uncomment out the pair."
  (save-excursion
    (let* ((temp (gams-judge-on-off-text))
	   (flag-beg (car temp))
	   (po-beg (cdr temp))
	   flag-com)
      (if (not flag-beg)
	  (message
	   (concat "This command is valid only if the cursor is "
		   "on either ontext or offtext."))
	(let* ((temp-end (gams-search-on-off-text (cons flag-beg po-beg)))
	       (beg-end (car temp-end))
	       (po-end (cdr temp-end)))
	  (if (not beg-end)
	      (cond
	       ((or (equal flag-beg "on")
		    (equal flag-beg "*on"))
		(message "No corresponding offtext is found!"))
	       ((or (equal flag-beg "off")
		    (equal flag-beg "*off"))
		(message (format "No corresponding ontext is found!"))))
	    ;; Found.
	    (when (string-match "\\*" flag-beg)
	      (setq flag-com t))
	    ;; If DELETE is non-nil.
	    (if delete
		(progn
		  (if flag-com
		      (message
		       (concat "Can't delete commented ontext-offtext!  "
			       "First uncoment them."))
		    (message "Delete the pair of ontext-offtext.")
		    (goto-char po-end)
		    (beginning-of-line)
		    (sit-for 1)
		    (delete-region
		     (point)
		     (progn (looking-at "^$\\(on\\|off\\)text") (match-end 0)))
		    (goto-char po-beg)
		    (beginning-of-line)
		    (delete-region
		     (point) (progn (looking-at "^$\\(on\\|off\\)text") (match-end 0)))))
	      ;; Comment or uncomment.
	      (if flag-com
		  ;; Commented ontext offtext.
		  (progn
		    (message "Uncomment the pair of ontext-offtext.")
		    (goto-char po-end)
		    (beginning-of-line)
		    (sit-for 1)
		    (delete-region
		     (point)
		     (progn (looking-at (concat "^[" gams-comment-prefix "][ \t]*"))
			    (match-end 0)))
		    (goto-char po-beg)
		    (beginning-of-line)
		    (delete-region
		     (point)
		     (progn
		       (looking-at (concat "^[" gams-comment-prefix "][ \t]*"))
		       (match-end 0))))
		;; Uncommented ontext-offtext.
		(progn
		  (message "Comment out a pair of ontext-offtext.")
		  (goto-char po-end)
		  (beginning-of-line)
		  (sit-for 1)
		  (insert (concat gams-comment-prefix " "))
		  (goto-char po-beg)
		  (if (> po-beg po-end)
		      (forward-char 2))
		  (beginning-of-line)
		  (insert (concat gams-comment-prefix " ")))))))))
    (when font-lock-mode
      (font-lock-fontify-block))))

;;; New function.
(defun gams-goto-matched-paren ()
  "Jump to the matched parenthesis.

The similar function as F8 in GAMSIDE.  This command is vaild only if the
cursor is on the parenthesis."
  (interactive)
  (let ((right 0)
	(left 0)
	po)
    (save-excursion
      (cond
       ((equal "(" (char-to-string (following-char)))
	(setq left 1)
	(forward-char 1))
       ((equal ")" (char-to-string (preceding-char)))
	(setq right 1)
	(forward-char -1)))
      (cond
       ((equal left 1)
	;; Search ")"
	(progn
	  (catch 'found
	    (while t
	      (if (re-search-forward "\\([)]\\)\\|\\([(]\\)" nil t)
		  (progn
		    (if (match-beginning 1)
			(setq right (+ 1 right))
		      (setq left (+ 1 left)))
		    (when (equal right left)
		      (setq po (point))
		      (throw 'found t)))
		(message "No matched parenthesis")
		(throw 'found t))))))
       ((equal right 1)
	;; Search "("
	(catch 'found
	  (while t
	    (if (re-search-backward "\\([)]\\)\\|\\([(]\\)" nil t)
		(progn
		  (if (match-beginning 1)
		      (setq right (+ 1 right))
		    (setq left (+ 1 left)))
		  (when (equal right left)
		    (setq po (point))
		    (throw 'found t)))
	      (message "No matched parenthesis")
	      (throw 'found t)))))
       (t (message "This command is valid only if the cursor is on `(' or `)'."))))
    (when po
      (goto-char po)
      (message "Jump to the matched parenthesis")
      )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Insert parens, quotations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; From yatex.el
(defun gams-insert-parens (arg)
  "Insert a parenthesis pair if `gams-close-paren-always' is non-nil.
If you attach the prefix argument, just insert `('."
  (interactive "P")
  (if gams-close-paren-always
      (if arg
	  (insert "(")
	(insert "()")
	(backward-char 1))
    (insert "(")))

(defun gams-close-quotation-p (&optional double)
  "If the single (or double) quotation should be closed, return t.
Otherwise nil.  If DOUBLE is non-nil, check double quoatation."
  (let ((cur-po (point))
	(count 0) flag
	(str (if double "\"" "'")))
    (save-excursion
      (beginning-of-line)
      (catch 'found
	(while t
	  (if (re-search-forward str cur-po t)
	      (setq count (1+ count))
	    (when (oddp count)
	      (setq flag t))
	    (throw 'found t)))))
    flag))

(defun gams-insert-double-quotation (&optional arg)
  "Insert double quotation.
If `gams-close-double-quotation-always' is non-nil,
insert a double quotation pair."
  (interactive "P")
  (if arg
      (insert "\"")
    (if gams-close-double-quotation-always
	(if (gams-close-quotation-p t)
	    (insert "\"")
	  (insert "\"\"") (backward-char 1))
      (insert "\""))))

(defun gams-insert-single-quotation (&optional arg)
  "Insert single quotation.
If `gams-close-single-quotation-always' is non-nil,
insert a single quotation pair."
  (interactive "P")
  (if arg
      (insert "'")
    (if gams-close-single-quotation-always
	(if (gams-close-quotation-p)
	    (insert "'")
	  (insert "''") (backward-char 1))
      (insert "'"))))

;;;;;;;;;;;;;;;;;
; GAMS modlib.
;;;;;;;;;;;;;;;;;

(defun gams-modlib ()
  "Extract a model from GAMS model library."
  (interactive)
  (let* ((buf "*modlib*")
	 (list-name
	  (directory-files
	   (concat
	    (file-name-as-directory gams-system-directory) "modlib")
	   nil ".*[.][0-9]+"))
	 (prog-name
	  (concat
	   (file-name-as-directory gams-system-directory) "gamslib"))
	 alist ele dir)
    (setq alist
    (mapcar
     '(lambda (x)
	(list (substring x 0 (string-match "[.]" x))))
     list-name))
    (setq alist (cons (list "all") alist))
    (setq name
	  (completing-read
	   "Input a model name (type \"all\" if you want to extract all models): "
	   alist))
    (setq dir (read-file-name
	       "Extract the model to which directory?: "
	       nil default-directory))
    (if (file-directory-p dir)
    (if (not (equal "all" name))
	(gams-modlib-extract name dir)
      (mapcar '(lambda (x)
		 (gams-modlib-extract (car x) dir)
		 (message "Extracting all models...  It may take much time."))
	      alist))
    (message "Input directory name!"))))

(defun gams-modlib-extract (name dir)
  "Extract model library NAME to the directory DIR."
  (let ((cur-dir default-directory)
	(pr-name
	 (concat
	  (file-name-as-directory gams-system-directory) "gamslib")))
    (setq default-directory (file-name-as-directory dir))
    (call-process pr-name nil nil nil name)
    (setq default-directory cur-dir)
    (message (format "Extracting %s to %s" name dir))
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Codes for changing command line options.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar gams-user-option-alist nil
  "The list of combinations of options defined by users.
If you register the new option combinations in the process
menu (`C-cC-to'), they are store in this variable and saved into the file
defined by `gams-statement-file'.")

(defvar gams-user-option-alist-initial nil)
(setq gams-user-option-alist-initial gams-user-option-alist)
      
(defvar gams-option-alist nil
  "The list of combinations of options in which
`gams:process-command-option' and `gams-user-option-alist' are combined.")

(defun gams-opt-make-alist (&optional com)
  "Combine `gams:process-command-option' and `gams-user-option-alist'."
  (if com
      (setq gams-command-alist
	    (append
	     (list (cons "default" gams:process-command-name))
	     (reverse gams-user-command-alist)))
    (setq gams-option-alist
	  (append
	   (list (cons "default" gams:process-command-option))
	   (reverse gams-user-option-alist)))))

(setq-default gams-opt-gms-buffer nil)

;;; initialize.
(setq gams-current-option-num "default")

(defun gams-opt-view (&optional com)
  "
com -> gams command
Otherwise -> option

Display the content of `gams-option-alist' in a buffer."
  (interactive)
  (let ((buffer-read-only nil)
	temp-buf
	temp-alist cur-num list-list)
    (setq temp-buf (if com "*Select commands*" "*Select options*"))
    (setq temp-alist (if com gams-command-alist gams-option-alist))
    (setq cur-num (if com gams-current-command-num gams-current-option-num))
    ;;
    (get-buffer-create temp-buf)
    (pop-to-buffer temp-buf)
    (setq buffer-read-only nil)
    (erase-buffer)
    (goto-char (point-min))
    ;; Insert.
    (while temp-alist
      (goto-char (point-max))
      (setq list-list (car temp-alist))
      (if (equal cur-num (car list-list))
	  (insert "*"))
      (move-to-column 2 t)
      (insert (car list-list))
      (move-to-column 20 t)
      (insert (cdr list-list))
      (insert "\n")
;      (gams-lst-insert-item list-list)
      (setq temp-alist (cdr temp-alist)))
    (insert "\n")
    (insert gams-opt-key-mess)
    (insert "\n")
    (goto-char (point-min))
    (setq buffer-read-only t)))

(defun gams-option ()
  "Change the combination of command line options.
The default GAMS command line option is determined by the variable
`gams:process-command-option'."
  (interactive)
  (let ((cur-buf (current-buffer)))
    ;; Display.
    (gams-opt-view)
    ;; Show key in the minibuffer.
    (gams-opt-show-key)
    ;; Start the mode.
    (gams-opt-select-mode cur-buf)
    ))

(defvar gams-opt-select-mode-map (make-keymap) "keymap for gams-mode")
(let ((map gams-opt-select-mode-map))
  (define-key map "n" 'gams-opt-next)
  (define-key map "p" 'gams-opt-prev)
  (define-key map "\r" 'gams-opt-change)
  (define-key map "e" 'gams-opt-edit)
  (define-key map "q" 'gams-opt-quit)
  (define-key map "a" 'gams-opt-add-new-option)
  (define-key map "d" 'gams-opt-delete))

(setq gams-opt-key-mess
  (concat
     "[*] => the current choice, "
     "Key: "     
     "[n]ext, "     
     "[p]rev, "     
     "RET = select, "     
     "[e]dit, "     
     "[a]dd, "     
     "[d]elete, "     
     "[q]uit."))

(defun gams-opt-show-key ()
  (message gams-opt-key-mess))

(defun gams-opt-next ()
  "Next line."
  (interactive)
  (next-line)
  (gams-opt-show-key))

(defun gams-opt-prev ()
  "Previous line."
  (interactive)
  (next-line -1)
  (gams-opt-show-key))

(defun gams-opt-quit ()
  "Quit."
  (interactive)
  (let ((cur-buf (current-buffer)))
    (switch-to-buffer 
     (if (equal mode-name "GAMS-COMMAND")
	 gams-command-gms-buffer
       gams-opt-gms-buffer))
    (kill-buffer cur-buf)
    (delete-other-windows)))

(defun gams-opt-add-new-option-to-alist (option &optional com)
  "Add OPTION to the alist `gams-user-option-alist', and update
`gams-option-alist'."
  (let* ((user-alist (if com gams-user-command-alist gams-user-option-alist))
	 (num (number-to-string (1+ (list-length user-alist)))))
    (if com 
	(setq gams-user-command-alist (cons (cons num option) user-alist))
      (setq gams-user-option-alist (cons (cons num option) user-alist)))
    (gams-opt-make-alist com)))

(defun gams-opt-add-new-option (&optional com)
  "Add a new option combination."
  (interactive)
  (let (opt mess)
    (setq opt (read-string (if com "Insert a new command name: " "Insert a new option set: ")))
    (gams-opt-add-new-option-to-alist opt com)
    (gams-opt-view com)
    (setq mess (if com "Added the new command " "Added the new option "))
    (message (concat mess (format "\"%s\"" opt)))))

(defun gams-opt-renumber (&optional com)
  "Change the number of option alist."
  (let* ((alist (if com gams-user-command-alist gams-user-option-alist))
	 (num (list-length alist))
	 new-alist)
    (while alist
      (setq new-alist
	    (cons (cons (number-to-string num) (cdr (car alist)))
		  new-alist))
      (setq num (1- num))
      (setq alist (cdr alist)))
    (if com
	(setq gams-user-command-alist (reverse new-alist))
      (setq gams-user-option-alist (reverse new-alist)))))

;;; from alist.el
(defun gams-del-alist (key alist)
  "Delete an element whose car equals KEY from ALIST.
Return the modified ALIST."
  (let ((pair (assoc key alist)))
    (if pair
	(delq pair alist)
      alist)))
	    
(defun gams-opt-delete ()
  "Delete the option combination on the current line."
  (interactive)
  (let ((num (gams-opt-return-option-num)))
    (cond
     ((equal num "default")
      (message "You cannot delete the default combination!"))
     ((equal num nil) nil)
     (t
      (message (format "Do you really delete \"%s\"?  Type `y' if yes." num))
      (let ((key (read-char)))
	(if (not (equal key ?y))
	    nil
	  (setq gams-user-option-alist
		(gams-del-alist num gams-user-option-alist))
	  (message (format "Remove \"%s\" from the registered alist." num))
	  ;; renumbering.
	  (gams-opt-renumber)
	  (gams-opt-make-alist)
	  (when (equal num gams-current-option-num)
	    (setq gams-current-option-num "default"))
	  (gams-opt-view)))))))

(defun gams-opt-return-option (&optional com num)
  "Return the option combination of the current line."
  (if com
      (cdr (assoc (or num gams-current-command-num) gams-command-alist))
    (cdr (assoc (or num gams-current-option-num) gams-option-alist))))

(defun gams-opt-return-option-num ()
  "Return the number of the option combination on the current line."
  (interactive)
  (save-excursion
    (let ((end-po (line-end-position))
	  num)
      (beginning-of-line)
      (if (re-search-forward "^\\*?[ \t]+\\([^ \t]+\\)[ \t]+" end-po t)
	  (progn  (setq num (gams*buffer-substring (match-beginning 1)
					      (match-end 1)))))
      num)))
      
(defun gams-opt-change (&optional com)
  "Set the option combination on the current line to the new option combination."
  (interactive)
  (let ((num (gams-opt-return-option-num))
	(cur-buf (current-buffer)))
    (when num
      (if com
	  (setq gams-current-command-num num)
	(setq gams-current-option-num num))
      (message (format
		(if com "GAMS command changed to \"%s\""
		  "GAMS command line option changed to \"%s\"")
		(gams-opt-return-option com)))
      (switch-to-buffer (if com gams-command-gms-buffer gams-opt-gms-buffer))
      (kill-buffer cur-buf)
      (delete-other-windows))))

(defun gams-opt-select-mode (buff)
  "Mode for changing command line options."
  (kill-all-local-variables)
  (setq mode-name "OPTION"
	major-mode 'gams-opt-select-mode)
  (use-local-map gams-opt-select-mode-map)
  (make-local-variable 'gams-opt-gms-buffer)
  (setq gams-opt-gms-buffer buff)
  (setq buffer-read-only t))

(defun gams-register-option ()
  "Save the content of `gams-user-option-alist' into the file
`gams-statement-file'."
  (gams-register-option-command))

(defun gams-register-command ()
  "Save the content of `gams-user-option-alist' into the file
`gams-statement-file'."
  (gams-register-option-command t))

(defun gams-option-updated (&optional com)
  (if com
      (and gams-user-command-alist
	   (not (equal gams-user-command-alist gams-user-command-alist-initial)))
    (and gams-user-option-alist
	 (not (equal gams-user-option-alist gams-user-option-alist-initial)))))

(defun gams-register-option-command (&optional com)
  "Save the content of `gams-user-option-alist' into the file
`gams-statement-file'."
  (interactive)
  (if (gams-option-updated com)
      (progn
	(let* ((temp-buff " *gams-option*")
	       (temp-file gams-statement-file)
	       (temp-alist (if com gams-user-command-alist gams-user-option-alist))
	       (old-alist temp-alist)
	       (alist-name (if com "gams-user-command-alist" "gams-user-option-alist"))
	       new-alist temp-cont)
	  (save-excursion
	    ;; Switch to the temporary buffer.
	    (get-buffer-create temp-buff)
	    (switch-to-buffer temp-buff)
	    ;;      (set-buffer temp-buff)
	    (erase-buffer)
	    ;; Write the content of the alist.
	    (insert (concat "(setq " alist-name " '(\n"))
	    (goto-char (point-max))
	    (mapc '(lambda (x)
		       (insert
			(concat "(\"" (car x) "\" . \"" (cdr x)	"\")\n"))
		       (goto-char (point-max))) temp-alist)
	    (insert "))\n")
	    ;; Check whether the variable is defined correctly.
	    (eval-buffer)
	    ;; Store the content of buffer
	    (setq temp-cont (gams*buffer-substring (point-min) (point-max)))
	    ;; Delete the list-name part.
	    (switch-to-buffer (find-file-noselect temp-file))
	    ;;      (set-buffer (find-file-noselect temp-file))
	    (goto-char (point-min))
	    ;; Check whether the list-name part exists or not.
	    (if (not (re-search-forward
		       (concat
			"\\(setq\\) " alist-name)
		       nil t))
		;; If it doesn't exists, do nothing.
		nil
	      ;; If it exists, delete it.
	      (let (point-beg point-en)
		(goto-char (match-beginning 1))
		(beginning-of-line)
		(setq point-beg (point))
		(forward-sexp 1)
		(forward-line 1)
		(setq point-en (point))
		(delete-region point-beg point-en)))
	    ;; Insert the content.
	    (goto-char (point-min))
	    (insert temp-cont)
	    ;; Save buffer of gams-statement-file.
	    (save-buffer (find-buffer-visiting temp-file))
	    (kill-buffer (find-buffer-visiting temp-file))
	    ;; kill the temporary buffer.
	    (kill-buffer temp-buff)
	    )))))

(defun gams-opt-edit (&optional com)
  "Edit the option combination on the current line."
  (interactive)
  (let ((cur-num (gams-opt-return-option-num))
	(cur-po (point))
	(type (if com "command" "option"))
	(alist (if com gams-user-command-alist gams-user-option-alist))
	old new mess)
    (when cur-num
      (save-excursion
	(if (equal "default" cur-num)
	    (if com
		(message "The default command is determined by the variable `gams:process-command-name'.")
	      (message "The default option is determined by the variable `gams:process-command-option'."))
	  (progn
	    (setq mess (format "Edit the %s No. %s: " type cur-num))
	    (setq old (gams-opt-return-option com cur-num))
	    (setq new (read-from-minibuffer mess old))
	    (if (equal old new)
		(message (format "No change on the %s No.%s" type cur-num))
	      (progn
		(setq alist (gams-opt-edit-sub alist cur-num new))
		(if com
		    (setq gams-user-command-alist alist)
		    (setq gams-user-option-alist alist)))
	      (gams-opt-make-alist com)
	      (gams-opt-view com)
	      (sit-for 0)))))
	      (goto-char cur-po))))


(defun gams-opt-edit-sub (alist num new)
  (let (new-alist ele)
    (while alist
      (setq ele (car alist))
      (when (equal (car ele) num)
	(setq ele (cons num new)))
      (setq new-alist (cons ele new-alist))
      (setq alist (cdr alist)))
    (reverse new-alist)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Codes for chaging gams command.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar gams-user-command-alist nil
  "The list of gams command defined by users.
If you register the new command in the process
menu (`C-cC-to'), they are store in this variable and saved into the file
defined by `gams-statement-file'.")

(defvar gams-user-command-alist-initial nil)
(setq gams-user-command-alist-initial gams-user-command-alist)
      
(defvar gams-command-alist nil
  "The list of combinations of options in which
`gams:process-command-option' and `gams-user-option-alist' are combined.")

(defun gams-command-make-alist ()
  "Combine `gams:process-command-option' and `gams-user-option-alist'."
  (setq gams-command-alist
	(append
	 (list (cons "default" gams:process-command-name))
	 (reverse gams-user-command-alist))))

(setq-default gams-command-gms-buffer nil)

;;; initialize.
(setq gams-current-command-num "default")

(defun gams-change-gams-command ()
  "Change GAMS command name.
The default GAMS command is determined by the variable
`gams:process-command-name'."
  (interactive)
  (let ((cur-buf (current-buffer)))
    ;; Display.
    (gams-opt-view t)
    ;; Show key in the minibuffer.
    (gams-opt-show-key)
    ;; Start the mode.
    (gams-command-select-mode cur-buf)
    ))

(defvar gams-command-select-mode-map (copy-keymap gams-opt-select-mode-map))
(let ((map gams-command-select-mode-map))
  (define-key map "n" 'gams-opt-next)
  (define-key map "p" 'gams-opt-prev)
  (define-key map "e" 'gams-command-edit)
  (define-key map "a" 'gams-command-add-new-command)
  (define-key map "d" 'gams-command-delete)
  (define-key map "\r" 'gams-command-change)
  )

(defun gams-command-select-mode (buff)
  "Mode for changing command line options."
  (kill-all-local-variables)
  (setq mode-name "GAMS-COMMAND"
	major-mode 'gams-command-select-mode)
  (use-local-map gams-command-select-mode-map)
  (make-local-variable 'gams-command-gms-buffer)
  (setq gams-command-gms-buffer buff)
  (setq buffer-read-only t))

(defun gams-command-add-new-command ()
  (interactive)
  (gams-opt-add-new-option t))

(defun gams-command-change ()
  (interactive)
  (gams-opt-change t))

(defun gams-command-edit ()
  (interactive)
  (gams-opt-edit t))

(defun gams-command-delete ()
  "Delete the option combination on the current line."
  (interactive)
  (let ((num (gams-opt-return-option-num)))
    (cond
     ((not num) nil)
     ((equal num "default")
      (message "You cannot delete the default command!"))
     ((equal num nil) nil)
     (t
      (message (format "Do you really delete \"%s\"?  Type `y' if yes." num))
      (let ((key (read-char)))
	(if (not (equal key ?y))
	    nil
	  (setq gams-user-command-alist
		(gams-del-alist num gams-user-command-alist))
	  (message (format "Remove \"%s\" from the registered alist." num))
	  ;; renumbering.
	  (gams-opt-renumber t)
	  (gams-opt-make-alist t)
	  (when (equal num gams-current-command-num)
	    (setq gams-current-command-num "default"))
	  (gams-opt-view t)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Replace the existing statements.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gams-rs-get-name ()
  "Store the name of GAMS statement or dollar control option under the cursor."
  (let (po-beg po-end type)
    (save-excursion
      (unless (or (gams-check-line-type)
		  (gams-in-quote-p))
	(skip-chars-backward "[a-zA-Z0-9]")
	(cond
	 ((and (looking-at gams-statement-regexp-base)
	       (not (equal ?$ (char-before))))
	  (setq po-beg (point))
	  (setq po-end (match-end 0))
	  (goto-char po-end)
	  (when (looking-at "[a-zA-Z]")
	    (setq po-beg nil
		  po-end nil)))
	 ((and (equal ?$ (char-before))
	       (or (looking-at
		    (concat gams-dollar-regexp "[^a-zA-Z0-9*]+"))
		   (looking-at gams-mpsge-regexp)))
	  (setq po-beg (point))
	  (setq po-end (match-end 1))
	  (goto-char po-end)
	  (setq type t))
	 )))
    (list po-beg po-end type)))

;;(define-key gams-mode-map "\C-c\C-u" 'gams-replace-statement)
(defun gams-replace-statement ()
  "Replace the existing statements or dollar control options with new one.
If you execute this command on the existing GAMS statements or dollar
control options, you can replace them with the new onew.  This command is
valid only if the cursor is on the GAMS statements or dollar control
options."
  (interactive)
  (let* ((temp (gams-rs-get-name))
	 (po-beg (car temp))
	 (po-end (nth 1 temp))
	 (type (nth 2 temp))
	 old new)
    (if (not po-beg)
	;; Do nothing
	(message
	 "This command is valid only on GAMS statements or dollar control options.")
      ;;
      (setq old (gams*buffer-substring po-beg po-end))
      (setq new (if type (gams-insert-dollar-control-get-name old)
		  (gams-insert-statement-get-name old)))
      (when new 
	(kill-region po-beg po-end)
	(insert new)
	(if type
	    (setq gams-dollar-control-name new)
	  (setq gams-statement-name new))
	(message
	 (if type (concat "Relpaced `$" old "' with `$" new "'.")
	   (concat "Relpaced `" old "' with `" new "'.")))
	))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Show the declaration part of an identifier.
;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcustom gams-sid-search-in-subroutine-file t
  "If non-nil, `gams-show-identifier' searches the identifier declaration
also in the subroutine files included through $include or $batinclude.  If
nil, search the identifier declaration in the current files."
  :type 'boolean
  :group 'gams)

(defvar gams-sid-in-subroutine-p nil "Flag variable.")
(defvar gams-sid-mess-1
      (concat 
       "[?]help,[d]ecl,[n]ext,[p]rev,"
       "[e]copy,"
       "[ ]restore,[RET]jump"))

(defvar gams-regexp-declaration-sub
      "\\(parameter[s]?\\)[ 	
(]+")

(defvar gams-regexp-declaration-3
      (concat
       "^[ \t]*\\("
       "parameter[s]?\\|set[s]?\\|scalar[s]?\\|table\\|alias"
       "\\|acronym[s]?\\|\\(free\\|positive"
       "\\|negative\\|binary\\|integer\\)*[ ]*variable[s]?"
       "\\|equation[s]?\\|model[s]?\\|$model:"
       "\\)[ \t\n(]*"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Open included file.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gams-get-included-filename ()
  (let ((f-name (thing-at-point 'filename)))
    (set-text-properties 0 (length f-name) nil f-name)
    f-name))

(defun gams-open-included-file ()
  "Open the included file under the cursor.

This command is valid only if the cursor is on the file name after
$batinclude or $include."
  (interactive)
  (let* ((thing-at-point-file-name-chars "~/A-Za-z0-9---_.${}#%,:\\\\")
	 (temp-fname (gams-get-included-filename))
	 fname)
    (when (not (equal temp-fname ""))
      (setq fname (expand-file-name
		   (gams-replace-regexp-in-string "\\\\" "/" temp-fname t)))
      (setq fname
	    (cond
	     ((file-exists-p fname) fname)
	     ((file-exists-p (concat fname ".gms"))
	      (concat fname ".gms"))
	     (t nil)))
      (if fname
	  (progn
	    (message (format "Open `%s'" fname))
	    (delete-other-windows)
	    (split-window)
	    (other-window 1)
	    (find-file fname))
	(message
	 (concat 
	  (format "The file '%s' does not exist!  " temp-fname)
	  "This command is valid on the file name."))))))

(defun gams-sid-get-alist-double-quote ()
  (let ((end (line-end-position)))
    (forward-char 1)
    (or (re-search-forward "\"" end t) (point))))

(defun gams-sid-get-alist-single-quote ()
  (let ((end (line-end-position)))
    (forward-char 1)
    (or (re-search-forward "'" end t) (point))))

(defun gams-sid-goto-inline-comment-end ()
  (let ((end (line-end-position)))
    (forward-char 1)
    (or (re-search-forward (regexp-quote gams-inlinecom-symbol-end) end t) end)))

(defun gams-sid-next-slash ()
  (let (po)
    (save-excursion
      (forward-char 1)
      (catch 'found
	(while t
	  (if (re-search-forward "/" nil t)
	      (when (and (not (gams-check-line-type nil t))
			 (not (gams-in-comment-p))
			 (not (gams-in-quote-p)))
		(setq po (point))
		(throw 'found t))
	    (throw 'found t))))
      po)))

(defun gams-sid-return-block-end (beg)
  "Return the point of the end of the block."
  (let ((cur-po (point)) temp flag)
    (save-excursion
      (goto-char beg)
      (catch 'found
	(while t
	  (if (not (re-search-forward 
		    (concat
		     "^[ \t]*"
		     "\\("
		     "[$][ \t]*" gams-dollar-regexp
		     "[^a-zA-Z0-9*]+"
		     "\\|"
		     gams-regexp-declaration-3
		     "\\|"
		     gams-regexp-loop
		     "\\|"
		     gams-regexp-put
		     "\\)\\|"
		     "\\(;\\)"
		     )
		    nil t))
	      ;; If not found, set point-max.
	      (progn (setq flag (point-max))
		     (throw 'found t))
	    ;; If found,
	    (setq temp (match-beginning 0))
	    (skip-chars-backward " \t\n")
	    (when (and (not (looking-at "[a-zA-Z0-9_]"))
		       (not (gams-check-line-type))
		       (not (gams-in-comment-p))
		       (not (gams-in-quote-p))
		       (gams-slash-end-p beg)
		       )
	      (setq flag temp)
	      (throw 'found t))))))
    flag))

(defun gams-sid-search-include-file-name (&optional po)
  "Search and return the included file name in the buffer.  PO is the
limit point."
  (let (fname beg end)
    (catch 'found
      (while t
	(if (not (re-search-forward
		  (concat "[ \t]*\\$\\(bat\\)?include"
			  "[ \t]+[\"']*"
			  "\\([^ \t\n\f\"']+\\)") po t))
	    ;; (regexp-opt '("$include" "$batinclude"))
	    ;; If not found.
	    (throw 'found t)
	  ;; If found.
	  (setq beg (match-beginning 2)
		end (match-end 2))
	  (when (and (not (gams-in-on-off-text-p))
		     (not (gams-check-line-type))
		     (not (gams-in-comment-p)))
	    (setq fname (gams*buffer-substring beg end))
	    (setq fname
		  (expand-file-name
		   (gams-replace-regexp-in-string "\\\\" "/" fname t)))
	    (when (setq fname (or (gams-gms-file-exist-p fname) nil))
	      (throw 'found t))))))
    fname))

(defun gams-gms-file-exist-p (file)
  "If FILE(.gms|.GMS) exist, return the full file name."
  (if (file-exists-p file)
      file
    (if (file-exists-p (concat file ".gms"))
	(concat file ".gms")
      (if (file-exists-p (concat file ".GMS"))
	  (concat file ".GMS")))))

(defun gams-sid-search-include (name)
  "Search an identifier declaration in subroutine files.
NAME is the name of an identifier searched.
Returned value is the list like (FPOINT FNAME DECL BEG).

FPOINT is the point of $(lib/bat)include statements.
FNAME is the name of a subroutine file in which the identifier is included.
DECL is the point of the declaration part.
BEG is the point of the beginning of the declaration block.
"
  (let ((cur-buf (current-buffer))
	(temp-buf (get-buffer-create "*temp*"))
	(cur-po (point))
	fname res fpo)
    (save-excursion
      (goto-char (point-min))
      (catch 'found
	(while t
	  (if (setq fname (gams-sid-search-include-file-name cur-po))
	      (progn
		(setq fpo (point))
		(when (or (file-exists-p fname)
			  (file-exists-p (setq fname (concat fname ".gms"))))
		  (set-buffer temp-buf)
		  (erase-buffer)
		  (insert-file-contents fname)
		  (font-lock-mode -1)
		  (gams-mode)
		  (goto-char (point-min))
		  (when (setq res (gams-sid-search-definition name t))
		    (setq res (cons fpo (cons fname res)))
		    (throw 'found t))
		  (switch-to-buffer cur-buf)
		  ))
	    (throw 'found t))))
      (switch-to-buffer cur-buf))
    (kill-buffer temp-buf)
    res))

(defun gams-sid-file-name-translate (file)
  (let ((dir default-directory))
  (expand-file-name
   (concat dir (gams-replace-regexp-in-string "\\\\" "/" file t)))))

(defun gams-sid-search-indentifier-include-sub (name file)
  (let ((cur-buf (current-buffer))
	(temp-buf (get-buffer-create "*temp*"))
	(cur-po (point))
	fname res fpo)
    (set-buffer temp-buf)
    (erase-buffer)
    (insert-file-contents file)
    (font-lock-mode -1)
    (gams-mode)
    (goto-char (point-min))
    (when (setq res (gams-sid-search-definition name t))
      (setq res (cons fpo (cons fname res))))
    (switch-to-buffer cur-buf)
    (kill-buffer temp-buf)
    res))

(defun gams-show-identifier (&optional arg)
;; (defun gams-show-identifier (&optional arg)
  "Show the declaration (definition) part of the identifier under the
cursor.  You can also show and move to the various places.  Execute this
command with the cursor on the identifier.  Or execute this command with
the universal-argument and you will be asked the identifier name you want
to search.

When you are reading or editing a GAMS program, you may often go back to
the declaration part of an identifier so as to see its definition.  Or you
may go to the place where an identifier is assigned some value.

In such a case, you could use, for example, `isearch-backward' and
`isearch-forward' command or something to search the identifier.  But if
the identifier is used many times at the different parts of the program,
it is difficult to find the declaration part of the identifier.  Or if the
identifier is declared in a subroutine file, it is quite messy to search
the declaration part.

If you use this command, you can search the declaration part of the
identifier.  See also the variable `gams-sid-search-in-subroutine-file'.

This command cannot search aliased set identifer."
  (interactive "P")
  (gams-show-identifier-internal arg)
  )

(defun gams-show-identifier-internal (arg &optional prev)
  (let (name beg temp type)
    (setq gams-sid-in-subroutine-p nil)
    (setq temp
	  (if arg (gams-sid-query-get-name)
	    (gams-sid-get-name)))
    (setq beg (car temp)
	  name (nth 1 temp)
	  type (nth 2 temp))
    (gams-show-identifier-sub beg name type arg prev)))

(defvar gams-get-identifer-name-history nil "Holds history of identifer.")
(put 'gams-get-identifer-name-history 'no-default t)
(defun gams-get-identifer-name (prompt &optional predicate initial)
  "Read an identifer with completion."
  (read-from-minibuffer
   prompt initial nil nil
   'gams-get-identifer-name-history))

(defun gams-sid-query-get-name ()
  (interactive)
  (let* ((hist gams-get-identifer-name-history)
	 (prev (car hist)))
    (setq name
	  (gams-get-identifer-name
	   (concat 
	    "Insert an identifer name you want to search"
	    (when prev (format " [default is %s]" prev))
	    ": ")))
    (setq name (gams-remove-spaces-from-string name))
    (when (equal name "") (setq name prev))
    (list (point) name "s")))

(defun gams-sid-read-key ()
  (interactive)
  (let (key)
    (setq key
	  (if gams-xemacs
	      (read-char-exclusive)
	    (read-event)))))

(defun gams-sid-copy-explanatory-text (po-def len)
  "Copy (extract) the explanatory text of the identifier from the declaration part."
  (let (org-po fl_q fl_e beg end etxt)
    (save-excursion
      (other-window 1)
      (setq org-po (point))
      ;; Go to the position of the identifier.
      (goto-char po-def)
      (if (gams-in-mpsge-block-p)
	  ;; if in mpsge block
	  (when (re-search-forward "!" (line-end-position) t)
	    (skip-chars-forward " \t")
	    (setq etxt (gams*buffer-substring (point) (line-end-position))))
	;; if not in mpsge block
	(forward-char len)
	(skip-chars-forward " \t")
	(when (looking-at "(")
	  (search-forward ")" nil t))
	(skip-chars-forward " \t")
	(cond
	 ((looking-at "[\n,;/]")
	  ;; Do nothing
	  )
	 ((looking-at "[\\('\\)|\\(\"\\)]")
	  (setq fl_q (gams*buffer-substring (point) (1+ (point))))
	  )
	 (t (setq fl_e t)))
	(if (not (or fl_q fl_e))
	    (message "No explanatory text is found.")
	  (if fl_q
	      (progn
		(forward-char 1)
		(setq beg (point))
		(if (search-forward fl_q (line-end-position) t)
		    (setq end (match-beginning 0))
		  (setq end (line-end-position))))
	    (setq beg (point))
	    (if (re-search-forward "[,/;]" (line-end-position) t)
		(setq end (match-beginning 0))
	      (setq end (line-end-position))))
	  (setq etxt (gams*buffer-substring beg end))
	  (setq etxt (substring etxt 0 (string-match "[ \t]+$" etxt)))))
      (if etxt
	  (progn (kill-new etxt)
		 (message "Copy (extract) explanatory text from the declaration part."))
	(message "No explanatory text is found."))
      ;;	(message (concat "<" (gams-replace-regexp-in-string "%" "%%" etxt) ">"))
      )
    (goto-char org-po)
    (other-window 1)))

(defun gams-show-identifier-sub (beg name &optional type query prev)
  (interactive)
  (let* ((len (length name))
	 (cur-po (point))
	 (line-beg (line-beginning-position))
	 (cur-buff (current-buffer))
	 res po po-def po-beg key win-conf fname fpo mess line)
    (if (not beg)
	(message "This command is valid only if the cursor is on an identifier.")
      (save-excursion
	(forward-line 1)
	(setq res (gams-sid-return-def-position name query)))
      (if res
	  (progn
	    (setq win-conf (current-window-configuration)
		  fpo (car res)
		  fname (nth 1 res)
		  po-def (nth 2 res)
		  po-beg (nth 3 res))
	    (when fname (setq gams-sid-in-subroutine-p (current-buffer)))
	    (gams-sid-show-result-def-sub name po-def len po-beg fname))
	(if (not (setq po (gams-sid-search-identifier name type (point-min) line-beg)))
	    (message "The declaration part is not found or this may not be an identifier.")
	  (setq win-conf (current-window-configuration)
		fpo nil
		fname nil
		po-def nil
		po-beg nil)
	  (gams-sid-show-result-one po len)
	  (message "The declaration part is not found, but the other part is found!")
	  (sleep-for 1)))
      (when prev
	(gams-sid-show-result-prev name type po-def len po-beg fname fpo))
      (when (or res po)
	(unwind-protect
	    (catch 'ok
	      (while t
		(gams-sid-show-result-mess name fname)
		(setq key (char-to-string (gams-sid-read-key)))
		(cond
		 ((equal key "n")
		  (gams-sid-show-result-next name type len fpo))
		 ((equal key "p")
		  (gams-sid-show-result-prev
		   name type po-def len po-beg fname fpo))
		 ((equal key "c")
		  (gams-sid-show-result-current
		   name beg (if query 1 len) cur-buff fname))
		 ((equal key "?")
		  (gams-sid-show-help))
		 ((equal key "d")
		  (gams-sid-show-result-def name po-def len po-beg fname))
		 ((equal key "e")
		  (gams-sid-show-result-def name po-def len po-beg fname t)
		  (gams-sid-copy-explanatory-text po-def len))
		 ((equal key " ")
		  (other-window 1)
		  (gams-highline-off)
 		  (other-window 1)
		  (set-window-configuration win-conf)
		  (goto-char cur-po)
		  (throw 'ok t))
		 ((or (equal key "\r")
		      (equal key 'return))
		  (other-window 1)
		  (throw 'ok t))
		 (t (throw 'ok t))
		 )))
	  (setq win-conf nil)
	  (gams-highline-off)
	  (message "Done.")
	  )))))

(defun gams-sid-show-result-def (name po-def len po-beg fname &optional nomess)
  "no mess -> no message"
  (let ((cur-po (point)))
;;    (current-buffer)
    (if po-def
	(cond
	 ((or (not fname) ;; No subroutine file
	      (and fname gams-sid-in-subroutine-p)) ;; Subroutine exists
						    ;; and the cursor
						    ;; exists in the main
						    ;; buffer.
	  (if (prog2 (other-window 1) (<= (point) po-def) (other-window 1))
	      ;; When the cursor lies before declaration point.
	      (progn
		(when (not nomess)
		  (message "You are already on the declaration part!")
		  (sit-for 1)))
	    (current-buffer)
	    (gams-highline-off)
	    (gams-sid-show-result-def-sub name po-def len po-beg fname)
	    (goto-char cur-po)))
	 ;; Subroutine exits and the cursor is on the subroutine buffer.
	 ((and fname (not gams-sid-in-subroutine-p))
	  (setq gams-sid-in-subroutine-p (current-buffer))
	  (gams-highline-off)
	  (other-window 1)
	  (switch-to-buffer (find-file fname))
	  (other-window 1)
	  (gams-sid-show-result-def-sub name po-def len po-beg fname)))
      (goto-char cur-po)
      (message "No declaration part for this identifier.")
;;      (sit-for 1)
      )))

(defun gams-sid-show-result-mess (name fname)
  (let* ((file
	  (if gams-sid-in-subroutine-p
	      fname
	    (buffer-file-name gams-sid-in-subroutine-p))))
    (message
     (concat
      (if fname (format "\"%s\" in %s: " name (file-name-nondirectory file))
	(format "\"%s\": " name))
      gams-sid-mess-1))))

(defun gams-sid-show-result-def-sub (name po-def len po-beg fname)
  (delete-other-windows)
  (split-window)
  (gams-sid-show-result po-def len po-beg fname)
  (message
   (if fname
       (concat 
	(format "\"%s\"'s declaration in \"%s\": "
		name
		(file-name-nondirectory fname))
	gams-sid-mess-1)
     (concat (format "\"%s\"'s declaration part: " name)
	     gams-sid-mess-1)))
  (other-window 1))

(defun gams-sid-show-result-one (po len)
  (delete-other-windows)
  (split-window)
  (gams-sid-show-result po len)
  (other-window 1))
  
(defun gams-sid-search-identifier-next (name type fpo)
  "Search the identifier NAME.

BEG indicates the declaration point (or file point)."
  (let ((cur-buff (current-buffer))
	(cur-po (point))
	po temp)
    (if (setq po (gams-sid-search-identifier-next-sub name type))
	(setq temp (list cur-buff po))
      (when (and fpo gams-sid-in-subroutine-p)
	(set-buffer gams-sid-in-subroutine-p)
	(goto-char fpo)
	(end-of-line)
	(setq po (gams-sid-search-identifier-next-sub name type))
	(when po
	  (goto-char po)
	  (setq temp (list (current-buffer) po))
	  (setq gams-sid-in-subroutine-p nil))
	(set-buffer cur-buff)
	(goto-char cur-po)))
    temp))

(defun gams-sid-search-identifier-next-sub (name type)
  "Search the identifier NAME.

BEG indicates the declaration point (or file point)."
  (let ((reg
	 (if type
	     (concat "[(,$ \t\n]+\\(" name "\\)[ \t\n,)(]+")
	   (concat "[^a-zA-Z0-9_.]+\\(" name "\\)[^:a-zA-Z0-9_]+")))
	(cur-po (point))
	po-beg po)
    (save-excursion
      (end-of-line)
      (catch 'found
	(while t
	  (if (re-search-forward reg nil t)
	      (progn
		(setq po-beg (match-beginning 1))
		(goto-char (match-end 1))
		(if (gams-in-on-off-text-p)
		    (gams-goto-next-offtext)
		  (if (and (not (gams-check-line-type))
			   (not (gams-in-quote-p-extended))
			   (not (gams-in-comment-p)))
		      (progn (setq po po-beg)
			     (throw 'found t)))))
	    (throw 'found t)))))
    po))

(defun gams-sid-show-result-next (name type len fpo)
  (let (cur-buff temp buff po)
    (other-window 1)
    (setq cur-buff (current-buffer))
    (setq temp (gams-sid-search-identifier-next name type fpo)
	  buff (car temp)
	  po (nth 1 temp))
    (if po
	(progn
	  (gams-highline-off)
	  (when (not (equal cur-buff buff))
	    (switch-to-buffer buff))
	  (gams-highline-off)
	  (gams-sid-show-result po len)
	  (if (not (equal cur-buff buff))
	      (message
	       (concat 
		(format "Up to \"%s\": "
			(file-name-nondirectory
			 (buffer-file-name buff)))
		gams-sid-mess-1))
	    (message gams-sid-mess-1)))
      (message
       (concat
	(format "\"%s\" does not exist after this point!  " name)
	gams-sid-mess-1)))
    (other-window 1)))

(defun gams-sid-search-identifier-prev (name type beg fname fpo)
  "Search the identifier NAME.

BEG indicates the declaration point (or file point)."
  (let ((cur-buff (current-buffer))
	(cur-po (point))
	temp po)
    (cond
     ((not fname)
      (setq temp
	    (list cur-buff (gams-sid-search-identifier-prev-sub name type beg))))
     (fname
      (if gams-sid-in-subroutine-p
	  (progn
	    (setq po (gams-sid-search-identifier-prev-sub name type beg))
	    (setq temp (list (current-buffer) po)))
	(if (setq po (gams-sid-search-identifier-prev-sub name type beg))
	    (setq temp (list (current-buffer) po))
	  (set-buffer (get-file-buffer fname))
	  (goto-char (point-max))
	  (when (setq po (gams-sid-search-identifier-prev-sub name type fpo))
	    (setq temp (list (current-buffer) po))
	    (setq gams-sid-in-subroutine-p cur-buff))
	  (set-buffer cur-buff)
	  (goto-char cur-po)))))
    temp))

(defun gams-sid-search-identifier-prev-sub (name type beg)
  "Search the identifier NAME.

BEG indicates the declaration point (or file point)."
  (let ((reg
	 (if type
	     (concat "[(,$ \t\n]+\\(" name "\\)[ \t\n,)(]+")
	   (concat "[^a-zA-Z0-9_.]+\\(" name "\\)[^a-zA-Z0-9_]+")))
	(cur-po (point))
	po-beg po)
    (save-excursion
      (beginning-of-line)
      (catch 'found
	(while t
	  (if (re-search-backward reg nil t)
	      (progn
		(setq po-beg (match-beginning 1))
		(goto-char po-beg)
		(if (gams-in-on-off-text-p)
		    (gams-goto-prev-ontext beg)
		  (if (and (not (gams-check-line-type))
			   (not (gams-in-quote-p-extended))
			   (not (gams-in-comment-p)))
		      (progn (setq po po-beg)
			     (throw 'found t)))))
	    (throw 'found t)))))
    po))

(defun gams-sid-show-result-prev (name type po-def len po-beg fname fpo)
  (let (cur-buff po buff temp)
    (other-window 1)
    (setq cur-buff (current-buffer))
    (if (and po-def
	     (or (not fname)
		 (and fname gams-sid-in-subroutine-p))
	     (<= (point) po-def))
	(progn (message "You are already on the declaration part!")
	       (sit-for 1))
      (if (setq temp (gams-sid-search-identifier-prev name type po-beg fname fpo))
	  (progn
	    (setq buff (car temp)
		  po (nth 1 temp))
	    (gams-highline-off)
	    (if (not (equal cur-buff buff))
		(progn (switch-to-buffer buff)
		       (gams-sid-show-result po len)
		       (message
			(concat (format "Down to \"%s\": "
					(file-name-nondirectory fname))
				gams-sid-mess-1)))
	      (gams-sid-show-result po len)
	      (message gams-sid-mess-1)))
	(if po-def
	    (progn
	      (other-window 1)
	      (gams-sid-show-result-def-sub name po-def len po-beg fname)
	      (other-window 1))
	  (message
	   (format "\"%s\" does not exist before this point!" name))
	  (sleep-for 1))))
    (other-window 1)))

(defun gams-sid-show-result-current (name po len buff fname)
  (other-window 1)
  (let ((cur-buff (current-buffer)))
    (when fname
      (if gams-sid-in-subroutine-p
	  (when (equal buff gams-sid-in-subroutine-p)
	    (setq gams-sid-in-subroutine-p nil))
	(if (equal buff cur-buff)
	    (setq gams-sid-in-subroutine-p nil)
	  (setq gams-sid-in-subroutine-p t))))
    (switch-to-buffer buff)
    (gams-highline-off)
    (gams-sid-show-result po len)
    (message
     (concat
      (format "\"%s\" in \"%s\": " name
	      (file-name-nondirectory (buffer-file-name (current-buffer))))
      gams-sid-mess-1))
    (other-window 1)))

(defun gams-sid-return-def-position (name &optional flag)
  "Search the identifier NAME and return its place if found."
  (let (res)
    (if (setq res (gams-sid-search-definition name flag))
	(setq res (cons nil (cons nil res)))
      (when gams-sid-search-in-subroutine-file
	(setq res (gams-sid-search-include name))))
    res))

(defun gams-sid-show-result (po len &optional beg file)
  "PO is declaration point.
LEN is the length of the identifier.
BEG is the beginning point of declaration block.
FILE is the file name where the declaration exists."
  (when file
    (find-file file)
    (when (not (equal major-mode 'gams-mode))
      (gams-mode)))
  (goto-char po)
  (when beg
    (goto-char beg)
    (recenter 1)
    (sit-for 0)	;; For redisplay
    (if (<= po (window-end))
	(goto-char po)
      (goto-char po)
      (recenter)))
  (beginning-of-line)
  (gams-highlight-current-line po (+ po len))
  )

(defun gams-sid-search-identifier-recent (name type beg)
  "Search the identifier NAME.

BEG indicates the declaration point (or file point)."
  (let ((reg
	 (if type
	     (concat "[^a-zA-Z0-9_-]+\\(" name "\\)[^a-zA-Z0-9_-]+")
	   (concat "[^a-zA-Z0-9_]+\\(" name "\\)[^a-zA-Z0-9_]+")))
	po-beg po)
    (save-excursion
      (catch 'found
	(while t
	  (if (re-search-backward reg beg t)
	      (progn
		(setq po-beg (match-beginning 1))
		(goto-char po-beg)
		(if (gams-in-on-off-text-p)
		    (gams-goto-prev-ontext beg)
		  (if (and (not (gams-check-line-type))
			   (or type (not (gams-in-declaration-p t)))
			   (not (gams-in-quote-p-extended))
			   (not (gams-in-comment-p)))
		      (progn (setq po po-beg)
			     (throw 'found t))
		    )))
	    (throw 'found t)))))
    po))

(defun gams-sid-search-identifier (name &optional type beg end)
  "Search the identifier NAME.
BEG"
  (let ((reg (concat "[^a-zA-Z0-9_]+\\(" name "\\)[^a-zA-Z0-9_]+"))
	po-beg po)
    (save-excursion
      (goto-char (or beg (point-min)))
      (catch 'found
	(while t
	  (if (re-search-forward reg end t)
	      (progn
		(setq po-beg (match-beginning 1))
		(goto-char (match-end 1))
		(if (gams-in-on-off-text-p)
		    (gams-goto-next-offtext)
		  (if (and (not (gams-check-line-type))
			   (or type (not (gams-in-declaration-p t)))
			   (not (gams-in-quote-p-extended))
			   (not (gams-in-comment-p)))
		      (progn (setq po po-beg)
			     (throw 'found t)))))
	    (throw 'found t)))))
    po))

(defun gams-sid-show-help ()
  (interactive)
  (let ((cur-buff (current-buffer))
	(cur-po (point))
	(temp-buf (get-buffer-create "*SD-HELP"))
	key)
    (save-window-excursion
      (switch-to-buffer temp-buf)
      (erase-buffer)
      (insert "[Help for GAMS show identifier]
`gams-show-identifier' is a command to search and show the
identifier which appears in various parts of the program.

d		Show the declaration part
n		Show the next part.
p		Show the previous part.
c		Show the current part.
e		Copy (extract) the explanatory text from the identifier declaration part.
SPACE		Quit and restore the window configuration.
RET		Quit and jump to the highligtened part.
Other key	Just quit.
?		Show this help.

Type any key to close this buffer.")
      (setq buffer-read-only t)
      (goto-char (point-min))
      (setq key (read-char))
      (kill-buffer temp-buf))))

(defun gams-in-parenthesis-p ()
  "Return t if the current point is in parenthesis.
Otherwise nil."
  (let* ((cur-po (point))
	 (beg (line-beginning-position))
	 (end (line-end-position))
	 po-beg po-end
	 cont flag)
    (save-excursion
      (when (re-search-backward "[()]" beg t)
	(setq cont
	      (gams*buffer-substring (setq po-beg (match-beginning 0))
				     (match-end 0)))
	(if (equal ")" cont)
	    (setq flag nil)
	  (goto-char (match-end 0))
	  (when (and (re-search-forward "[()]" end t) (<= cur-po (point)))
	    (when (equal ")" (gams*buffer-substring (match-beginning 0)
						    (setq po-end (match-end 0))))
	      (setq cont (gams*buffer-substring po-beg po-end))
	      (when (not (string-match "[*/+-]" cont))
		(setq flag t)))))))
    flag))

(defun gams-sid-get-name ()
  "Store the name under the cursor."
  (let (line str po po-beg po-end type)
    (save-excursion
      (setq line (gams-check-line-type))
      (if (and line
	       (not (equal line "c")))
	  (message "On the irrelevant line")
	(if (or (looking-at "[^a-zA-Z0-9_]")
		(gams-in-quote-p-extended))
	    (message "In the quoted text")
	  (if (gams-in-parenthesis-p)
	      (progn
		(re-search-backward "[^a-zA-Z0-9_]" nil t)
		(goto-char (setq po-beg (match-end 0)))
		(when (re-search-forward "[^a-zA-Z0-9_]" nil t)
		  (goto-char (setq po-end (match-beginning 0)))
		  (when (looking-at "[ \t\n=-/<>%);,*+.$]")
		    (setq str (gams*buffer-substring po-beg po-end))
		    (setq po po-beg)
		    (setq type "s")
		    )))
	    (when (re-search-backward "[^a-zA-Z0-9_]" nil t)
	      (goto-char (setq po-beg (match-end 0)))
	      (when (not (equal ?. (preceding-char)))
		(when (re-search-forward "[^a-zA-Z0-9_]" nil t)
		  (goto-char (setq po-end (match-beginning 0)))
		  (when (looking-at "[ \t\n-=<>%/:(;,*+.$]")
;;		  (when (looking-at " \t\n-=<>%/:(;,*+.$")
		    (setq str (gams*buffer-substring po-beg po-end))
		    (if (member str gams-statement-list-base)
			(setq po po-beg)
		      (setq po po-beg))))))))))
    (when (and str
	       (not (string-match "[a-zA-Z]" str))
	       (string-match "[0-9]" str))
      (setq po nil))
    (list po str type)))

;;; From highline.el
(defun gams-highlight-current-line (&optional beg end)
  "Highlight current line."
  (unless gams-highline-overlay
    (setq gams-highline-overlay (make-overlay 1 1)) ; Hide it for now
    (overlay-put gams-highline-overlay 'hilit t)
    (overlay-put gams-highline-overlay 'priority 0))
  ;; move highlight to the current line
  (if gams-sid-in-subroutine-p
      (overlay-put gams-highline-overlay 'face gams-highline-sub-face)
    (overlay-put gams-highline-overlay 'face gams-highline-face))
  (move-overlay gams-highline-overlay
		(or beg (line-beginning-position))
		(or end (1+ (line-end-position)))))

(defvar gams-highline-overlay nil
  "Highlight for current line")
(make-variable-buffer-local 'gams-highline-overlay)
(make-variable-buffer-local 'line-move-ignore-invisible)

(defun gams-highline-off ()
  "Turn off highlighting of the current line."
  (interactive)
  (and gams-highline-overlay
       (setq gams-highline-overlay (move-overlay gams-highline-overlay 1 1))))

(defun gams-in-alias-p ()
  "Return t if the cursor is in alias block.
Return the starting point of the alias if in alias block."
  (let ((cur-po (point))
	temp-po	beg-po temp-con)
    (save-excursion
      ;; Search reserved expression backward.
      (if (re-search-backward
	   (concat "^[ \t]*\\(alias\\)[ \t\n(]+") nil t)
	  ;; Search ; forward.
	  (let (flag)
	    (setq temp-po (point))
	    (catch 'found
	      (while (re-search-forward ";" cur-po t)
		(when (and (not (gams-in-comment-p))
			   (not (gams-in-quote-p)))
		  (setq flag t)))
	      (throw 'found t))
	    (when (not flag)
	      ;; If not found.
	      (goto-char cur-po)
	      ;; Move to the next line.
	      (while (and (gams-check-line-type) (not (eobp)))
		(forward-line 1))
	      (when (not (eobp))
		(when (not (looking-at (concat "^[ \t]*" gams-regexp-declaration-2)))
		  (setq beg-po temp-po)))))))
    beg-po))

(defun gams-sid-search-definition (name &optional flag)
  "Search the place of the definition (declaration) part of an identifier,
and return the point if it is found.

NAME is the name of the identifier.  FLAG is t if search in the whole
buffer

Returned value is a list like (DECL BEG).  DECL is the point of identifier
definition and BEG is the beginning of the declaration block."
  (let ((end-po (if flag (point-max) (point)))
	(reg (concat "[, \t\n]+\\(v:\\)?\\(" name "\\)[ \t(/]*" "[^:a-zA-Z0-9]+"))
	res po po-beg po-end temp-po line decl-end po-decl)
  (save-excursion
    (goto-char (point-min))
    (catch 'found
      (while t
	(if (re-search-forward reg end-po t)
	    ;; If reg is found.
	    (progn (setq po-end (match-end 0))
		   ;; for debug
;; 		   (gams*buffer-substring (match-beginning 2)
;; 					  (match-end 2))
;; 		   ;;
		   (goto-char (match-beginning 2))
		   (setq po (point))
		   (if (gams-check-line-type)
		       ;; If the line is the commented line, do nothing.
		       nil
		     (if (setq temp-po (gams-in-on-off-text-p))
			 ;; If the point is in the ontext-offtext pair,
			 ;; jump to the offtext.
			 (goto-char (car (cdr temp-po)))
		       (cond
			((setq po-beg (gams-in-declaration-p t))
			 ;; If the point is in the declaration block.
			 (if (gams-in-table-block-p)
			     ;; If the point is in the table block
			     (progn
			       (setq line (count-lines (point-min) (1+ (point))))
			       (re-search-backward "^[ \t]*table[ \t]*" nil t)
			       (skip-chars-forward " \t")
			       (if (equal line (count-lines (point-min) (1+ (point))))
				   (progn (setq res (list po po-beg))
					  (throw 'found t))
				 (goto-char po-end)
				 (forward-line 1)))
			   (goto-char po-beg)
			   (skip-chars-forward " \t\n")
			   (skip-chars-forward "^ \t\n")
			   (setq decl-end (gams-sid-return-block-end (point)))
			   (unwind-protect
			       (progn
				 (narrow-to-region po-beg decl-end)
				 (setq po-decl (gams-sid-get-alist name))
				 (goto-char (point-max)))
			     (widen))
			   (when po-decl
			     (setq res (list po-decl po-beg))
			     (throw 'found t))
			   ))
			;; alias
;; 			((setq po-beg (gams-in-alias-p))
;; 			 (setq res (list po po-beg))
;; 			 )
			((gams-in-mpsge-block-p)
			 (goto-char po)
			 (skip-chars-backward " \tv:")
;; 			 (when (looking-back "^[$]model")
;; 			   (beginning-of-line))
			 ;; If in MPSGE block.
			 (if (equal (current-column) 0)
			     (progn (setq res (cons po nil))
				    (throw 'found t))
			   (goto-char po-end)
			   (forward-line 1)))))))
	  ;; If reg is not found.
	  (throw 'found t)))))
  res))

(defun gams-sid-get-alist (name)
  (interactive)
  (let ((id-name (downcase name))
	po-beg po-end ex-end id-po f-id)
    (catch 'found
      (while t
	(while (gams-check-line-type)
	  (forward-line 1)
	  (when (eobp)
	    (throw 'found t)))
	(cond
	 ((eobp)
	  (throw 'found t))
	 ((looking-at "[ \t]")
	  (skip-chars-forward "[ \t]"))
	 ((looking-at (regexp-quote gams-eolcom-symbol))
	  (forward-line 1))
	 ((looking-at (regexp-quote gams-inlinecom-symbol-start))
	  (gams-sid-goto-inline-comment-end))
	 ((looking-at "\n")
	  (when f-id
	    (setq f-id nil))
	  (forward-char 1))
	 ((looking-at "/")
	  (goto-char (gams-sid-next-slash)))
	 ((or (looking-at "'") (looking-at "\""))
	  (when f-id
	    (setq ex-end (gams-sil-get-alist-exp))
	    (goto-char ex-end)))
	 ((looking-at ",")
	  (when f-id
	    (setq f-id nil))
	  (forward-char 1))
	 ((looking-at "(")
	  (re-search-forward ")" nil t))
	 (t (if f-id
		(progn
		  (setq ex-end (gams-sil-get-alist-exp))
		  (goto-char ex-end)
		  (setq f-id nil))
	      (setq po-beg (point))
	      (skip-chars-forward "[a-zA-Z0-9_]")
	      (when (equal id-name (downcase (gams*buffer-substring po-beg (point))))
		(setq id-po po-beg)
		(throw 'found t))
	      (setq f-id t))))))
    id-po))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Show the list of identifiers.
;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; This is a local variable for gams-mode.  It stores the list of
;; identifiers.
(setq-default gams-identifier-symbol-temp nil)

;; This is a local variable for gams-sil-mode.  It stores the name of gms
;; buffer.
(setq-default gams-sil-gms-buffer nil)

;; This is a local variable for gams-mode.  It stores the original point
;; in GMS buffer.
(setq-default gams-gms-original-point nil)

;; This is a local variable for gams-mode.  It stores the window
;; configuration in GMS buffer.
(setq-default gams-gms-window-configuration nil)

(defcustom gams-sil-follow-mode t
  "If non-nil, follow-mode is on in SIL mode. "
  :type 'boolean
  :group 'gams)

(defcustom gams-sil-column-width
  '(("num" . 8)
    ("type" . 9)
    ("identifier" . 22))
  "*The number of colums for `gams-show-identifier-list' command."
  :type '(repeat
	  (cons :tag "option"
		(string :tag "column name")
		(integer :tag "column size")))
  :group 'gams)

;; We keep a vector with several different overlays to do our highlighting.
(defvar gams-highlight-overlays [nil nil nil])

;; Initialize the overlays
(aset gams-highlight-overlays 0 (make-overlay 1 1))
(overlay-put (aref gams-highlight-overlays 0) 
	     'face 'gams-highline-face)
(aset gams-highlight-overlays 1 (make-overlay 1 1))
(overlay-put (aref gams-highlight-overlays 1)
	     'face gams-comment-face)
(aset gams-highlight-overlays 2 (make-overlay 1 1))
(overlay-put (aref gams-highlight-overlays 2)
	     'face gams-lst-warning-face)

;; Two functions for activating and deactivation highlight overlays
(defun gams-sil-highlight (index begin end &optional buffer)
  "Highlight a region with overlay INDEX."
  (move-overlay (aref gams-highlight-overlays index)
                begin end (or buffer (current-buffer))))

(defun gams-sil-unhighlight (index)
  "Detach overlay INDEX."
  (delete-overlay (aref gams-highlight-overlays index)))

(defun gams-sil-return-buffer (buffer)
  "Return the buffer name for identifier list.
BUFFER indicates the current GMS buffer."
  (let ((cur-buff (file-name-sans-extension (buffer-name buffer))))
    (concat "*" cur-buff "-SIL*")))

(defun gams-sil-current-line (point)
  (let (line po ele)
    (save-excursion
      (goto-char (point-min))
      (forward-line 4)
      (catch 'flag
	(while t
	  (if (setq po (nth 1 (get-text-property (point) :data)))
	      (if (<= point po)
		  (progn (setq line (count-lines (point-min) (point)))
			 (throw 'flag t))
		(forward-line 1))
	    (setq line (+ 1 (count-lines (point-min) (point))))
	    (throw 'flag t)))))
    line))

(defun gams-sil-add-explanatory (alist type)
  "Extract explanatory text from equation declaraton part and model
definition part and add it to equation definition part and solve statement part."
  (let* ((temp-al alist)
	 (org-al alist)
	 ele idname expl new-al
	 )
    (while temp-al
      (setq ele (car temp-al))
      (when (equal type (nth 0 ele))
	(setq idname (nth 2 ele))
	;; remove (*) part from identifier name.
	(setq idname (substring idname 0 (string-match "[ ]*(" idname)))
	(when (setq expl (gams-sil-search-explanatory-text idname org-al type))
	  (setq ele (list (nth 0 ele)
			  (nth 1 ele)
			  (nth 2 ele)
			  expl
			  (nth 4 ele)))))
      (setq new-al (cons ele new-al)
	    temp-al (cdr temp-al)))
    (reverse new-al)))

(defun gams-sil-search-explanatory-text (id alist type)
  (let ((al alist)
	ele expl idname str)
    (setq str
	  (cond
	   ((equal type "DEF") "EQU\\|MPS")
	   ((equal type "SOL") "MOD")))
    (catch 'found
      (while t
	(if (not al)
	    (throw 'found t)
	  (setq ele (car al))
	  (when (string-match str (nth 0 ele))
	    (setq idname (nth 2 ele))
	    (when (equal id (substring idname 0 (string-match "(" idname)))
	      (setq expl (nth 3 ele))
	      (throw 'found t)))
	  (setq al (cdr al)))))
    expl))

(defun gams-show-identifier-list ()
  "Show the list of all GAMS identifers existing in the current buffer.
Identifers are classified as

SET = set identifers,
PAR = parameter and scalar identifers,
VAR = variables identifers,
EQU = equations identifers,
MOD = model identifers.
SOL = solve statement.
MPS = MPSGE variable identifers.
DEF = equation definition part and $prod block in MPSGE.
FUN = Function defined by gams-f.
DOL = Dollar control options.
TIT = $(s)title.
COM = Special comment line.

This command cannot identify aliased set identifer."
  (interactive)
  (let* ((curr-buff (current-buffer))
	 (buff-name (buffer-name))
	 (temp-buff (gams-sil-return-buffer curr-buff))
	 (already-p (get-buffer temp-buff))
	 (po (point))
	 temp-alist
	 ident-alist)
    (unless already-p
      (get-buffer-create temp-buff)
      (if gams-identifier-symbol-temp
	  nil
	  (condition-case err
	      (progn
		(setq temp-alist
		      (reverse (gams-sil-get-identifier-alist)))
		(setq temp-alist (gams-sil-add-explanatory temp-alist "DEF"))
		(setq temp-alist (gams-sil-add-explanatory temp-alist "SOL"))
		(setq gams-identifier-symbol-temp temp-alist))
	    (kill-buffer temp-buff)
	    )))
    (when (get-buffer temp-buff)
      (setq gams-gms-window-configuration (current-window-configuration))
      (setq gams-gms-original-point po)
      (delete-other-windows)
      (split-window)
      (setq ident-alist gams-identifier-symbol-temp)
      (switch-to-buffer temp-buff)
      (if already-p
	  (progn (goto-line (gams-sil-current-line po))
		 (sit-for 0))
	(setq buffer-read-only nil)
	(erase-buffer)
	(gams-sil-display-list ident-alist buff-name)
	(gams-sil-mode)
	(goto-line (gams-sil-current-line po))
	(sit-for 0)
	(setq gams-sil-gms-buffer curr-buff)
	(setq buffer-read-only t)))))

(defun gams-sil-rescan ()
  (interactive)
  (let ((cur-line (count-lines
		   (point-min)
		   (min (+ 1 (point)) (point-max))))
	(cur-buff (current-buffer))
	ident-alist temp-alist)
    (switch-to-buffer gams-sil-gms-buffer)
    (message "Rescanning...")
    (condition-case err
	(progn
	  (setq temp-alist (reverse (gams-sil-get-identifier-alist)))
	  (setq temp-alist (gams-sil-add-explanatory temp-alist "DEF"))
	  (setq temp-alist (gams-sil-add-explanatory temp-alist "SOL"))
	  (setq gams-identifier-symbol-temp temp-alist))
      (switch-to-buffer cur-buff))
    (setq ident-alist gams-identifier-symbol-temp)
    (switch-to-buffer cur-buff)
    (setq buffer-read-only nil)
    (erase-buffer)
    (gams-sil-display-list ident-alist (buffer-name gams-sil-gms-buffer))
    (goto-line cur-line)
    (sit-for 0)
    (setq buffer-read-only t)
    (message "Done.")))

(defun gams-sil-search-identifier (name)
  (goto-char (point-min))
  (re-search-forward
   (concat "^[0-9]+[ \t]+[^ \t]+[ \t]+" name "[ \t]+") nil t))

(defun gams-sil-mode ()
  "Mode for GAMS Show-Identifier-List buffer."
  (interactive)
  (kill-all-local-variables)  
  (setq major-mode 'gams-sil-mode)
  (setq mode-name "GAMS-SIL")
  (use-local-map gams-sil-mode-map)
  (make-local-variable 'gams-sil-gms-buffer)
  (when (featurep 'xemacs)
    ;; XEmacs needs the call to make-local-hook
    (make-local-hook 'post-command-hook)
    (make-local-hook 'pre-command-hook))
  (add-hook 'pre-command-hook  'gams-sil-pre-command-hook nil t)
  ;; Setting for menu.
  (easy-menu-add gams-sil-menu)
  (setq truncate-lines t)
  (setq buffer-read-only t))

(defun gams-sil-pre-command-hook ()
  ;; used as pre command hook in *toc* buffer
  (gams-sil-unhighlight 0))

(defvar gams-sil-mode-map (make-keymap))
;; Key assignment.
(let ((map gams-sil-mode-map))
  (define-key map " " 'gams-sil-show-other-window)
  (define-key map "N" 'gams-sil-next)
  (define-key map "P" 'gams-sil-previous)
  (define-key map "n" 'gams-sil-next)
  (define-key map "p" 'gams-sil-previous)
  (define-key map "q" 'gams-sil-quit)
  (define-key map "k" 'gams-sil-quit-and-kill)
  (define-key map "d" 'gams-sil-scroll-up)
  (define-key map "f" 'gams-sil-scroll-down)
  (define-key map "c" 'gams-sil-quit-and-restore)
  (define-key map "\r" 'gams-sil-goto-identifier-and-hide)
  (define-key map "\t" 'gams-sil-goto-identifier)
  (define-key map "r" 'gams-sil-rescan)
  (define-key map "?" 'gams-sil-help)
  (define-key map "t" 'gams-sil-toggle-follow)
  (define-key map "." 'gams-sil-show-calling-point)
  (define-key map [down-mouse-1] 'gams-sil-show-click)
  )

;;; Menu for GAMS mode.
(easy-menu-define 
  gams-sil-menu gams-sil-mode-map "Menu keymap for GAMS-SIL mode."
  '("GAMS-SIL"
   [ "Show the content of the identifer." gams-sil-show-other-window t]
   [ "Move to next item." gams-sil-next t]
   [ "Move to previous item" gams-sil-previous t]
   [ "Show the place where GAMS-SIL was called from." gams-sil-show-calling-point t]
    "--"
   [ "Return to GMS buffer." gams-sil-quit t]
   [ "Kill the GAMS-SIL buffer." gams-sil-quit-and-kill t]
   [ "Kill the SIL buffer and restore the previous window situation." gams-sil-quit-and-restore t]
   [ "Go to the identifier on the current line and hide the SIL buffer." gams-sil-goto-identifier-and-hide t]
   [ "Go to the identifier on the current line and keep the SIL buffer." gams-sil-goto-identifier t]
   [ "Recreate the identifer list." gams-sil-rescan t]
    "--"
   [ "Scroll up." gams-sil-scroll-up t]
   [ "Scroll down." gams-sil-scroll-down t]
   [ "Toggle the follow mode." gams-sil-toggle-follow t]
    "--"
   [ "Help." gams-sil-help t]
   ))

(defvar gams-sil-mess-1
  (concat "[ ]=show, [?]help, [q]uit, [k]=kill"))

(defun gams-sil-show-mess ()
  (message gams-sil-mess-1))

(defun gams-sil-get-num ()
  "Return the identifer number on the current line"
  (save-excursion
    (beginning-of-line)
    (when (looking-at "[0-9]+")
      (string-to-number
       (gams*buffer-substring
	(match-beginning 0) (match-end 0))))))

(defun gams-sil-show-click (click)
  "Show the content of an item on the current line."
  (interactive "e")
  (mouse-set-point click)
  (gams-sil-show-other-window))

(defun gams-sil-toggle-follow ()
  "Toggle follow (other window follows with context)."
  (interactive)
  (setq gams-sil-follow-mode (not gams-sil-follow-mode))
  (if gams-sil-follow-mode
      (message "Follow-mode is on.")
    (message "Follow-mode is off.")))

(defun gams-sil-show-other-window (&optional key)
  "Show the content of the identifer in the other window."
  (interactive)
  (let* ((data (get-text-property (point) :data))
	 (mark (nth 4 data))
	 (len (length (nth 2 data))))
    (when mark
      (let ((buff gams-sil-gms-buffer))
	(delete-other-windows)
	(split-window)
	(pop-to-buffer buff)
	(goto-char (marker-position mark))
	(recenter 2)
	(if (equal len 0)
	    (gams-sil-highlight
	     0 (line-beginning-position) (line-end-position) (current-buffer))
	  (gams-sil-highlight 0 (point) (+ len (point)) (current-buffer)))
	(beginning-of-line)
	(other-window 1)
	))
    (gams-sil-show-mess)))

(defun gams-sil-show-calling-point ()
  "Show point where GAMS-SIL was called from."
  (interactive)
  (let ((this-window (selected-window)))
    (unwind-protect
	(progn
	  (switch-to-buffer-other-window
	   gams-sil-gms-buffer)
	  (goto-char gams-gms-original-point)
	  (recenter '(4)))
      (select-window this-window))))

(defun gams-sil-next (&optional arg)
  "Move to next selectable item."
  (interactive "p")
  (or (eobp) (forward-char 1))
  (goto-char (or (next-single-property-change (point) :data) 
		 (point)))
  (sit-for 0)
  (when gams-sil-follow-mode
    (gams-sil-show-other-window)))

(defun gams-sil-previous (&optional arg)
  "Move to previous selectable item."
  (interactive "p")
  (goto-char (or (previous-single-property-change (point) :data)
		 (point)))
  (sit-for 0)
  (when gams-sil-follow-mode
    (gams-sil-show-other-window)))

(defun gams-sil-quit ()
  "Just return to GMS buffer from SIL bufffer.
It does not kill SIL buffer."
  (interactive)
  (switch-to-buffer gams-sil-gms-buffer)
  (message
   (concat "Switched from GAMS show-identifier-list buffer"))
  (sit-for 0)
  (setq gams-gms-window-configuration nil)
  (setq gams-gms-original-point nil))

(defun gams-sil-quit-and-kill ()
  "Kill SIL buffer and return to GMS buffer."
  (interactive)
  (let ((cur-buff (current-buffer)))
    (switch-to-buffer gams-sil-gms-buffer)
    (kill-buffer cur-buff)
    (message
     (concat "Killed GAMS show-identifier-list buffer."))
    (sit-for 0)
    (setq gams-gms-window-configuration nil)
    (setq gams-gms-original-point nil)))

(defun gams-sil-goto-identifier-and-hide ()
  "Goto the identifier on the current line and hide the SIL buffer."
  (interactive)
  (let ((cur-buff (current-buffer)))
    (gams-sil-show-other-window)
    (gams-sil-unhighlight 0)
    (select-window (get-buffer-window gams-sil-gms-buffer))
    (sit-for 0)
    (delete-other-windows)))

(defun gams-sil-goto-identifier ()
  "Goto the identifier on the current line and keep the SIL buffer."
  (interactive)
  (let ((cur-buff (current-buffer)))
    (gams-sil-show-other-window)
    (gams-sil-unhighlight 0)
    (select-window (get-buffer-window gams-sil-gms-buffer))))

(defun gams-sil-quit-and-restore ()
  "Kill GAMS SIL buffer and restore the previous window situation."
  (interactive)
  (let ((cur-buff (current-buffer)))
    (switch-to-buffer gams-sil-gms-buffer)
    (kill-buffer cur-buff)
    (set-window-configuration gams-gms-window-configuration)
    (goto-char gams-gms-original-point)
    (message
     (concat "GAMS show-identifier-list mode ended "
	     "and window configuration is restored."))
    (sit-for 0)
    (setq gams-gms-window-configuration nil)
    (setq gams-gms-original-point nil)))

(defun gams-sil-scroll-up ()
  (interactive)
  (gams-sil-scroll)
  (gams-sil-show-mess))

(defun gams-sil-scroll-down ()
  (interactive)
  (gams-sil-scroll t)
  (gams-sil-show-mess))

(defun gams-sil-help ()
  (interactive)
  (let ((cur-buff (current-buffer))
	(cur-po (point))
	(temp-buf (get-buffer-create "*SIL-HELP"))
	key)
    (pop-to-buffer temp-buf)
    (setq buffer-read-only nil)
    (erase-buffer)
    (insert "[keys for GAMS show identifier list (GAMS SIL)]

SPACE	Show the declaration part of the identifier in the gms file.
n / p	next-line / previous-line.
d / f   Scroll up / down.
c	Toggle follow-mode.
x	Toggle display style.
TAB     Go to the location and keep the SIL window.
RET	Go to the location and hide the SIL window.
q / k	Hide / Kill the SIL buffer.
r	Reparse the gms file
.       Show the original position in the other window.
?	Show this help.

SET = set identifers,
PAR = parameter and scalar identifers,
VAR = variables identifers,
EQU = equations identifers,
MOD = model identifers.
SOL = solve statement.
MPS = MPSGE variable identifers.
DEF = equation definition part and $prod block in MPSGE.
FUN = Function defined by gams-f.
DOL = Dollar control options.
TIT = $(s)title.
COM = Special comment line.")
    (goto-char (point-min))
    (setq buffer-read-only t)
    (select-window (next-window nil 1))
    ))

(defun gams-sil-scroll (&optional down page)
  "Command for scrolling.

If DOWN is non-nil, scroll down.
If PAGE is non-nil, page scroll."
  (interactive)
  (let ((cur-win (selected-window))
	(win-num (gams-count-win))
	;; flag for page scroll or not.
	(fl-pa (if page nil 1)))
    ;; If LST buffer
    (cond
     ((eq win-num 1)
      (if down
	  (scroll-down fl-pa)
	(scroll-up fl-pa)))
     ((> win-num 1)
      (other-window 1)
      (if down
	  (scroll-down fl-pa)
	(scroll-up fl-pa))
      (select-window cur-win))
       (t nil))))

(defun gams-sil-text-color (type)
  (let ((len (length type)))
    (cond
     ((equal type "PAR")
      (put-text-property 0 len 'face gams-lst-par-face type))
     ((equal type "SET")
      (put-text-property 0 len 'face gams-lst-set-face type))
     ((equal type "VAR")
      (put-text-property 0 len 'face gams-lst-var-face type))
     ((equal type "EQU")
      (put-text-property 0 len 'face gams-lst-equ-face type))
;;      ((equal type "COM")
;;       (put-text-property 0 len 'face gams-comment-face type))
     ((equal type "MPS")
      (put-text-property 0 len 'face gams-sil-mpsge-face type))
     ((equal type "MOD")
      (put-text-property 0 len 'face gams-ol-loo-face type))
     ((equal type "SOL")
      (put-text-property 0 len 'face gams-lst-program-face type))
     ((equal type "FUN")
      (put-text-property 0 len 'face gams-func-face type))
     ((equal type "DOL")
      (put-text-property 0 len 'face gams-sil-dollar-face type))
     ((equal type "DEF")
      (put-text-property 0 len 'face gams-def-face type))
;;      ((equal type "TIT")
;;       (put-text-property 0 len 'face gams-title-face type))
     ))
  type)
     
(defun gams-sil-text-color-2 (type)
  (cond
   ((equal type "COM")
    (put-text-property (line-beginning-position) (line-end-position) 'face gams-comment-face))
   ((equal type "TIT")
    (put-text-property (line-beginning-position) (line-end-position) 'face gams-title-face))))
     
;; (defvar gams-sil-type-position-beg 6 "Column number of TYPE")
;; (defvar gams-sil-type-position-end (+ 3 gams-sil-type-position-beg))
;; (defun gams-sil-text-color (type)
;;   (let* ((po (line-beginning-position))
;; 	 (beg (+ po gams-sil-type-position-beg))
;; 	 (end (+ po gams-sil-type-position-end)))
;;     (cond
;;      ((equal type "PAR")
;;       (put-text-property beg end 'face gams-lst-par-face))
;;      ((equal type "SET")
;;       (put-text-property beg end 'face gams-lst-set-face))
;;      ((equal type "VAR")
;;       (put-text-property beg end 'face gams-lst-var-face))
;;      ((equal type "EQU")
;;       (put-text-property beg end 'face gams-lst-equ-face))
;;      ((equal type "COM")
;;       (put-text-property po (point) 'face gams-comment-face))
;;      ((equal type "MPS")
;;       (put-text-property beg end 'face gams-sil-mpsge-face))
;;      ((equal type "MOD")
;;       (put-text-property beg end 'face gams-ol-loo-face))
;;      ((equal type "SOL")
;;       (put-text-property beg end 'face gams-lst-program-face))
;;      ((equal type "FUN")
;;       (put-text-property beg end 'face gams-func-face))
;;      ((equal type "DOL")
;;       (put-text-property beg end 'face gams-sil-dollar-face))
;;      ((equal type "DEF")
;;       (put-text-property beg end 'face gams-def-face))
;;      ((equal type "TIT")
;;       (put-text-property po (point) 'face gams-title-face)))))
     
(defun gams-sil-display-list (alist buffer)
  (let* ((a-list alist)
	(count 0)
	(num-c 	(cdr (nth 0 gams-sil-column-width)))
 	(type-c (+ num-c (cdr (nth 1 gams-sil-column-width))))
	(expl-c (+ type-c (cdr (nth 2 gams-sil-column-width))))
	ele co po id exp
	)
    (goto-char (point-min))
    (insert
     (format
      "Idenfier list on %s
SPC=view, TAB=goto, RET=goto+hide, [q]uit [r]escan t=toggle follow, ?=Help
------------------------------------------------------------------------------\n"
      buffer))
    (put-text-property (point-min) (point) 'face gams-comment-face)
    (insert "[NUM]")
    (indent-to num-c)
    (insert "[Type]")
    (indent-to type-c)
    (insert "[Identifier]")
    (indent-to expl-c)
    (insert "[Explanatory texts]\n")
    (goto-char (point-max))
    (while a-list
      (setq ele (car a-list))
      (insert (number-to-string (setq count (+ 1 count))))
      (indent-to num-c)
      (insert (gams-sil-text-color (nth 0 ele)))
      (indent-to type-c)
      (setq id (nth 2 ele))
      (when (equal (nth 0 ele) "DOL")
	(put-text-property 0 (length id) 'face gams-dollar-face id))
      (insert (or id ""))
      (when (setq exp (nth 3 ele))
	(indent-to expl-c)
	(insert exp))
      (insert "\n")
      (backward-char 1)
      (gams-sil-text-color-2 (nth 0 ele))
      (put-text-property
       (line-beginning-position) (+ 1 (line-end-position)) :data ele)
      (goto-char (point-max))
      (setq a-list (cdr a-list)))
    (goto-char (point-min))
    (setq buffer-read-only t)
    ))

(defun gams-sil-search-previous-decl ()
  (re-search-backward gams-regexp-declaration-3 nil t))

;; This regular expression is used for GAMS SIL mode.
(setq gams-regexp-declaration-4-temp
      "\\(^$[ ]*[s]?title[ \t]+\\)\\|[$][ ]*\\(set\\|setglobal\\|gdxin\\|gdxout\\|include\\|batinclude\\|sysinclude\\|libinclude\\|goto\\|label\\|call\\)[ ]+\\|^[ \t]*\\(solve[ \t]+\\)[a-zA-Z_]+\\|\\([0-9A-Za-z) \t]+[.][.]\\)[^.]\\|\\(==\\)\\|\\(^$exit\\)\\|^[ \t]*\\(parameter[s]?\\|set[s]?\\|scalar[s]?\\|table\\|alias\\|acronym[s]?\\|\\(free\\|positive\\|negative\\|binary\\|integer\\)*[ \t]*variable[s]?\\|equation[s]?\\|model[s]?\\|$model:\\)[ \t\n(]*")

(defun gams-sil-regexp-update ()
  (setq gams-regexp-declaration-4
	(concat
	 "^[ \t]*\\(display[ \t]+\""
	 (regexp-quote gams-special-comment-symbol)
	 "[ \t]*\\)\\|"
	 gams-regexp-declaration-4-temp)))
(gams-sil-regexp-update)

(defun gams-sil-get-alist-title ()
  (let ((cont (gams*buffer-substring
	       (point) (line-end-position))))
    (list (list
	   "TIT" (point) nil cont
	   (set-marker (make-marker) (point))))))

(defun gams-sil-get-alist-exit ()
  (let* ((con "EXIT !!!  EXIT !!!  EXIT !!!")
	 (len (length con)))
    (put-text-property 0 len 'face gams-lst-warning-face con)
    (list (list
	   "DOL" (point) "$exit" con
	   (set-marker (make-marker) (point))))))

(defun gams-sil-get-alist-dollar (dollar beg)
  (let ((cur-po (point))
	(line-end-po (line-end-position))
	end-po
	cont)
    (save-excursion
      (if (re-search-forward " \t" line-end-po t)
	  (setq end-po (point))
	(setq end-po line-end-po)))
    (setq cont (gams*buffer-substring cur-po end-po))
    (list (list "DOL" beg dollar
		cont
		(set-marker (make-marker) beg)))))

(defun gams-sil-get-alist-special-comment ()
  (let ((cur-po (point))
	cont)
    (setq cont
	  (if (re-search-forward "\"" (line-end-position) t)
	      (gams*buffer-substring cur-po (match-beginning 0))
	    ""))
    (list (list "COM" cur-po nil cont
		(set-marker (make-marker) cur-po)))))

(defun gams-sil-solve-p ()
  "Whether the current line includes solve statement?
Yes it includes also the word using"
  (let (flag)
    (save-excursion
      (re-search-forward "[ \t]+using[ \t]+" (line-end-position) t))))

(defun gams-sil-get-alist-solve ()
  (let ((cur-po (point))
	name)
    (skip-chars-forward "a-zA-Z0-9_")
    (setq name (gams*buffer-substring cur-po (point)))
    (list (list "SOL" cur-po name nil
		(set-marker (make-marker) cur-po)))))

(defun gams-sil-get-alist-func ()
  (let (end name)
    (save-excursion
      (skip-chars-backward "= \t")
      (setq end (point))
      (beginning-of-line)
      (skip-chars-forward " \t")
      (setq name (gams*buffer-substring (point) end))
      (list (list "FUN" (point) name nil
		  (set-marker (make-marker) (point)))))))

(defun gams-sil-get-alist-def ()
  (let (cur-po beg end name)
    (save-excursion
      (skip-chars-backward " \t[.]")
      (setq cur-po (point))
      (beginning-of-line)
      (skip-chars-forward " \t")
      (setq beg (point))
      (if (re-search-forward "[$]" cur-po t)
	  (setq end (- (point) 1))
	(setq end cur-po))
      (setq name (gams*buffer-substring beg end))
      (list (list "DEF" beg name nil
		  (set-marker (make-marker) beg))))))
  
(defun gams-sil-include-spaces-p ()
  (let ((cur-po (point)))
    (save-excursion
      (beginning-of-line)
      (re-search-forward "[ \t]+" cur-po t))))

;; (gams-regexp-opt
;;  (list
;;   "comment" "eolcom" "gdxin" "gdxout" "inlinecom" "maxcol" "mincol" "offeolcom"
;;   "offinline" "offmargin" "offnestcom" "offtext" "onelcom" "oninline"
;;   "onmargin" "onnestcom" "ontext" "dollar" "offdigit" "offempty"
;;   "offend" "offeps" "offglobal" "offwarning" "ondigit" "onempty" "onend"
;;   "oneps" "onglobal" "onwarning" "use205" "use225" "use999" "double"
;;   "eject" "hidden" "lines" "load" "offdollar" "offinclude" "offlisting"
;;   "offupper" "ondollar" "oninclude" "onlisting" "onupper" "single"
;;   "stars" "stitle" "title" "offsymlist" "offsymxref" "offuellist"
;;   "offuelxref" "onsymlist" "onsymxref" "onuellist" "onuelxref" "abort"
;;   "batinclude" "call" "clear" "echo" "error" "exit" "goto" "if" "if exist"
;;   "include" "kill" "label" "libinclude" "onglobal" "onmulti" "offglobal"
;;   "offmulti" "phantom" "set" "setglobal" "setlocal" "shift" "sysinclude") t)

;; No argument dollar control:

;; 

;; One argument dollar control:
;; $\\(gdxin\\|gdxout\\|include\\|batinclude\\|sysinclude\\|libinclude\\|goto\\|label\\)
;; gdxin gdxout include batinclude sysinclude libinclude goto label 

(defun gams-sil-get-identifier-alist ()
  (let ((alist nil)
	(co 0)
	(case-fold-search t)
	co2 po-beg po-end type match-decl)
    (gams-sil-regexp-update)
    (save-excursion
      (unwind-protect
	  (goto-char (point-min))
	(catch 'found
	  (while t
	    (if (re-search-forward gams-regexp-declaration-4 nil t)
		(progn
		  (setq co (1+ co))
		  (setq co2 (% (/ co 50) 4))
		  (message "Starting GAMS-SIL mode %s"
			   (concat
			    (make-string (min (/ co 50) (- fill-column 20)) ?-)
			    (cond
			     ((equal co2 0) "|")
			     ((equal co2 1) "/")
			     ((equal co2 2) "-")
			     ((equal co2 3) "\\"))))
		  (cond
		   ((gams-in-on-off-text-p)
		    (re-search-forward "$offtext" nil t))
		   ;; display "com: ..."
		   ((match-beginning 1)
		    (goto-char (match-end 1))
		    (setq alist (append (gams-sil-get-alist-special-comment) alist))
		    )
		   ;; $(s)title
		   ((match-beginning 2)
		    (goto-char (match-end 2))
		    (setq alist (append (gams-sil-get-alist-title) alist))
;		    (forward-line 1)
		    )
		   ;; $(sys/lib)include
		   ((match-beginning 3)
		    (when (not (gams-check-line-type))
		      (let (match-dollar beg)
			(setq beg (- (match-beginning 3) 1))
			(setq match-dollar
			      (gams*buffer-substring beg (match-end 3)))
			(goto-char (match-end 3))
			(skip-chars-forward " \t")
			(setq alist (append (gams-sil-get-alist-dollar match-dollar beg) alist))))
		    )
		   ;; solve statement
		   ((match-beginning 4)
		    (goto-char (match-end 4))
		    (setq alist (append (gams-sil-get-alist-solve) alist))
		    )
		   ;; equation definition (..) :
		   ((match-beginning 5)
		    (goto-char (match-end 5))
		    (when (not (gams-check-line-type nil t))
		      (setq alist (append (gams-sil-get-alist-def) alist)))
		    )
		   ;; ==.
		   ((match-beginning 6)
		    (goto-char (match-end 6))
		    (when (not (gams-check-line-type nil t t))
		      (setq alist (append (gams-sil-get-alist-func) alist)))
;;		    (forward-line 1)
		    )
		   ;; $exit
		   ((match-beginning 7)
		    (goto-char (match-beginning 7))
		    (setq alist (append (gams-sil-get-alist-exit) alist))
		    (forward-line 1)
		    )
		   ;; identifier definition:
		   (t
		    (setq po-beg (match-beginning 0))
		    (goto-char (match-end 8))
		    (setq match-decl (gams*buffer-substring (match-beginning 8)
							    (match-end 8)))
		    (cond
		     ((string-match "set" match-decl)
		      (setq type "SET"))
		     ((string-match "parameter\\|scalar" match-decl)
		      (setq type "PAR"))
		     ((string-match "equation" match-decl)
		      (setq type "EQU"))
		     ((string-match "variable" match-decl)
		      (setq type "VAR"))
		     ((string-match "$model" match-decl)
		      (setq type "MPSGE"))
		     ((string-match "model" match-decl)
		      (setq type "MOD"))
		     ((string-match "table" match-decl)
		      (setq type "TBL"))
		     ((string-match "alias" match-decl)
		      (setq type "ALI"))
		     (t
		      (setq type "misc")))
		    (cond
;;		     ((string-match "TBL\\|ALI\\|MISC" type)
		     ((string-match "ALI\\|MISC" type)
		      nil)
		     ((string-match "MPSGE" type)
		      (setq alist (append (gams-sil-get-alist-mpsge) alist)))
		     (t
		      (cond
		       ((gams-in-on-off-text-p)
			(re-search-forward "$offtext" nil t))
		       ((gams-check-line-type)
			(forward-line 1)
			)
		       (t
			(setq po-end (gams-sid-return-block-end (point)))
			(unwind-protect
			    (progn
			      (narrow-to-region po-beg po-end)
			      (setq alist (append (gams-sil-get-alist type) alist))
			      (goto-char (point-max)))
			  (widen)))
		       ))))))
	      (throw 'found t))))))
    alist))
    
(defun gams-return-mpsge-end ()
  (save-excursion
    (when (re-search-forward "^$offtext" nil t)
      (match-beginning 0))))

(defun gams-sil-get-mpsge-model-name ()
  "Extract MPSGE model name"
  (skip-chars-forward " \t")
  (when (looking-at "[0-9a-zA-Z_]+")
    (let ((beg (match-beginning 0))
	  (end (match-end 0)))
      (gams-sil-make-alist "MOD" beg (gams*buffer-substring beg end) nil))))
	
(defun gams-sil-get-alist-mpsge ()
  (let ((end (gams-return-mpsge-end))
	alist rep block-begin block-end m-string)
    ;; Extract MPSGE model name.
    (setq alist (or (cons (gams-sil-get-mpsge-model-name) alist) nil))
    (catch 'found
      (while t
	(if (re-search-forward
	     (concat "^$\\(sectors\\|commodities\\|"
		     "consumers\\|auxiliary\\|report\\|prod\\|demand\\|constraint\\):")
	     end t)
	    (progn (setq block-begin (match-end 0))
		   (setq m-string (gams*buffer-substring
				   (match-beginning 0) (match-end 0)))
		   (when (string-match "report" m-string)
		     (setq rep t))
		   (if (string-match "^$\\(prod\\|demand\\|constraint\\):" m-string)
		       ;;
		       (setq alist (cons (gams-sil-get-mpsge-variable-definition) alist))
		       ;;
		       (if (re-search-forward "^$[a-zA-Z]+:" end t)
			   (setq block-end (match-beginning 0))
			 (setq block-end end))
		     (narrow-to-region block-begin block-end)
		     (goto-char (point-min))
		     (catch 'flag
		       (while t
			 (while (gams-check-line-type t)
			   (forward-line 1)
			   (when (eobp)
			     (throw 'flag t)))
			 (if rep
			     (setq alist
				   (cons
				    (gams-sil-get-mpsge-report-variable)
				    alist))
			   (setq alist
				 (cons
				  (gams-sil-get-mpsge-variable)
				  alist)))
			 (forward-line 1)))
		     (goto-char (point-max))
		     (widen)))
	  (throw 'found t))))
    alist))

;; (defun gams-sil-get-alist-mpsge ()
;;   (let ((end (gams-return-mpsge-end))
;; 	alist rep block-begin block-end)
;;     ;; Extract MPSGE model name.
;;     (setq alist (or (cons (gams-sil-get-mpsge-model-name) alist) nil))
;;     (catch 'found
;;       (while t
;; 	(if (re-search-forward
;; 	     (concat "^$\\(sectors\\|commodities\\|"
;; 		     "consumers\\|auxiliary\\|report\\):")
;; 	     end t)
;; 	    (progn (setq block-begin (match-end 0))
;; 		   (when (string-match
;; 			  "report" (gams*buffer-substring
;; 				    (match-beginning 0) (match-end 0)))
;; 		     (setq rep t))
;; 		   (if (re-search-forward "^$[a-zA-Z]+:" end t)
;; 		       (setq block-end (match-beginning 0))
;; 		     (setq block-end end))
;; 		   (narrow-to-region block-begin block-end)
;; 		   (goto-char (point-min))
;; 		   (catch 'flag
;; 		     (while t
;; 		       (while (gams-check-line-type t)
;; 			 (forward-line 1)
;; 			 (when (eobp)
;; 			   (throw 'flag t)))
;; 		       (if rep
;; 			   (setq alist
;; 				 (cons
;; 				  (gams-sil-get-mpsge-report-variable)
;; 				  alist))
;; 			 (setq alist
;; 			       (cons
;; 				(gams-sil-get-mpsge-variable)
;; 				alist)))
;; 		       (forward-line 1)))
;; 		   (goto-char (point-max))
;; 		   (widen))
;; 	  (throw 'found t))))
;;     alist))

(defun gams-sil-get-mpsge-variable ()
  (let ((end (line-end-position))
	beg id exp)
    (when (re-search-forward "^[ \t]*\\([0-9a-zA-Z_]+\\)" end t)
      (setq beg (match-beginning 1))
      (setq id (gams*buffer-substring beg (match-end 1)))
      (when (re-search-forward "!" end t)
	(skip-chars-forward "[! \t]")
	(setq exp (gams*buffer-substring (point) end)))
      (gams-sil-make-alist "MPS" beg id exp))))
  
(defun gams-sil-get-mpsge-report-variable ()
  (let ((end (line-end-position))
	beg id exp)
    (when (re-search-forward "^[ \t]*v:\\([0-9a-zA-Z_]+\\)" end t)
      (setq beg (match-beginning 1))
      (setq id (gams*buffer-substring beg (match-end 1)))
      (when (re-search-forward "!" end t)
	(skip-chars-forward "[! \t]")
	(setq exp (gams*buffer-substring (point) end)))
      (gams-sil-make-alist "MPS" beg id exp))))

(defun gams-sil-get-mpsge-variable-definition ()
  (let ((beg (point))
	end id)
    (skip-chars-forward "a-zA-Z0-9_")
    (when (looking-at "[ \t]*(")
      (re-search-forward ")" (line-end-position) t))
    (setq end (point))
    (setq id (gams*buffer-substring beg end))
    (gams-sil-make-alist "DEF" beg id "")))
  
(defun gams-sil-make-alist (type po name &optional exp)
  (list type po name (or exp nil) (set-marker (make-marker) po)))

(defun gams-sil-get-alist (type)
  (let ((f-tbl nil)
	alist po-beg ex-beg ex-end po id exp f-id)
    (when (equal type "TBL")
      (setq f-tbl t)
      (setq type "PAR"))
    (catch 'found
      (while t
	;; Skip irrelevant lines.
	(while (gams-check-line-type)
	  (forward-line 1)
	  (when (eobp) (throw 'found t)))
	(cond
	 ;; If reaced to the end of the buffer.
	 ((eobp)
	  (when f-id
	    (setq alist (cons (gams-sil-make-alist type po id exp) alist)))
	  (throw 'found t))
	 ((looking-at "[ \t]")
	  (skip-chars-forward "[ \t]"))
	 ((looking-at (regexp-quote gams-eolcom-symbol))
	  (forward-line 1))
	 ((looking-at (regexp-quote gams-inlinecom-symbol-start))
	  (gams-sid-goto-inline-comment-end))
	 ((looking-at "\n")
	  (when f-id
	    (setq f-id nil
		  alist (cons (gams-sil-make-alist type po id exp) alist)
		  po nil
		  id nil
		  exp nil)
	    (when f-tbl (throw 'found t))
	    )
	  (forward-char 1))
	 ((looking-at "/")
	  (goto-char (gams-sid-next-slash)))
	 ((or (looking-at "'") (looking-at "\""))
	  (when f-id
	    (setq ex-beg (match-beginning 0)
		  ex-end (gams-sil-get-alist-exp t)
		  exp (gams*buffer-substring (1+ ex-beg) (1- ex-end)))
	    (goto-char ex-end)))
	 ((looking-at ",")
	  (when f-id
	    (setq f-id nil
		  alist (cons (gams-sil-make-alist type po id exp) alist)
		  po nil
		  id nil
		  exp nil))
	  (forward-char 1))
	 ((looking-at "(")
	  (re-search-forward ")" nil t))
	 (t
	  (if f-id
	      (progn
		(setq ex-beg (point)
		      ex-end (gams-sil-get-alist-exp t)
		      exp (gams*buffer-substring ex-beg ex-end))
		(goto-char ex-end)
		(setq alist (cons (gams-sil-make-alist type po id exp) alist)
		      po nil
		      id nil
		      exp nil
		      f-id nil)
		(when f-tbl (throw 'found t))
		)
	    (setq po-beg (point)
		  po (point))
	    (skip-chars-forward "[a-zA-Z0-9_]")
	    (setq id (gams*buffer-substring po-beg (point)))
	    (setq f-id t))))))
    alist))

(defun gams-sil-get-alist-exp (&optional sil)
  (let (po-end)
    (save-excursion
      (catch 'found
	(while t
	  (cond
	   ((eobp)
	    (setq po-end (point))
	    (throw 'found t))
	   ((looking-at "[ \t]")
	    (skip-chars-forward "[ \t]"))
	   ((looking-at (regexp-quote gams-eolcom-symbol))
	    (setq po-end (point))
	    (throw 'found t))
	   ((looking-at (regexp-quote gams-inlinecom-symbol-start))
	    (gams-sid-goto-inline-comment-end))
	   ((looking-at "\n")
	    (setq po-end (point))
	    (throw 'found t))
	   ((looking-at "/")
	    (skip-chars-backward " \t")
	    (setq po-end (point))
	    (throw 'found t))
	   ((looking-at "\"")
	    (goto-char (gams-sid-get-alist-double-quote)))
	   ((looking-at "'")
	    (goto-char (gams-sid-get-alist-single-quote)))
	   ((looking-at ",")
	    (setq po-end (point))
	    (throw 'found t))
;; 	   ((looking-at "(")
;; 	    (re-search-forward ")" nil t))
	   ((and sil (looking-at ";"))
	    (setq po-end (point))
	    (forward-char 1)
	    (throw 'found t))
	   (t (forward-char 1))))))
      po-end))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Code for 
;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; (NAME . FUNCTION).  NAME is the name of the statement inserted.
;; FUNCTION is the name of the function called after insertion.
(defvar gams-statement-alist-ext
  '( ;; loop type
    ("loop" . gams-insert-post-loop)
    ("if" . gams-insert-post-loop)
    ("while" . gams-insert-post-loop)
    ("for" . gams-insert-post-loop)
    ;; solve type
    ("solve" . gams-insert-post-solve)
    ;; file type
    ("file" . gams-insert-post-file)
    ;; model type
    ("model" . gams-insert-post-model)
    ;; put type
    ("put" . gams-insert-post-put)
    ;; option type
    ("option" . gams-insert-post-option))
  "")

(defvar gams-statement-name-ext "model")

(setq gams-statement-alist-for-completion
      (gams-list-to-alist
       (mapcar 'car gams-statement-alist-ext)))

(defvar gams-insert-option-default "decimals"
  "Def")
(defvar gams-insert-solver-type-list
  '(("lp") ("nlp") ("dnlp") ("rmip") ("mip") ("rminlp") ("minlp") ("mpec") ("mcp") ("cns")))
(defvar gams-insert-solver-optimize-type-list
  '(("lp") ("nlp") ("dnlp") ("rmip") ("mip") ("rminlp") ("mpec") ("cns")))
(defvar gams-insert-option-previous nil)
(defvar gams-insert-solver-type-default "nlp")
(defvar gams-insert-solver-type-previous nil)

;;; (OPTION-NAME MESSAGE DEFAULT-VALUE).
;;; 
(defvar gams-option-option-alist
      '(;; 
	("decimals" "Number of decimals for printing (0 to 8)" 6)
	("eject" nil nil)
	("limcol" "The number of columns in COLUMN LISTING (integer)" 3)
	("limrow" "The number of rows in EQUATION LISTING (integer)" 3)
	("profile" "integer (0 to 2)" 0)
	("profiletol" "real" 0)
	("solprint" "on/off" "on")
	("sysout" "on/off" "on")
	;;
	("bratio" "real (0 to 1)" 0.25)
	("domlim" "integer" 0)
	("iterlim" "real" 1000)
	("optca" "real" 0)
	("optcr" "real" 0.1)
	("reslim" "real" 1000)
	;;
	("cns" "The default cns solver (string)" nil)
	("dnlp" "The default dnlp solver (string)" nil)
	("lp" "The default lp solver (string)" nil)
	("mcp" "The default mcp solver (string)" "path")
	("minlp" "The default minlp solver (string)" nil)
	("mip" "The default mip solver (string)" nil)
	("mpec" "The default mpec solver (string)" nil)
	("nlp" "The default nlp solver (string)" "minos")
	("rminlp" "The default rminlp solver (string)" nil)
	("rmip" "The default rmip solver (string)" nil)
	;;
	("seed" "integer" 3141)
	("soveopt" "merge/replace" "merge")
	))

(defun gams-remove-spaces-from-string (string)
  "Remove spaces from the beginning of the STRING.
If STRING contains only spaces, return null string."
  (let ((num (string-match "[^ \t]" string)))
    (if num (substring string num) "")))
      
(defun gams-remove-unnecessary-characters-from-string (string)
  "Remove unnecesarry characters from the beginning of the STRING.
If STRING contains only spaces, return null string."
  (let ((num (string-match "[^ \t,.]" string)))
    (if num (substring string num) "")))

(defvar gams-mb-map-ext-1 nil
  "*Key map used at gams completion of statements in the minibuffer.")
(if gams-mb-map-ext-1 nil
  (setq gams-mb-map-ext-1
	(copy-keymap minibuffer-local-completion-map))
  (define-key gams-mb-map-ext-1
    "\C-i" 'minibuffer-complete))

(defvar gams-mb-map-ext-2 nil
  "*Key map used at gams completion of statements in the minibuffer.")
(if gams-mb-map-ext-2 nil
  (setq gams-mb-map-ext-2
	(copy-keymap minibuffer-local-completion-map))
  (define-key gams-mb-map-ext-2
    "\C-i" 'minibuffer-complete)
  (define-key gams-mb-map-ext-2
    " " 'gams-minibuffer-insert-space)
  (define-key gams-mb-map-ext-2
    "(" 'gams-insert-parens))

(defun gams-minibuffer-insert-space ()
  (interactive)
  (insert " "))

;;; Define variables to store histories.
(defvar gams-st-hist-statement nil "")
(defvar gams-st-hist-solve-model nil "")
(defvar gams-st-hist-solve-solver nil "")
(defvar gams-st-hist-solve-maximin nil "")
(put 'gams-st-hist-statement 'no-default t)
(put 'gams-st-hist-solve-model 'no-default t)
(put 'gams-st-hist-solve-solver 'no-default t)
(put 'gams-st-hist-solve-maximin 'no-default t)

(defun gams-read-statement-ext (prompt completion &optional history initial key)
  "Read a GAMS statements with completion."
  (let ((minibuffer-completion-table completion))
    (gams-remove-spaces-from-string
     (read-from-minibuffer
      prompt initial
      (or key gams-mb-map-ext-1)
      nil
      history))))

(defun gams-insert-statement-get-name-ext ()
  "Get the name of satement inserted."
  (let ((mess "Insert statement ")
	name guess)
    (setq guess
	  (if gams-statement-upcase
	      (upcase gams-statement-name-ext)
	    (downcase gams-statement-name-ext)))
    (setq name (gams-read-statement-ext
		    (concat mess (format "(default = %s): " guess))
		    gams-statement-alist-for-completion
		    gams-st-hist-statement))
    (if (string= name "") guess name)))

(defun gams-change-case (str)
  "If gams-statement-upcase is non-nil, change STR to upcase."
  (if gams-statement-upcase
      (upcase str)
    (downcase str)))

(defun gams-insert-post-option (name)
  (let ((opt-def
	 (or gams-insert-option-previous
	     gams-insert-option-default))
	(opt-comp gams-option-option-alist)
	opt-list opt-mess opt-default opt-name)
    (insert " ")
    (catch 'flag
      (while t
	(setq opt-name
	      (gams-read-statement-ext
	       (format "Insert an option name (default = %s): " opt-def)
	       opt-comp nil nil gams-mb-map-ext-1))
	(when (equal "" opt-name) (setq opt-name opt-def))
	(setq gams-insert-option-previous opt-name)
	(insert (gams-change-case opt-name))
	(setq opt-list (assoc opt-name opt-comp)
	      opt-mess (car (cdr opt-list))
	      opt-default (car (cdr (cdr opt-list))))
	(when (numberp opt-default)
	  (setq opt-default (number-to-string opt-default)))
	(if (not opt-mess)
	    (insert ", ")
	  (let (arg)
	    (insert " = ")
	    (setq arg
		  (gams-read-statement-ext
		   (concat opt-mess 
			   (if opt-default
			       (format " [default is %s]: " opt-default)
			     ": "))
		   nil nil nil gams-mb-map-ext-1))
	    (cond
	     ((not (equal arg ""))
	      (insert (concat arg ", ")))
	     ((and (equal arg "") opt-default)
	      (insert (concat opt-default ", ")))
	     (t nil))))
	(message "Insert another option?: SPACE = yes, other keys = no.")
	(unless (equal ? (read-char))
	  (skip-chars-backward ", ")
	  (delete-char 2)
	  (insert ";")
	  (throw 'flag t))))))
  
(defun gams-insert-post-loop (name)
  (let (type mess arg-1 po-beg)
    (setq type (downcase name))
    (setq mess
	  (cond
	   ((equal type "loop")
	    "Insert domain part: ")
	   ((or (equal type "if") (equal type "while"))
	    "Insert condition part: ")
	   ((equal type "for")
	    "Insert start-end-incr part: ")))
    (setq po-beg (point))
    (insert (concat "(,\n);"))
    (indent-region po-beg (point) nil)
    (goto-char (1+ po-beg))
    (setq arg-1 (gams-read-statement-ext
		 mess nil nil nil gams-mb-map-ext-2))
    (unless (equal "" arg-1)
      (insert arg-1))))

(defun gams-insert-post-solve (name)
  (let ((def-solv (or gams-insert-solver-type-previous
		     gams-insert-solver-type-default))
	mod-name sol-type maxmin maximand)
    (insert " ")
    (let ((alist-modname
	   (gams-list-to-alist
	    (gams-store-model-name (point-min) (point)))))
      (setq mod-name
	    (gams-read-statement-ext
	     (concat "Insert model name: ")
	     alist-modname gams-st-hist-solve-model nil nil))
      (unless (equal mod-name "") (insert mod-name)))
    (insert (gams-change-case " using "))
    (setq sol-type
	  (gams-read-statement-ext
	   (format "Insert solver type (default = %s): " def-solv)
	   gams-insert-solver-type-list
	   gams-st-hist-solve-solver nil nil))
    (if (equal sol-type "")
	(progn (setq sol-type def-solv)
	       (insert (concat (gams-change-case sol-type) " ")))
      (setq gams-insert-solver-type-previous sol-type)
      (insert (concat (gams-change-case sol-type) " ")))
    (if (not (member (list sol-type) gams-insert-solver-optimize-type-list))
	;; Not optimization type.
	(progn (delete-char -1) (insert ";"))
      ;; Optimization type.
      (let ((var-alist (gams-list-to-alist (gams-store-variable-name (point)))))
	(catch 'key
	  (while t
	    (message "M(a)ximize or m(i)nimize?: a = maximize, i = minimize.")
	    (setq maxmin (read-char))
	    (cond
	     ((equal ?a maxmin)
	      (insert (gams-change-case "maximizing "))
	      (throw 'key t))
	     ((equal ?i maxmin)
	      (insert (gams-change-case "minimizing "))
	      (throw 'key t))
	     (t (message "Type a or i!") (sit-for 0.5)))))
	(setq maximand
	      (gams-read-statement-ext
	       (concat "Insert the objective variable: ")
	       var-alist nil nil nil))
	(unless (equal maximand "") 
	  (insert (concat maximand ";")))))))

(defun gams-insert-model-components ()
  (let* ((eq-list (gams-store-equation-name (point-min) (point)))
	 (eq-comp (gams-list-to-alist eq-list))
	 ele)
    (if (not eq-comp)
	(progn (message "No equations are defined yet!")
	       (sit-for 1.5))
      (catch 'flag
	(while t
	  (setq ele
		(gams-read-statement-ext
		 "Insert equation identifier (all = all, @ll = list all equations): "
		 eq-comp nil nil gams-mb-map-ext-1))
	  (cond
	   ((equal ele "")
	    (skip-chars-backward ", ")
	    (when (looking-at ",") (delete-char 2))
	    (throw 'flag t))
	   ((equal ele "all")
	    (insert ele)
	    (throw 'flag t))
	   ((equal ele "@ll")
	    (let ((eq-list-2 eq-list))
	      (while eq-list-2
		(insert (concat (car eq-list-2) ", "))
		(setq eq-list-2 (cdr eq-list-2))))
	    (delete-char -2)
	    (throw 'flag t))
	   (t (insert (concat ele ", ")))))))))
  
(defun gams-insert-post-model (name)
  (let (m-name m-exp m-equ eq-comp key)
    (insert " ")
    (catch 'flag
      (while t
	(setq m-name
	      (gams-read-statement-ext
	       (concat "Insert model name: ")
	       nil nil nil gams-mb-map-ext-2))
	(unless (equal "" m-name) (insert (concat m-name " ")))
	(setq m-exp
	      (gams-read-statement-ext
	       (concat "Insert model explanatory texts: ")
	       nil nil nil gams-mb-map-ext-2))
	(unless (equal m-exp "") (insert (concat m-exp " ")))
	(insert "/  /")
	(backward-char 2)
	;; Insert equation labels.
	(gams-insert-model-components)
	(end-of-line)
 	(message "Define another model?: SPACE = yes, other keys = no.")
	(setq key (read-char))
	(if (equal key ?y)
	    (progn (end-of-line)
		   (skip-chars-backward " \t")
		   (insert ",\n") (gams-indent-line))
	  (insert ";")
	  (throw 'flag t))
	))))

(defun gams-insert-post-file (name)
  (let ((f-comp (gams-list-to-alist
		 (directory-files default-directory)))
	f-label f-exp f-name)
    (insert " ")
    (setq f-label
	  (gams-read-statement-ext
	   (concat "Insert file label: ")
	   nil nil nil nil))
    (unless (equal f-label "")
      (insert (concat f-label " ")))
    (setq f-exp
	  (gams-read-statement-ext
	   (concat "Insert file explanatory texts: ")
	   nil nil nil gams-mb-map-ext-2))
    (if	(equal f-exp "")
	(delete-char -1)
      (insert (concat f-exp " ")))
    (insert " /  /")
    (backward-char 2)
    (setq f-name
	  (gams-read-statement-ext
	   (concat "Insert file name: ")
	   f-comp nil nil nil))
    (unless (equal f-name "")
      (insert f-name)
      (end-of-line)
      (insert ";"))))

(defun gams-insert-post-put (name)
  (let* ((f-comp
	  (gams-list-to-alist
	   (gams-store-file-label (point-min) (point))))
	 (mess (if f-comp
		   "Insert file label:"
		 "Insert file label (no file lable difined yet!): "))
	 f-label)
    (insert " ")
    (setq f-label (gams-read-statement-ext mess f-comp nil nil nil))
    (unless (equal f-label "")
      (insert f-label)
      (insert ";"))))

(defun gams-goto-next-offtext (&optional limit)
  "Search the next $offtext.
LIMIT is the limit point of searching."
  (re-search-forward "^$offtext" (or limit nil) t))

(defun gams-goto-prev-ontext (&optional limit)
  "Search the previous $ontext.
LIMIT is the limit point of searching."
  (re-search-backward "^$ontext" (or limit nil) t))

(defun gams-store-equation-name (beg end)
  "Return a list of equation names defined between BEG and END.
BEG and END are points."
  (let (equ-list po-beg po-end equ po-next)
    (save-excursion
      (goto-char beg)
      (catch 'found
	(while t
	  (if (re-search-forward "[.][.]" end t)
	      (progn
		(setq po-next (point))
		(if (gams-in-on-off-text-p)
		    (gams-goto-next-offtext (point-max))
		  (when (and (not (gams-check-line-type))
			     (not (gams-in-quote-p))
			     (not (gams-in-comment-p)))
		      (skip-chars-backward " \n\t.")
		      (setq po-end (point))
		      (beginning-of-line)
		      (skip-chars-forward " \t")
		      (setq po-beg (point))
		      (when (re-search-forward "[$]\\|(" po-end t)
			(setq po-end (match-beginning 0)))
		      (setq equ (gams*buffer-substring po-beg po-end))
		      (setq equ-list (cons equ equ-list))
		      (goto-char po-next))))
	    (throw 'found t)))))
  (nreverse equ-list)))

(defun gams-store-model-name (beg end)
  "Return a list of model names defined between BEG and END.
BEG and END are points."
  (let (model-list po-beg po-end model po-next)
    (save-excursion
      (goto-char beg)
      (catch 'found
	(while t
	  (if (re-search-forward "^[ \t]*\\(model[s]?\\|[$]model[s]?:\\)" end t)
	      (progn
		(setq po-next (point))
		(if (gams-in-on-off-text-p)
		    (gams-goto-next-offtext (point-max))
		  (skip-chars-forward " \t")
		  (setq po-beg (point))
		  (skip-chars-forward "^ \t\n")
		  (setq po-end (point))
		  (setq model (gams*buffer-substring po-beg po-end))
		  (setq model-list (cons model model-list))
		  (goto-char po-next)))
	    (throw 'found t)))))
    (nreverse model-list)))

(defun gams-store-file-label (beg end)
  "Return a list of file defined between BEG and END.
BEG and END are points."
  (let (f-list po-beg po-end f)
    (save-excursion
      (goto-char beg)
      (catch 'found
	(while t
	  (if (re-search-forward "^[ \t]*file[ \t]+" end t)
	      (progn
		(if (gams-in-on-off-text-p)
		    (gams-goto-next-offtext (point-max))
		  (setq po-beg (point))
		  (skip-chars-forward "^ \t")
		  (setq po-end (point))
		  (setq f (gams*buffer-substring po-beg po-end))
		  (setq f-list (cons f f-list))))
	    (throw 'found t)))))
  (nreverse f-list)))

(defun gams-store-identifier-list-sub ()
  (interactive)
  (let ((lst nil)
	po-beg po-end ex-end po id f-id)
    (catch 'found
      (while t
	(while (gams-check-line-type)
	  (forward-line 1)
	  (when (eobp)
	    (throw 'found t)))
	(cond
	 ((eobp)
	  (when f-id
	    (setq lst (cons id lst)))
	  (throw 'found t))
	 ((looking-at "[ \t]")
	  (skip-chars-forward "[ \t]"))
	 ((looking-at (regexp-quote gams-eolcom-symbol))
	  (forward-line 1))
	 ((looking-at (regexp-quote gams-inlinecom-symbol-start))
	  (gams-sid-goto-inline-comment-end))
	 ((looking-at "\n")
	  (when f-id
	    (setq f-id nil)
	    (setq lst (cons id lst))
	    (setq id nil))
	  (forward-char 1))
	 ((looking-at "/")
	  (goto-char (gams-sid-next-slash)))
	 ((or (looking-at "'") (looking-at "\""))
	  (when f-id
	    (setq ex-end (gams-store-identifer-alist-sub-sub))
	    (goto-char ex-end)))
	 ((looking-at ",")
	  (when f-id
	    (setq f-id nil)
	    (setq lst (cons id lst))
	    (setq id nil))
	  (forward-char 1))
	 ((looking-at "(")
	  (re-search-forward ")" nil t))
	 (t (if f-id
		(progn
		  (setq ex-end (gams-store-identifer-alist-sub-sub))
		  (goto-char ex-end)
		  (setq lst (cons id lst))
		  (setq id nil)
		  (setq f-id nil))
	      (setq po-beg (point))
	      (skip-chars-forward "[a-zA-Z0-9_]")
	      (setq po-end (point))
	      (setq id (gams*buffer-substring po-beg po-end))
	      (setq f-id t))))))
    lst))

(defun gams-store-identifer-alist-sub-sub ()
  (interactive)
  (let (po-end)
    (save-excursion
      (catch 'found
	(while t
	  (cond
	   ((eobp)
	    (setq po-end (point))
	    (throw 'found t))
	   ((looking-at "[ \t]")
	    (skip-chars-forward "[ \t]"))
	   ((looking-at (regexp-quote gams-eolcom-symbol))
	    (forward-line 1))
	   ((looking-at (regexp-quote gams-inlinecom-symbol-start))
	    (gams-sid-goto-inline-comment-end))
	   ((looking-at "\n")
	    (setq po-end (point))
	    (throw 'found t))
	   ((looking-at "/")
	    (skip-chars-backward " \t")
	    (setq po-end (point))
	    (throw 'found t))
	   ((looking-at "\"")
	    (goto-char (gams-sid-get-alist-double-quote)))
	   ((looking-at "'")
	    (goto-char (gams-sid-get-alist-single-quote)))
	   ((looking-at ",")
	    (setq po-end (point))
	    (throw 'found t))
	   ((looking-at "(")
	    (re-search-forward ")" nil t))
	   (t (forward-char 1)
	    )))))
      po-end))

(defun gams-store-identifer-list (&optional limit)
  (let ((list nil)
	(case-fold-search t)
	(reg "^[ \t]*\\(integer\\|binary\\|positive\\|negative\\)*[ \t]*\\(variables?\\)[ \t\n(]*")
	count
	po-beg po-end)
    (save-excursion
      (goto-char (point-min))
      (catch 'found
	(while t
	  (if (re-search-forward reg limit t)
	      (progn
		(setq po-beg (match-beginning 0))
		(goto-char (match-end 2))
		(cond
		 ((gams-in-on-off-text-p)
		  (re-search-forward "$offtext" nil t))
		 ((gams-check-line-type)
		  (forward-line 1))
		 (t
		  (setq po-end (gams-sid-return-block-end (point)))
		  (unwind-protect
		      (progn
			(narrow-to-region po-beg po-end)
			(setq list (append (gams-store-identifier-list-sub) list))
			(goto-char (point-max)))
		    (widen)))))
	    (throw 'found t)))))
    list))

(defun gams-store-variable-name (&optional end)
  "Return a list of variables names.
IF END is nil, search in the whole buffer.
IF END is t, search until the point END."
  (let ((var-list (nreverse (gams-store-identifer-list))))
    var-list))

(defun gams-insert-statement-extended (&optional cmd)
  "Insert GAMS statement with extended features.  This command has various
extended features than the normal `gams-insert-statement'.  Types of
statements you can insert with this command are:

* OPTION type statement
* MODEL type statement
* SOLVE type statement
* LOOP type statement
* FILE type statement
* PUT type statement.

*OPTION type
Completion of option name and option value.

*MODEL type
Completion of equation names.

*SOLVE type
Completion of model type and objective variable name.

*LOOP type
Completion of parenthesis.

*FILE type
Completion of external file name.

*PUT type
Completion of internal file name."
  (interactive)
  (unwind-protect
      (let* ((completion-ignore-case t)
	     (source-window (selected-window))
	     (statement
	      (or cmd
		  (gams-insert-statement-get-name-ext))))
	;; Insert.
	(if gams-statement-upcase
	    (setq statement (upcase statement))
	  (setq statement (downcase statement)))
	(setq gams-statement-name-ext statement)
	(insert statement)
	(let ((func-name (cdr (assoc (downcase statement) gams-statement-alist-ext))))
	  (when func-name
	    (funcall func-name statement))))
    (if (<= (minibuffer-depth) 0) (use-global-map global-map))
    (insert "")))
 ;;insert dummy string to fontify(Emacs20)

;;;	From yatex.el
;;; autoload
(defun substitute-all-key-definition (olddef newdef keymap)
  "Replace recursively OLDDEF with NEWDEF for any keys in KEYMAP now
defined as OLDDEF. In other words, OLDDEF is replaced with NEWDEF
where ever it appears."
    (mapcar
     (function (lambda (key) (define-key keymap key newdef)))
     (where-is-internal olddef keymap)))
;;-------------------- Final hook jobs --------------------
(substitute-all-key-definition
 'fill-paragraph 'gams-fill-paragraph gams-mode-map)

;;; The codes below are taken from hideshow.el.

;; internal variables.
(setq-default gams-invisible-areas-list ())
(setq-default gams-invisible-exist-p nil)

(defun gams-toggle-hide/show-comment-lines ()
  "Toggle hide/show of comment lines.
Note that this command just hide comment lines and makes no
modification to the buffer.  In addition, mpsge block is not
hidden although it is enclosed with $ontext-$offtext."
  (interactive)
  (if gams-invisible-exist-p
      ;; if comment lines are visible.
      (gams-show-all-invisible-comment-lines)
    ;; if comment lines are invisible.
    (gams-hide-comment-lines)))

(defun gams-add-invisible-overlay (start end &optional s-offset e-offset)
  "Add an overlay from `start' to `end' in the current buffer.  Push the
overlay onto the gams-invisible-areas-list list"
  (unless s-offset (setq s-offset 0))
  (unless e-offset (setq e-offset 0))
  (let ((ov (make-overlay start end)))
    (setq gams-invisible-areas-list (cons ov gams-invisible-areas-list))
    (overlay-put ov 'invisible 'gams)
    (overlay-put ov 'gams 'comment)
    (overlay-put ov 'gams-s-offset s-offset)
    (overlay-put ov 'gams-e-offset e-offset)))

(defun gams-hide-comment-lines  ()
  "Hide comment lines."
  (interactive)
  (let ((cur-po (point)))
    (setq line-move-ignore-invisible t)
    (save-excursion
      (condition-case err
	  (progn
	    (goto-char (point-min))
	    (let* ((com-start (concat "^[" comment-start "]"))
		   (reg (concat "\\(" com-start "\\)\\|\\(^[$]ontext" "\\)"))
		   ontext start-po end-po start-b-po end-b-po)
	      (catch 'found
		(while t
		  (setq ontext nil)
		  (if (not (re-search-forward reg nil t))
		      (throw 'found t)
		    (when (match-beginning 2) (setq ontext t))
		    (beginning-of-line)
		    (setq start-b-po (point))
		    (if ontext
			(setq start-po (line-end-position)))
		    (setq start-po (line-end-position))
		    (setq end-po (gams-forward-comment))
		    (when (not end-po)
		      (throw 'found t))
		    (forward-line -1)
		    (when (not (gams-in-mpsge-block-p (point)))
		      (setq end-b-po end-po)
		      (when (not (equal start-po end-po))
			(gams-add-invisible-overlay start-po end-po start-b-po)))
		    (forward-line 2)))))
	    (setq gams-invisible-exist-p t)
	    (message "All comment lines are made invisible.  Type C-cC-h to make them visible again."))
	;; error handlers.
	(gams-discard-overlays (point-min) (point-max))
	(setq gams-invisible-exist-p nil)
	(setq gams-invisible-areas-list ())))))

(defun gams-forward-comment (&optional lim)
  "Skip all comment lines from the current point."
  (let (type end-po)
    (setq lim (or lim (point-max)))
    (beginning-of-line)
    (catch 'found
      (while t
	(setq type (gams-check-line-type))
	(when (and (not type) (looking-at "^[$]ontext"))
	  (setq type "ontext"))
	(when (not type) (throw 'found t))
	(cond
	 ;; $ontext
	 ((equal type "ontext")
	  (if (re-search-forward "^[$]offtext" nil t)
	      ;; if $offtext is found
	      (progn
		(end-of-line)
		(setq end-po (point))
		(skip-chars-forward " \t\n"))
	    ;; if $offtext is not found
	    (throw 'found t)))
	 ;; empty line
	 ((equal type "e")
	  (skip-chars-forward " \t\n")
	  (beginning-of-line))
	 ;; comment line
	 ((equal type "c")
	  (end-of-line)
	  (setq end-po (point))
	  (skip-chars-forward " \t\n")))
	(when (or (eobp) (>= (point) lim))
	  (throw 'found t))))
    (skip-chars-backward " \t\n")
    end-po))
		
(defun gams-show-all-invisible-comment-lines ()
  "Show all areas hidden by the filter-buffer command"
  (interactive)
  (message "Showing all comment blocks ...")
  (gams-discard-overlays (point-min) (point-max))
  (message "Showing all comment blocks ... done")
  (setq gams-invisible-exist-p nil)
  (setq gams-invisible-areas-list ()))

(defun gams-overlay-at (position)
  "Return gams overlay at POSITION, or nil if none to be found."
  (let ((overlays (overlays-at position))
        ov found)
    (while (and (not found) (setq ov (car overlays)))
      (setq found (and (overlay-get ov 'gams) ov)
            overlays (cdr overlays)))
    found))

(defun gams-discard-overlays (from to)
  "Delete gams overlays in region defined by FROM and TO."
  (when (< to from)
    (setq from (prog1 to (setq to from))))
  (let (ov)
    (while (> to (setq from (next-overlay-change from)))
      (when (setq ov (gams-overlay-at from))
	(setq from (overlay-end ov))
	(delete-overlay ov))))
  (dolist (ov (overlays-in from to))
    (when (overlay-get ov 'gams)
      (delete-overlay ov))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Code for GAMS-LST mode.
;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; key assignment.
(defvar gams-lst-mode-map (make-keymap) "Keymap for gams-lst-mode")
(let ((map gams-lst-mode-map))
  (define-key map gams-lk-3 'gams-lst-view-error)
  (define-key map gams-lk-2 'gams-lst-jump-to-error-file)  
  (define-key map gams-lk-1 'gams-lst-jump-to-input-file)
  (define-key map "q" 'gams-lst-kill-buffer)    
  (define-key map "Q" 'gams-lst-exit)    
  (define-key map "?" 'gams-lst-help)    

  (define-key map "o" 'gams-outline)
  (define-key map "O" 'gams-outline-external)

  (define-key map "s" 'gams-lst-solve-summary)
  (define-key map "S" 'gams-lst-solve-summary-back)
  (define-key map "r" 'gams-lst-report-summary)    
  (define-key map "R" 'gams-lst-report-summary-back)    
  (define-key map "v" 'gams-lst-next-var)    
  (define-key map "V" 'gams-lst-previous-var)    
  (define-key map "e" 'gams-lst-next-equ)    
  (define-key map "E" 'gams-lst-previous-equ)    
  (define-key map "p" 'gams-lst-next-par)    
  (define-key map "P" 'gams-lst-previous-par)    
  (define-key map "x" 'gams-lst-next-elt)
  (define-key map "X" 'gams-lst-previous-elt)
  (define-key map "c" 'gams-lst-next-clt)
  (define-key map "C" 'gams-lst-previous-clt)

  (define-key map "L" 'gams-lst-query-jump-to-line)    
  (define-key map gams-lk-5 'gams-lst-jump-to-line)    

  (define-key map " " 'scroll-up)    
  (define-key map [delete] 'scroll-down)    
  (define-key map "1" 'gams-lst-widen-window)    
  (define-key map "2" 'gams-lst-split-window)
  (define-key map "m" 'gams-lst-move-frame)    
  (define-key map "w" 'gams-lst-resize-frame)
  (define-key map "z" 'gams-lst-move-cursor)    

  (define-key map gams-lk-4 'gams-lst-jump-to-input-file-2)

  (define-key map "d" 'gams-lst-scroll-1)
  (define-key map "f" 'gams-lst-scroll-down-1)
  (define-key map "g" 'gams-lst-scroll-2)
  (define-key map "h" 'gams-lst-scroll-down-2)
  (define-key map "j" 'gams-lst-scroll-double)
  (define-key map "k" 'gams-lst-scroll-down-double)

  (define-key map "D" 'gams-lst-scroll-page-1)
  (define-key map "F" 'gams-lst-scroll-page-down-1)
  (define-key map "G" 'gams-lst-scroll-page-2)
  (define-key map "H" 'gams-lst-scroll-page-down-2)
  (define-key map "J" 'gams-lst-scroll-page-double)
  (define-key map "K" 'gams-lst-scroll-page-down-double)

  (define-key map gams-choose-font-lock-level-key
    'gams-choose-font-lock-level)

  (define-key map "." 'gams-lst-file-summary)
  )

;;; Menu for GAMS-LST mode.
(easy-menu-define 
  gams-lst-menu gams-lst-mode-map "Menu keymap for GAMS-LST mode."
  '("GAMS-LST"
    ["Jump to the error and show its meaning" gams-lst-view-error t]
    ["Jump to the error place in the program file" gams-lst-jump-to-error-file t]
    ["Jump to the input file" gams-lst-jump-to-input-file t]
    ["Close the buffer" gams-lst-kill-buffer t]
    ["Exit the lst mode" gams-lst-exit t]
    ["Display Include File Summary" gams-lst-file-summary t]
    ["Show help" gams-lst-help t]
    "--"
    ["Start the GAMS-OUTLINE mode" gams-outline t]
    ["GAMS-OUTLINE mode with the external program" gams-outline-external t]
    "--"
    ["Jump to a line you specify" gams-lst-query-jump-to-line t]    
    ["Jump to a line" gams-lst-jump-to-line t]
    "--"
    ["Jump to the next SOLVE SUMMARY" gams-lst-solve-summary t]    
    ["Jump to the next REPORT SUMMARY" gams-lst-report-summary t]    
    ["Jump to the next VAR entry" gams-lst-next-var t]    
    ["Jump to the next EQU entry" gams-lst-next-equ t]    
    ["Jump to the next PARAMETER entry" gams-lst-next-par t]
    ["Jump to the next Equation Listing entry" gams-lst-next-elt t]
    ["Jump to the next Column Listing entry" gams-lst-next-clt t]
    "--"
    ["Choose font-lock level." gams-choose-font-lock-level t]
    ["Fontify block." font-lock-fontify-block t]
    ))

(setq-default gams-ol-alist nil)
(setq-default gams-ol-alist-tempo nil)
(setq-default gams-ol-flag nil)
(setq-default gams-lst-ol-buffer-point nil)
(setq-default gams-ol-use-external nil)

(defun gams-lst-mode ()
  "Major mode for viewing GAMS LST file. 

The following commands are available in the GAMS-LST mode:

\\[gams-lst-view-error]		Jump to the error and show its number and meaning.
\\[gams-lst-jump-to-error-file]		Jump back to the error place in the program file.
\\[gams-lst-jump-to-input-file] 		Jump to the input (GMS) file.
\\[gams-lst-kill-buffer]		Close the buffer.
\\[gams-lst-file-summary]		Display Include File Summary.
\\[gams-lst-help]		Display this help.

\\[gams-outline]		Start the GAMS-OUTLINE mode.
\\[gams-outline-external]		GAMS-OUTLINE mode with the external program.

\\[gams-lst-solve-summary]/\\[gams-lst-solve-summary-back]		Jump to the next/previous SOLVE SUMMARY.
\\[gams-lst-report-summary]/\\[gams-lst-report-summary-back]		Jump to the next/previous REPORT SUMMARY.
\\[gams-lst-next-var]/\\[gams-lst-previous-var]		Jump to the next/previous VAR entry.
\\[gams-lst-next-equ]/\\[gams-lst-previous-equ]		Jump to the next/previous EQU entry.
\\[gams-lst-next-par]/\\[gams-lst-previous-par]		Jump to the next/previous PARAMETER entry.
\\[gams-lst-next-elt]/\\[gams-lst-previous-elt]		Jump to the next/previous Equation Listing entry.
\\[gams-lst-next-clt]/\\[gams-lst-previous-clt]		Jump to the next/previous Column Listing entry.

\\[gams-lst-query-jump-to-line]		Jump to a line you specify.
\\[gams-lst-jump-to-line]		Jump to a line.

\\[scroll-up]		Scroll up.
\\[scroll-down] or DEL	Scroll down.
\\[gams-lst-widen-window]		Widen the window.
\\[gams-lst-split-window]		Split the window.
\\[gams-lst-move-frame]		Move frame.
\\[gams-lst-resize-frame]		Resize frame.
\\[gams-lst-move-cursor]		Move a cursor to the other window.

[Commands for Scrolling.]

Suppose that there are two windows displayed like

    __________________	  
   |   	      	      |  
   |  LST buffer 1    |  ==>  LST-1.
   |   	      	      |  
   |  CURSOR  here    |  
   |   	      	      |  
   |------------------|  
   |		      | 
   |  LST buffer 2    |  ==>  LST-2.
   |   	      	      |  
   |		      | 
    ------------------

\\[gams-lst-scroll-1]/\\[gams-lst-scroll-down-1]		Scroll the current buffer LST-1 up/down one line.
\\[gams-lst-scroll-2]/\\[gams-lst-scroll-down-2]		Scroll the next buffer LST-2 up/down one line.
\\[gams-lst-scroll-double]/\\[gams-lst-scroll-down-double]		Scroll two buffers LST-1 and LST-2 up/down one line.

Keyboard.

  _____________________________________________________________
  |         |         |         |         |         |         |
  |    d    |    f    |    g    |    h    |    j    |    k    |
  |         |         |         |         |         |         |
  -------------------------------------------------------------

       |         |         |         |         |         |

      UP        DOWN      UP        DOWN      UP        DOWN
         LST-1               LST-2             LST-1 & 2

If only one window exists, the above three commands have the same function
i.e. scroll up/down the current buffer.

The followings are page scroll commands.  Just changed to upper cases.

\\[gams-lst-scroll-page-1]/\\[gams-lst-scroll-page-down-1]		Scroll up/down the current buffer LST-1 by a page.
\\[gams-lst-scroll-page-2]/\\[gams-lst-scroll-page-down-2]		Scroll up/down the next buffer LST-2 by a page.
\\[gams-lst-scroll-page-double]/\\[gams-lst-scroll-page-down-double]		Scroll up/down two buffers LST-1 and LST-2 by a page."
  (interactive)
  (setq major-mode 'gams-lst-mode)
  (setq mode-name "GAMS-LST")
  (use-local-map gams-lst-mode-map)
  (setq buffer-read-only t) ;make the buffer read-only.
  (make-local-variable 'font-lock-defaults)
  (gams-update-font-lock-keywords "l" gams-lst-font-lock-level)
  (setq font-lock-defaults '(gams-lst-font-lock-keywords t t))
  ;; Create several buffer local variables for the OUTLINE mode.
  (make-local-variable 'gams-ol-flag)
  (setq gams-ol-flag nil)
  ;; `gams-ol-alist' is the variable in which full items are stored.
  (make-local-variable 'gams-ol-alist)
;;  (setq gams-ol-alist nil)
  ;; `gams-ol-alist-tempo' is the variable in which viewable items are
  ;; stored.
  (make-local-variable 'gams-ol-alist-tempo)
;;  (setq gams-ol-alist-tempo nil)
  (unless gams-lst-ol-buffer-point
    (make-local-variable 'gams-lst-ol-buffer-point))
  ;;
  (make-local-variable 'gams-ol-use-external)
  (setq gams-ol-use-external nil)
  ;; 					;
  (easy-menu-add gams-lst-menu)
  (setq truncate-lines t)
  (run-hooks 'gams-lst-mode-hook)
  (when font-lock-mode
    (setq font-lock-mode nil))
  (if (and (not (equal gams-lst-font-lock-keywords nil))
	   font-lock-mode)
      (if gams-xemacs
          nil
        (when (<= (buffer-size) font-lock-maximum-size)
        (font-lock-fontify-buffer))
        (if (equal gams-lst-font-lock-keywords nil)
        (font-lock-mode -1))))
)
;; gams-lst-mode ends here.		;

(defun gams-lst-help ()
  "Display help for the GAMS-LST mode."
  (interactive)
  (describe-function 'gams-lst-mode))

(defun gams-lst-kill-buffer ()
  "Close the LST buffer and return to the GMS file."
  (interactive)
  (let ((ov-buff (concat "*" (buffer-name) "-OL*"))
	(cur-buf (current-buffer)))
    (if (get-buffer ov-buff)
	(kill-buffer ov-buff))
    (when gams-lst-ol-buffer-point
      (gams-lst-jump-to-input-file)
      (setq gams-ol-buffer-point gams-lst-ol-buffer-point))
    (kill-buffer cur-buf)))

(defun gams-lst-exit ()
  "Close the LST buffer."
  (interactive)
  (let ((ov-buff (concat "*" (buffer-file-name) "-OL*"))
	(cur-buf (current-buffer)))
    (if (get-buffer ov-buff)
	(kill-buffer ov-buff))
    (when gams-lst-ol-buffer-point
      (setq gams-ol-buffer-point gams-lst-ol-buffer-point))
    (kill-buffer cur-buf)))

(defun gams-lst-view-error ()
  "Move to the error place.
and show its meaning in another window if error number is displayed."
  (interactive)
  (goto-char (point-min))
  (let ((mess (concat "LastMod "
	       (gams-get-lst-modified-time (buffer-file-name))
	       ": "))
	error-num error-place error-mes-place error-column b-point a-point)
    ;; First search syntax error. 
    (if (re-search-forward "\\*\\*\\*\\* [ ]+\\(\\$\\)\\([0-9]+\\)[$]?" nil t)
	(progn
	  (goto-char (match-beginning 1))
	  (setq error-place (point))
	  ;; set `error-num' the found error number. It is nil if no error.
	  (setq error-num (gams*buffer-substring (match-beginning 2)
					    (match-end 2)))
	  (message
	   (concat mess
		   (format "[%s]=Jump to the error place, [%s]=Jump to the input file"
			   gams-lk-2 gams-lk-1)))
	  (if error-num
	      (progn
		(if (not (re-search-forward "Error Messages" nil t))
		    nil
		  (setq error-mes-place
			(re-search-forward error-num nil t))))
	    ;; if error-num is nil, go to the top of the buffer.
	    (goto-char (point-min)))
	  ;; Display syntax error message.
	  (if error-mes-place
	      (progn
		(delete-other-windows)
		(split-window)
		(goto-char error-place)
		(recenter)
		(other-window 1)
		(goto-char error-mes-place)
		(recenter 0)
		(other-window 1))
	    (recenter)))

      ;; Search another type of errors.
      (if (catch 'found
	    (while (re-search-forward "\\*\\*\\*\\* " nil t)
	      (progn
		(setq b-point (line-end-position))
		(goto-char (setq a-point (line-beginning-position)))
		;; The following lines are not regarded as errors and
		;; skipped.  Is this right behavior?
		(if (not (re-search-forward
			  (concat "\\*\\*\\*\\* "
				  "\\(SOLVER STATUS\\|"
				  "MODEL STATUS\\|"
				  "REPORT SUMMARY\\|"
				  "REPORT FILE SUMMARY\\|"
				  "LIST OF STRAY NAMES\\|"
				  "STRAY NAME \\|"
				  "FILE SUMMARY\\|"
				  "Saved point\\|"
				  "OBJECTIVE VALUE\\)")
			  b-point t))
		    (throw 'found t)
		  (forward-line 1)))))
	  (progn
	    (goto-char (match-beginning 0))
	    (setq a-point (point))
	    (setq b-point (line-end-position))
	    (if (re-search-forward " at line \\([0-9]+\\)" b-point t)
		(message
		 (concat mess
			 (format "Error is found!  Type `%s' if you want to jump to the error line %s."
				 gams-lk-5 (gams*buffer-substring (match-beginning 1)
								  (match-end 1)))))
	      (message (concat mess "Error is found!")))
	    (goto-char a-point)
	    nil)
	;; Else part.  When no error is found.
	(progn
	  (message (concat mess "No error message is found!"))
	  (goto-char (point-min)))
	))))
;;; 
(defun gams-lst-jump-to-error ()
  "Jump to the error place."
  (interactive)
  (let ((current-point (point)))
    (goto-char (point-min))
    (if	(re-search-forward "\\*\\*\\*\\* [ ]+\\(\\$\\)\\([0-9]+\\)[$]?" nil t)
	(goto-char (match-beginning 1))
      (goto-char current-point)
      (message "No error is found!"))))

(defun gams-lst-get-gms ()
  "Return a GMS file name from a the current LST file buffer."
  (let ((file-buffer-lst (buffer-file-name))
	(ext-up (concat "." (upcase gams-lst-gms-extention)))
	(ext-down (concat "." (downcase gams-lst-gms-extention)))
	dir-lst file-noext file-gms file-lst)
    ; Store LST file name.
    (setq dir-lst (file-name-directory file-buffer-lst))
    (setq file-lst (file-name-nondirectory file-buffer-lst))
    (setq file-noext (file-name-sans-extension file-lst))
    ; Search GMS file name.  GMS file name is stored in file-gms.
    (cond
     ((file-exists-p
       (concat dir-lst file-noext ext-down))
      (setq file-gms (concat dir-lst file-noext ext-down)))
     ((file-exists-p
       (concat dir-lst file-noext ext-up))
      (setq file-gms (concat dir-lst file-noext ext-up)))
     ((file-exists-p
       (concat dir-lst (upcase file-noext) ext-down))
      (setq file-gms (concat dir-lst (upcase file-noext) ext-down)))
     ((file-exists-p
       (concat dir-lst (upcase file-noext) ext-up))
      (setq file-gms (concat dir-lst (upcase file-noext) ext-up)))
     ((file-exists-p
       (concat dir-lst (downcase file-noext) ext-down))
      (setq file-gms (concat dir-lst (downcase file-noext) ext-down)))
     ((file-exists-p
       (concat dir-lst (downcase file-noext) ext-up))
      (setq file-gms (concat dir-lst (downcase file-noext) ext-up)))
     (t
      (message "GMS file does not exist!")))
    file-gms))

(defun gams-lst-get-input-filename ()
  "Get the input file name associated to the current LST file.

The input file name is extract from FILE SUMMARY field."
  (let ((case-fold-search t)
	temp-file point-a)
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward "\\*\\*\\*\\* FILE SUMMARY" nil t)
	  ;; If FILE SUMMARY is found,
	  (progn
	    (setq point-a (match-beginning 0))
	    (when (re-search-forward "^input[ ]+\\(.*\\)" nil t)
	      (setq temp-file (gams*buffer-substring (match-beginning 1)
						  (match-end 1)))
	      (forward-line 1)
	      (while (looking-at "[ \t]+\\([^\n\f]+\\)")
		(setq temp-file
		      (concat temp-file
			      (gams*buffer-substring (match-beginning 1)
						     (match-end 1))))
		(forward-line 1))))
	;; If FILE SUMMARY is not found,
	(setq temp-file (gams-lst-get-gms))
	(message "FILE SUMMARY field does not exits!  The extension is assumed to be gms.")
	(sleep-for 0.5)))
    ;; Return the input file name.
    temp-file))

(defun gams-lst-save-error-string ()
  "Store programs arount the error place."
  (let ((times 4)
	(check 0)
	(regex-alist
	     '(("\\(\\\\\\)" . "[\\\\]")
	       ("[+]" . "[\+]")
	       ("[?]" . "[\?]")
	       ("[ ]+" . "[ \t]+")
	       ("[.]" . "[.]")
	       ("[$]" . "[$]")
	       ("[*]" . "[*]")
	       ("[\n]" . "[ \t]*[\n]")))
	regex-ele list-error list-error-new ele-error line end)
    ;; save string in list-error
    (while (and (> times 0) (< check 50))
      (forward-line -1)
      (setq end (line-end-position))
      (if (looking-at "^[ ]*[0-9]+  ")
	  (progn
	    (setq list-error
		  (cons
		   (if (equal
			(gams*buffer-substring (match-end 0) end) " ")
		       ;; if t, return "" not " ".
		       "^\n"
		     ;; if nil, return the matched.
		     (concat "^" (gams*buffer-substring (match-end 0) end)))
		   list-error))
	    (setq times (- times 1)))
	(setq check (+ check 1))))
    (while regex-alist
      (setq regex-ele (car regex-alist))
      (setq list-error-new nil)
      (while list-error
	(setq ele-error (car list-error))
	(setq list-error-new
	      (cons
	       (gams-replace-regexp-in-string
		(car regex-ele) (cdr regex-ele) ele-error)
	       list-error-new))
	(setq list-error (cdr list-error)))
      (setq list-error (reverse list-error-new))
      (setq regex-alist (cdr regex-alist)))
    list-error))

(defun gams-lst-save-error-string-skip-dollar ()
  "Skip dollar control option."
  (catch 'flag
    (while
	(cond
	 ((looking-at "^[$][ \t]*ontext")
	  (re-search-forward "^[$][ \t]*offtext" nil t)
	  (forward-line 1))
	 ((looking-at "^[$]")
	  (forward-line 1))
	 (t (throw 'flag t))))))

(defun gams-lst-search-error-place-in-gms (errlist)
  "ERRLIST is the list of error places."
  (let ((error-list errlist)
	(len (length errlist))
	found beg)
    (save-excursion
      (goto-char (point-min))
      (catch 'flag
	(while t
	  (if (not (re-search-forward (car error-list) nil t))
	      (throw 'flag t)
	    (when (string-match "\n" (car error-list))
	      (forward-char -1))
	    (when (equal len 1)
	      (setq found (point))
	      (throw 'flag t))
	    (setq beg (1+ (point)))
	    (forward-line 1)
	    (gams-lst-save-error-string-skip-dollar)
	    (if (not (looking-at (nth 1 error-list)))
		(goto-char beg)
	      (when (equal len 2)
		(setq found (point))
		(throw 'flag t))
	      (forward-line 1)
	      (gams-lst-save-error-string-skip-dollar)
	      (if (not (looking-at (nth 2 error-list)))
		  (goto-char beg)
		(when (equal len 3)
		  (setq found (point))
		  (throw 'flag t))
		(forward-line 1)
		(gams-lst-save-error-string-skip-dollar)
		(if (not (looking-at (nth 3 error-list)))
		    (goto-char beg)
		  (setq found (point))
		  (throw 'flag t))))))))
    found))

;;; New function.
(defun gams-lst-jump-to-error-file ()
  "Jump to the error place in GMS buffer."
  (interactive)
  (let (point-b line-num file-name error-column temp-col
		string col-num err-gms)
    (if	(gams-lst-jump-to-error)
	(progn
	  ;; Store column number.
	  (save-excursion
	    (if (re-search-forward "^\\([ ]*[0-9]+[ ][ ]\\)" nil t)
		(setq temp-col (current-column))
	      (setq temp-col 1)))
	  (setq error-column (- (current-column) temp-col))
	  (forward-line 1)
	  (save-excursion
	    (while (not (looking-at "^[ ]*[0-9]+[ ][ ]"))
	      (forward-line 1))
	    (setq point-b (point)))
	  ;; Search the file name line.
	  (if (re-search-forward
	       (concat "^\\*\\*\\*\\* LINE[ \t]+\\([0-9]+\\)[ ]+"
		       "\\(IN[ ]+FILE\\|BATINCLUDE\\|INCLUDE\\|INPUT\\)"
		       "\\([ ]+\\)\\([^\n]+\\)\n")
	       point-b t)
	      ;; If the file name line is found.
	      (progn
		(setq line-num (gams*buffer-substring
				(match-beginning 1)
				(match-end 1)))
		(setq file-name (gams*buffer-substring
				 (match-beginning 4)
				 (match-end 4)))
		(save-excursion (goto-char (match-end 3))
				(setq col-num (current-column)))
		(when (looking-at
		       (concat (make-string col-num (string-to-char " "))
			       "\\([^ %\t\n\f]+\\)"))
		  (setq file-name
			(concat file-name
				(gams*buffer-substring
				 (match-beginning 1)
				 (match-end 1)))))
		(if (file-exists-p file-name)
		    (progn
		      (if (find-buffer-visiting file-name)
			  (switch-to-buffer (find-buffer-visiting file-name))
			(find-file file-name))
		     
		      (goto-line (string-to-number line-num))
		      (move-to-column error-column)
		      (recenter))
		  (message "The file `%s' does not exist!" file-name)))
	    ;; If the file name line is not found
	    ;; Jump to the error place.
	    (gams-lst-jump-to-error)
	    (recenter)
	    ;; Save the string around error place.
	    (setq string (gams-lst-save-error-string))
	    (setq file-name (gams-lst-get-input-filename))
	    ;; open GMS file.
	    (if (file-exists-p file-name)
		(progn (if (find-buffer-visiting file-name)
			   (switch-to-buffer (find-buffer-visiting file-name))
			 (find-file file-name))
		       (when string
			 ;; Search the error place.
			 (if (setq err-gms (gams-lst-search-error-place-in-gms string))
			     (progn (goto-char err-gms)
				    (recenter)
				    (move-to-column error-column)
				    (message "Error place is found!")
				    )
			   (message "Error place is not found!")))
		       )
	      (message "The file `%s' does not exist!" file-name))))
      (message "No error is found!"))))

(defun gams-lst-jump-to-input-file ()
  "Switch to the GMS file buffer."
  (interactive)
  (let ((file-gms (gams-lst-get-input-filename)))
    (if (not (file-exists-p file-gms))
	;; If gms file does not exist.
	(message "The file `%s' does not exist!" file-gms)
      ;; If gms file exits.
      (if (find-buffer-visiting file-gms)
	  (switch-to-buffer (find-buffer-visiting file-gms))
	(find-file file-gms))
      (recenter))))

(defun gams-lst-jump-to-input-file-2 ()
  "Jump back to the error place in the input file."
  (interactive)
  (let ((file-gms (gams-lst-get-input-filename))
	string point-here err-gms)
    (forward-line 1)
    ;; Save the string around error place.
    (setq string (gams-lst-save-error-string))
    ;; open GMS file.
    (if (not (file-exists-p file-gms))
	;; If gms file does not exist.
	(message "The file `%s' does not exist!" file-gms)
      ;; If gms file does exists.
      (if (find-buffer-visiting file-gms)
	  (switch-to-buffer (find-buffer-visiting file-gms))
	(find-file file-gms))
      (setq point-here (point))
      (when string
	(goto-char (point-min))
	;; Search.
	(when (setq err-gms (gams-lst-search-error-place-in-gms string))
	  (setq point-here err-gms)))
      (goto-char point-here)
      (recenter)
      (beginning-of-line))))

(defun gams-lst-jump-item (item &optional flag)
  "Jump to the next (or previous) ITEM (VAR, EQU, SUMMARY etc.)

If FLAG is non-nil, jump to the previous item."
  (let ((item-name item)
	(regex-sum "S O L V E      S U M M A R Y")
	(regex-rep "\\*\\*\\*\\* REPORT SUMMARY")
	(regex-var "^---- ")
	(regex-par "[0-9]+ PARAMETER ")
	(regex-elt "^Equation Listing[ \t]+SOLVE")
	(regex-clt "^Column Listing[ \t]+SOLVE")
	)
    (if (not flag)
	;; Jump to the next.
	(progn
	  (end-of-line)
	  (if (re-search-forward
	       (cond
		((equal item "SUM") regex-sum)
		((equal item "REP") regex-rep)
		((equal item "PAR") regex-par)
		((equal item "ELT") regex-elt)
		((equal item "CLT") regex-clt)
		(t (concat "^---- " item)))
	       nil t)
	      (progn (beginning-of-line) (recenter))
	    (message (concat "No more " item " entry"))))
      ;; Jump to the previous.
      (beginning-of-line)
      (if (re-search-backward
	   (cond
	    ((equal item "SUM") regex-sum)
	    ((equal item "REP") regex-rep)
	    ((equal item "PAR") regex-par)
	    ((equal item "ELT") regex-elt)
	    ((equal item "CLT") regex-clt)
	    (t (concat "^---- " item)))
	   nil t)
	  (progn (beginning-of-line) (recenter))
	(message (concat "No more " item " entry"))))))

(defun gams-lst-solve-summary ()
  "Jump to the next SOLVE SUMMARY"
  (interactive)
  (gams-lst-jump-item "SUM"))

(defun gams-lst-solve-summary-back ()
  "Jump to the previous SOLVE SUMMARY"
  (interactive)
  (gams-lst-jump-item "SUM" t))

(defun gams-lst-report-summary ()
  "Jump to the next REPORT SUMMARY"  
  (interactive)
  (gams-lst-jump-item "REP"))

(defun gams-lst-report-summary-back ()
  "Jump to the previous REPORT SUMMARY"
  (interactive)
  (gams-lst-jump-item "REP" t))

(defun gams-lst-next-var ()
  "Jump to the next VAR entry"
  (interactive)
  (gams-lst-jump-item "VAR"))

(defun gams-lst-previous-var ()
  "Jump to the previous VAR entry"
  (interactive)
  (gams-lst-jump-item "VAR" t))

(defun gams-lst-next-equ ()
  "Jump to the next EQU entry"
  (interactive)
  (gams-lst-jump-item "EQU"))

(defun gams-lst-previous-equ ()
  "Jump to the previous EQU entry"
  (interactive)
  (gams-lst-jump-item "EQU" t))

(defun gams-lst-next-par ()
  "Jump to the next PARAMETER entry"  
  (interactive)
  (gams-lst-jump-item "PAR"))

(defun gams-lst-previous-par ()
  "Jump to the next PARAMETER entry"  
  (interactive)
  (gams-lst-jump-item "PAR" t))

(defun gams-lst-next-elt ()
  "Jump to the next Equation Listing"
  (interactive)
  (gams-lst-jump-item "ELT"))

(defun gams-lst-previous-elt ()
  "Jump to the previous Equation Listing"
  (interactive)
  (gams-lst-jump-item "ELT" t))

(defun gams-lst-next-clt ()
  "Jump to the next Column Listing"
  (interactive)
  (gams-lst-jump-item "CLT"))

(defun gams-lst-previous-clt ()
  "Jump to the previous Column Listing"
  (interactive)
  (gams-lst-jump-item "CLT" t))

(defun gams-lst-widen-window ()
  "Make the window fill its frame.  Same as `delete-other-window'."  
  (interactive)
  (delete-other-windows)
  (recenter)
  (message "Winden window."))

(defun gams-lst-split-window ()
  "Split current window into two windows.  Same as `split-window-vertically'."  
  (interactive)
  (split-window-vertically)
  (recenter)
  (message "Split window."))

(defun gams-lst-query-jump-to-line (line-num)
  "Jump to the line you specify."
  (interactive "sInput line number: ")
  (let (temp-num)
    (setq temp-num
	  (concat "^[ ]*" line-num))
    (goto-char (point-min))
    (re-search-forward temp-num nil t)
    (beginning-of-line)))

(defun gams-lst-jump-to-line ()
  "Jump to the line indicated by the number you are on.

If you execute this command on a line like

**** Exec Error 0 at line 32 .. Division by zero

you can jump to line 32."
  (interactive)
  (let ((cur-point (point))
	(end-point (line-end-position))
	line-num)
    ;;	Get the line number.
    (beginning-of-line)
    (if (re-search-forward "at line \\([0-9]+\\)" end-point t)
	(progn
	  (setq line-num
		(concat "^[ ]*"
			(gams*buffer-substring
			 (match-beginning 1)
			 (match-end 1))))
	  ;; Go to the beginning of the buffer
	  (goto-char (point-min))
	  ;; Search line.
	  (re-search-forward line-num nil t)
	  (beginning-of-line)
	  (message "If you want to jump to the GMS file, push `%s'."
		   gams-lk-4))
      (goto-char cur-point)
      (message (concat "This command is valid only "
		       "if the cursor is on a line with line number!"))
      )))

(defun gams-lst-move-cursor ()
  "Jump the cursor to the other window."
  (interactive) (other-window 1))

;; From the emasc lisp book written by Yuuji Hirose.
(defun gams-lst-resize-frame ()
  "Resize the frame by key.

n - Widen vertically
p - Narrow vertically
f - Widen horizontally
b - Narrow horizontally
Any other key - quit

To put Control key simultaneously makes movement faster."
  (interactive)
  (let (key
	(width (frame-width))
	(height (frame-height)))
    (catch 'quit
      (while t
	(message "Resize frame by [(C-)npfb] (%dx%d): " width height)
	(setq key (read-char))
	(cond
	 ((eq key ?n) (setq height (+ 1 height)))
	 ((eq key 14) (setq height (+ 5 height)))
	 ((eq key ?p) (setq height (- height 1)))
	 ((eq key 16) (setq height (- height 5)))
	 ((eq key ?f) (setq width (+ 1 width)))
	 ((eq key 6) (setq width (+ 5 width)))
	 ((eq key ?b) (setq width (- width 1)))
	 ((eq key 2) (setq width (- width 5)))
	 (t (throw 'quit t)))
	(modify-frame-parameters
	 nil (list (cons 'width width) (cons 'height height)))))
    (message "End...")))

;;; From the emacs lisp book written by Yuuji Hirose.
(defun gams-lst-move-frame ()
  "Move the frame by key.

n - Move upward
p - Move downward
f - Move rightward
b - Move leftward
Any other key - quit

To put Control key simultaneously makes movement faster."
  (interactive)
  (let (key
	(top (cdr (assoc 'top (frame-parameters nil))))
	(left (cdr (assoc 'left (frame-parameters nil)))))
    (when (listp top) (setq top (nth 1 top)))
    (when (listp left) (setq left (nth 1 left)))
    (catch 'quit
      (while t
	(message "Move frame by [(C-)npfb] (%dx%d): " top left)
	(setq key (read-char))
	(cond
	 ((eq key ?n) (setq top (+ 10 top)))
	 ((eq key ?p) (setq top (- top 10)))
	 ((eq key ?f) (setq left (+ 10 left)))
	 ((eq key ?b) (setq left (- left 10)))
	 ((eq key 14) (setq top (+ 20 top)))
	 ((eq key 16) (setq top (- top 20)))
	 ((eq key 6) (setq left (+ 20 left)))
	 ((eq key 2) (setq left (- left 20)))
	 (t (throw 'quit t)))
	(if (and (or (eq key ?p) (eq key 16)) (<= top 5))
	    (progn
	      (setq top 5)))
	(if (and (or (eq key ?b) (eq key 2)) (<= left 5))
	    (progn
	      (setq left 5)))
	(modify-frame-parameters
	 nil (list (cons 'top top) (cons 'left left )))))
    (message "End...")))

(defun gams-lst-scroll (&optional down num page)
  "Command for scrolling.

If DOWN is non-nil, scroll down.
NUM mean scroll type (nil, 2, or d).
If PAGE is non-nil, page scroll."
  (interactive)
  (let ((cur-win (selected-window))
	(win-num (gams-count-win))
	;; flag for lst or ov?
	(flag-lst
	 (if (or (equal "GAMS-LST" mode-name)
		 (equal "GAMS-LXI-VIEW" mode-name))
		 t nil))
	;; flag for page scroll or not.
	(fl-pa (if page nil 1)))
    (if flag-lst
	;; If LST buffer
	(cond
	 ;; scroll type 1.
	 ((not num)
	  (save-excursion
	    (if down (scroll-down fl-pa)
	      (scroll-up fl-pa))))
	 ;; scroll type 2.
	 ((equal num "2")
	  (cond
	   ((eq win-num 1)
	    (if down
		(scroll-down fl-pa)
	      (scroll-up fl-pa)))
	   ((> win-num 1)
	    (other-window 1)
	    (if down
		(scroll-down fl-pa)
	      (scroll-up fl-pa))
	    (select-window cur-win))
	   (t nil)))
	 ;; scroll type double.
	 ((equal num "d")
	  (cond
	   ((eq win-num 1)
	    (if down
		(scroll-down fl-pa)
	      (scroll-up fl-pa)))
	   ((> win-num 1)
	    (if down
		(scroll-down fl-pa)
	      (scroll-up fl-pa))
	    (other-window 1)
	    (if down
		(scroll-down fl-pa)
	      (scroll-up fl-pa))
	    (select-window cur-win))
	   (t nil))))
      ;; If OL buffer.
      (cond
       ;; scroll type 1.
       ((not num)
	(cond
	 ((eq win-num 1)
	  nil)
	 ((> win-num 1)
	  (save-excursion
	    (other-window 1)
	    (if down
		(scroll-down fl-pa)
	      (scroll-up fl-pa))
	    (select-window cur-win)))))
       ;; scroll type 2.
       ((equal num "2")
	(cond
	 ((eq win-num 1)
	  nil)
	 ((eq win-num 2)
	  (other-window 1)
	  (if down
	      (scroll-down fl-pa)
	    (scroll-up fl-pa))
	  (select-window cur-win))
	 ((eq win-num 3)
	  (other-window 2)
	  (if down
	      (scroll-down fl-pa)
	    (scroll-up fl-pa))
	  (select-window cur-win))
	 (t nil)))
       ;; scroll type double.
       ((equal num "d")
	(cond
	 ((eq win-num 1)
	  nil)
	 ((eq win-num 2)
	  (other-window 1)
	  (if down
	      (scroll-down fl-pa)
	    (scroll-up fl-pa))
	  (select-window cur-win))
	 ((eq win-num 3)
	  (other-window 1)
	  (if down
	      (scroll-down fl-pa)
	    (scroll-up fl-pa))
	  (other-window 1)
	  (if down
	      (scroll-down fl-pa)
	    (scroll-up fl-pa))
	  (select-window cur-win))
	 (t nil))))
      (if (equal "GAMS-LXI-VIEW" mode-name)
	  (gams-lxi-show-key)
	(gams-ol-show-key))
      )))

;;; line scroll.
(defun gams-lst-scroll-1 ()
  (interactive)
  (gams-lst-scroll))

(defun gams-lst-scroll-down-1 ()
  (interactive)
  (gams-lst-scroll t))

(defun gams-lst-scroll-2 ()
  (interactive)
  (gams-lst-scroll nil "2"))

(defun gams-lst-scroll-down-2 ()
  (interactive)
  (gams-lst-scroll t "2"))

(defun gams-lst-scroll-double ()
  (interactive)
  (gams-lst-scroll nil "d"))

(defun gams-lst-scroll-down-double ()
  (interactive)
  (gams-lst-scroll t "d"))

;;; Page scroll
(defun gams-lst-scroll-page-1 ()
  (interactive)
  (gams-lst-scroll nil nil t))

(defun gams-lst-scroll-page-down-1 ()
  (interactive)
  (gams-lst-scroll t nil t))

(defun gams-lst-scroll-page-2 ()
  (interactive)
  (gams-lst-scroll nil "2" t))

(defun gams-lst-scroll-page-down-2 ()
  (interactive)
  (gams-lst-scroll t "2" t))

(defun gams-lst-scroll-page-double ()
  (interactive)
  (gams-lst-scroll nil "d" t))

(defun gams-lst-scroll-page-down-double ()
  (interactive)
  (gams-lst-scroll t "d" t))

;; Added `gams-lst-file-summary' command to GAMS-LST mode. This command shows
;; the include file summary.

(defun gams-lst-file-summary-display-list (buf)
  (setq buffer-read-only nil)
  (erase-buffer)
  (goto-char (point-min))
  (insert (format "Include File Summary of %s\n" buf))
  (insert "Key: [RET]=open, [q]=quit, [b]=return to LST buffer\n")
  (insert "---------------------------------------------------\n")
  (insert "   SEQ   GLOBAL TYPE      PARENT   LOCAL  FILENAME\n")
  (insert "---------------------------------------------------\n")
  (let (v-seq v-gol v-type v-pare v-loc v-fname)
    (while f-alist
      (setq f-list (car f-alist))
      (setq v-seq (nth 0 f-list))
      (setq v-gol (nth 1 f-list))
      (setq v-type (nth 2 f-list))
      (setq v-pare (nth 3 f-list))
      (setq v-loc (nth 4 f-list))
      (setq v-fname (nth 5 f-list))
      (move-to-column (- 6 (length v-seq)) t)
      (insert v-seq)
      (move-to-column (- 15 (length v-gol)) t)
      (insert v-gol)
      (insert " ")
      (insert v-type)
      (move-to-column (- 32 (length v-pare)) t)
      (insert v-pare)
      (move-to-column (- 40 (length v-loc)) t)
      (insert v-loc)
      (insert (concat "  " v-fname "\n"))
      (backward-char 1)
      ;;	(gams-sil-text-color-2 (nth 0 ele))
      (put-text-property
       (line-beginning-position) (+ 1 (line-end-position)) :data f-list)
      (goto-char (point-max))
      (setq f-alist (cdr f-alist))))
  (setq buffer-read-only t)
  (goto-char (point-min))
  (forward-line 2)
  (gams-ifs-mode)
  (setq gams-ifs-lst-buffer buf)
  )

(defun gams-ifs-quit ()
  "Quit the Include File Summary mode."
  (interactive)
  (let ((ifs-buf (current-buffer))
	(lst-buf gams-ifs-lst-buffer))
    (switch-to-buffer lst-buf)
    (kill-buffer ifs-buf)
    (delete-other-windows)))

(defun gams-ifs-return-to-lst ()
  "Back to the gms file from the Include File Summary mode."
  (interactive)
  (let ((lst-buf gams-ifs-lst-buffer))
    (switch-to-buffer lst-buf)))

(defun gams-lst-file-summary ()
  "Display the Include File Summary."
  (interactive)
  (let* ((cur-buf (buffer-name))
	 (buf-name (concat "*Include File Summary of " cur-buf "*"))
	f-alist f-list)
    (delete-other-windows)
    (split-window-vertically)
    (other-window 1)
    (if (get-buffer buf-name)
	(switch-to-buffer buf-name)
      (setq f-alist (gams-lst-create-file-list))
      (get-buffer-create buf-name)
      (switch-to-buffer buf-name)
      (gams-lst-file-summary-display-list cur-buf))
    ))

(defun gams-ifs-open-file ()
  "Open the file under the cursor."
  (interactive)
  (let (data fname)
    (setq data (get-text-property (point) :data))
    (when data
      (setq fname (nth 5 data))
      (setq fname (gams-replace-regexp-in-string "^[.]+" "" fname))
      (if (file-exists-p fname)
	  (find-file fname)
	(message (format "%s does not exist!" fname))))))

(defvar gams-ifs-mode-map (make-keymap) "keymap.")
(let ((map gams-ifs-mode-map))
  (define-key map "\r" 'gams-ifs-open-file)
  (define-key map "q" 'gams-ifs-quit)
  (define-key map "b" 'gams-ifs-return-to-lst)
  (define-key map "n" 'next-line)
  (define-key map "p" 'previous-line)
  )

(setq-default gams-ifs-lst-buffer nil)

(defun gams-ifs-mode ()
  "GAMS Include File Summary mode."
  (kill-all-local-variables)
  (setq major-mode 'gams-ifs-mode)
  (setq mode-name "GAMS-IFS")
  (use-local-map gams-ifs-mode-map)
  (make-local-variable 'gams-ifs-lst-buffer)
  (setq truncate-lines t)
  )

(defun gams-lst-create-file-list ()
  (let (f-alist
	po-ifs col-fn v-seq
	v-gol v-type v-pare
	v-loc v-fname v-fname f-info f-info-prev co-nest)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^Include File Summary" nil t)
	(setq po-ifs (point))
	(forward-line 1)
	(while (looking-at "[ \t]*\n")
	  (forward-line 1))
	(re-search-forward "FILENAME\n" nil t)
	(goto-char (match-beginning 0))
	(setq col-fn (current-column))
	(forward-line 2)
	(catch 'found
	  (while t
	    (when (looking-at "[ \t\]*[\n\f]+")
	      (setq f-info-prev (append f-info-prev (list v-fname)))
	      (when f-alist
		(setq f-alist (cons f-info-prev f-alist)))
	      (setq v-fname nil)
	      (throw 'found t))
	    (if (re-search-forward
		 (concat "^[ \t]+\\([0-9]+\\)[ \t]+\\([0-9]+\\)[ \t]+"
			 "\\([^0-9]+\\)\\([0-9]+\\)[ \t]+\\([0-9]+\\)[ \t]+")
		 (line-end-position) t)
		(progn
		  (setq v-seq (gams*buffer-substring (match-beginning 1) (match-end 1))
			v-gol (gams*buffer-substring (match-beginning 2) (match-end 2))
			v-type (gams-replace-regexp-in-string
				"[ \t]+$" ""
				(gams*buffer-substring (match-beginning 3) (match-end 3)))
			v-pare (gams*buffer-substring (match-beginning 4) (match-end 4))
			v-loc (gams*buffer-substring (match-beginning 5) (match-end 5)))
		  (setq f-info (list v-seq v-gol v-type v-pare v-loc))
		  (setq f-info-prev (append f-info-prev (list v-fname)))
		  (when v-fname
		    (setq f-alist (cons f-info-prev f-alist)))
		  (setq f-info-prev f-info)
		  (setq co-nest 0)
		  (when (looking-at "[.]+")
		    (setq co-nest (length (gams*buffer-substring (match-beginning 0)
								 (match-end 0)))))
		  (setq v-fname (gams*buffer-substring (point) (line-end-position)))
		  (forward-line 1))
	      (move-to-column (+ co-nest col-fn))
	      (setq v-fname
		    (concat v-fname (gams*buffer-substring (point) (line-end-position))))
	      (forward-line 1))
	    ))))
    (reverse f-alist)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Code for GAMS-TEMPLATE.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;(autoload 'gams-template "gams-temp" "Start GAMS-TEMPLATE" t)

;;;;; Codes

(defvar gams-template-file-already-loaded nil)

(defvar gams-user-template-alist nil)
(defvar gams-temp-buffer "*Template List*")
(defvar gams-temp-edit-buffer "*Template Edit*")
(defvar gams-temp-cont-buffer "*Template Content*")
(defvar gams-prog-file-buff nil)

(defvar gams-user-template-alist-init nil)
(defun gams-template ()
  "Start the GAMS-TEMPLATE mode."
  (interactive)
  (when (and (file-exists-p gams-template-file)
	     (not gams-template-file-already-loaded))
    (condition-case err
	(progn (load-file gams-template-file)
	       (setq gams-user-template-alist-init gams-user-template-alist)
	       (setq gams-template-file-already-loaded t))
      (error
       (message "Error(s) in %s!  Need to check; %s"
		gams-template-file (error-message-string err))
       (sleep-for 1))))
  (let* ((temp-buffer (get-buffer-create gams-temp-buffer))
	 (cur-buf (current-buffer)))
    ;; Store window configuration.
    (setq gams-temp-window (current-window-configuration))
    (pop-to-buffer temp-buffer)
    (gams-template-mode cur-buf)))

;; Key assignment of GAMS-TEMPLATE mode.
(defvar gams-template-mode-map (make-keymap) "Keymap for GAMS-TEMPLATE mode.")

(let ((map gams-template-mode-map))
  (define-key map " "     'gams-temp-show-cont)
  (define-key map "\r"    'gams-temp-exit)
  (define-key map "q"     'gams-temp-quit)
  (define-key map "a"     'gams-temp-add)
  (define-key map "d"     'gams-temp-delete)
  (define-key map "e"     'gams-temp-reedit)
  (define-key map "r"     'gams-temp-rename)
  (define-key map "u"     'gams-temp-up)
  (define-key map "j"     'gams-temp-down)
  (define-key map "g"     'gams-temp-gms)
  (define-key map "s"     'gams-temp-scroll)
  (define-key map "S"     'gams-temp-scdown)
  (define-key map "h"     'gams-temp-help)
  (define-key map "o"     'gams-temp-write-alist-to-file)
  (define-key map "p"     'gams-temp-prev)
  (define-key map "n"     'gams-temp-next)
  (define-key map [up]     'gams-temp-prev)
  (define-key map [down]     'gams-temp-next))

;;; Menu for GAMS-TEMPLATE mode.
(easy-menu-define 
  gams-template-mode-menu gams-template-mode-map "Menu keymap for GAMS-TEMPLATE mode."
  '("GAMS-TEMPLATE"
    ["Show a content of a template" gams-temp-show-cont t]
    ["Insert a template" gams-temp-exit t]
    ["Quit TEMPLATE mode" gams-temp-quit t]
    ["Add a new template" gams-temp-add t]
    "--"    
    ["Delete a template" gams-temp-delete t]
    ["Re-edit a template" gams-temp-reedit t]
    ["Rename a template" gams-temp-rename t]
    ["Move a template up" gams-temp-up t]
    ["Move a template down" gams-temp-down t]
    ["Show gms file" gams-temp-gms t]
    "--"
    ["Scroll up Content buffer" gams-temp-scroll t]
    ["Scroll down Content buffer" gams-temp-scdown t]
    "--"
    ["Show help" gams-temp-help t]
    ["Save" gams-temp-write-alist-to-file t]
    "--"
    ["Show the previous template" gams-temp-prev t]
    ["Show the next template" gams-temp-next t]
    ))

;; GAMS-TEMPLATE mode.
(defun gams-template-mode (&optional buff-name)
  "The GAMS-TEMPLATE mode (a mode for template handling).

BUFF-NAME is the name of the current LST file buffer.

The following commands are available in this mode.

\\[gams-temp-show-cont]		Show a content of a template.
\\[gams-temp-exit]		Insert a template.
\\[gams-temp-quit]		Quit.
\\[gams-temp-add]		Add a new template.

\\[gams-temp-delete]		Delete a template.
\\[gams-temp-reedit]		Re-edit a template.
\\[gams-temp-rename]		Rename a template.
\\[gams-temp-up]		Move a template up.
\\[gams-temp-down]		Move a template down.

\\[gams-temp-gms]		Show the gms file.
\\[gams-temp-scroll](\\[gams-temp-scdown])		Scroll up (down) *Template Content* buffer.
\\[gams-temp-help]		Show this help.
\\[gams-temp-write-alist-to-file]		Save the content of gams-user-template-alist.

\\[gams-temp-prev]		Show the previous template.
\\[gams-temp-next]		Show the next template."
  (let ((temp-buff gams-prog-file-buff))
    (kill-all-local-variables)
    (setq mode-name "GAMS-TEMPLATE"
	  major-mode 'gams-template-mode)
    (use-local-map gams-template-mode-map)
    ;; Make a buffer local variable.
    (if (not temp-buff)
	(progn
	  ;; Set the gms file buffer to gams-prog-file-buff.  
	  (make-local-variable 'gams-prog-file-buff)
	  (setq gams-prog-file-buff buff-name))
      (make-local-variable 'gams-prog-file-buff)
      (setq gams-prog-file-buff temp-buff))
    (setq buffer-read-only nil)
    (gams-temp-show-list)
    (gams-temp-show-cont)
    (if gams-user-template-alist
	(gams-temp-select-key)
      (gams-temp-show-message))
    (setq buffer-read-only t)
    ;; menu.
    (easy-menu-add gams-template-mode-menu)
    ))

(defun gams-temp-select-key ()
  "Show key assignments in the GAMS-TEMPLATE mode."
  (message
   (format "[h]elp, [p]rev, [n]ext, SPACE = show, [g]ms, [q]uit, RET = insert, [a]dd. ")))

(defun gams-temp-show-list ()
  "Insert template list in the *Template List* buffer."
  (save-excursion
    (let ((temp-alist gams-user-template-alist)
	  (buffer-read-only nil))
      (erase-buffer)
      (goto-char (point-min))
      (if temp-alist
	  ;; If gams-user-template-alist is not empty.
	  (progn
	    ;; Insert elements of gams-user-template-alist.
;; 	    (while temp-alist
;; 	      (setq temp-ele (car temp-alist))
;; 	      (setq temp-ele-name (car temp-ele))
;; 	      (setq temp-ele-cont (cdr temp-ele))
;; 	      (beginning-of-line)
;; 	      (move-to-column 2 t) 
;; 	      (insert (concat "[" temp-ele-name "]\n"))
;; 	      (setq temp-alist (cdr temp-alist)))
	    (mapc '(lambda (x)
		       (beginning-of-line)
		       (move-to-column 2 t)
		       (insert (concat "[" (car x) "]\n")))
		       temp-alist)
	    ;; Narrow the region.
	    (narrow-to-region (point-min)
			      (- (point-max) 1))
	    (goto-char (point-min)))
	(gams-temp-show-message)))))

(defun gams-temp-show-message ()
  (message
   (concat "No template is registered!"
	   "  `a' = add, `q' = quit, `h' = help.")))

(defun gams-temp-show-cont ()
  "Show the content of a template in the *Template Content* buffer. "
  (interactive)
  (let ((curr-buf (current-buffer))
	(temp-buf (get-buffer-create gams-temp-cont-buffer))
	(temp-na (gams-temp-get-name)))
    (if gams-user-template-alist
	(if temp-na
	    (progn
	      (pop-to-buffer temp-buf)
	      (let ((buffer-read-only nil))
		(erase-buffer)
		(goto-char (point-min))
		(insert (cdr (assoc temp-na gams-user-template-alist)))
		;; Change the Mode.
		(gams-temp-cont-mode)
		(goto-char (point-min))
		(setq buffer-read-only t)
		(pop-to-buffer curr-buf)
		(gams-temp-select-key)
		)))
      (gams-temp-show-message)
      )))

(defun gams-temp-cont-mode ()
  "The mode for *Template Content* buffer."
  (kill-all-local-variables)
  (setq major-mode 'gams-temp-cont-mode)
  (setq mode-name "Content")
  (mapc
   'make-local-variable
   '(gams-comment-prefix
     gams-eolcom-symbol
     gams-inlinecom-symbol-start
     gams-inlinecom-symbol-end))
  ;; Make `gams-eolcom-symbol' a buffer-local variable.
  (let (temp)
    (if (setq temp (gams-search-dollar-com t))
	(setq gams-eolcom-symbol temp)
      (setq gams-eolcom-symbol gams-eolcom-symbol-default)))
  ;; Make `gams-inlinecom-symbol-start' and `gams-inlinecom-symbol-end'
  (let (temp)
    (if (setq temp (gams-search-dollar-com))
	(progn (setq gams-inlinecom-symbol-start (car temp))
	       (setq gams-inlinecom-symbol-end (cdr temp)))
      (setq gams-inlinecom-symbol-start gams-inlinecom-symbol-start-default)
      (setq gams-inlinecom-symbol-end gams-inlinecom-symbol-end-default)))
  ;; Font-lock
  (when gams-template-cont-color
    (make-local-variable 'font-lock-defaults)
    (make-local-variable 'font-lock-keywords)
    (gams-update-font-lock-keywords "g" gams-font-lock-level)
    (setq font-lock-keywords gams-font-lock-keywords)
    (setq font-lock-defaults '(font-lock-keywords t t))
    (setq font-lock-mark-block-function 'gams-font-lock-mark-block-function)
    ;; Turn on font-lock.
    (if (and (not (equal gams-font-lock-keywords nil))
	     font-lock-mode)
	(font-lock-fontify-buffer)
      (if (equal gams-font-lock-keywords nil)
	  (font-lock-mode -1))))
  (buffer-name)
  (setq buffer-read-only t)
  ) ;; 
  
(defun gams-temp-get-name ()
  "Get a name of a template on the current line."
  (interactive)
  (save-excursion
    (let ((point-a (line-end-position))
	  temp-na)
      (beginning-of-line)
      (when (re-search-forward "[   ]+[[]\\(.*\\)[]]" point-a t)
	(setq temp-na (gams*buffer-substring (match-beginning 1)
					     (match-end 1))))
      temp-na)))

(defun gams-temp-scroll ()
  "Scroll up *Template Content* buffer."
  (interactive)
  (scroll-other-window 1)
  (gams-temp-select-key))
  
(defun gams-temp-scdown ()
  "Scroll down *Template Content* buffer."
  (interactive)
  (scroll-other-window-down 1)
  (gams-temp-select-key))

(defun gams-temp-help ()
  "Display help for GAMS-TEMPLATE mode."
  (interactive)
  (describe-function 'gams-template-mode))

(defun gams-temp-quit ()
  "Quit the GAMS-TEMPLATE mode."
  (interactive)
  (if gams-save-template-change
      (gams-temp-write-alist-to-file))
  (pop-to-buffer gams-prog-file-buff)
  (when (get-buffer gams-temp-cont-buffer)
    (kill-buffer gams-temp-cont-buffer))
  (when (get-buffer gams-temp-buffer)
    (kill-buffer gams-temp-buffer))
  (delete-other-windows)
  ;; Restore window configurations.
  (set-window-configuration gams-temp-window))

(defun gams-temp-next ()
  "Display the next template."
  (interactive)
  (let ((sig-max-num (length gams-user-template-alist)))
    (if gams-user-template-alist
	(progn
	  (when (not (equal sig-max-num (count-lines (point-min) (+ 1 (point)))))
	    (next-line 1))
	  (gams-temp-show-cont)
	  (setq buffer-read-only t))
      (gams-temp-show-message))))

(defun gams-temp-prev ()
  "Display the previous template."
  (interactive)
  (if gams-user-template-alist
      (progn
	(if (not (equal 1 (count-lines (point-min) (+ (point) 1))))
	    (next-line -1))
	(gams-temp-show-cont)
	(setq buffer-read-only t))
    (gams-temp-show-message)))

(defun gams-temp-gms ()
  "Show the gms file."
  (interactive)
  (let ((temp-buf (current-buffer)))
    (pop-to-buffer gams-prog-file-buff)
    (pop-to-buffer temp-buf)
    (gams-temp-select-key)))

(defun gams-temp-internal (temp)
  (let (point-a point-b)
    (if temp
	(if (string= temp "")
	    nil
	  (save-restriction
	    (narrow-to-region (point-min)
			      (setq point-a (point)))
	    (insert temp)
	    (setq point-b (gams-temp-replace point-a (point-max))))
	  (set-buffer-modified-p (buffer-modified-p))
	  (or point-b point-a))
      nil)))

(defun gams-temp-exit ()
  "Insert a template into a buffer."
  (interactive)
  (let* ((temp-name (gams-temp-get-name))
	 (temp-cont (cdr (assoc temp-name gams-user-template-alist)))
	 po)
    ;; Back to the program file buffer.
    (switch-to-buffer gams-prog-file-buff)
    (delete-other-windows)
    ;; Insert a template.
    (setq po (gams-temp-internal temp-cont))
    (point)
    (kill-buffer gams-temp-cont-buffer)
    (kill-buffer gams-temp-buffer)
    ;; restore window configurations.
    (set-window-configuration gams-temp-window)
    (when po (goto-char po))
    ))

(defun gams-temp-add ()
  "Add a new template."
  (interactive)
  ;; kill template buffers.
  (kill-buffer gams-temp-cont-buffer)
  (gams-edit-template))

(defun gams-temp-reedit ()
  "Re-edit already registered templates."
  (interactive)
  (let ((temp-name (gams-temp-get-name))
	(temp-line (count-lines (point-min) (+ (point) 1)))
	key)
    (gams-temp-show-cont)
    ;; Go to "*Template Content*" buffer.
    (switch-to-buffer gams-prog-file-buff)
    (pop-to-buffer (get-buffer-create gams-temp-cont-buffer))
    (when (get-buffer gams-temp-edit-buffer)
      (kill-buffer gams-temp-edit-buffer))
    (rename-buffer gams-temp-edit-buffer)
    ;; Switch to gams-edit-template mode.
    (gams-edit-template temp-name)
    ))

(defun gams-temp-rename ()
  "Rename already registered templates."
  (interactive)
  (let* ((buffer-read-only nil)
	 (temp-alist gams-user-template-alist)
	 (old-name (gams-temp-get-name))
	 (new-name (read-string "Insert a new name: " old-name))
	 (line-num (count-lines (point-min) (+ 1 (point)))))
    (when temp-alist
      ;; Replace the old name with the new name.
      (setcar (assoc old-name temp-alist) new-name)
      ;; If gams-save-template-change is non-nil, save.
      (when gams-save-template-change
	(gams-temp-write-alist-to-file))
      (gams-temp-show-list)
      (goto-line line-num)
      (gams-temp-show-cont))))

(defun gams-temp-delete ()
  "Delete existing templates."
  (interactive)
  (when gams-user-template-alist
    (let ((temp-name (gams-temp-get-name))
	  (line-num (count-lines (point-min) (+ 1 (point))))
	  key)
      ;; Delete.
      (message (format "Do you really want to delete `%s'?  Type `y' if yes." temp-name))
      (setq key (read-char))
      (when (equal key ?y)
	(forward-line 1)
	(gams-template-processing "del" temp-name)
	(gams-temp-show-list)
	(goto-line (- line-num 1))
	(gams-temp-show-cont))
      )))

(defun gams-temp-up ()
  "Move up a template."
  (interactive)
  (when gams-user-template-alist
    (let ((temp-name (gams-temp-get-name))
	  (temp-alist gams-user-template-alist)
	  (line-num (count-lines (point-min)
				 (+ 1 (point)))))
      (if (equal 1 line-num)
	  nil
	(setq gams-user-template-alist
	      (gams-temp-alist-change temp-alist temp-name)))
      (gams-temp-show-list)
      (goto-line (- line-num 1))
      (gams-temp-show-cont)
      )))

(defun gams-temp-down ()
  "Move down a template."
  (interactive)
  (when gams-user-template-alist
    (let ((temp-name (gams-temp-get-name))
	  (temp-alist gams-user-template-alist)
	  (line-num (count-lines (point-min)
				 (+ 1 (point))))
	  (sig-max-num (length gams-user-template-alist)))
      (if (equal sig-max-num line-num)
	  nil
	(setq gams-user-template-alist
	      (gams-temp-alist-change temp-alist temp-name t)))
      (gams-temp-show-list)
      (goto-line (+ line-num 1))
      (gams-temp-show-cont)
      )))

;; Editing templates.
(defun gams-temp-add-key ()
  (message
   (format "Edit the template:  C-cC-s = save and exit, C-xC-s = save, C-xk = quit, C-xh = help")))

; key assignment.
(defvar gams-template-edit-map (make-keymap) "keymap for gams-template-edit")
(defun gams-temp-edit-key-update ()
  (let ((map gams-template-edit-map))
      (define-key map "(" 'gams-insert-parens)
      (define-key map "\"" 'gams-insert-double-quotation)
      (define-key map "'" 'gams-insert-single-quotation)
      (define-key map "\C-l" 'gams-recenter)
      
      (define-key map "\C-c\C-k" 'gams-insert-statement)
      (define-key map "\C-c\C-d" 'gams-insert-dollar-control)
      ;;(define-key map "\C-c\C-v" 'gams-view-lst)
      ;;(define-key map "\C-c\C-j" 'gams-jump-to-lst)    
      (define-key map "\C-c\C-t" 'gams-start-menu)
      (define-key map "\C-c\C-e" 'gams-template)
      (define-key map "\C-c\C-o" 'gams-insert-comment)
      (define-key map "\C-c\C-g" 'gams-jump-on-off-text)
      (define-key map "\C-c\M-g" 'gams-remove-on-off-text)
      (define-key map "\C-c\M-c" 'gams-comment-on-off-text)
      (define-key map "\C-c\C-c" 'gams-insert-on-off-text)
      (define-key map "\C-c\C-m" 'gams-view-docs)
      (define-key map "\C-c\C-z" 'gams-modlib)

      (substitute-all-key-definition
       'next-line 'gams-edit-temp-next map)
      (substitute-all-key-definition
       'previous-line 'gams-edit-temp-prev map)
      (substitute-all-key-definition
       'forward-char 'gams-edit-temp-forward map)
      (substitute-all-key-definition
       'backward-char 'gams-edit-temp-backward map)

      (define-key map gams-choose-font-lock-level-key
	'gams-choose-font-lock-level)

      (define-key map "\M-;" 'gams-comment-dwim)
      (define-key map [(control \;)] 'gams-comment-dwim-inline)
      
      (define-key map "\C-xh" 'gams-edit-template-help)
      (define-key map "\C-x\C-s" 'gams-save-template)
      (define-key map "\C-c\C-s" 'gams-save-and-exit-template)
      (define-key map "\C-xk" 'gams-quit-template)))

(gams-temp-edit-key-update)

(defun gams-edit-temp-prev (&optional n)
  "Move the the previous line.  Same as `previous-line'."
  (interactive "p")
  (next-line (* -1 n))
  (gams-temp-add-key))

(defun gams-edit-temp-next (&optional n)
  "Move the the next line.  Same as `next-line'."
  (interactive "p")
  (next-line n)
  (gams-temp-add-key))

(defun gams-edit-temp-forward (&optional n)
  "Move point right N characters (left if N is negative).
On reaching end of buffer, stop and signal error."
  (interactive "p")
  (forward-char n)
  (gams-temp-add-key))

(defun gams-edit-temp-backward (&optional n)
  "Move point left N characters (right if N is negative).
On attempt to pass beginning or end of buffer, stop and signal error."
  (interactive "p")
  (forward-char (* -1 n))
  (gams-temp-add-key))
      
;;; Menu for GAMS-TEMPLATE-EDIT mode. 
(easy-menu-define 
  gams-template-edit-menu gams-template-edit-map "Menu keymap for GAMS-TEMPLATE-EDIT mode."
  '("TEMPLATE-EDIT"
    ["Save the template" gams-save-template t]
    ["Save the template and exit" gams-save-and-exit-template t]
    ["Show help" gams-edit-template-help t]
    ["Quit TEMPLATE-EDIT mode" gams-quit-template t]
    "--"
    ["Insert GAMS statement" gams-insert-statement t]
    ["Insert GAMS dollar control" gams-insert-dollar-control t]
    ["Insert parenthesis" gams-insert-parens t]
    ["Insert double quotations" gams-insert-double-quotation t]
    ["Insert single quotations" gams-insert-single-quotation t]
    ["Insert a comment template" gams-insert-comment t]
    ))

(setq-default gams-add-template-file nil)

(defun gams-edit-template (&optional file)
  "Edit a template.

FILE is a file name.  It is used for gams-temp-reedit.

Key-bindings are almost the same as GAMS mode.

'\\[gams-save-template] - Save a template.
'\\[gams-save-and-exit-template] - Save a template and exit.
'\\[gams-quit-template] - Quit.
'\\[gams-edit-template-help] - Show this help.

'\\[gams-insert-statement] - Insert GAMS statement with completion.
'\\[gams-insert-dollar-control] - Insert GAMS statement (dollar control option).
'\\[gams-insert-parens] - Insert parenthesis.
'\\[gams-insert-double-quotation] - Insert double quotations.
'\\[gams-insert-single-quotation] - Insert single quotations.

'\\[gams-insert-comment] - Insert comment template."
  (interactive)
;;  (delete-other-windows)
  (pop-to-buffer gams-temp-edit-buffer)
  (kill-all-local-variables)
  (setq major-mode 'gams-template-edit)
  (setq mode-name "TEMPLATE-EDIT")
  (use-local-map gams-template-edit-map)
  (setq fill-prefix "\t\t")
  (mapc
   'make-local-variable
   '(fill-column
     fill-prefix
     indent-line-function
     comment-start
     comment-start-skip
     gams-comment-prefix
     gams-eolcom-symbol
     gams-inlinecom-symbol-start
     gams-inlinecom-symbol-end
     ))
  (setq fill-column gams-fill-column
	fill-prefix gams-fill-prefix
	comment-end "")
  ;; Various setting.
  (gams-init-setting)
  ;; Font-lock
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(gams-font-lock-keywords t t))
  ;; set file name used for 
  (make-local-variable 'gams-add-template-file)
  (setq gams-add-template-file file)
  (setq buffer-read-only nil)
  ;; TEST.
  (set-buffer-modified-p nil)
  (current-buffer)
  (gams-temp-add-key)
  (easy-menu-add gams-template-edit-menu)
  ) ;; gams-edit-template ends here.

(defun gams-edit-template-help ()
  "Show help."
  (interactive)
  (describe-function 'gams-edit-template))

(defun gams-save-and-exit-template ()
  ""
  (interactive)
  (if (gams-save-template)
      (progn (kill-buffer gams-temp-edit-buffer)
	     (switch-to-buffer gams-temp-buffer)
	     (gams-temp-show-list)
	     (gams-temp-show-cont))
    (message "Not saved.")))

(defun gams-save-template ()
  "Register a template."
  (interactive)
  (let* ((temp-name (read-string
		     "Enter a name of this template: "
		     gams-add-template-file))
	 (temp-alist gams-user-template-alist)
	 list-tmp flag)
    (save-excursion
      (if (string= temp-name "")
	  (error "Need to specify a name of this template!")
	(setq list-tmp
	      (list temp-name
		    (gams*buffer-substring (point-min) (point-max))))
	;; The same name is already used?
	(if (assoc temp-name temp-alist)
	    ;; Already used.
	    ;; Overwrite it?
	    (if (y-or-n-p
		 "This template name is already exists. Do you want to override it?: ")
		;; Yes
		(progn (gams-template-processing
			"red" (car list-tmp) (car (cdr list-tmp)))
		       (setq flag t))
	      ;; No. Do nothing.
	      nil)
	  ;; The same name is not registered. 
	  (gams-template-processing
	   "reg" (car list-tmp) (car (cdr list-tmp)))
	  (setq flag t)
	  )))
    flag))
  
;; (defun gams-quit-template ()
;;   ""
;;   (interactive)
;;   (exit-recursive-edit))

(defun gams-quit-template ()
  ""
  (interactive)
  (when (y-or-n-p (format "Kill this buffer? "))
    (kill-buffer gams-temp-edit-buffer)
    (switch-to-buffer gams-temp-buffer)
    (gams-temp-show-list)
    (gams-temp-show-cont)))

(defun gams-temp-write-alist ()
  "Update the value of `gams-user-template-alist'."
  (let ((temp-list gams-user-template-alist)
	(standard-output (current-buffer)))
    (erase-buffer)
    (insert (concat "(setq gams-user-template-alist '(\n"))
    (goto-char (point-max))
    (mapc
     (lambda (x)
       (print x))
     temp-list)
    (insert "))\n")
    (eval-buffer)))
   
(defun gams-template-processing (type name &optional cont)
  "Process a template in a temporary buffer.

TYPE is a sting.
reg = register a new template.
del = delete.
red = re-edit."
  (let ((cur-buff (current-buffer))
	(temp-buff " *gams-temporary*")
	(temp-file gams-template-file))
    ;; Cases:
    (cond
    ;; register
     ((equal type "reg")
      (setq gams-user-template-alist
	    (append (list (cons name cont))
		    gams-user-template-alist)))
    ;; delete
     ((equal type "del")
      (setq gams-user-template-alist
	    (delete
	     (assoc name gams-user-template-alist)
	     gams-user-template-alist)))
    ;; red
     ((equal type "red")
      (setcdr (assoc name gams-user-template-alist) cont)))
    ;; reedit. not yet.
    ;; Write the content of gams-user-template-alist in the temporary
    ;; buffer.
    ;; If gams-save-template-change is non-nil, save the temporary buffer
    ;; as gams-template-file.
    (when gams-save-template-change
	  ;; Move to the temporary buffer
	  (switch-to-buffer (get-buffer-create temp-buff))
	  (unwind-protect
	      (progn
		(gams-temp-write-alist)
		(write-file gams-template-file))
	    (kill-buffer (find-buffer-visiting gams-template-file))
	    (switch-to-buffer cur-buff)))))

(defun gams-temp-write-alist-to-file ()
  "Save the content of `gams-user-template-alist' into the file
`gams-user-template-alist'."
  (interactive)
  (save-excursion
    (when (and gams-user-template-alist
	       (not (equal gams-user-template-alist gams-user-template-alist-init)))
      (set-buffer (get-buffer-create " *gams-temporary*"))
      (unwind-protect
	  (progn
	    (gams-temp-write-alist)
	    (write-file gams-template-file))
	(kill-buffer (find-buffer-visiting gams-template-file))))))
  
(defun gams-temp-alist-change (alist ele &optional flag)
  "Reorder `gams-user-template-alist'.

ELE is car part.  If FLAG is t, move down."
  (interactive)
  (let ((temp-alist alist)
	(car-p ele)
	alist-a	alist-b	list-a list-b)
    ;; Judge whether alist include ele.
    (if (setq alist-b
	      (member (assoc car-p temp-alist)
		      temp-alist))
	;; Included.
	(progn
	  (cond
	  ;; If flag is nil
	   ((not flag)
	    ;; If ele is the first element, do nothing.
	    (if (not (equal temp-alist alist-b))
		;; If ele is the second or later element 
		(progn
		  (setq list-a (car alist-b))
		  (setq alist-b (cdr alist-b))
		  (setq temp-alist (reverse temp-alist))
		  (setq alist-a
			(member (assoc car-p temp-alist)
				temp-alist))
		  (setq alist-a	(cdr alist-a))
		  (setq list-b (car alist-a))
		  (setq alist-a (cdr alist-a))
		  (setq alist-a (append (list list-a) alist-a))
		  (setq alist-a (reverse alist-a))
		  (setq alist-b (append (list list-b) alist-b))
		  (setq temp-alist (append alist-a alist-b))
		  )))
	   ;; If flag is t
	   (flag
	    ;; If ele is the last element, do nothing.
	    (if	(not (equal alist-b (nth (- (length temp-alist) 1) temp-alist)))
		(progn
		  ;; alist-b
		  (setq list-a (car alist-b))
		  (setq list-b (car (cdr alist-b)))
		  (setq alist-b (cdr (cdr alist-b)))
		  (setq alist-b (append (list list-a) alist-b))
		  (setq alist-b	(append (list list-b) alist-b))
		  ;; alist-a
		  (setq temp-alist (reverse temp-alist))
		  (setq alist-a	(member (assoc car-p temp-alist) temp-alist))
		  (setq alist-a	(cdr alist-a))
		  (setq alist-a (reverse alist-a))
		  ;; New alist.
		  (setq temp-alist (append alist-a alist-b))
		  ))))))
    temp-alist))

(defun gams-temp-replace (begin end)
  "Replace a mark with cursor in the inserted template.

BEGIN and END are points."
  (interactive)
  (let ((mark gams-template-mark) po)
    (goto-char begin)
    (if (re-search-forward (format "\\(%s\\)" mark) end t)
	(progn
	  (goto-char (setq po (match-beginning 0)))
	  (replace-match ""))
      (goto-char end))
    po))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Code for the GAMS-OUTLINE mode.
;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;(autoload 'gams-outline "gams-ol" "Start GAMS-OUTLINE" t)

;;; Codes for outlineing LST files.  

(defun gams-ol-create-alist (alist)
  "Create a alist of car part from ALIST."
  (mapcar '(lambda (x) (list (car x))) alist))

(defun gams-ol-item-make-alist (alist)
  "Combine `gams:process-command-option' and `gams-user-option-alist'."
  (setq gams-outline-item-alist
	(append
	 (list (cons "default" (list (gams-ol-make-list-view-item alist))))
	 gams-user-outline-item-alist)))
 
(defvar gams-ol-create-alist-done nil)
(defvar gams-ol-item-alist nil)

(defun gams-ol-store-point (&optional flag)
  "Store points of re-search-forward results.

If FLAG is non-nil, it means the item is VARIABLE."
  (let (par-type2 par-name2 par-exp2)
    (if flag
	(setq par-type2 "VRI")
      (setq par-type2
	    (substring
	     (upcase (gams*buffer-substring
		      (match-beginning 1)
		      (match-end 1)))
	     0 3)))
    (setq par-name2 (gams*buffer-substring
		     (match-beginning 2)
		     (match-end 2)))
    (setq par-exp2 (gams*buffer-substring
		    (match-beginning 3)
		    (match-end 3)))
    (list par-type2 par-name2 par-exp2)))

(defun gams-outline (&optional external)
  "Start GAMS-OUTLINE mode.

In GAMS-OUTLINE mode, you can see the important elements in LST file.
Type ? in the OUTLINE buffer for the help.  See also the explanation of
`gams-outline-external' command."
  (interactive)
  (let ((buffname
	 (concat "*" (buffer-name) "-OL*"))
	(lst-file-buf (current-buffer))
	(ol-point gams-lst-ol-buffer-point)
	(buf-f-name (if external (buffer-file-name) nil))
	alist)
    ;; Judge whether OL buffer is already created or not.
    (if (or (not (get-buffer buffname))
	    (not gams-ol-flag))
	;; OL buffer is not created or out of date.
	(progn
	  (setq gams-ol-flag t)
	  (get-buffer-create buffname)
	  (gams-sil-regexp-update)
	  (setq alist
		(gams-ol-make-alist
		 (if external buf-f-name lst-file-buf) external))
	  (setq gams-ol-alist alist)
	  (setq alist (gams-ol-convert alist))
	  (setq gams-ol-alist-tempo alist)
	  (gams-ol-show buffname alist)
	  ;; Switch to the OL buffer.
	  (switch-to-buffer buffname)
	  (recenter)
	  ;; Start gams-ol-mode.
	  (gams-ol-mode lst-file-buf))
      ;; Switch to the OL buffer.
      (switch-to-buffer buffname)
      (recenter))))

(defun gams-outline-external ()
  "Start GAMS-OUTLINE mode with external program.

When a LST file is very large, it often takes much time to start
GAMS-OUTLINE mode.  In stead of the lisp code, this command uses the
external program to create GAMS-OUTLINE buffer.

When a LST file is large, this command _may_ take much less time than
`gams-outline'.  Generally, 

Small LST files => `gams-outline' is a little faster.
Large LST files => `gams-outline-external' is faster.

But it depends on the type of LST files.  `gams-outline' may be faster
than `gams-outline-external' even for large LST files.  If you are
satisfied with the speed of GAMS-OUTLINE mode, you need not use this
command.  Just use `gams-outline'.

As the external program, you can use the C program (gamsolc.exe) or the
Perl script (gamsolperl.pl).  The C program works faster than the Perl
script, but the C program is offered only for MS windows (I cannot compile
the program with gcc on Unix).  The Perl script gamsolperl.pl works both
on MS windows and Unix systems as long as Perl5 is installed in that
system.  If you are MS windows user, use gamsolc.exe.  If you are Unix
user, use gamsolperl.pl.

To use this command, you need to set the proper values to the variable
`gams-ol-external-program'.  If you use the Perl script,
`gams-perl-command' also must be assign the value (the default values of
two variables above are set to nil).  Moreover, gamsolc.exe or
gamsolperl.pl must be placed at the proper place."
  (interactive)
  (let ((ex-prog gams-ol-external-program))
    (if ex-prog
	(cond
	 ((string-match  "gamsolperl" gams-ol-external-program)
	  (if gams-perl-command
	      (gams-outline t)
	    (message
	     (concat "Set the proper value to "
		     "`gams-perl-command' if you use gamsolperl.pl"))))
	 (t
	  (gams-outline t))
	 (t (message
	     (concat "The value of `gams-ol-external-program' is inadequate.  "
		     "Check the value."))))
      (message (concat "This command is valid only if "
		       "`gams-ol-external-program' is assigned the proper value.")))))

(defun gams-ol-get-alist (&optional buffer view)
  "Return the value of `gams-ol-alist' or `gams-ol-alist-tempo'.
If BUFFER is non-nil, the current buffer is OL buffer, not LST buffer.
If VIEW is non-nil, return the value of `gams-ol-alist-tempo'.
"
  (let ((cur-buf (if buffer (current-buffer) nil))
	alist)
    ;; The current buffer is LST buffer or OL buffer?
    (if cur-buf
	;; If OL buffer, switch to LST buffer and return the value of
	;; `gams-ol-alist-tempo'.
	(progn
	  (set-buffer gams-ol-lstbuf)
	  (current-buffer)
	  (setq alist (if view gams-ol-alist-tempo gams-ol-alist))
	  (switch-to-buffer cur-buf))
	;; If LST buffer, return the value of `gams-ol-alist'.
      (setq alist (if view gams-ol-alist-tempo gams-ol-alist)))
    ;; Return the value of alist.
    alist))
    
; key assignment.
(defvar gams-ol-mode-map (make-keymap) "Keymap for GAMS-OUTLINE mode")

(let ((map gams-ol-mode-map))
  (define-key map gams-olk-5 'gams-ol-view-base)
  (define-key map gams-olk-4 'gams-ol-select-item)
  (define-key map gams-olk-8 'gams-ol-item)
  (define-key map "c" 'gams-ol-toggle-follow-mode)
  (define-key map "x" 'gams-ol-toggle-display-style)
  (define-key map "n" 'gams-ol-next)
  (define-key map "p" 'gams-ol-previous)

  (define-key map gams-olk-7 'gams-ol-mark)
  (define-key map "u" 'gams-ol-unmark)
  (define-key map "y" 'gams-ol-jump-mark)
  
  (define-key map "i" 'gams-ol-back-to-lst)
  (define-key map gams-olk-1 'gams-ol-help)
  (define-key map gams-olk-6 'gams-ol-view-quit)
  
  (define-key map "l" 'recenter)
  (define-key map [return] 'scroll-up)
  (define-key map [delete] 'scroll-down)
  (define-key map "a" 'delete-other-windows)

  (define-key map "d" 'gams-lst-scroll-1)
  (define-key map "f" 'gams-lst-scroll-down-1)
  (define-key map "g" 'gams-lst-scroll-2)
  (define-key map "h" 'gams-lst-scroll-down-2)
  (define-key map "j" 'gams-lst-scroll-double)
  (define-key map "k" 'gams-lst-scroll-down-double)

  (define-key map "D" 'gams-lst-scroll-page-1)
  (define-key map "F" 'gams-lst-scroll-page-down-1)
  (define-key map "G" 'gams-lst-scroll-page-2)
  (define-key map "H" 'gams-lst-scroll-page-down-2)
  (define-key map "J" 'gams-lst-scroll-page-double)
  (define-key map "K" 'gams-lst-scroll-page-down-double)

  (define-key map "o" 'gams-ol-narrow-one-line)
  (define-key map "l" 'gams-ol-widen-one-line)
  (define-key map "w" 'gams-lst-resize-frame)
  (define-key map "e" 'gams-lst-move-frame)

  (define-key map ";" 'gams-from-outline-to-gms)
  (define-key map "," 'beginning-of-buffer)
  (define-key map "." 'end-of-buffer)

  (define-key map "r" 'gams-ol-refresh)

  (define-key map [down-mouse-1] 'gams-ol-view-base-click)
  (define-key map [double-mouse-1] 'gams-ol-mark-click)
  
  (define-key map gams-choose-font-lock-level-key
    'gams-choose-font-lock-level)

  (define-key map gams-olk-8 'gams-ol-item)
  );; ends.

;;; Menu for GAMS-OUTLINE mode.
(easy-menu-define 
  gams-ol-mode-menu gams-ol-mode-map "Menu keymap for GAMS-OUTLINE mode."
  '("GAMS-OUTLINE"
    ["Show the current item" gams-ol-view-base t]
    ["Select viewable items" gams-ol-select-item t]
    ["Select registered viewable items pattern" gams-ol-item t]
    ["Next item" gams-ol-next t]
    ["Previous item" gams-ol-previous t]
    ["Toggle follow mode" gams-ol-toggle-follow-mode t]
    ["Toggle display style" gams-ol-toggle-display-style t]
    "--"
    ["Mark an item" gams-ol-mark t]
    ["Unmark an item" gams-ol-unmark t]
    ["Jump to the marked item" gams-ol-jump-mark t]
    "--"
    ["Switch back to the LST buffer" gams-ol-back-to-lst t]
    ["Switch back to the GMS buffer" gams-from-outline-to-gms t]
    ["Show help" gams-ol-help t]
    ["Quit OUTLINE mode" gams-ol-view-quit t]
    "--"
    ["Widen the window with one line" gams-ol-widen-one-line t]
    ["Narrow the window with one line" gams-ol-narrow-one-line t]
    ["Widen the window" delete-other-windows t]
    ["Recentering" recenter t]
    "--"
    ["Scroll up" scroll-up t]
    ["Scroll down" scroll-down t]
    ["Go to the beginning of the buffer" beginning-of-buffer t]
    ["Go to the end of the buffer" end-of-buffer t]
    "--"
    ["Resize frame" gams-lst-resize-frame t]
    ["Move frame" gams-lst-move-frame t]
    "--"
    ["Choose font-lock level." gams-choose-font-lock-level t]
    ["Fontify block." font-lock-fontify-block t]
    ))

(defvar gams-ol-view-item-default nil)

(defun gams-ol-mode (lst-file-buf)
"The GAMS-OUTLINE mode.

\\[gams-ol-view-base]		Show the content of the item on the current line.
\\[gams-ol-select-item]		Select viewable items.
\\[gams-ol-item]		Select registered viewable item combination.
\\[gams-ol-next]		Next line.
\\[gams-ol-previous]		Previous line.
\\[gams-ol-toggle-follow-mode]		Toggle follow mode.
\\[gams-ol-toggle-display-style]		Toggle display style.

\\[gams-ol-mark]		Mark an item.
\\[gams-ol-unmark]		Unmark an item.
\\[gams-ol-jump-mark]		Jump to the marked line.

\\[gams-ol-back-to-lst]		Switch back to the LST buffer.
\\[gams-from-outline-to-gms]		Switch back to the GMS buffer.
\\[gams-ol-help]		Show this help.
\\[gams-ol-view-quit]		Quit.

\\[gams-ol-widen-one-line]		Widen the window with one line.
\\[gams-ol-narrow-one-line]		Narrow the window with one line.
\\[delete-other-windows]		Widen the window.
\\[recenter]		Recenter.

\\[scroll-up] or RET	Scroll up the OUTLINE buffer.
\\[scroll-down] or DEL	Scroll down the OUTLINE buffer.
\\[beginning-of-buffer]		Go to the beginning of the buffer
\\[end-of-buffer]		Go to the end of the buffer

\\[gams-lst-resize-frame]		Resize frame.
\\[gams-lst-move-frame]		Move frame.

\\[gams-choose-font-lock-level]		Choose font-lock level.

Commands for Scrolling

Commands for scrolling are almost the same as the ones in the GAMS-LST mode.

Suppose that there are three windows displayed like

    __________________	  
   |   	      	      |  
   |  OUTLINE buffer  |  ==>  OL-1
   |  CURSOR  here    |  
   |   	      	      |  
   |------------------|
   |   	      	      |  
   |  LST buffer 1    |  ==>  LST-1.
   |   	      	      |  
   |------------------|  
   |		      | 
   |  LST buffer 2    |  ==>  LST-2.
   |   	      	      |  
    ------------------

\\[gams-lst-scroll-1](\\[gams-lst-scroll-down-1])		Scroll the next buffer (LST-1) up (down) one line.
\\[gams-lst-scroll-2](\\[gams-lst-scroll-down-2])		Scroll the other next buffer (LST-2) up (down) one line.
\\[gams-lst-scroll-double](\\[gams-lst-scroll-down-double])		Scroll two LST buffers (LST-1 and LST-2) up (down) one line.

Keyboard.

  _____________________________________________________________
  |         |         |         |         |         |         |
  |    d    |    f    |    g    |    h    |    j    |    k    |
  |         |         |         |         |         |         |
  -------------------------------------------------------------

       |         |         |         |         |         |

      UP        DOWN      UP        DOWN      UP        DOWN
         LST-1               LST-2             LST-1 & 2


If only two window exists (e.g. OL-1 and LST-1),

\\[gams-lst-scroll-1] or '\\[gams-lst-scroll-2] or '\\[gams-lst-scroll-double]  ==> Scroll LST-1 up a line.
\\[gams-lst-scroll-down-1] or '\\[gams-lst-scroll-down-2] or '\\[gams-lst-scroll-down-double]  ==> Scroll LST-1 down a line.

The followings are page scroll commands.  Just changed to upper cases.

\\[gams-lst-scroll-page-1](\\[gams-lst-scroll-page-down-1])		Scroll the next buffer (LST-1) up (down) a page.
\\[gams-lst-scroll-page-2](\\[gams-lst-scroll-page-down-2])		Scroll the other next buffer (LST-2) up (down) a page.
\\[gams-lst-scroll-page-double](\\[gams-lst-scroll-page-down-double])		Scroll two buffers (LST-1 and LST-2) up (down) a page."
  (interactive)
  (setq major-mode 'gams-ol-mode)
  (setq mode-name "GAMS-OUTLINE")
  (use-local-map gams-ol-mode-map)
  (setq buffer-read-only t)
  (make-local-variable 'font-lock-defaults)
  (make-local-variable 'font-lock-keywords)
  (gams-update-font-lock-keywords "o" gams-ol-font-lock-level)
  (setq font-lock-keywords gams-ol-font-lock-keywords)
  (setq font-lock-defaults '(font-lock-keywords t t))
  ;; Store the LST buffer name in a local variable.
  (make-local-variable 'gams-ol-lstbuf)
  (setq gams-ol-lstbuf lst-file-buf)
  ;; Create the local variable gams-ol-mark-flag.  gams-ol-mark-flag is
  ;; assigned non-nil if an item is marked in the OUTLINE buffer.
  (make-local-variable 'gams-ol-mark-flag)
  (setq gams-ol-mark-flag nil)
  ;;
  (when (not gams-ol-create-alist-done)
    (setq gams-ol-item-alist
	  (gams-ol-create-alist gams-ol-view-item))
    (setq gams-ol-create-alist-done t)
    (gams-ol-item-make-alist gams-ol-view-item) 
    (setq gams-ol-view-item-default (gams-ol-make-list-view-item gams-ol-view-item)))
  ;; Menu
  (easy-menu-add gams-ol-mode-menu)
  ;;
  (if gams-emacs
      (when global-font-lock-mode
	(font-lock-mode t))
    (font-lock-mode t))
  ;; Run hook
  (run-hooks 'gams-ol-mode-hook)
  ;; Turn on font-lock.
  (if (and (not (equal gams-ol-font-lock-keywords nil))
	   font-lock-mode)
      (if gams-emacs
	  (font-lock-fontify-buffer))
    (if (equal gams-ol-font-lock-keywords nil)
	(font-lock-mode -1)))
) ;;; ends.

(defun gams-ol-count-line ()
  "Calculate the current line number in the OUTLINE buffer."
  (count-lines (point-min)
	       (min (point-max) (1+ (point)))))

(defun gams-ol-view-quit ()
  "Quit the GAMS-OUTLINE mode."
  (interactive)
  (let ((cur-buf (current-buffer))
	(po-ol (point)))
    ;; Unmark the marked item.
    (gams-ol-unmark)
    (if (buffer-live-p (get-buffer gams-ol-lstbuf))
	(switch-to-buffer gams-ol-lstbuf)
      (message "No correspoding LST buffer!")
      (sleep-for 0.5))
    (kill-buffer cur-buf)
    (delete-other-windows)
    (setq gams-lst-ol-buffer-point po-ol)))

(defun gams-ol-help ()
  (interactive)
  (let ((cur-buff (current-buffer))
	(cur-po (point))
	(temp-buf (get-buffer-create "*OL-HELP"))
	key)
    (pop-to-buffer temp-buf)
    (setq buffer-read-only nil)
    (erase-buffer)
    (insert "[keys for GAMS-OUTLINE mode]

SPACE	Show the content of the item on the current line.
n / p	next-line / previous-line.
T	Select viewable items.
t	Select registered viewable item combination.
c	Toggle follow-mode.
x	Toggle display style.

m	Mark an item.
u	Unmark an item.
y	Jump to the marked line.

i	Back to the LST buffer.
;	Back to the GMS buffer.
?	Show this help.
q	Quit.

l	Widen the window with one line.
o	Narrow the window with one line.
a	Widen the window.
v	Recenter.

RET	Scroll up the OUTLINE buffer.
DEL	Scroll down the OUTLINE buffer.
,	Go to the beginning of the buffer
.	Go to the end of the buffer

w	Resize frame.
e	Move frame.

C-c C-f	Choose font-lock level.

Commands for Scrolling

Commands for scrolling are almost the same as the ones in the GAMS-LST mode.

Suppose that there are three windows displayed like

    __________________	  
   |  OUTLINE buffer  |  ==>  OL-1
   |  CURSOR  here    |  
   |------------------|
   |  LST buffer 1    |  ==>  LST-1.
   |------------------|  
   |  LST buffer 2    |  ==>  LST-2.
    ------------------

d(f)		Scroll the next buffer (LST-1) up (down) one line.
g(h)		Scroll the other next buffer (LST-2) up (down) one line.
j(k)		Scroll two LST buffers (LST-1 and LST-2) up (down) one line.

Keyboard.

  _____________________________________________________________
  |         |         |         |         |         |         |
  |    d    |    f    |    g    |    h    |    j    |    k    |
  |         |         |         |         |         |         |
  -------------------------------------------------------------

       |         |         |         |         |         |

      UP        DOWN      UP        DOWN      UP        DOWN
         LST-1               LST-2             LST-1 & 2

If only two window exists (e.g. OL-1 and LST-1),

d or 'g or 'j  ==> Scroll LST-1 up a line.
f or 'h or 'k  ==> Scroll LST-1 down a line.

The followings are page scroll commands.  Just changed to upper cases.

D(F)		Scroll the next buffer (LST-1) up (down) a page.
G(H)		Scroll the other next buffer (LST-2) up (down) a page.
J(K)		Scroll two buffers (LST-1 and LST-2) up (down) a page.")
    (goto-char (point-min))
    (setq buffer-read-only t)
    (select-window (next-window nil 1))
    ))

(defun gams-ol-back-to-lst ()
  "Switch to the LST file buffer."
  (interactive)
  ;; Unmark.
  (gams-ol-unmark)
  (switch-to-buffer gams-ol-lstbuf)
  (recenter))

(defcustom gams-ol-display-style '(nil nil)
  "The default display style in the GAMS-OUTLINE mode.
nil means the vertical style and non-nil means the horizontal
style.

For details, see the help of `gams-ol-toggle-display-style'."
  :group 'gams)
  
(defcustom gams-ol-width 40
"*The default width of the GAMS-OUTLINE buffer.
You can change the width of the OUTLINE buffer with
`gams-ol-narrow-one-line' and `gams-ol-widen-one-line'."
  :type 'integer
  :group 'gams)

(defun gams-ol-toggle-display-style ()
  "Toggle the display style in the GAMS-OUTLINE mode.
You can select different display styles for
* the layout for OUTLINE and LST buffers
* the layout for different LST buffers.

There are four styles:
1: vertical-vertical
2: vertical-horizontal
3: horizontal-vertical
4: horizontal-horizontal

The former indicates how OUTLINE and LST buffers are arrayed.
'vertical' means two buffers are arrayed vertically and
'horizontal' means two buffers are arrayed horizontally.

The latter indicates how two LST buffers are arrayed.  'vertical'
means two buffers are arrayed vertically and 'horizontal' means
two buffers are arrayed horizontally.  This choice is valid only
if there are two LST windows exist (that is, there is the marked item).

If there is no marked item, one OUTLINE buffer and one LST buffer
are displayed.  In this case, there are two choices:

o vertical-vertical or vertical-horizontal style.
  __________________	  
 |  OUTLINE buffer  | 
 |------------------|
 |  LST buffer      |
 |------------------|  

o horizontal-vertical or horizontal-horizontal style.
  ________________________
 | OUTLINE   | LST        |
 | buffer    | buffer     |
 |-----------|------------|  

If there is marked item, one OUTLINE buffer and two LST buffers
are displayed.  In this case, there are four choices:x

o vertical-vertical.
  __________________	  
 |  OUTLINE buffer  | 
 |------------------|
 |  LST buffer No1  |
 |------------------|  
 |  LST buffer No2  |
 |------------------|  

o vertical-horizontal.
  __________________	  
 |  OUTLINE buffer  | 
 |--------|---------|
 | LST    | LST     |
 | buffer | buffer  |  
 | No1    | No2     |
 |--------|---------|  

o horizontal-vertical
  __________________________
 | OUTLINE   | LST          |
 | buffer    | buffer No1   |
 |           |--------------|  
 |           | LST          |
 |           | buffer No2   |
 |-----------|--------------|  

o horizontal-horizontal
  __________________________
 | OUTLINE   | LST  | LST   |
 | buffer    | No1  | No2   |
 |           |      |       |
 |-----------|------|-------|  "
  (interactive)
  (let ((main (car gams-ol-display-style))
	(sub (car (cdr gams-ol-display-style)))
	mess-main mess-sub)
    (cond
     ((and (not main) (not sub))
      (setq gams-ol-display-style '(nil t)))
     ((and (not main) sub)
      (setq gams-ol-display-style '(t nil)))
     ((and main (not sub))
      (setq gams-ol-display-style '(t t)))
     (t
      (setq gams-ol-display-style '(nil nil))))
    (setq main (car gams-ol-display-style)
	  sub (car (cdr gams-ol-display-style)))
    (setq mess-main
	  (if main "Horizontal" "Vertical"))
    (setq mess-sub
	  (if sub "Horizontal" "Vertical"))
    (message
     (format "Switched to %s-%s display style." mess-main mess-sub))))

(defun gams-ol-view-base ()
  "Show the content of the item on the current line in the another window."
  (interactive)
  (let* ((line-num (gams-ol-count-line))
	 (list-par (assoc line-num (gams-ol-get-alist t t)))
	 (point-par (car (cdr list-par)))
	 (marked gams-ol-mark-flag))
    (when list-par
      (gams-ol-view-base-internal point-par marked))
    (gams-ol-show-key)))

(defun gams-ol-view-base-internal (point &optional marked)
  (let 	((cur-buf (current-buffer))
	 (cur-win (selected-window))
	 (main (car gams-ol-display-style))
	 (sub (car (cdr gams-ol-display-style))))
    (if (one-window-p t)
	;; If only one window.
	(if (not marked)
	    ;; no marked item.
	    (progn
	      (split-window (selected-window)
			    (+ 1 (if main gams-ol-width gams-ol-height))
			    main)
	      (other-window 1)
	      (switch-to-buffer gams-ol-lstbuf)
	      (if gams-ol-use-external (goto-line point) (goto-char point))
	      (recenter 1)
	      (select-window cur-win))
	  ;; there is a marked item.
	  (split-window (selected-window)
			(+ 1 (if main gams-ol-width gams-ol-height-two))
			main)
	  (other-window 1)
	  (switch-to-buffer gams-ol-lstbuf)
	  (split-window (selected-window)
			(/ (if sub (window-width) (window-height)) 2)
			sub)
	  (if gams-ol-use-external
	      (goto-line (car (cdr (assoc marked (gams-ol-get-alist nil marked)))))
	    (goto-char (car (cdr (assoc marked (gams-ol-get-alist nil marked))))))
	  (recenter 1)
	  (other-window 1)
	  (if gams-ol-use-external (goto-line point) (goto-char point))
	  (recenter 1)
	  (pop-to-buffer cur-buf))
      ;; If two or more windows already exist.
      (delete-other-windows)
      (if (not marked)
	  ;; no marked item.
	  (progn
	    (split-window (selected-window)
			  (+ 1 (if main gams-ol-width gams-ol-height))
			  main)
	    (other-window 1)
	    (switch-to-buffer gams-ol-lstbuf)
	    (if gams-ol-use-external (goto-line point) (goto-char point))
	    (recenter 1)
	    (select-window cur-win))
	;; there in an marked item.
	(split-window (selected-window)
		      (+ 1 (if main gams-ol-width gams-ol-height-two))
		      main)
	(other-window 1)
	(switch-to-buffer gams-ol-lstbuf)
	(split-window (selected-window)
		      (/ (if sub (window-width) (window-height)) 2)
		      sub)
	(if gams-ol-use-external
	    (goto-line (car (cdr (assoc marked (gams-ol-get-alist nil marked)))))
	  (goto-char (car (cdr (assoc marked (gams-ol-get-alist nil marked))))))
	(recenter 1)
	(other-window 1)
	(if gams-ol-use-external (goto-line point) (goto-char point))
	(recenter 1)
	(pop-to-buffer cur-buf))
      )))

(defun gams-ol-view-base-click (click)
  "Show the content of an item on the current line."
  (interactive "e")
  (mouse-set-point click)
  (gams-ol-view-base))

(defun gams-ol-mark-click (click)
  "Mark or unmark an item on the current line."
  (interactive "e")
  (mouse-set-point click)
  (let ((line-num (gams-ol-count-line))
	(flag gams-ol-mark-flag))
    (if (and flag (equal flag line-num))
	(gams-ol-unmark)
      (gams-ol-mark))))

(defun gams-ol-show-key ()
  "Show the basic keybindings in the GAMS-OUTLINE mode."
  (interactive)
  (message
   (format "[%s]=help, [%s]=show, [%s]toggle follow mode, [%s]toogle display style, [%s]ark, d,f,g,h,j,k=scroll, [%s]uit."
	   gams-olk-1 gams-olk-5 "c" "x" gams-olk-7 gams-olk-6)))

(setq gams-ol-follow-mode t)
(defun gams-ol-toggle-follow-mode ()
  "Toggle follow (other window follows with context)."
  (interactive)
  (setq gams-ol-follow-mode (not gams-ol-follow-mode))
  (message
   (format (concat "Follow-mode is "
		   (if gams-ol-follow-mode "on." "off.")))))

(defun gams-ol-next (&optional n)
  "Show the content of the item on the next line."
  (interactive "p")
  (next-line n)
  (sit-for 0)
  (when gams-ol-follow-mode
    (gams-ol-view-base)))

(defun gams-ol-previous (&optional n)
  "Show the content of the item on the previous line."
  (interactive "p")
  (next-line (* -1 n))
  (sit-for 0)
  (when gams-ol-follow-mode
    (gams-ol-view-base)))

(defun gams-ol-mark ()
  "Mark an item on the curent line.  If you mark an item and move to the
other line and type space, you can see the content of two items
simultaneously.  If you want to unmark the marked item or move to the
marked item, use `gams-ol-unmark' and `gams-ol-jump-mark'."
  (interactive)
  (let ((cur-buff (current-buffer))
	(cur-col (current-column))
	(buffer-read-only nil)
	(line-num (gams-ol-count-line))
	(flag gams-ol-mark-flag)
	(com (save-excursion
	       (beginning-of-line)
	       (if (looking-at "^[[]") t nil))))
    (when (not com)
      ;; Delete mark if flag is non-nil.
      (if flag
	  (progn
	    (save-excursion
	      (goto-line flag)
	      (beginning-of-line)
	      (delete-char 1)
	      (insert " ")
	      (move-to-column cur-col))))
      ;;
      (when (not com)
	(beginning-of-line)
	(delete-char 1)
	(insert "*")
	(move-to-column cur-col)
	(setq gams-ol-mark-flag line-num)))
    (gams-ol-show-key)))

(defun gams-count-win ()
  "Count the number of windows."
  (interactive)
  (let ((cur-win (selected-window))
	(num 1)
	flag)
    (save-excursion
      (if (one-window-p)
	  nil
	(catch 'quit
	  (while t
	    (other-window 1)
	    (setq flag (selected-window))
	    (cond
	     ((not (eq flag cur-win))
	      (setq num (+ num 1)))
	     ((eq flag cur-win)
	      (throw 'quit t)))))))
    num))
      
(defun gams-ol-unmark ()
  "Unmark the marked item.
Even if the marked item does not appear in the window, mark will disappear."
  (interactive)
  (let ((buffer-read-only nil)
	line-num flag)
    (if gams-ol-mark-flag
	(save-excursion
	  (goto-char (point-min))
	  (if (re-search-forward "^* " nil t)
	      (progn (beginning-of-line)
		     (delete-char 1)
		     (insert " ")
		     (setq gams-ol-mark-flag nil)))))
    (gams-ol-show-key)))

(defun gams-ol-jump-mark()
  "Jumpt to the marked item line."
  (interactive)
  (let ((line-num gams-ol-mark-flag))
    (if line-num
	(goto-line line-num))))

;;;;; New variables.  Experimental.
(defun gams-ol-make-alist (name file)
  "Make the alist of all items from the LST buffer or LST file.

If FILE is non-nil, NAME is the LST file name.  If FILE is nil, NAME is
the LST buffer."
  (if file
      (progn (setq gams-ol-use-external t)
	     (gams-ol-make-alist-external name))
    (setq gams-ol-use-external nil)
    (gams-ol-make-alist-lisp name)))

(defsubst gams-ol-solve-sum ()
;;(defun gams-ol-solve-sum ()
  "Extract SOLVER STATUS and MODEL STATUS."
  (let (po-end var-1 var-2 var-3)
    (save-excursion
      (setq po-end (+ (point) 600))	; 600 is sufficient?
      (re-search-forward "\\*\\*\\*\\* SOLVER STATUS[ ]+\\([0-9]*\\)\\(.*\\)[ ]*$" po-end t)
      (setq var-1 (gams*buffer-substring (match-beginning 1)
				    (match-end 1)))
      (when (equal var-1 "")
	  (setq var-1 (gams*buffer-substring (match-beginning 2)
					(match-end 2))))
      (re-search-forward "\\*\\*\\*\\* MODEL STATUS[ ]+\\([0-9]*\\)\\(.*\\)[ ]*$" po-end t)
      (setq var-2 (gams*buffer-substring (match-beginning 1)
				    (match-end 1)))
      (when (equal var-2 "")
	  (setq var-2 (gams*buffer-substring (match-beginning 2)
					(match-end 2))))
      ;; Remove the spaces in the line end.
      (setq var-1 (gams-replace-regexp-in-string "[ ]+$" "" var-1))
      (setq var-2 (gams-replace-regexp-in-string "[ ]+$" "" var-2))
      (setq var-3 (concat "SOLVER STATUS = " var-1 ", " "MODEL STATUS = " var-2)))
    var-3))

(defsubst gams-ol-report-sum ()
;;(defun gams-ol-report-sum ()
  "Extract the content of REPORT SUMMARY."
  (let ((cur-po (point))
	end cont var var-list)
    (setq end (gams-ol-report-summary-region))
    (save-excursion
      (while (< (point) end)
	(when (looking-at "[ \t]*\\([0-9]+\\)[ \t]+")
	  (setq var (gams*buffer-substring (match-beginning 1)
					   (match-end 1)))
	  (setq var-list (cons var var-list)))
	(forward-line 1)
	))
    (setq cont
	  (concat "["
		  (gams-remove-unnecessary-characters-from-string
		   (gams-ol-list-to-string var-list))
		   "]"))
    cont))

(defun gams-ol-list-to-string (list)
  "Create a string that consists of elements of a LIST."
  (let (str)
    (while (car list)
      (setq str (concat ", " (car list) str))
      (setq list (cdr list)))
    str))

(defun gams-ol-report-summary-region ()
  (let (p)
    (save-excursion
      (forward-line 1)
      (while (not (looking-at "\n\\|\f\\|\\r"))
	(forward-line 1))
      (setq p (point)))
    p))

(setq gams-ol-make-alist-regexp-full
      (gams-regexp-opt
       (list
	"----"
	"               S O L V E      S U M M A R Y"
	"               L O O P S"
	"**** REPORT SUMMARY :"
	"E x e c u t i o n"
	"Model Statistics"
	"Solution Report"
	"C o m p i l a t i o n"
	"Equation Listing"
	"Column Listing"
	"Include File Summary"
	) t))

(defun gams-ol-make-alist-lisp (buffer)
  "Create and return the alist of items from lst buffer using emacs lisp.
This is used if `gams-ol-external-program' is assigned nil.  Otherwise,
`gams-ol-make-alist-external' is used."
  (interactive)
  (let ((count 0) ; count
	(malist nil) ; alist
	(case-fold-search t)
	pobeg mpoint mlist matched lmatched)
    (save-excursion
      (set-buffer buffer)
      (goto-char (point-min))
      ;;
      (while
	  ;; Search items.
	  (re-search-forward (concat "^" gams-ol-make-alist-regexp-full) nil t)
 	(message "Starting GAMS-OUTLINE...%s"
 		 (make-string (min (/ count 100) (- fill-column 20)) ?.))
	;; Store the match.
	(setq matched
	      (gams*buffer-substring (match-beginning 1) (match-end 1)))
	;; If an item is found.
	(cond
	 ;; The case for VAR, EQU, SET, PAR, COM.
	 ((equal matched "----")
	  (setq pobeg (1+ (line-end-position)))
	  (cond
	   ;; set.
	   ((looking-at "[ ]+[0-9]*[ ]*\\(set\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n]*\\)")
	    (setq mpoint (line-beginning-position))
	    (setq count (1+ count))
	    (setq mlist (gams-ol-store-point))
	    (setq malist
		  (cons (append (list count mpoint) mlist) malist))
	    (end-of-line))
	   ;; parameter.
	   ((looking-at
	     "[ ]+[0-9]*[ ]*\\(parameter\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n\f]*\\)")
	    (setq mpoint (line-beginning-position))
	    (setq count (1+ count))
	    (setq mlist (gams-ol-store-point))
	    ;; Make alist.
	    (setq malist
		  (cons
		   (append (list count mpoint) mlist) malist))
	    (end-of-line)
	    ;; Subprocess
	    (let (po-sub)
	      (save-excursion
		(re-search-forward "\\(\n\n\\|\f\\)" nil t)
;; 		(re-search-forward "\\(\n\n\n\\|\f\\)" nil t)
		(setq po-sub (point)))
	      (while
		  (re-search-forward
		   "^[ ]+\\(parameter\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n\f]*\\)"
		   po-sub t)
		(setq mpoint (line-beginning-position))
		(setq count (1+ count))
		(setq mlist (gams-ol-store-point))
		(setq malist
		      (cons (append (list count mpoint) mlist) malist))
		(end-of-line))))
	   ;; VARIABLE.
	   ((looking-at
	     "[ ]+[0-9]*[ ]*\\(variable\\|equation\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n\f]*\\)")
	    (setq mpoint (line-beginning-position))
	    (setq count (1+ count))
	    (setq mlist (gams-ol-store-point t))
	    (setq malist
		  (cons (append (list count mpoint) mlist) malist))
	    (end-of-line)
	    ;; subprocess
	    (let (po-sub)
	      (save-excursion
		(re-search-forward "\\(\n\n\\|\f\\)" nil t)
		(setq po-sub (point)))
	      (while
		  (progn
		    (re-search-forward "^[ ]+\\(variable\\|equation\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n\f]*\\)" po-sub t))
		(setq mpoint (line-beginning-position))
		(setq count (1+ count))
		(setq mlist (gams-ol-store-point t))
		(setq malist
		      (cons (append (list count mpoint) mlist) malist))
		(end-of-line))))
	   ;; VAR.
	   ((looking-at "[ ]+\\(VAR\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n]*\\)")
	    (setq mpoint (line-beginning-position))
	    (setq count (1+ count))
	    (setq mlist (gams-ol-store-point))
	    (setq malist
		  (cons (append (list count mpoint) mlist) malist))
	    (end-of-line))
	   ;; EQU.
	   ((looking-at "[ ]+\\(EQU\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n]*\\)")
	    (setq mpoint (line-beginning-position))
	    (setq count (1+ count))
	    (setq mlist (gams-ol-store-point))
	    (setq malist
		  (cons (append (list count mpoint) mlist) malist))
	    (end-of-line))
	   ;; COM.
	   ((looking-at
	     (concat "[ ]+[0-9]+[ ]"
		     (regexp-quote gams-special-comment-symbol)
		     "[ \t]*\\([^\n]*\\)"))
	    (let (ma-com)
	      (setq ma-com
		    (gams*buffer-substring (match-beginning 1) (match-end 1)))
	      (setq mpoint (line-beginning-position))
	      (setq count (1+ count))
	      (setq malist
		    (cons (list count mpoint "COM" ma-com nil) malist)))
	    (end-of-line))
	   ;; OTHER.
	   ((looking-at "[ ]+[0-9]+[ ]+\\([^\n]*\\)")
	    (let (ma-oth)
	      (setq ma-oth (gams*buffer-substring (match-beginning 1)
						   (match-end 1)))
	      (setq mpoint (line-beginning-position))
	      (setq count (1+ count))
	      (setq malist
		    (cons (list count mpoint "OTH" "" ma-oth) malist))
	      (end-of-line)
	    ))))
	 ;; REPORT SUMMARY
	 ((equal matched "**** REPORT SUMMARY :")
	  (let (rep-co)
	    (setq mpoint (line-beginning-position))
	    (setq rep-co (gams-ol-report-sum))
	    (setq count (1+ count))
	    (setq malist
		  (cons (list count mpoint "SUM" "REPORT SUMMARY" rep-co) malist)))
	  (end-of-line))
	 ;; E x e c u t i o n, ...
	 ((string-match gams-copied-program-regexp matched)
	  (when (not (equal matched lmatched))
	    (setq lmatched matched)
	    (let (name cont po-end)
	      (setq mpoint (line-beginning-position))
	      (setq po-end (+ mpoint (length matched)))
	      (setq name (gams*buffer-substring mpoint po-end))
	      (goto-char po-end)
	      (skip-chars-forward " \t")
	      (setq cont (gams*buffer-substring (point) (line-end-position)))
	      (when (not (equal "MODEL STATISTICS" name))
		(setq count (1+ count))
		(setq malist
		      (cons (list count mpoint "INF" name cont) malist)))))
	  (end-of-line))
	 ;; LOOP
	 ((equal matched "               L O O P S")
	  (let ((par-type "LOO")
		poend par-name par-exp)
	    (setq poend (line-end-position))
	    (while
		(re-search-forward "[ ]+\\([^ \n]+\\)[ ]+\\([^ ]+\\)" poend t)
	      (setq  par-name (gams*buffer-substring
			       (match-beginning 1)
			       (match-end 1)))
	      (setq  par-exp (gams*buffer-substring
			      (match-beginning 2)
			      (match-end 2)))
	      (setq pobeg (line-beginning-position))
	      (setq count (1+ count))
	      (setq malist
		    (cons (list count pobeg par-type par-name par-exp) malist))
	      (forward-line 1)
	      (setq poend (line-end-position))
	      )))
	 ;; Others = SOLVE SUMMARY.
	 (t
	  (let (po-so)
	    (setq pobeg (line-beginning-position))
	    (setq count (1+ count))
	    (setq malist
		  (cons (list count pobeg "SUM" "SOLVE SUMMARY"
			      (gams-ol-solve-sum))
			malist))
	    (end-of-line))))))
    (reverse malist)))

(defun gams-ol-make-alist-lisp-sub ()
  (cond
   ((looking-at
     "[ ]+[0-9]*[ ]*\\(parameter\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n\f]*\\)")
    )
   ((looking-at
     "^[ ]+\\(parameter\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n\f]*\\)")
    )
   ((looking-at
     "[ ]+[0-9]*[ ]*\\(variable\\|equation\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n\f]*\\)")
    )
   ((looking-at "^[ ]+\\(variable\\|equation\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n\f]*\\)")
    )
   ((looking-at "[ ]+\\(VAR\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n]*\\)")
    )
   ((looking-at "[ ]+\\(EQU\\)[ ]+\\([^ \n]+\\)[ ]+\\([^\n]*\\)")
    )
   ;; OTHER.
   ((looking-at "[ ]+[0-9]+[ ]+\\([^\n]*\\)")
    )))


(defvar gams-ol-alist-temp-alist nil)

(defun gams-ol-make-alist-external (file)
  "Create the alist of items from lst buffer with the external program.

This command is used if `gams-ol-external-program' is assigned non-nil.
Otherwise, `gams-ol-make-alist-lisp' is used.  See also the explanation of
`gams-outline-external', too."
  (let* ((cur-buf (buffer-name))
	 ;; Make a temporary file.
 	 (out-file (concat
 		    (if gams-xemacs
 			(gams-replace-regexp-in-string
			 (file-name-directory file) "\\\\" "/")
 		      (file-name-directory file))
 		    "temp.temp"))
	 (out-buf (get-buffer-create " *temp*"))
	 (com (concat (if (string-match "gamsolperl" gams-ol-external-program)
			  gams-perl-command nil) " "
			  gams-ol-external-program " "
			  (if gams-xemacs
			      (gams-replace-regexp-in-string file "\\\\" "/") file)
			  " " out-file))
	 (p-name "test")
	 (temp-alist nil)
	 proc-name)
    (setq gams-ol-alist-temp-alist nil)
    ;; Call the external program.
    (call-process shell-file-name nil out-buf nil gams:shell-c com)
    (load out-file nil t t)
    (delete-file out-file)
    (switch-to-buffer cur-buf)
    (kill-buffer out-buf)
    gams-ol-alist-temp-alist
    ))

(defun gams-ol-convert (alist)
  "Convert `gams-ol-alist' to the alist with only viewable items."
  (interactive)
  (let ((list-count 1)
	(al alist)
	al-new
	type ele ele-sub)
    (if (rassoc nil gams-ol-view-item)
	(progn
	  (while al
	    (setq ele (car al))
	    (setq type (nth 2 ele))
	    (when (cdr (assoc type gams-ol-view-item))
	      (setq ele-sub (cdr ele))
	      (setq ele (cons list-count ele-sub))
	      (setq al-new (cons ele al-new))
	      (setq list-count (1+ list-count)))
	    (setq al (cdr al)))
	  (setq gams-ol-alist-tempo (reverse al-new)))
      (setq gams-ol-alist-tempo al))))
	    

(defun gams-from-outline-to-gms ()
  "Jump directly to the gms file buffer from the OUTLINE buffer."
  (interactive)
  (gams-ol-back-to-lst)
  (gams-lst-jump-to-input-file)
  (delete-other-windows))

(defun gams-from-gms-to-outline-external ()
  "Same as `gams-from-gms-to-outline' but this uses the external program.

See the explanation of `gams-from-gms-to-outline' and
`gams-outline-external'."
  (interactive)
  (when (gams-view-lst)
    (gams-outline-external)))

(defun gams-ol-show (buffname alist)
  "?.
BUFFNAME is the OL buffer name.
ALIST is the alist of all items."
  (interactive)
  (let ((temp-alist alist)
	(lst-buf (current-buffer))
	list-list fl-flag point-end)
    (switch-to-buffer buffname)
    (setq buffer-read-only nil)
    (setq fl-flag font-lock-mode)
    ;; Deactivate font-lock to make the process faster.
    (if fl-flag
	(font-lock-mode -1))
    (setq truncate-lines t)
    (erase-buffer)
    (goto-char (point-min))
    ;; Insert.
    (if (not temp-alist)
	(insert (concat "No viewable item in GAMS-LST-OUTLINE mode!  "
			"Type `q' to quit or type `t' to toggle!"))
      (mapc '(lambda (x)
		 (goto-char (point-max))
		 (gams-lst-insert-item x)
		 (insert "\n")
		 ) temp-alist)
      (goto-char (point-min))
      (if fl-flag
	  (font-lock-mode 1))
      )))

(defun gams-lst-insert-item (list-list)
  "Insert item into the OUTLINE buffer."
  (interactive)
  (let* ((list-type (nth 2 list-list))
	 (list-name (nth 3 list-list))
	 (list-cont (nth 4 list-list))
	 (list-width gams-ol-item-name-width)
	 (cont-pos (+ list-width 6)))
    (cond
      ;; COM.
     ((equal list-type "COM")
      (insert (concat "[ " list-name " ]")))
     ;;
     ((string-match gams-copied-program-regexp list-name)
      (move-to-column 2 t)
      (insert (concat list-type "  " list-name))
      (move-to-column cont-pos t)
      (when (looking-at "[^\n]")
	(delete-region (point) (line-end-position)))
      (insert " ")
      (insert list-cont)
      )
     (t
      ;; Not COM.
      (move-to-column 2 t)
      (insert list-type)
      (insert "  ")
      ;; column 7
      (insert list-name)
      (if list-cont
	  (progn
	    (move-to-column cont-pos t)
	    (delete-region (point) (line-end-position))
	    (insert " ")
	    (insert list-cont))))
     )))
  
(defvar gams-ol-item-buffer "*gams-select-item*")

(defun gams-ol-select-item ()
  "Evoke the select-item mode. 
In select-item mode, you can select the viewable items.  For example, if
you don't want to see VARIABLEs, then you can make them disappear from
OUTLINE buffer."
  (interactive)
  (let ((cur-buf (current-buffer))
	(temp-buf gams-ol-item-buffer)
	(item-alist gams-ol-item-alist)
	temp-item
	(temp-num 1)
	(flag nil))
    (pop-to-buffer (get-buffer-create temp-buf))
    (erase-buffer)
    (goto-char (point-min))
    (while item-alist
      (setq temp-item (car (car item-alist)))
      (if (gams-ol-check-included temp-item t)
	  (setq flag t)
	(setq flag nil))
      (goto-char (point-max))
      (insert
       (concat " " " ["
	       (if flag "+" "-")
	       "] " temp-item "\n"))
      (setq item-alist (cdr item-alist))
      (setq temp-num (+ temp-num 1)))
    (goto-char (point-max))
    (gams-ol-select-key)
    (goto-char (point-min))
    (gams-ol-select-mode cur-buf)))

;;; key assignment for select-item mode.
(defvar gams-os-on "j")
(defvar gams-os-on-prev "i")
(defvar gams-os-off "h")
(defvar gams-os-off-prev "u")
(defvar gams-os-on-all "d")
(defvar gams-os-off-all "f")
(defvar gams-os-quit "q")
(defvar gams-os-add "a")
(defvar gams-os-select "\r")
(defvar gams-os-sum "s")
(defvar gams-os-var "v")
(defvar gams-os-equ "e")
(defvar gams-os-vri "r")
(defvar gams-os-set "t")
(defvar gams-os-par "p")
(defvar gams-os-loo "l")
(defvar gams-os-oth "o")
(defvar gams-os-com "c")

(defvar gams-ol-select-mode-map (make-keymap) "keymap.")
(let ((map gams-ol-select-mode-map))
  (define-key map " " 'gams-ol-toggle)
  (define-key map gams-os-on 'gams-ol-toggle-on)
  (define-key map gams-os-off 'gams-ol-toggle-off)
  (define-key map gams-os-on-prev 'gams-ol-toggle-on-prev)
  (define-key map gams-os-off-prev 'gams-ol-toggle-off-prev)
  (define-key map gams-os-select 'gams-ol-select-select)
  (define-key map gams-os-quit 'gams-ol-select-quit)
  (define-key map gams-os-add 'gams-ol-item-add)
  (define-key map gams-os-on-all 'gams-ol-toggle-all-on)
  (define-key map gams-os-off-all 'gams-ol-toggle-all-off)

  (define-key map gams-os-var 'gams-ol-toggle-var)
  (define-key map gams-os-equ 'gams-ol-toggle-equ)
  (define-key map gams-os-vri 'gams-ol-toggle-vri)
  (define-key map gams-os-set 'gams-ol-toggle-set)
  (define-key map gams-os-par 'gams-ol-toggle-par)
  (define-key map gams-os-sum 'gams-ol-toggle-sum)
  (define-key map gams-os-loo 'gams-ol-toggle-loo)
  (define-key map gams-os-oth 'gams-ol-toggle-oth)
  (define-key map gams-os-com 'gams-ol-toggle-com)
  )

(setq-default gams-ol-olbuff nil)
(setq-default gams-ol-item-flag nil)
(setq-default gams-ol-lstbuf nil)
(setq-default  gams-ol-mark-flag nil)

;;; menu for outline-select mode.
(easy-menu-define 
  gams-ol-select-mode-menu gams-ol-select-mode-map "menu keymap for outline-select mode."
  '("outline-select"
    ["toggle" gams-ol-toggle t]
    ["toggle on (next)" gams-ol-toggle-on t]
    ["toggle off (next)" gams-ol-toggle-off t]
    ["toggle on (previous)" gams-ol-toggle-on-prev t]
    ["toggle off (previous)" gams-ol-toggle-off-prev t]
    ["toggle on all" gams-ol-toggle-all-on t]
    ["toggle off all" gams-ol-toggle-all-off t]
    "--"
    ["Register" gams-ol-item-add t]
    ["Select" gams-ol-select-select t]
    ["quit select mode" gams-ol-select-quit t]
    "--"
    ["toggle var" gams-ol-toggle-var t]
    ["toggle equ" gams-ol-toggle-equ t]
    ["toggle vri" gams-ol-toggle-vri t]
    ["toggle set" gams-ol-toggle-set t]
    ["toggle par" gams-ol-toggle-par t]
    ["toggle sum" gams-ol-toggle-sum t]
    ["toggle loo" gams-ol-toggle-loo t]
    ["toggle oth" gams-ol-toggle-oth t]
    ["toggle com" gams-ol-toggle-com t]
    ))

(defun gams-ol-select-key ()
    (insert (concat "\n"
		    (format "[spc]    = toggle\n")
		    (format "[%s/%s]    = toggle on\n"
			    gams-os-on gams-os-on-prev)
		    (format "[%s/%s]    = toggle off\n"
			    gams-os-off gams-os-off-prev)
		    (format "[%s]      = toggle on all\n" gams-os-on-all)
		    (format "[%s]      = toggle off all\n" gams-os-off-all)
		    (format "[%s]      = register: You can register the current viewable item combination\n" gams-os-add)
		    (format "[ret]    = select\n")
		    (format "[%s]      = quit.\n\n" gams-os-quit)
		    (format "[%s] = sum, " gams-os-sum)
		    (format "[%s] = var, " gams-os-var)
		    (format "[%s] = equ, " gams-os-equ)
		    (format "[%s] = par, " gams-os-par)
		    (format "[%s] = set,\n" gams-os-set)
		    (format "[%s] = vri, " gams-os-vri)
		    (format "[%s] = loo, " gams-os-loo)
		    (format "[%s] = oth, " gams-os-oth)
		    (format "[%s] = com." gams-os-com))))

(defun gams-ol-select-mode (buffname)
  "start the select-item mode.

buffname is the outline buffer name."
  (interactive)
  (setq major-mode 'gams-ol-select-mode)
  (setq mode-name "gams-select-item")
  (use-local-map gams-ol-select-mode-map)
  (setq buffer-read-only t)
;  (make-local-variable 'font-lock-defaults)
;  (setq font-lock-defaults '(gams-ol-font-lock-keywords t t))
;  (font-lock-fontify-buffer)
  (make-local-variable 'gams-ol-olbuff)
  (setq gams-ol-olbuff buffname)
  ;; make local variable.  `gams-ol-item-flag' is a buffer local
  ;; variable. when the select buffer is created, `gams-ol-item-flag' is
  ;; given the same content as `gams-ol-view-item'.
  ;; `gams-ol-item-flag' may be modified but `gams-ol-view-item'
  ;; reserve its initial value.
  (make-local-variable 'gams-ol-item-flag)
  (setq gams-ol-item-flag
	(gams-ol-check-func gams-ol-view-item))
  )
;; gams-ol-select-mode ends here.

(defun gams-ol-check-func (alist)
  "copy the alist to the new alist."
  (let ((temp-alist (reverse alist))
	temp-list
	temp-item
	res-alist)
    (while temp-alist
      (setq temp-item (car temp-alist))
      (if (cdr temp-item)
	  (setq res-alist
		(append
		 (list (cons (car temp-item) t)) res-alist))
	(setq res-alist
	      (append
	       (list (cons (car temp-item) nil)) res-alist)))
      (setq temp-alist (cdr temp-alist)))
    res-alist))

(defun gams-ol-select-judge ()
  "Judge the item on the line and return its value."
  (save-excursion
    (beginning-of-line)
    (if (re-search-forward
	 "\\([+]\\|[-]\\)[]][ ]+\\([a-z][a-z][a-z]\\)$" (line-end-position) t)
	(gams*buffer-substring (match-beginning 2) (match-end 2)))))

(defun gams-ol-toggle (&optional on off prev)
  "toggle check.

if on in non-nil, toggle on. if off is non-nil, toggle off.
if prev is non-nil, move up after toggle."
  (interactive)
  (let* ((buffer-read-only nil)
	(item (gams-ol-select-judge))
	(flag (gams-ol-check-included item)))
    (if (not item)
	;; if no item on the current line, do nothing.
	nil
      ;; if any item on the current line.
      (beginning-of-line)
      (move-to-column 3)
      (cond
       ;; just toggle.
       ((and (not on) (not off))
	;; delete.
	(delete-char 1)
	(if flag
	    ;; if checked.
	    (insert "-")
	  ;; not checked.
	  (insert "+"))
	(gams-ol-check-toggle item))
       ;; toggle on.
       ((and on (not off))
	(if flag
	    nil
	  ;; delete.
	  (delete-char 1)
	  (insert "+")
	  (gams-ol-check-toggle item)))
       ;; toggle off.
       ((and (not on) off)
	(if (not flag)
	    nil
	  ;; delete.
	  (delete-char 1)
	  (insert "-")
	  (gams-ol-check-toggle item)))))
    ;; forward or backward?
    (if prev
	(forward-line -1)
      (forward-line 1))
    ))

(defun gams-ol-toggle-on ()
  "toggle on the item on the current line."
  (interactive)
  (gams-ol-toggle t))

(defun gams-ol-toggle-on-prev ()
  "toggle on the item on the current line."
  (interactive)
  (gams-ol-toggle t nil t))

(defun gams-ol-toggle-all-on ()
  "toggle on all items."
  (interactive)
  (let ((times 9))
    (save-excursion
      (goto-char (point-min))
      (while (> times 0)
	(gams-ol-toggle t)
	(setq times (- times 1))))))

(defun gams-ol-toggle-all-off ()
  "toggle off all the items."
  (interactive)
  (let ((times 9))
    (save-excursion
      (goto-char (point-min))
      (while (> times 0)
	(gams-ol-toggle nil t)
	(setq times (- times 1))))))

(defun gams-ol-toggle-off ()
  "toggle off the item on the current line."
  (interactive)
  (gams-ol-toggle nil t))

(defun gams-ol-toggle-off-prev ()
  "toggle off the item on the current line."
  (interactive)
  (gams-ol-toggle nil t t))

(defun gams-ol-toggle-func (item)
  "item is an item name."
  (goto-char (point-min))
  (goto-char (re-search-forward (concat "] " item) nil t))
  (beginning-of-line)
  (gams-ol-toggle))

(defun gams-ol-toggle-var ()
  (interactive)
  (gams-ol-toggle-func "var"))

(defun gams-ol-toggle-equ ()
  (interactive)
  (gams-ol-toggle-func "equ"))

(defun gams-ol-toggle-vri ()
  (interactive)
  (gams-ol-toggle-func "vri"))

(defun gams-ol-toggle-par ()
  (interactive)
  (gams-ol-toggle-func "par"))

(defun gams-ol-toggle-set ()
  (interactive)
  (gams-ol-toggle-func "set"))

(defun gams-ol-toggle-loo ()
  (interactive)
  (gams-ol-toggle-func "loo"))

(defun gams-ol-toggle-sum ()
  (interactive)
  (gams-ol-toggle-func "sum"))

(defun gams-ol-toggle-oth ()
  (interactive)
  (gams-ol-toggle-func "oth"))

(defun gams-ol-toggle-com ()
  (interactive)
  (gams-ol-toggle-func "com"))


(defun gams-ol-select-select ()
  "quit the select-item mode."
  (interactive)
  (let ((cur-buff (current-buffer))
	(ov-buff gams-ol-olbuff)
	(item gams-ol-item-flag)
	temp-buf)
    (if (buffer-live-p ov-buff)
	;; if outline buffer exits.
	(progn
	  (switch-to-buffer ov-buff)
	  (kill-buffer cur-buff)
	  (delete-other-windows)
	  (if (equal item gams-ol-view-item)
	      ;; if no change has been made to gams-ol-view-item.
	      nil
	    ;; if any change has been made.
	    ;; switch to the lst buffer.
	    (switch-to-buffer gams-ol-lstbuf)
	    ;; store the lst buffer name.
	    (setq temp-buf (current-buffer))
	    (setq gams-ol-view-item item)
	    (gams-ol-show ov-buff (gams-ol-convert (gams-ol-get-alist)))
	    (switch-to-buffer ov-buff)
	    (setq gams-ol-mark-flag nil)
	    ;; give lst buffer name.
	    (gams-ol-mode temp-buf))
	  (gams-ol-show-key))
      ;; if outline buffer does not exists.
      (message "No outline buffer exists!")
      (sleep-for 0.5)
      (kill-buffer cur-buff))))

(defun gams-ol-check-included (item &optional flag)
  "judge whether the item is checked or not.
if the flag is non-nil, use `gams-ol-view-item'.
"
  (let ((temp-alist
	 (if flag gams-ol-view-item gams-ol-item-flag)))
    (if (cdr (assoc item temp-alist))
	t
      nil)))

(defun gams-ol-check-toggle (item)
  "toggle the check of the item."
  (let ((temp-alist gams-ol-item-flag))
    (if (gams-ol-check-included item)
	;; if checked.
	(setcdr (assoc item temp-alist) nil)
      ;; if not checked.
      (setcdr (assoc item temp-alist) t))
    gams-ol-view-item
    gams-ol-item-flag))

(defun gams-ol-change-window-one-line (&optional narrow)
  "widen (narrow) a outline mode buffer one line.
if narrow is non-nil, narrow the window."
  (interactive)
  (let ((key (this-command-keys))
	(win-num (gams-count-win))
	(main (car gams-ol-display-style)))
    (if narrow
	;; narrowing
	(cond
	 ((equal win-num 1) nil)
	 ((equal win-num 2)
	  (if main
	      (setq gams-ol-width (max 10 (- gams-ol-width 1)))
	    (setq gams-ol-height (max 5 (- gams-ol-height 1)))))
	 (t
	  (if main
	      (setq gams-ol-width (max 10 (- gams-ol-width 1)))
	    (setq gams-ol-height-two (max 5 (- gams-ol-height-two 1))))))
      ;; widening
      (if (not main)
	  (cond
	   ((equal win-num 1) nil)
	   ((equal win-num 2)
	    (when (>= (window-height (next-window)) 8)
	      (setq gams-ol-height (+ gams-ol-height 1))))
	   (t
	    (when (>= (window-height (next-window)) 8)
	      (setq gams-ol-height-two (+ gams-ol-height-two 1)))))
	(when (and (not (equal win-num 1))
		   (>= (window-width (next-window)) 8))
	  (setq gams-ol-width (+ gams-ol-width 1))))))
  (gams-ol-view-base))

(defun gams-ol-widen-one-line ()
  "Widen the outline mode buffer by one line."
  (interactive)
  (gams-ol-change-window-one-line))

(defun gams-ol-narrow-one-line ()
  "Narrow the outline mode buffer by one line."
  (interactive)
  (gams-ol-change-window-one-line t))

(defun gams-ol-refresh ()
  "Refresh the GAMS-OL buffer if the LST file is updated."
  (interactive)
  (let ((lst-buf gams-ol-lstbuf)
	(cur-buf (current-buffer))
	lst-fname)
    (if (verify-visited-file-modtime lst-buf)
	(progn
	  ;; Move to the LST buffer.
	  (set-buffer lst-buf)
	  ;; Kill the OL buffer.
	  (kill-buffer cur-buf)
	  ;; Get the LST file name.
	  (setq lst-fname (buffer-file-name (current-buffer)))
	  ;; Kill the LST buffer.
	  (set-buffer-modified-p nil)
	  (kill-buffer (current-buffer))
	  ;; Open the LST file.
	  (find-file lst-fname)
	  ;; Restart OL mode.
	  (gams-outline)
	  (message "GAMS-OUTLINE buffer is updated!"))
      (message "The LST file is not updated."))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Codes for chaging viewable items in GAMS-OUTLINE mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar gams-user-outline-item-alist nil
  "The list of combinations of items defined by users.")

(defvar gams-user-outline-item-alist-initial nil)
(setq gams-user-outline-item-alist-initial gams-user-outline-item-alist)
      
(defvar gams-outline-item-alist nil
  "The list of combinations of options in which
`gams:process-command-option' and `gams-user-option-alist' are combined.")

(defvar gams-current-item-num "default")

(defvar gams-ol-item-alist-2
      '(
	("SUM" . 1)
	("VAR" . 2)
	("EQU" . 3)
	("PAR" . 4)
	("SET" . 5)
        ("VRI" . 6)
	("LOO" . 7)
	("OTH" . 8)
	("COM" . 9)
	("INF" . 10)
	))

(defun gams-ol-make-list-view-item (alist)
  (let ((temp-alist-1 gams-ol-item-alist)
	(temp-alist-2 alist)
	(temp-alist-3 gams-ol-item-alist-2)
	temp-1 temp-2 list-1 temp-ele)
    (while temp-alist-3
      (setq temp-ele (cdr (assoc (car (car temp-alist-3)) temp-alist-2)))
      (if (equal temp-ele t)
	  (setq list-1 (cons 1 list-1))
	(setq list-1 (cons 0 list-1)))
      (setq temp-alist-3 (cdr temp-alist-3)))
    (reverse list-1)))

;;; initialize.
(setq gams-current-item-num "default")

(defun gams-ol-item-insert (alist num)
  (let ((item-num (car alist))
	(item-cont (car (cdr alist)))
	(temp-alist1 gams-ol-item-alist)
	(temp-alist2 gams-ol-item-alist-2)
	temp-ele)
    (if num
	(insert "* ")
      (insert "  "))
    (insert item-num)
    (move-to-column 18 t)
    (while temp-alist1
      (setq temp-ele
	    (nth (- (cdr (assoc (car (car temp-alist1)) temp-alist2)) 1)
		 item-cont))
      (insert (concat (if (equal 1 temp-ele) " o " "   ") "  "))
      (setq temp-alist1 (cdr temp-alist1)))
    (insert "\n")))

(defun gams-ol-item-view ()
  "Display the content of item on the current line in the next buffer."
  (interactive)
  (let ((temp-alist gams-outline-item-alist)
	(temp-alist-2 gams-ol-item-alist)
	(temp-alist-3 gams-ol-item-alist)	
	(cur-num gams-current-item-num)
	(temp-buf "*Select item*")
	(buffer-read-only nil)
	(count (length gams-user-outline-item-alist))
	(count2 1)
	list-list flag)
    (get-buffer-create temp-buf)
    (pop-to-buffer temp-buf)
    (setq buffer-read-only nil)
    (erase-buffer)
    (goto-char (point-min))
    ;; Insert.
    (move-to-column 18 t)
    (while temp-alist-3
      (insert (concat (car (car temp-alist-3)) "  "))
      (setq temp-alist-3 (cdr temp-alist-3)))
    (insert "\n")
    (setq list-list (assoc "default" temp-alist))
    (if (equal cur-num "default")
	(setq flag t)
      (setq flag nil))
    (gams-ol-item-insert list-list flag)

    (while (<= count2 count)
      (setq list-list (assoc (number-to-string count2) temp-alist))
      (goto-char (point-max))
      (if (equal count2 (string-to-number cur-num))
	  (setq flag t)
	(setq flag nil))
      (gams-ol-item-insert list-list flag)
      (setq count2 (+ count2 1)))
    (goto-char (point-min))
    (forward-line 1)
    (goto-char (point-max))
    (insert
     (concat "\n\n"
	     "To register the viewable item combinations,\n"
	     "use `gams-ol-select-item'"
	     (format " binded to `%s' by default.\n\n" gams-olk-4)))
    (goto-char (point-min))
    (setq buffer-read-only t)))

(defun gams-ol-item ()
  "Select the registered item combination.
To register the viewable item combinations, use `gams-ol-select-item'."
  (interactive)
  (let ((cur-buf (current-buffer)))
    ;; Display.
    (gams-ol-item-view)
    ;; Show key in the minibuffer.
    (gams-ol-item-show-key)
    ;; Start the mode.
    (gams-ol-item-mode cur-buf)
    ;;
    (forward-line 1)
    ))

(defvar gams-ol-item-mode-map (make-keymap) "keymap for gams-mode")
(let ((map gams-ol-item-mode-map))
  (define-key map "n" 'gams-ol-item-next)
  (define-key map "p" 'gams-ol-item-prev)
  (define-key map "\r" 'gams-ol-item-change)
  (define-key map "q" 'gams-ol-item-quit)
  (define-key map "d" 'gams-ol-item-delete))

(setq-default gams-ol-item-ol-buffer nil)

(defun gams-ol-item-mode (buff)
  "Mode for changing command line options."
  (kill-all-local-variables)
  (setq mode-name "item"
	major-mode 'gams-ol-item-select-mode)
  (use-local-map gams-ol-item-mode-map)
  (make-local-variable 'gams-ol-item-ol-buffer)
  (setq gams-ol-item-ol-buffer buff)
  (setq buffer-read-only t))

(defun gams-ol-item-show-key ()
  (message
    (concat
     "* => the current choice, "
     "Key: "     
     "[n]ext, "     
     "[p]rev, "     
     "RET = select, "     
     "[q]uit, "     
     "[d]elete")))

(defun gams-ol-item-next ()
  "Next line."
  (interactive)
  (next-line 1)
  (gams-ol-item-show-key))

(defun gams-ol-item-prev ()
  "Previous line."
  (interactive)
  (next-line -1)
  (gams-ol-item-show-key))

(defun gams-ol-item-quit ()
  "Quit."
  (interactive)
  (let ((cur-buf (current-buffer)))
    (switch-to-buffer gams-ol-item-ol-buffer)
    (kill-buffer cur-buf)
    (delete-other-windows)))

(defun gams-ol-item-change ()
  "Set the option combination on the current line to the new option combination."
  (interactive)
  (let ((cur-buff (current-buffer))
	(ov-buff gams-ol-item-ol-buffer)
	temp-buf
	(old-num gams-current-item-num)
	(num (gams-ol-item-return-item-num)))

    (if (not num)
	(gams-ol-item-show-key)
      (if (buffer-live-p ov-buff)
	  ;; if outline buffer exits.
	  (progn
	    (switch-to-buffer ov-buff)
	    (kill-buffer cur-buff)
	    (delete-other-windows)
	    (setq gams-current-item-num num)
	    (gams-ol-item-return-item)
	    ;; if any change has been made.
	    ;; switch to the lst buffer.
	    (switch-to-buffer gams-ol-lstbuf)
	    ;; store the lst buffer name.
	    (setq temp-buf (current-buffer))
	    (gams-ol-show ov-buff (gams-ol-convert (gams-ol-get-alist)))
	    (switch-to-buffer ov-buff)
	    (setq gams-ol-mark-flag nil)
	    ;; give lst buffer name.
	    (gams-ol-mode temp-buf)
	    (gams-ol-show-key))
	;; if outline buffer does not exists.
	(message "No outline buffer exists!")
	(sleep-for 0.5)
	(kill-buffer cur-buff)))))

(defun gams-ol-item-renumber ()
  "Change the number of option alist."
  (let* ((alist gams-user-outline-item-alist)
	 (num (list-length alist))
	 new-alist)
    (while alist
      (setq new-alist
	    (cons (cons (number-to-string num) (cdr (car alist)))
		  new-alist))
      (setq num (1- num))
      (setq alist (cdr alist)))
    (setq gams-user-outline-item-alist new-alist)))
	    
(defun gams-ol-item-delete ()
  "Delete the option combination on the current line."
  (interactive)
  (let ((num (gams-ol-item-return-item-num))
	(cur-num gams-current-item-num))
    (cond
     ((equal num "default")
      (message "You cannot delete the default combination!"))
     ((equal num nil)
      (message "??"))
     (t
      (message (format "Do you really delete \"%s\"?  Type `y' if yes." num))
      (let ((key (read-char)))
	(if (not (equal key ?y))
	    nil
	  (setq gams-user-outline-item-alist
		(gams-del-alist num gams-user-outline-item-alist))
	  (message (format "Remove \"%s\" from the registered alist." num))
	  ;; renumbering.
	  (gams-ol-item-renumber)
	  (when (equal num cur-num)
	      (setq  gams-current-item-num "default"))
	  (setq gams-outline-item-alist
		(append
		 (list (cons "default" (list gams-ol-view-item-default)))
		 gams-user-outline-item-alist))
	  (when (equal num gams-current-item-num)
	    (setq gams-current-item-num "default"))
	  (gams-ol-item-view)))))))

(defun gams-ol-item-return-item ()
  "Return the option combination of the current line."
  (gams-ol-change-view-item
   (car (cdr (assoc gams-current-item-num gams-outline-item-alist)))))

(defun gams-ol-change-view-item (list)
  (let ((alist gams-ol-item-alist)
	(alist2 gams-ol-item-alist-2)
	(temp-list list)
	new-alist)
    (while alist
      (if (equal 1 (nth (- (cdr (assoc (car (car alist)) alist2)) 1) list))
	  (setq new-alist
		(cons (cons (car (car alist)) t) new-alist))
	(setq new-alist
	      (cons (cons (car (car alist)) nil) new-alist)))
      (setq alist (cdr alist)))
    (setq new-alist (reverse new-alist))
    (setq gams-ol-item-flag new-alist)
    (setq gams-ol-view-item new-alist)))
    
(defun gams-ol-item-return-item-num ()
  "Return the number of the option combination on the current line."
  (interactive)
  (save-excursion
    (if (equal 1 (count-lines (point-min) (+ 1 (point))))
	nil
      (beginning-of-line)
      (cond
       ((looking-at "^\\*?[ \t]+\\([0-9]+\\)[ \t]+")
	(gams*buffer-substring (match-beginning 1)
			       (match-end 1)))
       ((looking-at "^\\*?[ \t]+\\(default\\)[ \t]+")
	"default")))))

(defun gams-kill-emacs-hook ()
  (when (not gams-save-template-change)
    (gams-temp-write-alist-to-file))
  (gams-register-option)
  (gams-register-command)
  (gams-register-ol-item))
(add-hook 'kill-emacs-hook 'gams-kill-emacs-hook)

(defun gams-ol-item-make-number-list (num-list)
  (let* ((count 10)
	(old-list (reverse num-list))
	(diff (- 10 (length old-list)))
	new-list)
    (when (not (equal 0 diff))
      (setq old-list (append (make-list diff 0) old-list)))
    (while (<= 1 count)
      (setq new-list (concat
		      (if (equal 1 (car old-list))
			  " 1"
			" 0")
		      new-list))
      (setq count (- count 1))
      (setq old-list (cdr old-list)))
    (setq new-list (substring new-list 1))
    new-list))

(defun gams-register-ol-item ()
  "Save the content of `gams-user-outline-item-alist' into the file
`gams-statement-file'."
  (interactive)
  (if (and gams-user-outline-item-alist
	   (not (equal gams-user-outline-item-alist gams-user-outline-item-alist-initial)))
      (progn
	(let* ((temp-buff " *gams-item*")
	       (temp-file gams-statement-file)
	       (temp-alist gams-user-outline-item-alist)
	       (old-alist temp-alist)
	       (alist-name "gams-user-outline-item-alist")
	       (count 10)
	       new-alist temp-cont)
	  (save-excursion
	    ;; Switch to the temporary buffer.
	    (get-buffer-create temp-buff)
	    (switch-to-buffer temp-buff)
	    ;;      (set-buffer temp-buff)
	    (erase-buffer)
	    ;; Write the content of the alist.
	    (insert (concat "(setq " alist-name " '(\n"))
	    (goto-char (point-max))
	    (while temp-alist
	      (insert
	       (concat
		"(\"" (car (car temp-alist)) "\" ("
		(gams-ol-item-make-number-list (car (cdr (car temp-alist))))
		"))\n"))
	      (goto-char (point-max))
	      (setq temp-alist (cdr temp-alist)))
	    (insert "))\n")
	    ;; Check whether the variable is defined correctly.
	    (eval-buffer)
	    ;; Store the content of buffer
	    (setq temp-cont (gams*buffer-substring (point-min) (point-max)))
	    ;; Delete the list-name part.
	    (switch-to-buffer (find-file-noselect temp-file))
	    (goto-char (point-min))
	    ;; Check whether the list-name part exists or not.
	    (if (not (re-search-forward
		       (concat
			"\\(setq\\) " alist-name)
		       nil t))
		;; If it doesn't exists, do nothing.
		nil
	      ;; If it exists, delete it.
	      (let (point-beg point-en)
		(goto-char (match-beginning 1))
		(beginning-of-line)
		(setq point-beg (point))
		(forward-sexp 1)
		(forward-line 1)
		(setq point-en (point))
		(delete-region point-beg point-en)))
	    ;; Insert the content.
	    (goto-char (point-min))
	    (insert temp-cont)
	    ;; Save buffer of gams-statement-file.
	    (save-buffer (find-buffer-visiting temp-file))
	    (kill-buffer (find-buffer-visiting temp-file))
	    ;; kill the temporary buffer.
	    (kill-buffer temp-buff)
	    )))))
      
(defun gams-ol-item-add ()
  (interactive)
  (message "Do you really register this item combination?  Type `y' if yes.")
  (if (equal ?y (read-char))
      (let ((num (+ 1 (length gams-user-outline-item-alist))))
	(setq gams-user-outline-item-alist
	      (append
	       (list (cons (number-to-string num)
			   (list (gams-ol-make-list-view-item gams-ol-item-flag))))
	       gams-user-outline-item-alist))
	(setq gams-outline-item-alist
	      (append
	       (list (cons "default" (list gams-ol-view-item-default)))
	       gams-user-outline-item-alist))
	(message "Added this viewable item combination to item list."))))
    
(defun gams-ol-select-quit ()
  "quit the select-item mode."
  (interactive)
  (let ((cur-buff (current-buffer))
	(ov-buff gams-ol-olbuff)
	(item gams-ol-item-flag)
	temp-buf)
    (if (buffer-live-p ov-buff)
	;; if outline buffer exits.
	(progn
	  (switch-to-buffer ov-buff)
	  (kill-buffer cur-buff)
	  (delete-other-windows)
	  (if (equal item gams-ol-view-item)
	      ;; if no change has been made to gams-ol-view-item.
	      nil
	    ;; if any change has been made.
	    ;; switch to the lst buffer.
	    (switch-to-buffer gams-ol-lstbuf)
	    ;; store the lst buffer name.
	    (setq temp-buf (current-buffer))
	    (setq gams-ol-view-item item)
	    (gams-ol-show ov-buff (gams-ol-convert (gams-ol-get-alist)))
	    (switch-to-buffer ov-buff)
	    (setq gams-ol-mark-flag nil)
	    ;; give lst buffer name.
	    (gams-ol-mode temp-buf))
	  (gams-ol-show-key))
      ;; if outline buffer does not exists.
      (message "No outline buffer exists!")
      (sleep-for 0.5)
      (kill-buffer cur-buff))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	code for GAMS-LXI mode.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gams-file-attributes (file)
  (if gams-emacs-21
      (file-attributes file)
    ;; Emacs22/23
    (file-attributes file t)))

;; (gams-regexp-opt
;;    (list
;;     "C o m p i l a t i o n"
;;     "Include File Summary"
;;     "E x e c u t i o n"
;;     "Model Statistics"
;;     "Solution Report"
;;     "Equation Listing"
;;     "Column Listing"
;;     ) t)

(defvar gams-lxi-font-lock-keywords
;; (setq gams-lxi-font-lock-keywords
  '(
;    ("^[ \t]+\\(C\\(?: o m p i l a t i o n\\|olumn Listing\\)\\|E\\(?: x e c u t i o n\\|quation Listing\\)\\|Include File Summary\\|Model Statistics\\|Solution Report\\)" (0 gams-lst-warning-face))
    ("^[[][+-][]]\\(SolVAR\\)" (0 gams-lst-var-face))
    ("^[[][+-][]]\\(SolEQU\\)" (0 gams-lst-equ-face))
    ("^[[][+-][]]\\(Column\\)" (0 gams-lxi-col-face))
    ("^[[][+-][]]\\(Equation\\)" (0 gams-lxi-equ-face))
    ("^[[][+-][]]\\(Display\\)" (0 gams-lst-par-face))
    )
  )

(defvar gams-lxi-col-face 'gams-lxi-col-face)

(defface gams-lxi-col-face
  '((((class color) (background light))
     (:bold t :foreground "lime green"))
    (((class color) (background dark))
     (:bold t :italic nil :foreground "green")))
  "Face for COLUMN in GAMS-LXI mode."
  :group 'gams-faces)

(defvar gams-lxi-equ-face 'gams-lxi-equ-face)
(defface gams-lxi-equ-face
  '((((class color) (background light))
     (:bold t :foreground "orange"))
    (((class color) (background dark))
     (:bold t :italic nil :foreground "orange")))
  "Face for EQUATION in GAMS-LXI mode."
  :group 'gams-faces)

;;; Check:
(when (not gams-emacs-21)
  (require 'warnings)
  (add-to-list 'warning-suppress-types '(undo discard-info)))

(defun gams-lxi-create-lxi-file (lst)
  "Evoke gamslxi.exe to create the LXI file."
  (let* ((lxi-name (concat (file-name-sans-extension lst) "." gams-lxi-extension))
	 (out-buf (get-buffer-create " *temp-lxi*"))
	 (cur-buf (current-buffer)))
    (call-process gams-lxi-command-name nil out-buf nil lst lxi-name)
    (kill-buffer out-buf)
    ))

(defun gams-lxi-create-item-list ()
  (let (type line iden ele alist tlnum)
    (save-excursion
      (goto-char (point-min))
      (forward-line 1)
      (while (looking-at "^\\([A-Z]\\)[ ]+\\([0-9]+\\)[ ]+\\([^\n]+\\)")
	(setq type (gams*buffer-substring (match-beginning 1) (match-end 1))
	      line (gams*buffer-substring (match-beginning 2) (match-end 2))
	      iden (gams*buffer-substring (match-beginning 3) (match-end 3)))
	(setq ele (list type line iden))
	(setq alist (cons ele alist))
	(forward-line 1))
      ;; Get the number of lines.
      (goto-char (point-max))
      (re-search-backward "line=[[]\\([0-9]+\\)[]]" nil t)
      (setq tlnum (string-to-number
		   (gams*buffer-substring (match-beginning 1)
					  (match-end 1)))))
    (list tlnum (reverse alist))))

;; (defun gams-lxi-dired-lxi ()
;;   (interactive)
;;   (let ((file (dired-get-filename)))
;;     (if (not (equal (file-name-extension file) "lst"))
;; 	(message "You can use this command only for lst file.")
;;       (gams-lxi-internal file))))

(defun gams-lxi-get-view-buffer ()
  (let ((lxi-buf (buffer-name)))
    (setq lxi-buf
	  (gams-replace-regexp-in-string "[*]$" "" lxi-buf))
    (concat lxi-buf "-VIEW*")))

(defun gams-lxi-quit ()
  "Quit GAMS-LXI mode."
  (interactive)
  (let ((v-buf (gams-lxi-get-view-buffer))
	(g-buf gams-lxi-gms-buffer)
	(cur-buf (current-buffer)))
    (when (get-buffer v-buf)
      (kill-buffer v-buf))
    (when g-buf
      (switch-to-buffer g-buf))
    (kill-buffer cur-buf)
    (delete-other-windows)))

(defun gams-lxi-jump-to-gms-file ()
  "Jump back to the GMS file buffer."
  (interactive)
  (let* ((g-file (buffer-file-name gams-lxi-gms-buffer))
	 (g-buf gams-lxi-gms-buffer)
	 key)
    (if g-buf
	(progn (switch-to-buffer g-buf)
	       (delete-other-windows))
      (message (format "GMS file Buffer does not exist.  Open? [y/n]"))
      (setq key (read-char))
      (when (equal key ?y)
	(if (file-exists-p g-file)
	    (progn (find-file g-file)
		  (delete-other-windows))
	  (message (format "%s does not exist." g-file)))))))

(defun gams-lxi-get-lxi-file-name (file)
  (let ((lst-sub (file-name-sans-extension file)))
    (concat lst-sub "." gams-lxi-extension)))

(defun gams-lxi-lst-modified-p (lst)
  (let ((lxi (gams-lxi-get-lxi-file-name lst)))
    (when (> (string-to-number (format-time-string "%s" (nth 5 (gams-file-attributes lst))))
	     (string-to-number (format-time-string "%s" (nth 5 (gams-file-attributes lxi)))))
      t)))

(defun gams-lxi ()
  "Start GAMS-LXI mode.
For the details of GAMS-LXI mode, see `gams-lxi-sample.gms' file."
  (interactive)
  (let* ((lst (gams-get-lst-filename))
	 (lxi-buf (concat "*" (buffer-name) "-LXI*")))
    (if (not lst)
	(message "LST file does not exist.")
      (if (and (file-exists-p (gams-lxi-get-lxi-file-name lst))
	       (not (gams-lxi-lst-modified-p lst))
	       (buffer-live-p gams-lxi-buffer))
	  (switch-to-buffer lxi-buf)
	(gams-lxi-create-lxi-buffer)))))
	       
(defun gams-lxi-create-lxi-buffer ()
  (let* ((lst (gams-get-lst-filename))
	 (gms (buffer-file-name))
	 (gms-buf (current-buffer))
	 (lxi (gams-lxi-get-lxi-file-name lst))
	 (lxi-buf (concat "*" (buffer-name) "-LXI*"))
	 alist alist-a alist-b)
    (switch-to-buffer (get-buffer-create lxi-buf))
    ;;
    (when (not (equal mode-name "GAMS-LXI"))
      (gams-lxi-mode))
    (setq buffer-read-only nil)
    (setq font-lock-mode nil)
    ;;
    (if (not (file-exists-p (gams-lxi-get-lxi-file-name lst)))
	(progn
	  (message "Creating the LXI file.")
	  (gams-lxi-create-lxi-file lst)
	  (when (not (file-exists-p lxi))
	    (message "LXI (GLX) file is not created.  See ...")))
      (when (gams-lxi-lst-modified-p lst)
	(message "Updating the LXI file.")
	(gams-lxi-create-lxi-file lst)
	(when (not (file-exists-p lxi))
	  (message "LXI (GLX) file is not created.  See ..."))))
    ;;
    (message "Starting LXI mode.")
    (setq alist (gams-lxi-create-lxi-alist lxi lxi-buf))
    (setq alist-a (car alist))
    (setq alist-b (car (cdr alist)))
    ;;
    (erase-buffer)
    (setq gams-lxi-alist alist-b)
    (gams-lxi-display-alist alist-b)
    (gams-lxi-mode-start gms-buf lst lxi alist-a)
    ;;
    (set-buffer gms-buf)
    (setq gams-lxi-buffer (get-buffer lxi-buf))
    ;;
    (set-buffer lxi-buf)
    (setq buffer-read-only t)
    (setq font-lock-mode t)
    ))

(defun gams-lxi-back-to-lxi ()
  (interactive)
  (let ((lxi-buf gams-lxi-view-lxi-buffer))
    (if (get-buffer lxi-buf)
	(switch-to-buffer lxi-buf)
      (message "%s buffer does not exist." lxi-buf))))

(defun gams-lxi-mode-start (gms lst lxi lnum)
  (setq gams-lxi-lxi-file lxi)
  (setq gams-lxi-lst-file lst)
  (setq gams-lxi-gms-buffer gms)
  (setq gams-lxi-gms-file (buffer-file-name))
  (setq gams-lxi-lst-file-total-line lnum)
  (gams-lxi-fold-all-items-first)
  (goto-char (point-min))
  (message "Done.")
  )

(defun gams-lxi-create-lxi-alist (lxi lxibuf)
  (let ((temp-buf (get-buffer-create " *temp-lxi*"))
	(cur-buf (current-buffer))
	alist)
    (set-buffer temp-buf)
    (setq font-lock-mode nil)
    (erase-buffer)
    (insert-file-contents lxi)
    (setq alist (gams-lxi-create-item-list))
    (set-buffer cur-buf)
    (kill-buffer temp-buf)
    alist))

(setq-default gams-lxi-lxi-file nil)
(setq-default gams-lxi-lst-file nil)
(setq-default gams-lxi-gms-file nil)
(setq-default gams-lxi-gms-buffer nil)
(setq-default gams-lxi-lst-file-total-line nil)
(setq-default gams-lxi-last-regions nil)

(defvar gams-lxi-mode-map (make-keymap) "Keymap used in gams mode")
;; Key assignment.
(defun gams-lxi-mode-key-update ()
  (let ((map gams-lxi-mode-map))
      (define-key map "\C-m" 'gams-lxi-item)
      (define-key map "q" 'gams-lxi-quit)
      (define-key map "i" 'gams-lxi-jump-to-gms-file)
      (define-key map " " 'gams-lxi-item)
      (define-key map "r" 'gams-lxi-update)
      (define-key map "n" 'gams-lxi-item-next)
      (define-key map "p" 'gams-lxi-item-prev)
      (define-key map "v" 'gams-lxi-toggle-fold-item)
      (define-key map "c" 'gams-lxi-toggle-follow-mode)
      (define-key map "x" 'gams-lxi-toggle-fold-all-items)
      (define-key map "?" 'gams-lxi-help)

      (define-key map "d" 'gams-lst-scroll-1)
      (define-key map "f" 'gams-lst-scroll-down-1)
      (define-key map "g" 'gams-lst-scroll-2)
      (define-key map "h" 'gams-lst-scroll-down-2)
      (define-key map "j" 'gams-lst-scroll-double)
      (define-key map "k" 'gams-lst-scroll-down-double)

      (define-key map "D" 'gams-lst-scroll-page-1)
      (define-key map "F" 'gams-lst-scroll-page-down-1)
      (define-key map "G" 'gams-lst-scroll-page-2)
      (define-key map "H" 'gams-lst-scroll-page-down-2)
      (define-key map "J" 'gams-lst-scroll-page-double)
      (define-key map "K" 'gams-lst-scroll-page-down-double)
      (define-key map [down-mouse-1] 'gams-lxi-item-click)
      (define-key map "," 'beginning-of-buffer)
      (define-key map "." 'end-of-buffer)
      (define-key map "N" 'gams-lxi-tree-next)
      (define-key map "P" 'gams-lxi-tree-prev)
      (define-key map "o" 'gams-lxi-narrow-one-line)
      (define-key map "l" 'gams-lxi-widen-one-line)
      ))

(defun gams-lxi-show-key ()
  "Show the basic keybindings in the GAMS-LXI mode."
  (interactive)
  (message
   (format "[%s]=help, [%s]=show, [%s]toggle follow mode, d,f,j,k=scroll, [%s]uit."
	   "?" "[RET]" "c" "q")))

(defun gams-lxi-scroll ()
  (interactive)
  (gams-lxi-scroll))

(defun gams-lxi-scroll-down ()
  (interactive)
  (gams-lxi-scroll t))

(defun gams-lxi-scroll (&optional down num page)
  "Command for scrolling.

If DOWN is non-nil, scroll down.
NUM mean scroll type (nil, 2, or d).
If PAGE is non-nil, page scroll."
  (interactive)
  (let ((cur-win (selected-window))
	(win-num (gams-count-win))
	;; flag for lst or ov?
	(fl-pa (if page nil 1)))
    (cond
     ;; scroll type 1.
     ((not num)
      (cond
       ((eq win-num 1)
	nil)
       ((> win-num 1)
	(save-excursion
	  (other-window 1)
	  (if down
	      (scroll-down fl-pa)
	    (scroll-up fl-pa))
	  (select-window cur-win)))))
     ;; scroll type 2.
     ((equal num "2")
      (cond
       ((eq win-num 1)
	nil)
       ((eq win-num 2)
	(other-window 1)
	(if down
	    (scroll-down fl-pa)
	  (scroll-up fl-pa))
	(select-window cur-win))
       ((eq win-num 3)
	(other-window 2)
	(if down
	    (scroll-down fl-pa)
	  (scroll-up fl-pa))
	(select-window cur-win))
       (t nil)))
     ;; scroll type double.
     ((equal num "d")
      (cond
       ((eq win-num 1)
	nil)
       ((eq win-num 2)
	(other-window 1)
	(if down
	    (scroll-down fl-pa)
	  (scroll-up fl-pa))
	(select-window cur-win))
       ((eq win-num 3)
	(other-window 1)
	(if down
	    (scroll-down fl-pa)
	  (scroll-up fl-pa))
	(other-window 1)
	(if down
	    (scroll-down fl-pa)
	  (scroll-up fl-pa))
	(select-window cur-win))
       (t nil))))
    (gams-lxi-show-key)
    ))

;;; Menu for GAMS-LXI mode.
(easy-menu-define 
  gams-lxi-menu gams-lxi-mode-map "Menu keymap for GAMS-LXI mode."
  '("GAMS-LXI"
    ["Show the content of the current item" gams-lxi-item t]
    ["Quit GAMS-LXI mode" gams-lxi-quit t]
    ["Jump to the GMS file buffer" gams-lxi-jump-to-gms-file t]
    ["Update the buffer" gams-lxi-update t]
    ["Toggle fold/unfold items in the current tree" gams-lxi-toggle-fold-item t]
    ["Toggle fold/unfold of all items" gams-lxi-toggle-fold-all-items t]
    ["Toggle follow mode" gams-lxi-toggle-follow-mode t]
    "--"
    ["Widen the window with one line" gams-lxi-widen-one-line t]
    ["Narrow the window with one line" gams-lxi-narrow-one-line t]
    "--"
    ["Next item" gams-lxi-item-next t]
    ["Previous item" gams-lxi-item-prev t]
    ["Next tree" gams-lxi-tree-next t]
    ["Previous tree" gams-lxi-tree-prev t]
    ))

(defun gams-lxi-mode ()
  "The major mode for viewing LST files."
  (interactive)
  (kill-all-local-variables)  
  (setq major-mode 'gams-lxi-mode)
  (setq mode-name "GAMS-LXI")
  (use-local-map gams-lxi-mode-map)
  (mapc
   'make-local-variable
   '(gams-lxi-lxi-file
     gams-lxi-lst-file
     gams-lxi-gms-file
     gams-lxi-gms-buffer
     gams-lxi-lst-file-total-line
     gams-lxi-last-regions
     gams-lxi-fold-all-items-p
     ))
  (gams-lxi-mode-key-update)
  (add-to-invisibility-spec '(gams-lxi . t))
  (setq buffer-read-only t
	truncate-lines t)
  (setq font-lock-defaults '(gams-lxi-font-lock-keywords t t))
  (easy-menu-add gams-lxi-menu)
  )

(setq-default gams-lxi-fold-all-items-p t)
(setq-default gams-lxi-view-lxi-buffer nil)

(defvar gams-lxi-view-mode-map (make-keymap) "Keymap used in gams-lxi-view mode")
;; Key assignment.
(defun gams-lxi-view-mode-key-update ()
  (let ((map gams-lxi-view-mode-map))
    (define-key map "i" 'gams-lxi-back-to-lxi)
    (define-key map "q" 'gams-lxi-view-quit)

    (define-key map "d" 'gams-lst-scroll-1)
    (define-key map "f" 'gams-lst-scroll-down-1)
    (define-key map "g" 'gams-lst-scroll-2)
    (define-key map "h" 'gams-lst-scroll-down-2)
    (define-key map "j" 'gams-lst-scroll-double)
    (define-key map "k" 'gams-lst-scroll-down-double)

    (define-key map "D" 'gams-lst-scroll-page-1)
    (define-key map "F" 'gams-lst-scroll-page-down-1)
    (define-key map "G" 'gams-lst-scroll-page-2)
    (define-key map "H" 'gams-lst-scroll-page-down-2)
    (define-key map "J" 'gams-lst-scroll-page-double)
    (define-key map "K" 'gams-lst-scroll-page-down-double)
    ))

(gams-lxi-view-mode-key-update)

(defun gams-lxi-view-quit ()
  (interactive)
  (let ((lxi-buf gams-lxi-view-lxi-buffer)
	(cur-buf (current-buffer))
	g-buf)
    (when (get-buffer lxi-buf)
      (switch-to-buffer lxi-buf))
    (kill-buffer cur-buf)
    (delete-other-windows)))

(defun gams-lxi-view-mode ()
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'gams-lxi-view-mode)
  (setq mode-name "GAMS-LXI-VIEW")
  (use-local-map gams-lxi-view-mode-map)
  (setq buffer-read-only t
	truncate-lines t)
  (mapc
   'make-local-variable
   '(gams-lxi-view-lxi-buffer))
  (gams-update-font-lock-keywords "l" gams-lst-font-lock-level)
  (setq font-lock-defaults '(gams-lst-font-lock-keywords t t))
  (setq font-lock-mode t)
  )

(defun gams-lxi-display-alist (alist)
  (let ((al alist)
	(col1 "   ")
	(col2 "  ")
	ele type ltype iden lnum)
    (while al
      (setq buffer-undo-list nil)
      (setq ele (car al))
      (setq type (nth 0 ele))
      (setq iden (nth 2 ele))
      (setq lnum (nth 1 ele))
      (setq sp col1)
      (when (equal type "I")
	(setq sp (concat col2 sp))
	(when (not (equal ltype "I"))
	  (insert (concat col1 "Display\n"))))
      (when (equal type "F")
	(setq sp (concat col2 sp))
	(when (not (equal ltype "F"))
	  (insert (concat col1 "SolEQU\n"))))
      (when (equal type "G")
	(setq sp (concat col2 sp))
	(when (not (equal ltype "G"))
	  (insert (concat col1 "SolVAR\n"))))
      (when (equal type "D")
	(setq sp (concat col2 sp))
	(when (not (equal ltype "D"))
	  (insert (concat col1 "Equation\n"))))
      (when (equal type "E")
	(setq sp (concat col2 sp))
	(when (not (equal ltype "E"))
	  (insert (concat col1 "Column\n"))))
      (setq ltype type)
      (insert (concat sp iden))
      (insert "\n")
      (backward-char 1)
      (put-text-property
       (line-beginning-position) (1+ (line-end-position)) :data lnum)
      (goto-char (point-max))
      (setq buffer-undo-list nil)
      (setq al (cdr al)))
    ))

(defun gams-lxi-overlay-at (position)
  "Return gams overlay at POSITION, or nil if none to be found."
  (let ((overlays (overlays-at position))
        ov found)
    (while (and (not found) (setq ov (car overlays)))
      (setq found (and (overlay-get ov 'gams-lxi) ov)
            overlays (cdr overlays)))
    found))

(defun gams-lxi-invisible-item (beg end)
  (let ((ov (make-overlay beg end)))
    (overlay-put ov 'invisible 'gams-lxi)
    (overlay-put ov 'gams-lxi t)))

(defun gams-lxi-visible-item (beg end)
  (let ((ov (gams-lxi-overlay-at (1+ beg))))
    (when ov (delete-overlay ov))))

(defun gams-lxi-fold-all-items-first ()
  (interactive)
  (let ((buffer-read-only nil)
	beg end flag po)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^   [^ \t\n]+" nil t)
	(if beg
	    (progn
	      (forward-line -1)
	      (setq end (line-end-position))
	      (forward-line 1)
	      (when (not (equal beg end))
		(setq po (point))
		(goto-char beg)
		(beginning-of-line)
		(delete-char 3)
		(insert "[+]")
		(put-text-property
		 (line-beginning-position) end :region (list t beg end))
		(goto-char po)
		(gams-lxi-invisible-item beg end))
	      (setq beg nil))
	  (setq beg (line-end-position)))
	(setq buffer-undo-list nil))
      (when beg
	(forward-line 1)
	(when (looking-at "^     ")
	  (forward-line -1)
	  (beginning-of-line)
	  (delete-char 3)
	  (insert "[+]")
	  (put-text-property
	   (line-beginning-position) (1- (point-max)) :region (list t beg (1- (point-max))))
	  (gams-lxi-invisible-item beg (1- (point-max)))))
      )))

(defun gams-lxi-toggle-fold-all-items ()
  "Toggle fold/unfold all items."
  (interactive)
  (if gams-lxi-fold-all-items-p
      (gams-lxi-unfold-all-items)
    (gams-lxi-fold-all-items)))
      
(defun gams-lxi-fold-all-items ()
  "Fold all items."
  (let ((buffer-read-only nil)
	reg beg end flag po)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[[]-[]]" nil t)
	(setq reg (get-text-property (point) :region))
	(setq beg (nth 1 reg))
	(setq end (nth 2 reg))
	(beginning-of-line)
	(delete-char 3)
	(insert "[+]")
	(put-text-property
	 (line-beginning-position) end :region (list t beg end))
	(gams-lxi-invisible-item beg end)
	(goto-char end)))
    (message "Foled all items.")
    (setq gams-lxi-fold-all-items-p t)))

(defun gams-lxi-unfold-all-items ()
  (let ((buffer-read-only nil)
	reg beg end flag po)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[[][+][]]" nil t)
	(beginning-of-line)
	(setq reg (get-text-property (point) :region))
	(setq beg (nth 1 reg))
	(setq end (nth 2 reg))
	(gams-lxi-visible-item beg end)
	(delete-char 3)
	(insert "[-]")
	(put-text-property 
	 (line-beginning-position) end :region (list nil beg end))
	(goto-char end)))
    (message "Unfoled all items.")
    (setq gams-lxi-fold-all-items-p nil)))

(defun gams-lxi-item (&optional unfold)
  "Show the content of the current item."
  (interactive)
  (let ((data (get-text-property (point) :data))
	(reg (get-text-property (point) :region)))
    (cond
     (data
      (gams-lxi-show-item))
     ((not unfold)
      (gams-lxi-toggle-fold-item-iternal)))))

(defun gams-lxi-item-click (click)
  "Show the content of an item on the current line."
  (interactive "e")
  (mouse-set-point click)
  (gams-lxi-item))

(setq gams-lxi-follow-mode t)
(defun gams-lxi-toggle-follow-mode ()
  "Toggle follow (other window follows with context)."
  (interactive)
  (setq gams-lxi-follow-mode (not gams-lxi-follow-mode))
  (message
   (format (concat "Follow-mode is "
		   (if gams-lxi-follow-mode "on." "off.")))))

(defun gams-lxi-item-next ()
  "Move to the next item."
  (interactive)
  (next-line 1)
  (when gams-lxi-follow-mode
    (gams-lxi-item t)))

(defun gams-lxi-item-prev ()
  "Move to the previous item."
  (interactive)
  (next-line -1)
  (when gams-lxi-follow-mode
    (gams-lxi-item t)))

(defun gams-lxi-toggle-fold-item ()
  "Toggle fold/unfold items in the current tree."
  (interactive)
  (let ((reg (get-text-property (point) :region))
	(buffer-read-only nil)
	beg end)
    (beginning-of-line)
    (when reg
      (setq beg (nth 1 reg))
      (setq end (nth 2 reg))
      (if (looking-at "^     [^ \t]+")
	  ;; not [+/-] line
	  (progn
	    (re-search-backward "^[[][+-][]]" nil t)
	    (gams-lxi-invisible-item beg end)
	    (beginning-of-line)
	    (delete-char 3)
	    (insert "[+]")
	    (put-text-property 
	     (line-beginning-position) end :region (list t beg end))
	    (message "Folded the current tree.")
	    )
	;; [+/-] line
	(if (not (car reg))
	    ;; [-] line
	    (progn (gams-lxi-invisible-item beg end)
		   (beginning-of-line)
		   (delete-char 3)
		   (insert "[+]")
		   (put-text-property 
		    (line-beginning-position) end :region (list t beg end))
		   (message "Folded the current tree.")
		   )
	  ;; [+] line
	  (gams-lxi-toggle-fold-item-iternal)
	  (message "Unfolded the current tree.")
	  ))
      (beginning-of-line))))

(defun gams-lxi-calculate-region (line last)
  "line number"
  (let ((max-size gams-lxi-maximum-line)
	(tlnum gams-lxi-lst-file-total-line)
	beg-l end-l res
	beg end lnum)
    (if (>= max-size tlnum)
	(setq res (list 1 tlnum line))
      (if (not last)
	  (progn (setq beg (- line (/ max-size 2)))
		 (setq end (+ line (/ max-size 2)))
		 (when (< beg 0)
		   (setq end (+ end (* -1 beg)))
		   (setq beg 1))
		 (when (> end tlnum)
		   (setq beg (- beg (- end tlnum)))
		   (setq end tlnum))
		 (setq lnum (1+ (- line beg)))
		 (setq res (list beg end lnum)))
	(setq beg-l (car last)
	      end-l (car (cdr last)))
	(if (and (>= line (+ beg-l (/ max-size 10)))
		 (<= line (- end-l (/ max-size 10))))
	    (progn (setq lnum (1+ (- line beg-l)))
		   (setq res (list beg-l end-l lnum)))
	  (setq beg (- line (/ max-size 2)))
	  (setq end (+ line (/ max-size 2)))
	  (when (< beg 0)
	    (setq end (+ end (* -1 beg)))
	    (setq beg 1))
	  (when (> end tlnum)
	    (setq beg (- beg (- end tlnum)))
	    (setq end tlnum))
	  (setq lnum (1+ (- line beg)))
	  (setq res (list beg end lnum)))))
      res))

(defun gams-lxi-show-item-process (lst buff beg end)
  (let (com)
    (message
     (format "Importing line %s-%s from the LST file %s"
	     (number-to-string beg)
	     (number-to-string end)
	     (file-name-nondirectory lst)))
    (setq buffer-read-only nil)
    (erase-buffer)
    (setq com
	  (concat gams-lxi-import-command-name " "
		  (number-to-string beg) " "
		  (number-to-string end) " "
		  lst))
    (call-process shell-file-name nil buff nil gams:shell-c com)))

(defun gams-lxi-show-item ()
  (interactive)
  (let* ((cur-buf (current-buffer))
	 (lnum (get-text-property (point) :data))
	 (tlnum gams-lxi-lst-file-total-line)
	 (lst gams-lxi-lst-file)
	 (pbuff (gams-lxi-get-view-buffer))
	 (last gams-lxi-last-regions)
	 buff-exist-p beg-end beg end line cont)
    (when lnum
      (setq lnum (string-to-number lnum))
      (setq beg-end (gams-lxi-calculate-region lnum last))
      (setq beg (car beg-end)
	    end (car (cdr beg-end))
	    line (nth 2 beg-end))
      (setq gams-lxi-last-regions (list beg end))
      ;;
      (delete-other-windows)
      (split-window (selected-window) gams-lxi-width t)
      (other-window 1)
      ;;
      (when (get-buffer pbuff)
	(setq buff-exist-p t))
      (get-buffer-create pbuff)
      (switch-to-buffer pbuff)
      ;;
      (when (or (not (equal beg (car last)))
		(not (equal end (car (cdr last))))
		(not buff-exist-p))
	(if (<= tlnum gams-lxi-maximum-line)
	    (insert-file-contents lst)
	  (setq buffer-read-only nil)
	  (gams-lxi-show-item-process lst pbuff beg end)))
      ;;
      (setq buffer-undo-list nil)
      (setq buffer-read-only t)
      (setq truncate-lines t)
      (goto-line line) 
      (recenter 2)
      (gams-lxi-view-mode)
      (setq gams-lxi-view-lxi-buffer cur-buf)
      (other-window 1)
      ;;
      (let ((pc (/ (* 100.0 lnum) tlnum))
	    (pc-b (if (equal beg 1) 0 (/ (* 100.0 beg) tlnum)))
	    (pc-e (/ (* 100.0 end) tlnum)))
	(message
	 (concat (format "On line %d (%d%%%%) (%d%%%%-%d%%%% displayed): " lnum pc pc-b pc-e)
		 gams-lxi-key-sub)))
	 
      )))

(defun gams-lxi-toggle-fold-item-iternal (&optional po)
  (interactive)
  (let* ((reg (get-text-property (point) :region))
	 (beg (nth 1 reg))
	 (end (nth 2 reg))
	 (buffer-read-only nil))
    (save-excursion
      (when po (goto-char po))
      (beginning-of-line)
      (when (and reg (looking-at "^[[][+-][]]"))
	(if (car reg)
	    (progn
	      (gams-lxi-visible-item beg end)
	      (beginning-of-line)
	      (delete-char 3)
	      (insert "[-]")
	      (put-text-property 
	       (line-beginning-position) end :region (list nil beg end)))
	  (gams-lxi-invisible-item beg end)
	  (beginning-of-line)
	  (delete-char 3)
	  (insert "[+]")
	  (put-text-property 
	   (line-beginning-position) end :region (list t beg end))))
      )))

(defun gams-lxi-tree-next ()
  "Move to the next tree."
  (interactive)
  (let ((cur-po (point)))
    (forward-char 1)
    (if (re-search-forward "^   [^ \t]+\\|^[[][+-][]]" nil t)
	(beginning-of-line)
      (goto-char cur-po))))

(defun gams-lxi-tree-prev ()
  "Move to the previous tree."
  (interactive)
  (let ((cur-po (point)))
    (forward-char -1)
    (if (re-search-backward "^   [^ \t]+\\|^[[][+-][]]" nil t)
	(beginning-of-line)
      (goto-char cur-po))))

(defun gams-lxi-update ()
  "Update the LXI buffer."
  (interactive)
  (let ((gms-buf gams-lxi-gms-buffer))
    (switch-to-buffer gms-buf)
    (gams-lxi)
    ))

(defvar gams-lxi-key
      "[?]=help, [ /RET]=show, [x]toggle fold/unfold, [c]toggle follow mode, d,f,g,h,j,k=scroll, [q]uit.")
(defvar gams-lxi-key-sub
      "[?]=help, [ /RET]=show, [x]=fold/unfold, [q]uit.")

(defun gams-lxi-show-key ()
  "Show the basic keybindings in the GAMS-LXI mode."
  (interactive)
  (message gams-lxi-key))

(defun gams-lxi-help ()
  "Display the help for the GAMS-LXI mode."
  (interactive)
  (let ((cur-buff (current-buffer))
	(cur-po (point))
	(temp-buf (get-buffer-create "*LXI-HELP*"))
	key)
    (pop-to-buffer temp-buf)
    (setq buffer-read-only nil)
    (erase-buffer)
    (insert "[keys for GAMS-LXI mode]

SPACE/RET	Show the content of the item on the current line.
n/p	next item / previous item
c	Toggle follow-mode.
x	Toggle fold/unfold all trees
v	Toggle fold/unfold the current tree
N/P	Next tree / Previous tree

i	Back to the GMS buffer.
?	Show this help.
q	Quit.

l	Widen the LXI buffer.
o       Narrow the LXI buffer.

,	Go to the beginning of the buffer
.	Go to the end of the buffer
")
    (goto-char (point-min))
    (setq buffer-read-only t)
    (select-window (next-window nil 1))
    ))

(defun gams-lxi-widen-one-line ()
  "Widen the GAMS-LXI mode buffer by one line."
  (interactive)
  (gams-lxi-change-window-one-line))

(defun gams-lxi-narrow-one-line ()
  "Narrow the GAMS-LXI mode buffer by one line."
  (interactive)
  (gams-lxi-change-window-one-line t))

(defun gams-lxi-change-window-one-line (&optional narrow)
  "widen (narrow) GAMS-LXI mode buffer one line.
if narrow is non-nil, narrow the window."
  (interactive)
  (let ((key (this-command-keys))
	(win-num (gams-count-win)))
    (if narrow
	;; narrowing
	(cond
	 ((equal win-num 1) nil)
	 ((equal win-num 2)
	  (setq gams-lxi-width (max 10 (- gams-lxi-width 1))))
	 (t
	  (setq gams-lxi-width (max 10 (- gams-lxi-width 1)))))
      ;; widening
      (when (and (not (equal win-num 1))
		 (>= (window-width (next-window)) 8))
	(setq gams-lxi-width (+ gams-lxi-width 1))))
    (gams-lxi-show-item)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	code for indent.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;; functions for indent.

(defvar gams-regexp-declaration
      (concat
       "\\("
       "parameter[s]?\\|set[s]?\\|scalar[s]?\\|table"
       "\\|alias\\|acronym[s]?\\|\\(free\\|positive"
       "\\|negative\\|binary\\|integer\\)*[ ]*variable[s]?"
       "\\|equation[s]?\\|model[s]?"
       "\\)[ \t\n(]+")
      "regular expression for declaration type statements.")

(defvar gams-regexp-loop
  (concat (gams-regexp-opt (list "loop" "while" "if" "for" "else") t)
	  "[ \t\n]*(")
  "regular expression for loop type statements.")

(defvar gams-regexp-mpsge
  (concat (gams-regexp-opt gams-statement-mpsge t))
  "regular expression for mpsge type statements")

(defvar gams-regexp-equation
  (concat "[^.\n]*\\([.][.][^.\\/]\\)")
  "regular expression for equation definition.")

;;; 
(defvar gams-regexp-put
  (concat (gams-regexp-opt
	   (list "abort" "display" "options" "option" "files"
		 "file" "put" "putpage" "puttl"
		 "putclose" "solve")
	   t)
	  "[ \t$]?"))

(defvar gams-regexp-other
  (gams-regexp-opt
	(list "abort" "display" "option[s]?" "file" "put" "solve") t))

;;;
(defun gams-check-line-type (&optional com plus dollar slash paren)
  "Judge the type of the current line.

Return c if the current line is commented line (*, eol, inline).
Return e if the current line is empty.
Return c if the current line starts with * if com is non-nil.
Return p if the current line starts with + and if PLUS is non-nil.
Return d if the current line starts with dollar control and if DOLLAR is non-nil.
Return s if the current line starts with slash and if SLASH is non-nil.
Return k if the current line starts with ); and if PAREN is non-nil.
Otherwise nil."
  (let (flag)
    (save-excursion
      (beginning-of-line)
      (cond
       ;; Starts with *
       ((and com
	     (looking-at (concat "^[" gams-comment-prefix "]")))
	(setq flag "c"))
       ;; Commented line.
       ((and (not com)
	     (or (looking-at (concat "^[" gams-comment-prefix "]"))
		 (looking-at (concat "^[ \t]*" (regexp-quote gams-eolcom-symbol)))
		 (looking-at (concat "^[ \t]*" (regexp-quote gams-inlinecom-symbol-start)))))
	  (setq flag "c"))
       ;; Empty line.
       ((looking-at "[ \t]*$") (setq flag "e"))
       ;; Starts with +
       ((if plus (looking-at "^[+]") nil) (setq flag "p"))
       ;; Starts +
       ((if dollar (looking-at "^[$][ \t]*[a-za-z]*") nil)
	(setq flag "d"))
       ;; Starts with /
       ((if slash (looking-at "^[ \t]*/") nil)
	(setq flag "s"))
       ;; Starts with );
       ((if paren (looking-at "^[ \t]*);") nil)
	(setq flag "k"))
       (t)))
    flag))

(defun gams-search-line ()
  "Search non indented line backward.

Exclude commented lines and dollar control lines."
  (let ((cur-po (point)) flag)
    (save-excursion
      (forward-line -1)
      (catch 'found
	(while t
	  (cond
	   ((not (gams-check-line-type))
	    (cond
	     ((looking-at "^[^ \t$]+")
	      (setq flag (point))
	      (throw 'found t))
	     ((looking-at "^[$]+")
	      (cond
	       ((looking-at (concat "[$][ \t]*" gams-regexp-mpsge))
		(setq flag (point))
		(throw 'found t))
	       ((looking-at "^[$][ \t]*offtext")
		(setq flag (point))
		(throw 'found t))
	       (t (if (bobp) (throw 'found t) (forward-line -1)))))
	     (t (if (bobp) (throw 'found t) (forward-line -1)))))
	   ((bobp)
	    (throw 'found t))
	   (t
	    (forward-line -1))))))
    flag))

(defun gams-block-end-p (beg new)
  "Judge whether the block ends or not."
  (let ((cur-po (point)) temp flag)
    (save-excursion
      (goto-char beg)
      (catch 'found
	(while t
	  (if (not (re-search-forward ";" cur-po t))
	      ;; If ; is not found, escape.
	      (throw 'found t)
	    ;; If ; is found,
	    (setq temp (match-end 0))
	    (when (and (not (gams-check-line-type))
		       (not (gams-in-comment-p))
		       (not (gams-in-quote-p)))
	      (setq flag temp)
	      (throw 'found t)))))
      ;; If ; is not found and new is nil.
      (when (and (not flag) (not new))
	;; If the next line starts with a reserved word, then the
	;; declaration already ends.
	(goto-char cur-po)
	;; Forward line until a non-empty line is found.
	(while (and (not (eobp)) (gams-check-line-type))
	  (forward-line 1))
	(skip-chars-forward " \t\n")
	(when (looking-at
	       (concat gams-statement-regexp-base-sub "[^-a-zA-Z0-9_:;]+"))
	  ;; If the next line starts with a reserved word,
	  ;; no indent is necessary.
	  (setq flag cur-po))))
    flag))

(defun gams-in-comment-p ()
  "Return t if the current point is in eol comment or inline comment.
Otherwise nil."
  (let* ((cur-po (point))
	 (eol (regexp-quote gams-eolcom-symbol))
	 (inl (regexp-quote gams-inlinecom-symbol-start))
	 (inl-end (regexp-quote gams-inlinecom-symbol-end))
	 (beg (line-beginning-position))
	 (end (line-end-position))
	 cont flag reg)
    (save-excursion
      (cond
       ((and eol inl)
	(setq reg (concat eol "\\|" inl)))
       (eol (setq reg eol))
       (inl (setq reg inl)))
      ;; If either eol or inl are defined.
      (catch 'found
	(while t
	  (if (and reg (re-search-backward reg beg t))
	      (when (not (gams-in-quote-p))
		(setq cont
		      (gams*buffer-substring (match-beginning 0)(match-end 0)))
		(if (equal cont inl)
		    (when (and (re-search-forward inl-end end t)
			       (<= cur-po (point)))
		      (setq flag t))
		  (setq flag t))
		(throw 'found t))
	    (throw 'found t)))))
    flag))

(defun gams-in-quote-p ()
  "Return t if the current point is in quoted text.
Otherwise nil.

When this function misjudges, usee `gams-in-quote-p-extended'."
  (let* ((cur-po (point))
	 (beg (line-beginning-position))
	 (end (line-end-position))
	 cont flag)
    (save-excursion
      (when (re-search-backward "\"\\|'" beg t)
	(setq cont
	      (gams*buffer-substring (match-beginning 0) (match-end 0)))
	(goto-char (match-end 0))
	(when (and (re-search-forward cont end t) (<= cur-po (point)))
	  (setq flag t))))
    flag))

(defun gams-in-quote-p-extended ()
  "Return t if the current point is in quoted text.  Otherwise nil.
`gams-in-quote-p' is much faster, but it often misjudges."
  (let* ((cur-po (point))
	 (beg (line-beginning-position))
	 (end (line-end-position))
	 (left 0)
	 (right 0)
	 cont flag)
    (save-excursion
      (beginning-of-line)
      (catch 'found
	(while t
	  (if (re-search-forward "\"\\|'" end t)
	      (progn
		(setq cont
		      (gams*buffer-substring (match-beginning 0) (match-end 0)))
		(goto-char (match-end 0))
		(setq left (+ 1 left))
		(when (<= cur-po (point))
		  (throw 'found t))
		(if (re-search-forward cont end t)
		    (progn (setq right (+ 1 right))
			   (when (<= cur-po (point))
			     (throw 'found t)))
		  (throw 'found t)))
	    (setq left (+ 1 left))
	    (throw 'found t)))))
    (when (and (not (equal left 0))
	       (equal left right))
      (setq flag t))))

;; handle slash.
(defun gams-slash-in-line-p (&optional prev)
  "Judge whether the line includes slash.

Return 1 if the line contains one slash.
Return 2 if the line contains two slashes.
Return nil if the line contains no slash.

If PREV is non-nil, the line indicates the previous line."
  (let (po-end flag (count 0))
    (save-excursion
      (when prev
	(forward-line -1)
	;; back to non-empty line.
	(while (gams-check-line-type) (forward-line -1)))
      (setq po-end (line-end-position))
      (while (re-search-forward "/" po-end t)
	(when (and (not (gams-in-comment-p))
		   (not (gams-in-quote-p)))
	  (setq count (+ count 1))))
      (cond
       ((and (> count 0) (oddp count))
	(setq flag 1))
       ((and (> count 0) (evenp count))
	(setq flag 2))))
    flag))

(defun gams-judge-decl-type (line)
  "Judge the type of declaration line.

If it includes only declaration, return nil.  if it includes other
components (identifiers etc.), return the column number of identifier.  if
it includes one slash, return the column number of the word after slash.

LINE indicates the number of line to back."
  (save-excursion
    (let (po-end col-num)
      (forward-line (* -1 line))
      (setq po-end (line-end-position))
      (looking-at gams-regexp-declaration)
      (goto-char (match-end 1))
      (if (equal 1 (gams-slash-in-line-p))
	  ;; If declaration line includes slash.
	  (progn
	    (if (re-search-forward "\\(/[ \t]*\\)[^ \t\n]+" po-end t)
		;; If something appears after slash.
		(goto-char (match-end 1))
	      ;; If nothing appears after slash.
	      (skip-chars-forward " \t")
	      (cond
	       ((looking-at "[^ \t(\n]+[ \t]*[(][^)]+[)][ \t]+\\([^ /\t\n]+\\)")
		(goto-char (match-beginning 1)))
	       ((looking-at "[^ \t\n]+[ \t]+\\([^ /\t\n]+\\)")
		(goto-char (match-beginning 1)))
	       ((looking-at "\\([^ \t(\n]+\\)[ \t]*[(][^)]+[)][ \t\n]+")
		(goto-char (match-beginning 1)))
	       ((looking-at "\\([^ \t\n]+\\)[ \t\n]+")
		(goto-char (match-beginning 1)))))
	    (setq col-num (current-column)))
	;; No slash in declaration line.
	(skip-chars-backward "[ \t\n]")
	(if (re-search-forward "\\([ \t]+\\)\\([^ \t]+\\)" po-end t)
	    ;; If identifier is found.
	    (progn
	      (goto-char (match-beginning 2))
	      (setq col-num (current-column)))
	  ;; If no identifier is found.
	  (setq col-num gams-indent-number)))
      col-num)))

(defun gams-slash-end-p (beg)
  "Return t if the point is not in a slash pair."
  (let ((count 1) (cur-po (point)) flag)
    (save-excursion
      (goto-char beg)
      (while (re-search-forward "/" cur-po t)
	(when (and (not (gams-check-line-type nil nil t))
		   (not (gams-in-quote-p-extended))
		   (not (gams-in-comment-p)))
	  (setq count (+ 1 count))))
      (when (and (> count 0) (oddp count)) (setq flag t)))
    flag))

(defun gams-calculate-indent-previous (&optional line)
  "Return the indent number of the previous line
which is not an empty line.

line is the line number to go back."
  (let ((start-column (current-column))
	(point-here (point))
	indent)
    (beginning-of-line)
    (save-excursion
      (if (or (if line (forward-line (* -1 line)) nil)
	      (re-search-backward (concat "^[^" gams-comment-prefix "\n]") nil t))
	  (let ((end (save-excursion (forward-line 1) (point))))
	    ;; is start-column inside a tab on this line?
	    (if (> (current-column) start-column)
		(backward-char 1))
	    (cond
	     ((looking-at "[ \t]")
	      (skip-chars-forward " \t" end))
	     ((looking-at gams-regexp-declaration)
	      (goto-char (match-end 0))))
	    (setq indent (current-column)))))
    indent))
  
(defun gams-return-previous-slash (line)
  "Return the column number of the word after the last slash."
  (let ((cur-po (point)) (count 2)
	col po-slash flag-slash)
    (save-excursion
      (catch 'found
	(while t
	  (re-search-backward "/" nil t)
	  (when (and (not (equal "c" (gams-check-line-type)))
		     (not (gams-in-comment-p)))
	    (setq count (1- count))
	    (when (equal count 0)
	      (throw 'found t)))))
      (setq po-slash (point))
      (beginning-of-line)
      (if (looking-at "^[ \t]+/")
	  (setq col (gams-calculate-indent-previous))
	(when (looking-at gams-regexp-declaration)
	  (goto-char (match-end 0)))
	(skip-chars-forward " \t")
	(setq col (current-column)))
      col)))

(defun gams-judge-line (beg &optional type)
  "Judge the current line numbers.

Return a list of real line number, effective line number, and another line
number.

TYPE 
mpsge	=>	mpsge type
"
  (let* ((line-1 1) (line-2 1)
	 (flag-a (if (equal type "mpsge") t nil))
	 flag line-3 res)
    (save-excursion
      (forward-line -1)
      (while (>= (point) beg)
	(if (not (gams-check-line-type nil flag-a))
	    (progn (setq line-1 (+ 1 line-1))
		   (setq line-2 (+ 1 line-2))
		   (when (not flag)
		     (setq line-3 (- line-1 1))
		     (setq flag t)))
	  (setq line-1 (+ 1 line-1)))
	(when (equal 1 (point)) (setq beg 2))
	(forward-line -1)
	))
    (setq res (list line-1 line-2 line-3))
    res))

(defun gams-line-start-semicolon-p ()
  (if (looking-at "^[ \t]*;") t nil))

(defun gams-calculate-indent-decl (beg)
  "Calculate the number of indent in declaration type."
  (let* ((temp (gams-judge-line beg))
	 (line (car (cdr temp)))
	 (re-line (car temp))
	 (pre-line (car (cdr (cdr temp))))
	 slash-num indent-num)
    (beginning-of-line)
    (if (gams-line-start-semicolon-p)
	(setq indent-num 0)
      (progn
	(cond
	 ((equal line 2)
	  (if (equal "s" (gams-check-line-type nil nil nil t))
	      (progn
		(forward-line (* -1 pre-line))
		(skip-chars-forward "^ \t")
		(cond
		 ((looking-at "[ \t]+[^ \t(\n]+[ \t]*[(][^)]+[)][ \t]+\\([^ \t\n]+\\)")
		  (goto-char (match-beginning 1)))
		 ((looking-at "[ \t]+[^ \t\n]+[ \t]+\\([^ \t\n]+\\)")
		  (goto-char (match-beginning 1)))
		 ((looking-at "[ \t]+\\([^ \t(\n]+\\)[ \t]*[(][^)]+[)][ \t\n]+")
		  (goto-char (match-beginning 1)))
		 ((looking-at "[ \t]+\\([^ \t\n]+\\)[ \t\n]+")
		  (goto-char (match-beginning 1))))
		(setq indent-num (current-column)))
	    (setq indent-num (gams-judge-decl-type (- re-line 1)))))
	 ;; After third line.
	 (t (cond
	     ;; If the previous line includes one slash.
	     ((equal 1 (setq slash-num (gams-slash-in-line-p t)))
	      (if (not (gams-slash-end-p beg))
		  ;; If in slash pair
		  (let (temp-po)
		    (forward-line (* -1 pre-line))
		    (setq temp-po (line-end-position))
		    (if (re-search-forward "\\(/[ \t]*\\)[^ \t\n]+" temp-po t)
			;; If something appears after slash.
			(goto-char (match-end 1))
		      ;; If nothing appears after slash.
		      (skip-chars-forward " \t")
		      (cond
		       ((looking-at "[^ \t(\n]+[ \t]*[(][^)]+[)][ \t]*")
			(goto-char (match-end 0)))
		       ((looking-at "[^ \t\n]+[ \t]*")
			(goto-char (match-end 0)))
		       ))
		    (setq indent-num (current-column)))
		;; If not in slash pair.
		(setq indent-num (gams-return-previous-slash pre-line))))
	     ;; If the previous line includes two slashes.
	     ((equal 2 slash-num)
	      (setq indent-num (gams-return-previous-slash pre-line)))
	     ;; If the previous line includes no slash.
	     (t
	      (if (equal "s" (gams-check-line-type nil nil nil t))
		  ;; If the current line starts with slash.
		  (if (not (gams-slash-end-p beg))
			(setq indent-num (gams-calculate-indent-previous pre-line))
		    ;;
		    (let (temp-po)
		      (forward-line (* -1 pre-line))
		      (setq temp-po (line-end-position))
		      (cond
		       ((re-search-forward "\\(/[ \t]*\\)[^ \t\n]+" temp-po t)
			;; if slash exists and if something appears after slash.
			(goto-char (match-end 1)))
		       ;; if slash exists and if nothing appears after slash.
		       ((re-search-forward "\\(/[ \t]*\\)[ \t\n]+" temp-po t)
			(skip-chars-forward " \t")
			(cond
			 ((looking-at "[^ \t(\n]+[ \t]*[(][^)]+[)][ \t]*")
			  (goto-char (match-end 0)))
			 ((looking-at "[^ \t\n]+[ \t]*")
			  (goto-char (match-end 0)))))
		       ;; if slash doesn't exits.
		       (t
			(cond
			 ((looking-at "^[ \t]*[^ \t(\n]+[ \t]*[(][^)]+[)][ \t]+\\([^ \t\n]+\\)")
			  (goto-char (match-beginning 1)))
			 ((looking-at "^[ \t]*\\([^ \t(\n]+\\)[ \t]*[(][^)]+[)][ \t]+\\([ \t\n]+\\)")
			  (goto-char (match-beginning 1)))
			 ((looking-at "^[ \t]*[^ \t\n]+[ \t]+\\([^ \t\n]+\\)")
			  (goto-char (match-beginning 1)))
			 ((looking-at "^[ \t]*\\([^ \t\n]+\\)[ \t\n]+")
			  (goto-char (match-beginning 1))))))
		      (setq indent-num (current-column))
		      ))
		;; If current line does not starts with slash.
		(setq indent-num (gams-calculate-indent-previous pre-line)))))))))
    indent-num))

(defun gams-judge-decl-type-light (line)
  "Judge the type of declaration line.

If it includes only declaration, return nil.  if it includes other
components (identifiers etc.), return the column number of identifier. 

LINE indicates the number of line to back.
Almost same as `gams-judge-decl-type'."
  (save-excursion
    (let (po-end col-num)
      (forward-line (* -1 line))
      (setq po-end (line-end-position))
      (looking-at gams-regexp-declaration)
      (goto-char (match-end 1))
      (skip-chars-forward " \t")
      (if (equal 1 (gams-slash-in-line-p))
	  ;; If declaration line includes slash.
	  (progn
	    (when (re-search-forward "\\(/[ \t]*\\)[^ \t\n]+" po-end t)
	      ;; If something appears after slash.
	      (goto-char (match-end 1)))
	      ;; If nothing appears after slash.
	    (setq col-num (current-column)))
	;; No slash in declaration line.
	(skip-chars-backward "[ \t\n]")
	(if (re-search-forward "\\([ \t]+\\)\\([^ \t]+\\)" po-end t)
	    ;; If identifier is found.
	    (progn
	      (goto-char (match-beginning 2))
	      (setq col-num (current-column)))
	  ;; If no identifier is found.
	  (setq col-num gams-indent-number)))
      col-num)))

;; gams-calculate-indent-decl-light
(defun gams-calculate-indent-decl-light (beg)
  "Calculate the number of indent in declaration type.
Almost same as `gams-calculate-indent-decl'."
  (let* ((temp (gams-judge-line beg))
	 (line (car (cdr temp)))
	 (re-line (car temp))
	 (pre-line (car (cdr (cdr temp))))
	 slash-num indent-num)
    (beginning-of-line)
    (if (gams-line-start-semicolon-p)
	;; If the current line starts with a semicolon, it is the last
	;; line of the declaration block.
	(setq indent-num 0)
      ;; If the current line does not start with a semicolon, it is the
      ;; line inside the declaration block.
      (progn
	(cond
	 ((equal line 2)
	  ;; If the current line is the second line of the declaration
	  ;; part.
	  (if (equal "s" (gams-check-line-type nil nil nil t))
	      ;; If the current line starts with slash.
	      (progn
		(forward-line (* -1 pre-line))
		(skip-chars-forward "^ \t")
		(skip-chars-forward " \t")
		(setq indent-num (current-column)))
	    ;; If the current line does not start with slash.
	    (setq indent-num (gams-judge-decl-type-light (- re-line 1)))))
	 (t
	  ;; If the current line is after the second line of the
	  ;; declaration part.
	  (cond
	   ((equal 1 (setq slash-num (gams-slash-in-line-p t)))
	    ;; If the previous line includes one slash.
	    (if (not (gams-slash-end-p beg))
		;; If in slash pair
		(let (temp-po)
		  (forward-line (* -1 pre-line))
		  (setq temp-po (line-end-position))
		  (if (re-search-forward "\\(/[ \t]*\\)[^ \t\n]+" temp-po t)
		      ;; If something appears after slash.
		      (goto-char (match-end 1))
		    ;; If nothing appears after slash.
		    (skip-chars-forward " \t")
		    (cond
		     ((looking-at "[^ \t(\n]+[ \t]*[(][^)]+[)][ \t]*")
		      (goto-char (match-beginning 0)))
		     ((looking-at "[^ \t\n]+[ \t]*")
		      (goto-char (match-beginning 0)))
		     ))
		  (setq indent-num (current-column)))
	      ;; If not in slash pair.
	      (setq indent-num (gams-return-previous-slash pre-line))))
	   ;; If the previous line includes two slashes.
	   ((equal 2 slash-num)
	    (setq indent-num (gams-return-previous-slash pre-line)))
	   ;; If the previous line includes no slash.
	   (t
	    (if (not (equal "s" (gams-check-line-type nil nil nil t)))
		;; If current line does not starts with slash.
		(setq indent-num (gams-calculate-indent-previous pre-line))
	      ;; If the current line starts with slash.
	      (if (not (gams-slash-end-p beg))
		  ;; If the slash pair already ends.
		  (setq indent-num (gams-calculate-indent-previous pre-line))
		;; If in the slash pair.
		(let (temp-po)
		  (forward-line (* -1 pre-line))
		  (setq temp-po (line-end-position))
		  (cond
		  ((re-search-forward "\\(/[ \t]*\\)[^ \t\n]+" temp-po t)
		  ;; if slash exists and if something appears after slash.
		   (goto-char (match-end 1)))
		  ((re-search-forward "\\(/[ \t]*\\)[ \t\n]+" temp-po t)
		   ;; if slash exists and if nothing appears after slash.
		   (skip-chars-forward " \t")
		   (cond
		    ((looking-at "[^ \t(\n]+[ \t]*[(][^)]+[)][ \t]*")
		     (goto-char (match-end 0)))
		    ((looking-at "[^ \t\n]+[ \t]*")
		     (goto-char (match-end 0)))))
		  ;; if slash doesn't exits.
		  (t
		   (skip-chars-forward " \t")))
		  (setq indent-num (current-column)))
		))))))))
    indent-num))

(defun gams-calculate-indent-mpsge (beg)
  "Calculate the number of indent in mpsge block."
  (if (looking-at "[ \t]*[+]")
      ;; If the line starts with "+"  no indent.
      nil
    ;; Other line.
    (let* ((temp (gams-judge-line beg "mpsge"))
	   (cur-line (car (cdr temp)))
	   (line (car (cdr (cdr temp)))))
      (if (equal cur-line 2)
	  ;; The second line.
	  gams-indent-number-mpsge
	;; The line after third.
	(gams-calculate-indent-previous line)))))

(defun gams-calculate-indent-other (beg &optional new)
  "Calculate the number of indent of other types."
  (let* (p-alist p-close
	 p-list
	 (indent gams-indent-number))
    (beginning-of-line)
    (setq p-close (gams-parenthesis-close-p))
    ;; Parenthesis list:
    (setq p-alist (gams-count-parenthesis beg))
    (when p-alist
      (setq p-list (gams-create-list-from-alist-1 p-alist))
      (cond
       (p-close
	(goto-char (car p-list))
	(beginning-of-line)
	(skip-chars-forward " \t")
	(setq indent (current-column)))
       (t
	(if (gams-point-included-in-prev-line-p (car (cdr (car p-alist))))
	    (progn
	      (gams-back-previous-line)
	      (skip-chars-forward " \t")
	      (setq indent (+ gams-indent-number (current-column))))
	  (goto-char (car (cdr (car p-alist))))
	  (beginning-of-line)
	  (skip-chars-forward " \t")
	  (setq indent (+ (current-column) gams-indent-number))))
	))
    indent))

(defun gams-judge-equ-type (line)
  "Examine the type of equation definition line.

If the line ends with .., return nil.  otherwise, return the column-number
of ..  line is line number."
  (save-excursion
    (let (po-end col-num)
      (forward-line (* -1 line))
      (setq po-end (line-end-position))
      (beginning-of-line)
      (looking-at gams-regexp-equation)
      (goto-char (match-end 0))
      (skip-chars-backward "[ \t\n]")
      (if (re-search-forward "\\([ \t]+\\)\\([^ \t]+\\)" po-end t)
	  (progn
	    (goto-char (match-beginning 2))
	    (setq col-num (current-column))) ;
	(setq col-num gams-indent-number-equation))
      col-num)))

(defun gams-check-dollar-line ()
  "Return t if the current line starts with a dollar control.
Otherwise nil."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t")
    (if (looking-at "[$][ \t]*[a-za-z]+[0-9]*") t nil)))

(defun gams-calculate-indent-equation (beg &optional new)
  "Calculate the indent number in equation type."
  (let* ((temp (gams-judge-line beg))
	 (re-line (car temp))
	 (ef-line (car (cdr temp)))
	 (ba-line (car (cdr (cdr temp))))
	 indent-num)
    (cond
     ;; the second line.
     ((equal ef-line 2)
      (if new
	  (setq indent-num (gams-judge-equ-type ba-line))
	(setq indent-num nil)))
     ;; other.
     (t
      (if new
	  (setq indent-num (gams-calculate-indent-prev-equ beg (- re-line 1)))
	(setq indent-num nil))))
    indent-num))

;; Unnecesarry?
(defun gams-in-mpsge-block-p (&optional cp)
  "Return t if the current line is in mpsge block.
Otherwise nil."
  (let ((po (or cp (point)))
	flag-beg po-beg flag)
    (save-excursion
       (when (re-search-backward "^$[ \t]*\\(on\\|off\\)text" nil t)
	(setq flag-beg (downcase (gams*buffer-substring (match-beginning 1)
							(match-end 1))))
	(setq po-beg (match-beginning 0))
	(when (equal flag-beg "on")
	  ;; If ontext found, search $model.
	  (when (re-search-forward "^[ \t]*$model" po t)
	    (setq flag t)))))
    flag))

;;; New functions.
(defun gams-in-loop-block-p (beg)
  "Calculate the number of loop type statements before the current point.
BEG is the point of the first loop statement where the search begins."
  (let ((cur-po (point)) temp)
    (save-excursion
      (goto-char beg)
      (while (re-search-forward
	      (concat "^[ \t]*" gams-regexp-loop) cur-po t)
	(setq temp (cons (match-beginning 0) temp))))
    temp))

(defun gams-loop-end-p (beg cur)
  (let ((c-left 0) (c-right 0)
	flag temp)
    (save-excursion
      (goto-char beg)
      (catch 'found
	(while t
	  (if (re-search-forward "\\([)]\\|[(]\\)" cur t)
	      (if (not (gams-check-line-type))
		  (progn
		    (setq temp (gams*buffer-substring (match-beginning 1)
						      (match-end 1)))
		    (if (equal "(" temp)
		      (setq c-left (+ 1 c-left))
		      (setq c-right (+ 1 c-right))
		      (when (equal c-left c-right)
			(setq flag (match-end 0))
			(throw 'found t)))))
	    (throw 'found t)))))
    flag))

(defun gams-parenthesis-close-p ()
  "Return t if the line starts with closing parenthesis."
  (save-excursion
    (if (looking-at "[ \t]*)[ \t]*[;]?") t nil)))

(defun gams-calculate-indent-loop (beg)
  (let* ((cur-po (point))
	 p-alist p-close cond-end-po b-alist
	 p-list
	 l-list
	 np-list			; Number of parenthesis not closed.
	 nl-list			; Number of loop
	 line
	 po-else
	 indent)
    ;; Calculate the number of loop.
    ;; Retrun the loop level.
    (beginning-of-line)
    (setq p-close (gams-parenthesis-close-p))
    ;; Parenthesis list:
    (setq p-alist (gams-count-parenthesis beg))
    (if (not p-alist)
	(setq indent 0)
      (setq p-list (gams-create-list-from-alist-1 p-alist))
      (setq l-list (gams-create-list-from-alist-2 p-alist))
      (setq np-list (list-length p-list))
      (setq nl-list (list-length l-list))
      (setq po-else (gams-search-else-back (car l-list)))

      (when (not (looking-at "[ \t]*else\\(if\\)*"))
	(setq cond-end-po
	      (gams-condition-part-end
	       cur-po
	       (or po-else (car l-list))))
	(when cond-end-po
	  (when (setq b-alist (gams-return-block-alist cond-end-po))
	    (setq line (gams-count-line-in-block (car (car b-alist)))))))

      (cond
       ((looking-at "[ \t]*else")
	(goto-char (car p-list))
	(beginning-of-line)
	(skip-chars-forward " \t")
	(setq indent (current-column)))
       ((not cond-end-po)
	(goto-char (car l-list))
	(beginning-of-line)
	(skip-chars-forward " \t")
	(setq indent (+ (current-column) gams-indent-number)))
       (p-close
	(goto-char (car p-list))
	(beginning-of-line)
	(skip-chars-forward " \t")
	(setq indent (current-column)))
       (t
	(if (gams-point-included-in-prev-line-p (car (cdr (car p-alist))))
	    (progn
	      (gams-back-previous-line)
	      (skip-chars-forward " \t")
	      (setq indent (+ gams-indent-number (current-column))))
	  (cond
	   ((or (not line) (equal line 1))
	    (if (> (list-length b-alist) 1)
		(progn (goto-char (car (car (cdr b-alist))))
		       (skip-chars-forward " \t")
		       (setq indent (current-column)))
	      (goto-char (car (cdr (car p-alist))))
	      (beginning-of-line)
	      (skip-chars-forward " \t")
	      (setq indent (+ (current-column) gams-indent-number))))
	   ((equal line 2)
	    (goto-char (car (car b-alist)))
	    (skip-chars-forward " \t")
	    (setq indent (+ (current-column) gams-indent-number)))
	   ((> line 2)
	    (if (equal (car p-list) (car l-list))
		(progn (gams-back-previous-line)
		       (skip-chars-forward " \t")
		       (setq indent (current-column)))
	      (goto-char (car p-list))
	      (beginning-of-line)
	      (skip-chars-forward " \t")
	      (setq indent (+ gams-indent-number (current-column)))))
	   (t
	    (setq indent 10)))))))
    indent))

(defun gams-in-table-block-p ()
  "Judge whether the current point in table block.
Return t if the point is in table block."
  (let ((cur-po (point)) po-a flag)
    (save-excursion
      (if (setq po-a (re-search-backward
		      (concat "^[ \t]*" gams-regexp-declaration) nil t))
	  (progn
	    (when (string-match "table" (gams*buffer-substring (match-beginning 1)
							       (match-end 1)))
	      (goto-char cur-po)
	      (if (gams-block-end-p po-a nil)
		  (setq flag nil)
		(setq flag t))))
	(setq flag nil)))
    flag))

(defun gams-in-on-off-text-p ()
  "Return t if the current line is in ontext-offtext pair.  Otherwise
return nil.  Note that when the cursor is in mpsge block, return nil."
  (let ((cur-po (point))
	flag-beg po-beg flag-end po-end)
    (save-match-data
      (save-excursion
	(when (re-search-backward "^$[ \t]*\\(on\\|off\\)text" nil t)
	  (setq flag-beg (downcase (gams*buffer-substring
				    (match-beginning 1) (match-end 1))))
	  (forward-line 1)
	  (setq po-beg (point))
	  (when (equal flag-beg "on")
	    ;; If ontext found, search offtext.
	    (goto-char cur-po)
	    (when (re-search-forward "^$[ \t]*\\(on\\|off\\)text" nil t)
	      (setq flag-end (downcase (gams*buffer-substring
					(match-beginning 1) (match-end 1))))
	      (beginning-of-line)
	      (setq po-end (point))
	      (when (equal flag-end "off")
		;; If offtext found, then check whether mpsge block or not.
		(unless (progn (goto-char po-beg)
			       (re-search-forward "$model:" po-end t))
		  ;; Not in mpsge block.
		  (list po-beg po-end))))))))))

(defun gams-get-indent-for-put (&optional line)
  (save-excursion
    (forward-line (* -1 line))
    (when (looking-at
	   "^[ \t]*\\(abort\\|display\\|file\\|option\\[s\\]\\?\\|put\\|solve\\)[ \t]*\\([^ \t\n]*\\)")
      (goto-char (match-beginning 2))
      (current-column))))

(defun gams-calculate-indent-put (beg &optional new)
  "calculate the number of indent of put type."
  (let (temp line back indent-num)
    (save-excursion
      (setq temp (gams-judge-line beg))
      (setq line (car (cdr temp)))
      (setq back (car (cdr (cdr temp))))
      ;; judge put type environment ends or not.
      (cond
       ((equal 1 line)
	(setq indent-num (gams-get-indent-for-put line)))
       ((equal line 2)
	(setq indent-num (gams-get-indent-for-put back)))
       (t
	(setq indent-num (gams-calculate-indent-previous back)))))
    indent-num))

(defun gams-calculate-indent (&optional column)
  "Calculate necessary indent number and return it.

If any change is unnecessary for the current line, return nil.  When this
command is evoked by `gams-newline-and-indent', the column number column
is supplied.  Otherwise, column is nil."
  (let ((new (if gams-indent-equation-on t column))
	else-flag
	new*match indent-num)
        (save-excursion
      (if (gams-in-on-off-text-p)
	  ;; If the current point is in an ontext-offtext pair, do
	  ;; nothing.
	  nil
	;; If not in ontext-offtext pair.
	(let* ((cur-po (save-excursion (beginning-of-line) (point)))
	       ;; check the current line starts with a dollar control.
	       (dol (gams-check-dollar-line))
	       ;; check the type of the current line.
	       (type (gams-check-line-type t))
	       ;; other local variables.
	       com times table)
	  ;; Judge 
	  (cond
	   ;; Judge whether the current line is not commented line.
	   ((not (equal "c" type)))
	   ;; The line starts with *, but it is multiplication symbol if
	   ;; new is non-nil.
	   ((and (equal "c" type) (or (equal column nil)
				      (equal column 0)))
	    (setq com t))
	   ;; 
	   (t (setq times t)))
	  ;; Judge whether the current line is a commented line or dollar
	  ;; line.
	  (if (or com dol)
	      ;; If commented-line or dollar control line, indent is zero.
	      (setq indent-num 0)
	    ;; If neither commented line nor dollar control line
	    (if times
		;; If the current line starts with * and this commented is
		;; evoked by `gams-newline-and-indent', insert a space
		;; temporarily.
		(insert " "))
	    ;; Search the zero indent line.
	    (catch 'found
	      (while t
		(setq else-flag nil)
		(if (not (setq new*match (gams-search-line)))
		    (setq indent-num 0)
		  (goto-char new*match)
		  ;; Various cases.
		  (cond
		   ((looking-at "[ \t]*else")
		    (setq else-flag t))
		   ;; Declaration block.
		   ((looking-at (concat "^" gams-regexp-declaration))
		    (if (string-match
			 "table"(gams*buffer-substring (match-beginning 0)
						       (match-end 0)))
			(setq table t)
		      (setq table nil))
		    (goto-char cur-po)
		    ;; Whether the declaration block already ends?
		    (if (gams-block-end-p new*match column)
			;; Yes.
			(setq indent-num 0)
		      ;; Not end.
		      (if table
			  (setq indent-num nil)
			(setq indent-num
			      (if gams-indent-more-indent
				  (gams-calculate-indent-decl new*match)
				(gams-calculate-indent-decl-light new*match))
			      ))))
		   ;; Loop block.
		   ((looking-at (concat "^" gams-regexp-loop))
		    (goto-char cur-po)
		    (let ((flag (if (gams-parenthesis-close-p) t nil)))
		      (when flag (re-search-forward ")" nil t))
		      (setq indent-num (gams-calculate-indent-loop new*match))))
		   ;; Put block.
		   ((looking-at (concat "^[ \t]*" gams-regexp-put))
		    (goto-char cur-po)
		    ;; Put ends?
		    (if (gams-block-end-p new*match column)
			;; Yes.
			(setq indent-num 0)
		      ;; No.
		      (setq indent-num (gams-calculate-indent-put new*match))))
		   ;; MPSGE block.
		   ((looking-at (concat "^[$][ \t]*" gams-regexp-mpsge))
		    (goto-char cur-po)
		    (setq indent-num (gams-calculate-indent-mpsge new*match)))
		   ;; $offtext.
		   ((looking-at "^[$][ \t]*offtext")
		    (setq indent-num 0))
		   ;; Equation definition block.
		   ((looking-at gams-regexp-equation)
		    ;; cases: if there is ; before cur-po, the equation
		    ;; definition already ends.
		    (goto-char cur-po)
		    (if (gams-block-end-p new*match column)
			;; ends.
			(setq indent-num 0)
		      ;; does not end.
		      (goto-char cur-po)
		      (setq indent-num
			    (gams-calculate-indent-equation new*match new))))
		   ;; The line starts with + in mpsge block.
		   ((looking-at "^[+]")
		    (let (match-plus)
		      (re-search-backward (concat "^[$][ \t]*" gams-regexp-mpsge
						  "\\|"
						  "^[ \t]*table")
					  nil t)
		      (setq match-plus (gams*buffer-substring
					(match-beginning 0)
					(match-end 0)))
		      (setq new*match (match-beginning 0))
		      (goto-char cur-po)
		      (if (string-match "table" match-plus)
			  (setq indent-num nil)
			(setq indent-num (gams-calculate-indent-mpsge new*match)))))
		   ;; Zero indent line in table block.
		   ((progn (goto-char cur-po) (gams-in-table-block-p))
		    (setq indent-num nil))
		   ;; Other cases.
		   (t
		    (goto-char cur-po)
		    (if (gams-block-end-p new*match column)
			(setq indent-num 0)
		      (if (setq cur-po (gams-in-declaration-p))
			  (setq indent-num
				(if gams-indent-more-indent
				    (gams-calculate-indent-decl cur-po)
				  (gams-calculate-indent-decl-light cur-po)))
			(setq indent-num (gams-calculate-indent-other new*match new)))))
		   ))
		(when (not else-flag) (throw 'found t))
		))))))
	indent-num))

;;; functions for indent.  from indent.el
(defun gams-newline-and-indent ()
  "Insert a newline, then indent.
Indent is done using `gams-indent-line'."
  (interactive "*")
  (let ((column (current-column)))
    (delete-horizontal-space)
    (newline)
    (funcall 'gams-indent-line column)))

(defun gams-remove-indent (beg end)
  "Remove all the indents in a specified region.
the indent in a line that starts with * is not removed."
  (interactive "r")
  (save-excursion
    (goto-char beg)
    (while (and (< (point) end) (not (eobp)))
      (when (and (re-search-forward "^[ \t]+\\(\\*?\\)" (line-end-position) t)
	         (not (equal "*" (gams*buffer-substring
				  (match-beginning 1) (match-end 1)))))
	    (delete-region (match-beginning 0) (match-end 0)))
      (forward-line 1))))

(defun gams-indent-line (&optional column)
  "Indent the current line.

If this command is evoked by `gams-newline-and-indent', the column number
is provided by COLUMN."
  (interactive)
  (if column
      (gams-indent-function column)
    (beginning-of-line)
    (gams-indent-function nil)))
;;     (if (looking-at "^[ \t]*\n")
;; 	(delete-region (point) (line-end-position))
;;       (gams-indent-function nil))))

(defun gams-indent-function (&optional column unindented-ok)
  "Indent function in GAMS mode."
  (if (and abbrev-mode
	   (eq (char-syntax (preceding-char)) ?w))
      (expand-abbrev))
  (let* ((cur-column (current-column))
	 (indent-num (gams-calculate-indent column))
	 (cur-indent
	  (save-excursion
	    (beginning-of-line)
	    (skip-chars-forward " \t")
	    (current-column))))
    (beginning-of-line)
    (cond
     ((not indent-num)
      (move-to-column cur-column))
     ((and (equal cur-indent indent-num)
	   (equal indent-num 0))
      (move-to-column cur-column))
     ((equal cur-indent indent-num)
      (move-to-column indent-num))
     (t
      (re-search-forward "^[ \t]*" nil t)
      (delete-region (match-beginning 0)
		     (match-end 0))
      (indent-to indent-num)))))

(defun gams-condition-part-end (cur start)
  "Return the point of the condition part."
  (let* ((p-l 0)
	 (p-r 0)
	 end)
    (save-excursion
      (goto-char start)
      (if (looking-at "\\(else\\)[^iI]")
	  (setq end (match-end 1))
	(catch 'found
	  (while t
	    (if (not (re-search-forward "\\([,]\\)\\|\\([(]\\)\\|\\([)]\\)" cur t))
		(throw 'found t)
	      (cond
	       ((match-beginning 1)
		(when (equal p-l p-r)
		  (setq end (match-end 1))
		  (throw 'found t)))
	       ((match-beginning 2)
		(setq p-l (1+ p-l)))
	       ((match-beginning 3)
		(setq p-r (1+ p-r)))))))))
      end))


(defun gams-count-parenthesis (beg)
  "Count the number of parenthesis from beg to the current point.
Alist of (L . POINT)
L - t if loop, nil if not loop.
POINT - point of the parenthesis."
  (let ((cur-po (point))
	p-alist)
    (save-excursion
      (goto-char beg)
      (catch 'found
	(while t
	  (if (not (re-search-forward
		    "\\(else\\|for\\|if\\|loop\\|while\\)*[ \t]*\\([(]\\)\\|\\([)]\\)"
		    cur-po t))
	      (throw 'found t)
	    (when (not (gams-check-line-type))
	      (cond
	       ((match-beginning 2)
		(if (match-beginning 1)
		    (setq p-alist (cons (list t (point)) p-alist))
		  (setq p-alist (cons (list nil (point)) p-alist))))
	       ((match-beginning 3)
		(setq p-alist (cdr p-alist)))))))))
    p-alist))

(defun gams-back-previous-line ()
  "Back to the effective previous line."
  (forward-line -1)
  (while (gams-check-line-type)
    (forward-line -1)))

(defun gams-point-included-in-prev-line-p (po)
  "Return t if PO is in the previous line."
  (save-excursion
    (gams-back-previous-line)
    (and (<= (point) po)
	 (<= po (line-end-position)))))

(defun gams-calculate-indent-prev-equ (beg line)
  ""
  (let ((cur-po (point))
	p-alist n-list indent p-close)
    (beginning-of-line)
    (setq p-close (gams-parenthesis-close-p))
    (save-excursion
      (setq p-alist (gams-count-parenthesis beg))
      (setq n-list (list-length p-alist))
      (if (equal n-list 0)
	  (progn
	    (goto-char (gams-return-equ-def-point beg))
	    (skip-chars-forward " \t")
	    (setq indent (current-column)))
	(if p-close
	    (progn
	      (goto-char (car (cdr (car p-alist))))
	      (beginning-of-line)
	      (skip-chars-forward " \t")
	      (setq indent (current-column)))
	  (goto-char cur-po)
	  (if (gams-point-included-in-prev-line-p (car (cdr (car p-alist))))
	      (progn
		(gams-back-previous-line)
		(skip-chars-forward " \t")
		(setq indent (+ gams-indent-number (current-column))))
	    (goto-char (car (cdr (car p-alist))))
	    (beginning-of-line)
	    (skip-chars-forward " \t")
	    (setq indent (+ gams-indent-number (current-column))))
	  )))
    indent))

(defun gams-return-equ-def-point (beg)
  "Return the startign point of equation definition."
  (let ((cur-po (point))
	po)
    (save-excursion
      (goto-char beg)
      (forward-line 1)
      (catch 'found
	(while t
	  (if (<= (point) cur-po)
	      (if (gams-check-line-type)
		  (forward-line 1)
		(setq po (point))
		(throw 'found t))
	    (throw 'found t)))))
    po))


(defun gams-search-semicolon (beg end)
  (let (po)
    (save-excursion
      (goto-char beg)
      (catch 'found
	(while t
	  (if (re-search-forward ";" end t)
	      (when (not (gams-check-line-type))
		(setq po (point))
		(throw 'found t))
	    (throw 'found t)))))
    po))

(defun gams-search-else-back (limit)
  (let (po)
    (save-excursion
      (catch 'found
	(while t
	  (if (re-search-backward "else\\(if\\)*" (or limit nil) t)
	      (when (not (gams-check-line-type))
		(setq po (match-beginning 0))
		(throw 'found t))
	    (throw 'found t)))))
    po))

(defun gams-return-block-alist (beg)
  (let ((cur-po (point))
	b-beg b-end
	b-alist)
    (save-excursion
      (goto-char beg)
      (forward-line 1)
      (catch 'found
	(while t
	  (if (<= (point) cur-po)
	      (if b-beg
		  (if (setq b-end (gams-search-semicolon (point) cur-po))
		      (progn (setq b-alist (cons (list b-beg b-end) b-alist))
			     (setq b-beg nil)
			     (goto-char b-end)
			     (forward-line 1))
		    (setq b-alist (cons (list b-beg nil) b-alist))
		    (throw 'found t))
		(if (not (gams-check-line-type t nil t))
		    (if (looking-at "[ \t]*else\\(if\\)*")
			(progn
			  (goto-char (match-end 0))
			  (goto-char (gams-search-semicolon (point) cur-po))
			  (forward-line 1))
		      (setq b-beg (point)))
		  (forward-line 1)))
	    (throw 'found t)))))
    b-alist))

(defun gams-count-line-in-block (beg)
  (let ((line 1)
	(cur-po (point)))
    (save-excursion
      (goto-char beg)
      (forward-line 1)
      (catch 'found
	(while t
	  (if (<= (point) cur-po)
	      (progn
		(when (not (gams-check-line-type t nil t))
		  (setq line (1+ line)))
		(forward-line 1))
	    (throw 'found t)))))
    line))

(defun gams-create-list-from-alist-1 (alist)
  (let (li c-part)
    (while alist
      (setq c-part (car alist))
      (setq li (cons (car (cdr c-part)) li))
      (setq alist (cdr alist)))
    (reverse li)))

(defun gams-create-list-from-alist-2 (alist)
  (let (li c-part)
    (while alist
      (setq c-part (car alist))
      (when (car c-part)
	(setq li (cons (car (cdr c-part)) li)))
      (setq alist (cdr alist)))
    (reverse li)))

;;; Functions for eol and inline comment.

(defun gams-search-dollar-comment ()
  "Search comment dollar control option.
If it is found, return the matched content."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "^\\([$]\\)[ \t]*comment[ \t]+\\([^ \t\n]+\\)" nil t)
      (gams*buffer-substring (match-beginning 2) (match-end 2)))))

(defun gams-search-dollar-com (&optional eol)
  "Search inline or eolcom dollar control option.  If it is found, return the
  matched content.  If EOL is non-nil, search eol dollar control option."
  (let ((regexp-1 (if eol "eolcom" "inlinecom"))
	(regexp-2 (if eol "\\([^ \t\n]+\\)[ \t\n]?"
		    "\\([^ \t\n]+\\)[ \t]+\\([^ \t\n]+\\)"))
	match po-beg cont)
    (save-excursion
      (goto-char (point-min))
      (catch 'found
	(while t
	  (if (re-search-forward regexp-1 nil t)
	      (progn (setq po-beg (match-end 0))
		     (beginning-of-line)
		     (if (looking-at "^[$]")
			 (progn (goto-char po-beg)
				(skip-chars-forward " \t")
				(looking-at regexp-2)
				(setq cont
				      (if eol (gams*buffer-substring (match-beginning 1)
								     (match-end 1))
					(cons
					 (gams*buffer-substring (match-beginning 1)
								(match-end 1))
					 (gams*buffer-substring (match-beginning 2)
								(match-end 2)))))
				(throw 'found t))
		       (goto-char po-beg)))
	    (throw 'found t)))))
    cont))
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	code for inserting end-of-line and inline comments.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The codes below are for inserting end-of-line and inline comments.  In
;; principle, they cannot handle multi-character comment symbols.
;;

;;;; Comment indent
(substitute-all-key-definition
 'comment-dwim 'gams-comment-dwim gams-mode-map)

;;; From newcomment.el
(defun gams-comment-search-forward (starter limit)
  "Find a comment start between point and LIMIT.
Moves point to inside the comment and returns the position of the
comment-starter.  If no comment is found, moves point to LIMIT
and raises an error or returns nil of NOERROR is non-nil."
  (if (search-forward starter limit t)
      (progn (goto-char (match-end 0))
	     (match-beginning 0))
    (goto-char limit) nil))

(defun gams-comment-dwim (&optional arg)
  "Insert end-of-line comment.
If you attach the universal-argument, you can select the end-of-line
comment symbol.  Otherwise, the value of `gams-eolcom-symbol-default' is
used as the end-of-line comment symbol.  In mpsge block, ! is always used
as end-of-line comment symbol."
  (interactive "*P")
  (gams-comment-dwim-internal arg))

(defun gams-comment-dwim-inline (&optional arg)
  "Insert inline comment.
If you attach the universal-argument, you can select the inline comment
symbol.  Otherwise, the values of `gams-inlinecom-symbol-start' and
`gams-inlinecom-symbol-end' are used as the inline comment symbols."
  (interactive "*P")
  (gams-comment-dwim-internal arg t))

(defun gams-comment-dwim-internal (arg &optional inline)
  "Insert the end-of-line or inline comment.
Non-nil of INLINE means the inline comment.
In mpsge block, ! is always used as end-of-line comment symbol."
  (let ((flag (if inline nil t))
	starter ender temp)
    (if flag
	;; MPSGE or eol comment.
	(progn (setq ender nil)
	       (let ((mpsge (if (gams-in-mpsge-block-p) t nil)))
		 (if mpsge
		     (setq starter "!")
		   (if (or arg (not gams-eolcom-symbol))
		       (progn
			 ;;
			 (message
			  (concat "Do you want to define end-of-line comment symbol?"
				  "  Type y if yes."))
			 (when (equal (read-char) ?y)
			   (setq starter
				 (read-string "Insert end-of-line comment symbol: "
					      gams-eolcom-symbol-default))
			   (setq gams-eolcom-symbol starter)
			   (gams-insert-comment-symbol-def starter)))
		     (setq starter gams-eolcom-symbol)))))
      ;; inline comment.
      (if (or arg (not gams-inlinecom-symbol-start))
	  (progn
	    (message (format (concat "Do you want to define inline comment symbol?"
				     "  Type y if yes.")))
	    (if (equal (read-char) ?y)
		;;
		(let (pref1 pref2)
		  (setq starter
			(read-string "Insert inline comment start symbol: "
				     gams-inlinecom-symbol-start-default))
		  (setq ender
			(read-string "Insert inline comment end symbol: "
				     gams-inlinecom-symbol-end-default))
		  (setq gams-inlinecom-symbol-start starter)
		  (setq gams-inlinecom-symbol-end ender)
		  (gams-insert-comment-symbol-def starter ender))))
	(if gams-inlinecom-symbol-start
	    (progn (setq starter gams-inlinecom-symbol-start)
		   (setq ender gams-inlinecom-symbol-end)))))
    (when starter
      (gams-comment-dwim-insert starter ender))))
  
(defun gams-insert-comment-symbol-def (starter &optional ender)
  "Insert inlinecom or eolcom dollar control option at the fisrt line in the file."
  (let ((dollar (if ender "$inlinecom" "$eolcom")))
    (save-excursion
      (goto-char (point-min))
      (insert (concat dollar " " starter " " ender "\n"))
      (sit-for 1)
      (message (format
		(concat (if ender "$inlinecome" "$eolcom")
			" was inserted at the first line of the buffer."))))))

;;; From newcomment.el
(defun gams-comment-indent (start end)
  "Indent eol and inline comment.
I forgot what this function is..."
  (interactive "*")
  (let* ((comment-start start)
	 (empty (save-excursion (beginning-of-line)
				(looking-at "[ \t]*$")))
	 (starter comment-start)
	 (ender end)
	 (comment-width (length comment-start)))
    (unless starter (error "No comment syntax defined"))
    (beginning-of-line)
    (let* ((eolpos (line-end-position))
	   (begpos (gams-comment-search-forward comment-start eolpos))
	   cpos indent)
      ;; An existing comment?
      (if begpos
	  (setq cpos (point-marker))
	;; If none, insert one.
	(save-excursion
	  ;; Some comment-indent-function insist on not moving comments that
	  ;; are in column 0, so we first go to the likely target column.
	  (indent-to comment-column)
	  (setq begpos (point))
	  (insert starter)
	  (setq cpos (point-marker))
	  (if ender (insert ender))))
      (goto-char begpos)
      ;; Compute desired indent.
      (setq indent (gams-comment-calculate-indent comment-start))
      (when (not indent)
	(setq indent 0))
      (if (= (current-column) indent)
	  (goto-char begpos)
	;; If that's different from current, change it.
	(skip-chars-backward " \t")
	(delete-region (point) begpos)
	(indent-to (if (bolp) indent
		     (max indent (1+ (current-column))))))
      (goto-char cpos)
      (set-marker cpos nil))
    (gams-ci-mode comment-width)))

(defun gams-comment-dwim-insert (starter ender)
  (interactive "*P")
  (if (and gams-emacs mark-active transient-mark-mode)
      (let ((beg (min (point) (mark)))
	    (end (max (point) (mark))))
	(if (save-excursion ;; check for already commented region
	      (goto-char beg)
	      (forward-comment (point-max))
	      (<= end (point)))
	    (uncomment-region beg end)
	  (comment-region beg end)))
    ;;
    (gams-comment-indent starter ender)))

(defun gams-comment-calculate-indent (starter &optional ender)
  (let ((start (gams-ci-block-begin))
	back col)
    (save-excursion
      (forward-line -1)
      (setq back (or start (point)))
      (catch 'found
	(while t
	  (if (>= (point) back)
	      (if (search-forward starter (line-end-position) t)
		  (progn
		    (goto-char (match-beginning 0))
		    (setq col (current-column))
		    (throw 'found t))
		(forward-line -1))
	    (forward-line -1)
	    (throw 'found t)))))
    col))

(defun gams-ci-mode (width)
  "Select the position of the end-of-line or inline comment."
  (interactive)
  (let (key)
    (catch 'quit
      (while t
	(message (concat "Position: (C-)f => forward, (C-)b => backward, "
			 "TAB => TAB, Other key => finish."))
	(setq key (read-char))
	(cond
	 ((eq key (string-to-char "\t")) (gams-ci-tab width))
	 ((or (eq key ?b)
	      (eq key 2))
	      (gams-ci-backward width))
	 ((or (eq key ?f)
	      (eq key 6))
	  (gams-ci-forward width))
	 ((eq key 32) (insert " ") (throw 'quit t))
	 (t (throw 'quit t)))))
    (message "Finished.")))

(defun gams-ci-forward (width)
  (save-excursion
    (backward-char width)
    (insert " ")))

(defun gams-ci-tab (width)
  (save-excursion
    (backward-char width)
    (insert "\t")))

(defun gams-ci-backward (width)
  (save-excursion
    (backward-char (+ 1 width))
    (if (looking-at "[^ \t]")
	nil
      (delete-char 1))))

(defun gams-ci-block-begin ()
  (let ((flag nil) beg)
    (save-excursion
      (beginning-of-line)
      (catch 'quit
	(while t
	  (if (not (gams-check-line-type nil t))
	      (cond
	       ((looking-at
		 (concat "\\(^[ \t]*\\("
			 gams-regexp-declaration-2
			 "\\|"
			 gams-regexp-loop
			 "\\|"
			 gams-regexp-put
			 "\\|"
			 "[$][ \t]*" gams-regexp-mpsge
			 "\\|$offtext\\|$ontext\\)\\)" ))
		(setq beg (point))
		(throw 'quit t))
	       ((looking-at "^[^ \t]+")
		(if flag
		    (progn (setq beg (point)) (throw 'quit t))
		  (setq flag t)
		  (forward-line -1)))
	       (t (setq flag t) (forward-line -1)))
	    (forward-line -1)))))
    beg))

;;; From newcomment.el.
(defun gams-comment-kill-line ()
  "Kill the comment on this line, if any."
  (interactive)
  (let ((end (line-end-position))
	beg)
    (save-excursion
      (beginning-of-line)
      (cond
       ((re-search-forward (regexp-quote gams-eolcom-symbol) end t)
	(delete-region (match-beginning 0) end))
       ((re-search-forward (regexp-quote gams-inlinecom-symbol-start) end t)
	(setq beg (match-beginning 0))
	(re-search-forward (regexp-quote gams-inlinecom-symbol-end) end t)
	(setq end (match-end 0))
	(delete-region beg end))
       (t
	(message "No end-of-line or inline comment in this line"))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Mouse.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; (when (fboundp 'popup-menu)
;;   (define-key gams-mode-map [down-mouse-3] 'gams-right-click)
;;   (define-key gams-mode-map [down-mouse-2] 'gams-right-click)
;;   (define-key gams-lst-mode-map [down-mouse-3] 'gams-right-click)
;;   (define-key gams-lst-mode-map [down-mouse-2] 'gams-right-click)
;;   (define-key gams-ol-mode-map [down-mouse-3] 'gams-right-click)
;;   (define-key gams-ol-mode-map [down-mouse-2] 'gams-right-click)
;;   )
(define-key gams-ol-mode-map [(mode-line) (down-mouse-1)] 'gams-ol-mouse-drag-mode-line)

(defun gams-ol-mouse-drag-mode-line (start-event)
  (interactive "e")
  (mouse-drag-mode-line start-event)
  (gams-ol-change-window-height))

(defun gams-ol-change-window-height ()
  (let ((win-num (gams-count-win))
	(height (- (window-height) 1)))
    (cond
     ((equal win-num 2)
      (setq gams-ol-height height))
     ((equal win-num 3)
      (setq gams-ol-height-two height))
     )))

(setq-default gams-mode-menu-sub nil)
(setq-default gams-lst-mode-menu-sub nil)
(setq-default gams-ol-mode-menu-sub nil)
(setq-default menu-bar-edit-menu-hoge nil)

;; From mouse.el
;; (defun gams-mode-right-click (event prefix)
;;   (interactive "@e\nP")
;;   (run-hooks 'activate-menubar-hook 'menu-bar-update-hook)
;;   (let* (;; This is where mouse-major-mode-menu-prefix
;; 	 ;; returns the prefix we should use (after menu-bar).
;; 	 ;; It is either nil or (SOME-SYMBOL).
;; 	 (mouse-major-mode-menu-prefix nil)
;; 	 ;;
;; 	 (mode-menu
;; 	  (cond
;; 	   ((equal major-mode 'gams-mode)
;; 	    gams-mode-menu-sub)
;; 	   ((equal major-mode 'gams-lst-mode)
;; 	    gams-lst-mode-menu-sub)
;; 	   ((equal major-mode 'gams-ol-mode)
;; 	    gams-ol-mode-menu-sub)))
;; 	 ;; Keymap from which to inherit; may be null.
;; 	 (ancestor (mouse-major-mode-menu-1 mode-menu))
;; 	 (defalias 'easy-menu-remove 'ignore)
;; 	 (newmap menu-bar-edit-menu-hoge))
;;     (if ancestor
;; 	(set-keymap-parent newmap ancestor))
;;     (popup-menu newmap event prefix)))

;; (defun gams-right-click (click prefix)
;;   (interactive "@e\nP")
;;   (if (zerop (assoc-default 'menu-bar-lines (frame-parameters) 'eq 0))
;;       (mouse-popup-menubar click prefix)
;;     (mouse-menu-major-mode-map)))
;; ;;    (popup-menu (mouse-menu-bar-map) event prefix)))
;; ;;    (gams-mode-right-click click prefix)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Misc.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; (defvar gams-display-small-logo t)
(defvar gams-mode-line-image-cache t)
(defun gams-mode-line-buffer-identification ()
  (let ((str "A") temp)
    (if (fboundp 'find-image)
	(progn
	  (setq temp
		(find-image
		 '((:type xbm :data
			  "#define gams_mark_width 18
#define gams_mark_height 12
static unsigned char gams_mark_bits[] = {
   0x00, 0x00, 0x00, 0xde, 0xd5, 0x01, 0x42, 0x5d, 0x00, 0xda, 0xdd, 0x01,
   0x5a, 0x15, 0x01, 0x5e, 0xd5, 0x01, 0x00, 0x00, 0x00, 0xfe, 0xfd, 0x01,
   0xfe, 0xfd, 0x01, 0xfe, 0xfd, 0x01, 0xfe, 0xfd, 0x01, 0x00, 0x00, 0x00 };"
			  :ascent center))))
	  (if (not temp)
	      nil
	    (add-text-properties
	     0 1
	     (list 'display
		   (if (eq t gams-mode-line-image-cache)
		       (setq gams-mode-line-image-cache temp)
		     gams-mode-line-image-cache)
		   'help-echo "GAMS mode")
	     str)
	    (list str '(" ")))))))
;;
(defun gams-add-mode-line ()
  (setq mode-line-buffer-identification
	(append (gams-mode-line-buffer-identification)
		mode-line-buffer-identification)))

;;; 
(setq gams-emacs-variables-list
      (list
       'emacs-version
       'default-process-coding-system
       'current-language-environment
       'file-name-coding-system
       'buffer-file-coding-system
       'default-terminal-coding-system
       'process-coding-system-alist
       'default-process-coding-system
       'locale-coding-system
       'default-enable-multibyte-characters
       'shell-file-name
       'explicit-shell-file-name
       'shell-file-name-chars
       'global-font-lock-mode
       'font-lock-mode
       'font-lock-support-mode
       'jit-lock-chunk-size
       'comment-style
       'buffer-file-name
       ))

(setq gams-mode-variables-list
      (list
       'gams-mode-version
       'gams:process-command-name
       'gams:process-command-option
       'gams-statement-file
       'gams-statement-upcase
       'gams-dollar-control-upcase
       'gams-insert-dollar-control-on
       'gams-system-directory
       'gams-use-mpsge
       'gams:shell-c
       'gams-always-popup-process-buffer
       'gams-comment-column
       'gams-comment-prefix
       'gams-special-comment-symbol
       'gams-paragraph-start
       'gams-file-extension
       'gams-multi-process
       'gams-indent-on
       'gams-indent-more-indent
       'gams-indent-equation-on
       'gams-indent-number
       'gams-indent-number-loop
       'gams-indent-number-equation
       'gams-indent-number-mpsge
       'gams-close-double-quotation-always
       'gams-close-single-quotation-always
       'gams-close-paren-always
       'gams-default-pop-window-height
       'gams-eolcom-symbol
       'gams-inlinecom-symbol-start
       'gams-inlinecom-symbol-end
       'gams-eolcom-symbol-default
       'gams-inlinecom-symbol-start-default
       'gams-inlinecom-symbol-end-default
       'gams-fill-column
       'gams-lst-extention
       'gams-lst-gms-extention
       'gams-recenter-font-lock
       'gams-sid-search-in-subroutine-file
       'gams-sil-column-width
       'gams-sil-follow-mode
       'gams-docs-directory
       'gams-docs-view-program
       'gams-process-log-to-file
       'gams-log-file-extension
       'gams-ol-external-program
       'gams-ol-height-two
       'gams-ol-item-name-width
       'gams-ol-use-mouse
       'gams-ol-view-item-default
       'gams-user-outline-item-alist
       'gams-ol-buffer-point
       'gams-ol-use-external
       'gams-ol-view-item
       'gams-ol-width
       'gams-ol-height
       'gams-perl-command
       'gams-template-file
       'gams-template-mark
       'gams-save-template-change
       'gams-template-cont-color
       'gams-mode-hook
       'gams-mode-load-hook
       'gams-ol-mode-hook
       'gams-lst-mode-hook
       'gams-lxi-extension
       'gams-lxi-maximum-line
       'gams-lxi-command-name
       'gams-lxi-import-command-name
       )
      )

(defun gams-report-bug ()
  "Create information for debugging GAMS mode.
Execute this command in a GAMS mode buffer with bugs and
problems."
  (interactive)
  (let ((from-buffer (current-buffer))
	buf fl-fl)
    (if (not (string-match "GAMS" mode-name))
 	(message "This command must be executed in a GAMS mode buffer!")
      (setq fl-fl font-lock-mode)
      (setq buf (get-buffer-create "*GAMS mode bug*"))
      (switch-to-buffer buf)
      (erase-buffer)
      (insert "\n")
      (insert "--- Copy and paste the content of this buffer to email. ---\n\n")
      ;;
      (insert "General Emacs settings:\n\n")
      (dolist (mode gams-emacs-variables-list)
	(and (boundp mode) (buffer-local-value mode from-buffer)
	     (insert (format "  %s: %s\n" mode
			     (buffer-local-value mode from-buffer)))))
      (insert "\n\n")
      ;;
      (insert "Minor modes in effect:\n\n")
      (dolist (mode minor-mode-list)
	(and (boundp mode) (buffer-local-value mode from-buffer)
	     (insert (format "  %s: %s\n" mode
			     (buffer-local-value mode from-buffer)))))
      (insert "\n\n")
      ;;
      (insert "Settings for GAMS mode:\n")
      (insert "\n")
      (dolist (mode gams-mode-variables-list)
	(and (boundp mode) (buffer-local-value mode from-buffer)
	     (insert (format "  %s: %s\n" mode
			     (buffer-local-value mode from-buffer)))))
      (insert "\n\n")
      ;;
      (insert "--- Debugging information ends. ---\n\n")
      ;;
      (delete-other-windows)
      (goto-char (point-min)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Hook.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Load hook.
(defvar gams-mode-load-hook nil
  "*List of functions to be called when gams.el is loaded.")

;;; provide.
(provide 'gams)
(run-hooks 'gams-mode-load-hook)

;;(load "./gams_new/gams-modlib.el")

;;; GAMS.EL ends here
