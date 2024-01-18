" Vim filetype plugin for using emacs verilog-mode
" Last Change: 2024 1/18
" Origin Author:  Seong Kang <seongk@wwcoms.com>
" Author: zsccll 
" License:     This file is placed in the public domain.

" comment out these two lines
" if you don't want folding or if you prefer other folding methods
"setlocal foldmethod=expr
"setlocal foldexpr=VerilogEmacsAutoFoldLevel(v:lnum)

if exists("loaded_verilog_emacsauto")
   finish
endif
let loaded_verilog_emacsauto = 1

function! s:InitVar(var, value)
    if !exists(a:var)
        exec 'let '.a:var.'='.string(a:value)
    endif
endfunction
" map \a, \d pair to Add and Delete functions, assuming \ is the leader
" alternatively, map C-A, C-D to Add and Delete functions

let s_DefaultPath = expand("$HOME") . "/.elisp/verilog-mode.el"

call s:InitVar('g:VerilogModeAddKey', '<leader>a')
call s:InitVar('g:VerilogModeDeleteKey', '<leader>d')
call s:InitVar('g:VerilogModeFile', s_DefaultPath)
call s:InitVar('g:VerilogModeTrace', 0)
call s:InitVar('g:VerilogModeEmacsDefault', 1)

"if !hasmapto('<Plug>VerilogEmacsAutoAdd')
"map <unique> <leader>a <Plug>VerilogEmacsAutoAdd
"endif
try
    if g:VerilogModeAddKey != ""
        exec 'nnoremap <silent><unique> ' g:VerilogModeAddKey '<Plug>VerilogEmacsAutoAdd'
    endif
catch /^Vim\%((\a\+)\)\=:E227/
endtry

"if !hasmapto('<Plug>VerilogEmacsAutoDelete')
"   map <unique> <leader>d <Plug>VerilogEmacsAutoDelete
"endif
try
    if g:VerilogModeDeleteKey != ""
        exec 'nnoremap <silent><unique> ' g:VerilogModeDeleteKey '<Plug>VerilogEmacsAutoDelete'
    endif
catch /^Vim\%((\a\+)\)\=:E227/
endtry



noremap <unique> <script> <Plug>VerilogEmacsAutoAdd    <SID>Add
noremap <unique> <script> <Plug>VerilogEmacsAutoDelete <SID>Delete
noremap <SID>Add    :call <SID>Add()<CR>
noremap <SID>Delete :call <SID>Delete()<CR>
noremap <SID>Add_Debug    :call <SID>Add_Debug()<CR>
noremap <SID>Delete_Debug :call <SID>Delete_Debug()<CR>
noremap <SID>EN_Default :call <SID>EN_Default()<CR>
noremap <SID>Dis_Default :call <SID>Dis_Default()<CR>


" add menu items for gvim
noremenu <script> Verilog-Mode.AddAuto    <SID>Add
noremenu <script> Verilog-Mode.DeleteAuto <SID>Delete

let s:is_win = has('win16') || has('win32') || has('win64')

function s:EN_Default()
   let g:VerilogModeEmacsDefault = 1
   echo "set default mode"
endfunction

function s:Dis_Default()
   let g:VerilogModeEmacsDefault = 0
   echo "set file mode"
endfunction

" Add function
" saves current document to a temporary file
" runs the temporary file through emacs
" replaces current document with the emacs filtered temporary file
" removes temporary file
" also replaces emacs generated tabs with spaces if expandtab is set
" comment out the two if blocks to leave the tabs alone
function s:Add()
   if &expandtab
      let s:save_tabstop = &tabstop
      let &tabstop=8
   endif
   " a tmp file is need 'cause emacs doesn't support the stdin to stdout flow
   " maybe add /tmp to the temporary filename
   let l:tmpfile = expand("%:p:h") . "/." . expand("%:p:t")
   "echom l:tmpfile
   silent! call writefile(getline(1, "$"), fnameescape(l:tmpfile), '')
   if g:VerilogModeTrace
	   exec "silent !emacs -batch --no-site-file -l ". g:VerilogModeFile . " " . shellescape(l:tmpfile, 1) . " -f verilog-batch-auto"
   else
	   exec "silent !emacs -batch --no-site-file -l ". g:VerilogModeFile . " " . shellescape(l:tmpfile, 1) . " -f verilog-batch-auto 2> /dev/null"
   endif
   let l:newcontent = readfile(fnameescape(l:tmpfile), '')
   
   if &expandtab
      retab
      let &tabstop=s:save_tabstop
   endif
   "call deletebufline('.', 1, '$')
   let l:i=1
   call setline(1, l:newcontent)
   exec "silent !rm -rf " . shellescape(l:tmpfile)
   w! %
   exec 'redraw!'
endfunction

" Delete function
" saves current document to a temporary file
" runs the temporary file through emacs
" replaces current document with the emacs filtered temporary file
" removes temporary file
function s:Delete()
   " a tmp file is need 'cause emacs doesn't support the stdin to stdout flow
   " maybe add /tmp to the temporary filename
   let l:tmpfile = expand("%:p:h") . "/." . expand("%:p:t")
   "exec 'wrtie'   fnameescape(l:tmpfile)
   silent! call writefile(getline(1, "$"), fnameescape(l:tmpfile), '')
   if g:VerilogModeTrace
	   exec "silent !emacs -batch --no-site-file -l " . g:VerilogModeFile . " " . l:tmpfile . " -f verilog-batch-delete-auto"
   else
	   exec "silent !emacs -batch --no-site-file -l " . g:VerilogModeFile . " " . l:tmpfile . " -f verilog-batch-delete-auto 2> /dev/null"
   endif
   exec "silent %!cat " . shellescape(l:tmpfile)
   exec "silent !rm -rf " . shellescape(l:tmpfile)
   w! %
   exec 'redraw!'
endfunction

function s:Add_Debug()
   if g:VerilogModeEmacsDefault
      echo "default mode auto"
      exec "!emacs -batch % -f verilog-auto -f save-buffer"
   else
      echo "file mode auto"
      exec "!emacs -batch % -l " . g:VerilogModeFile . " -f verilog-auto -f save-buffer"   
   endif
endfunction

function s:Delete_Debug()
   if g:VerilogModeEmacsDefault
      echo "default mode deleteauto"
      exec "!emacs -batch % -f verilog-delete-auto -f save-buffer"
   else
      echo "file mode deleteauto"
      exec "!emacs -batch % -l " . g:VerilogModeFile . " -f verilog-delete-auto -f save-buffer"   
   endif
endfunction

" VerilogEmacsAutoFoldLevel function
" only deals with 0 and 1 levels
function VerilogEmacsAutoFoldLevel(l)
   if (getline(a:l-1)=~'\/\*A\S*\*\/' && getline(a:l)=~'\/\/ \(Outputs\|Inputs\|Inouts\|Beginning\)')
      return 1
   endif
   if (getline(a:l-1)=~'\(End of automatics\|);\)')
      return 0
   endif
   return '='
endfunction
