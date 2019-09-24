---
title: "Vim Plug Autoload"
date: 2019-09-23T17:41:25-07:00
draft: false

---

This post is about how to write some vim-script to autoload the plugin manager from the .vimrc.  This makes the process of getting up and running on a new system easier because the plugin manager is automatically downloaded as well as the plugins are also automatically downloaded.

Using the commands from https://github.com/junegunn/vim-plug I was able to create a script to auto download VimPlug for vim and NeoVim on windows and on Linux.



```sh
" Expand the home directory to an absolute path.
let homeDir = expand('~')

" Find the desired VimPlug install location for different system configurations.
if(has('win32') || has('win64'))
    if has('nvim')
        let shareDir=homeDir.'\AppData\Local\nvim'
        let plugVim=shareDir.'\autoload\plug.vim'
    else
        let shareDir=homeDir.'\vimfiles'
        let plugVim=shareDir.'\autoload\plug.vim'
    endif
else
    if has('nvim')
        let shareDir=homeDir.'/.local/share/nvim/site'
        let plugVim=shareDir.'/autoload/plug.vim'
    else
        let shareDir=homeDir.'/.vim'
        let plugVim=shareDir.'/autoload/plug.vim'
    endif
endif

" Url of the VimPlug script.
let plugUri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
if empty(glob(expand(plugVim)))
    if has('win32') || has('win64')
    	" Make sure the autoload directory has been created.
        exec '!md '.shareDir.'\autoload'
        
        " Download VimPlug using PowerSHell.
        exec '!powershell -command Invoke-WebRequest -Uri "'.plugUri.'" -OutFile '.plugVim.'"'
    else
        " Download VimPlug using curl.
        exec '!curl -fLo '.plugVim.' --create-dirs '.plugUri
    endif

	# Automatically run PlugInstall command.
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

```

