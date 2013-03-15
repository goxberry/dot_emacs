# Customizations for Emacs

This directory contains the custom emacs modes that I use for development.

## Installation

First, clone the repo into your `~/.emacs.d` directory. *Be advised: you must delete your current `~/.emacs.d` directory, so you should probably back this directory up!*

	git clone https://github.com/goxberry/dot_emacs.git ~/.emacs.d
	cd ~/.emacs.d
	git submodule init
	git submodule update
	cd ~
	
Next, soft-link `nix_init_file.el` in this repo to `~/.emacs`. *Warning: this command will overwrite your current `~/.emacs` file, so you should back it up!*

	ln -sf ~/.emacs.d/nix_init_file.el ~/.emacs
	
And you're done!

## Versions and OSes supported

This installation only works for Unix-like operating systems (that is, OS X and Linux). It also assumes that you have Emacs version 22 or greater. The visual-line-mode features won't work on Emacs 22 unless you add `simple.el` to `~/.emacs.d/`.

## Features included

1. The Solarized color theme.
2. Various modes:
   - color-theme-mode (already installed for Emacs 24, but needed for Emacs 22 and 23)
   - markdown-mode
   - pandoc-mode
   - cython-mode
   - puppet-mode
   - vagrant-mode
   - git-commit-mode
   - gams-mode
3. Globally disables visual-line-mode, except for file types typically used for documentation (for me, these would be `*.org`, `*.txt`, Markdown files, and LaTeX files. For these documentation files, also enable on-the-fly spell-checking.
4. Always enable column-number-mode.
5. Only scroll one line at a time instead of the half-screen default used by Emacs.
6. Replace 'yes/no' questions with 'y/n' questions.

## TODO:

- Add proper attribution for these Emacs lisp files in the README.
