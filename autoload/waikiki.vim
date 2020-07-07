" waikiki autoload
let s:save_cpo = &cpo
set cpo&vim

"------------
" Debug {{{1
"------------
let g:waikiki_debug = 1
if 0
append
  " comment out all dbg calls
  :g,\c^\s*call <Sid>Dbg(,s/call/"call/
  " uncomment
  :g,\c^\s*"call <Sid>Dbg(,s/"call/call/
.
endif


"----------------
" Variables {{{1
"----------------

let s:dirsep = get(g:, 'waikiki_dirsep', '/')
let s:follow = get(g:, 'waikiki_follow_action', 'edit')
let s:create = get(g:, 'waikiki_create_action', 'edit')
let s:ext    = get(g:, 'waikiki_ext', '.md')
let s:index  = get(g:, 'waikiki_index', 'index'.s:ext)
let s:todo   = get(g:, 'waikiki_todo', ' ')
let s:done   = get(g:, 'waikiki_done', 'X')
let s:wiki_patterns  = get(g:, 'waikiki_wiki_patterns',
                        \ get(g:, 'waikiki_patterns', []))
let s:wiki_roots     = get(g:, 'waikiki_wiki_roots',
                        \ get(g:, 'waikiki_roots', []))
let s:lookup_order   = get(g:, 'waikiki_lookup_order', ['raw', 'ext', 'subdir'])
let s:mkdir_prompt   = get(g:, 'waikiki_mkdir_prompt', 0)
let s:ask_if_noindex = get(g:, 'waikiki_ask_if_noindex', 0)
let s:create_type    = get(g:, 'waikiki_create_type', 'ext')
let s:space_replacement = get(g:, 'waikiki_space_replacement', '_')


"-----------------------
" Public Functions {{{1
"-----------------------

" waikiki#NextLink {{{2
function! waikiki#NextLink() abort
  let link_regex = get(g:, 'waikiki_link_regex', '\[[^]]*\]([^)]\+)')
  call search(link_regex)
endfun

" waikiki#PrevLink {{{2
function! waikiki#PrevLink() abort
  let link_regex = get(g:, 'waikiki_link_regex', '\[[^]]*\]([^)]\+)')
  call search(link_regex, 'b')
endfun

" waikiki#ToggleListItem {{{2
function! waikiki#ToggleListItem() abort
  let line = getline('.')
  let box  = matchstr(line,
        \ '\[\%('.s:todo.'\|'.s:done.'\)\]')
  if box != ""
    if box =~ s:todo
      exe printf('s/\[\zs%s\ze\]/%s/', s:todo, s:done)
      norm! ``
    elseif box =~ s:done
      exe printf('s/\[\zs%s\ze\]/%s/', s:done, s:todo)
      norm! ``
    endif
  endif
endfun

" waikiki#SetupBuffer {{{2
function! waikiki#SetupBuffer() abort
  "call <Sid>Dbg("Setting up buffer")
  if get(g:, 'waikiki_default_maps', 0)
    nmap  <buffer>  <LocalLeader><Space>  <Plug>(waikikiToggleListItem)
    nmap  <buffer>  <LocalLeader>n        <Plug>(waikikiNextLink)
    nmap  <buffer>  <LocalLeader>p        <Plug>(waikikiPrevLink)
    nmap  <buffer>  <LocalLeader><cr>     <Plug>(waikikiFollowLink)
    nmap  <buffer>  <LocalLeader>s        <Plug>(waikikiFollowLinkSplit)
    nmap  <buffer>  <LocalLeader>v        <Plug>(waikikiFollowLinkVSplit)
    xmap  <buffer>  <LocalLeader><cr>     <Plug>(waikikiFollowLink)
    xmap  <buffer>  <LocalLeader>s        <Plug>(waikikiFollowLinkSplit)
    xmap  <buffer>  <LocalLeader>v        <Plug>(waikikiFollowLinkVSplit)
    nmap  <buffer>  <LocalLeader>u        <Plug>(waikikiGoUp)
    nmap  <buffer>  <LocalLeader>T        <Plug>(waikikiTags)
  endif

  setl concealcursor=n

  if exists('#Waikiki#User#setup')
    "call <Sid>Dbg("doauto Waikiki User setup")
    doauto <nomodeline> Waikiki User setup
  endif
endfun

" waikiki#CheckBuffer {{{2
function! waikiki#CheckBuffer(file) abort
  if s:IsUnderWikiRoot(a:file) || s:IsMatchingWikiPattern(a:file)
    call waikiki#SetupBuffer()
    return
  endif
  "call <Sid>Dbg("nothing to setup")
endfun

" waikiki#GetCurrentLink {{{2
function! waikiki#GetCurrentLink() abort
  let link_url_regex = get(g:, 'waikiki_link_url_regex',
        \ '\[[^]]*\](\zs[^)]\+\ze)' )
  let line = getline('.')
  let link = matchstr(line,
        \ '\%<'.(col('.')+1).'c'.
        \ link_url_regex.
        \ '\%>'.col('.').'c')
  "call <Sid>Dbg("Current link:", link)
  return link
endfun

" waikiki#FollowLink {{{2
function! waikiki#FollowLink(...) abort
  let options = a:0 ? a:1 : {}
  let follow  = get(options, 'action', s:follow)
  let create  = get(options, 'create', s:create)
  let name    = get(options, 'name', expand('<cword>'))
  let curlink = get(options, 'link', waikiki#GetCurrentLink())
  let curpath = expand('%:p:h')
  let targetlist  = []
  let finaltarget = ''
  "call <Sid>Dbg("name, link: ", name, curlink)

  " is there a link with a url
  if curlink != ""
    " yes, got a link
    let link_info = s:GetTargetInfo(curlink)
    " does it have a path component
    if link_info['has_path']
      let abstarget = s:JoinPath(curpath, curlink)
      let finaltarget = isdirectory(abstarget)
            \ ? s:JoinPath(abstarget, s:index)
            \ : abstarget
      "call <Sid>Dbg("link with path: ", finaltarget)
      if filereadable(finaltarget)
        exe follow finaltarget
        return
      elseif !link_info['has_ext'] && filereadable(finaltarget.s:ext)
        exe follow finaltarget.s:ext
        return
      endif
    else
      " no path, look up file in expected locations
      let targetlist = s:GetPossibleTargetsOrderedList(curlink)
      for target in targetlist
        let abstarget = s:JoinPath(curpath, target)
        "call <Sid>Dbg("trying: ", abstarget)
        if filereadable(abstarget)
          exe follow abstarget
          return
        endif
      endfor
      "call <Sid>Dbg("all failed.")
    endif
  endif

  " cannot find page, let's create one

  " set url if we don't have it yet
  if finaltarget == ''
    " get target
    let targetbase = (curlink != "" ? curlink : name)
    if s:create_type != ''
      " user has prefs, don't prompt
      let targetdict = s:GetPossibleTargetsDict(targetbase)
      let target = get(targetdict, s:create_type, targetdict['raw'])
    else
      let targetlist = s:GetPossibleTargetsOrderedList(targetbase)
      let target = s:PromptForTarget(targetlist)
    endif
    let nospacetarget = substitute(target, ' ', s:space_replacement, 'g')
    let finaltarget = s:JoinPath(curpath, nospacetarget)
    "call <Sid>Dbg("nospacetarget, finaltarget:", nospacetarget, finaltarget)
    if curlink == ""
      call s:InsertLinkCode(name, nospacetarget)
    endif
  endif

  call s:EnsurePathExists(finaltarget)
  exe create finaltarget
endfun

" waikiki#GoUp {{{2
function! waikiki#GoUp(...) abort
  let options     = a:0 ? a:1 : {}
  let action      = get(options, 'action', s:follow)
  let curpath     = expand('%:p:h')
  let curtarget   = expand('%:t')
  let oldpath     = curpath
  let finaltarget = ''
  let lvl_dir_up  = 0
  let move_up     = 0

  "call <Sid>Dbg("curpath, curtarget:", curpath, curtarget)

  if curtarget == s:index
    if s:IsPathAtWikiRoot(curpath)
      echo "Already at wiki root."
      return
    endif
    let path = fnamemodify(curpath, ':h')
    "call <Sid>Dbg("updating path before loop:", path)
    let lvl_dir_up += 1
    if path == oldpath
      return
    endif
  else
    let path = curpath
  endif

  let nb_iter_left = 32
  while finaltarget == ''
    let nb_iter_left -= 1
    if nb_iter_left == 0
      echohl ErrorMsg
      echom "GoUp: Too many recursion."
      echohl None
      return
    endif
    let target  = s:JoinPath(path, s:index)
    "call <Sid>Dbg("Testing target:", target)
    if filereadable(target)
      let finaltarget = target
    elseif s:ask_if_noindex
      let globpath   = s:JoinPath(path, '*')
      let targetlist = glob(globpath, 1, 1)
      if empty(targetlist)
            \ || (len(targetlist) == 1
            \   && (targetlist[0] == s:JoinPath(path, curtarget)
            \     || lvl_dir_up == 1 && targetlist[0] == path))
        " if no candidate, move up and try again
        let move_up = 1
      else
        " let the user choose
        let target = s:PromptForTarget(
              \ targetlist + [fnamemodify(path, ':h')],
              \ {'prompt': 'Choose file:', 'complete': 1}
              \)
        if filereadable(target)
          let finaltarget = target
        elseif isdirectory(target)
          let path = target
          "call <Sid>Dbg("user set path:", path)
          " user could have entered anything, no point tracking dir lvl
          let lvl_dir_up = 99
        else
          " can't find user choice, just move up
          let move_up = 1
        endif
      endif
    else
      let move_up = 1
    endif
    if move_up
      if s:IsPathAtWikiRoot(path)
        echo "Already at wiki root."
        return
      endif
      let path = fnamemodify(path, ':h')
      "call <Sid>Dbg("updating path:", path)
      let lvl_dir_up += 1
      if path == oldpath
        echo "Cannot find ".s:index." in upper dirs."
        return
      endif
    endif
    let move_up = 0
    let oldpath = path
  endwhile

  exe action finaltarget
endfun

" waikiki#Tags {{{2
" Arg: dir where to save tags file
function! waikiki#Tags(...) abort
  let tagstart = get(g:, 'waikiki_tag_start', ':')
  let tagend   = get(g:, 'waikiki_tag_end', ':')
  let tag      = '[a-zA-Z0-9_]+'
  let ttag     = tag.tagend
  let blanks   = '[ \t]*'
  let regex1 = printf('/^%s%s(%s)%s(%s)*%s$/\1/t,tag/i',
        \ blanks, tagstart, tag, tagend, ttag, blanks)
  let regex2 = printf('/^%s%s%s(%s)%s(%s)*%s$/\1/t,tag/i',
        \ blanks, tagstart, ttag, tag, tagend, ttag, blanks)
  let regex3 = printf('/^%s%s%s%s(%s)%s(%s)*%s$/\1/t,tag/i',
        \ blanks, tagstart, ttag, ttag, tag, tagend, ttag, blanks)
  let regex4 = printf('/^%s%s%s%s%s(%s)%s(%s)*%s$/\1/t,tag/i',
        \ blanks, tagstart, ttag, ttag, ttag, tag, tagend, ttag, blanks)
  let regex5 = printf('/^%s%s%s%s%s%s(%s)%s(%s)*%s$/\1/t,tag/i',
        \ blanks, tagstart, ttag, ttag, ttag, ttag, tag, tagend, ttag, blanks)
  let regex6 = printf('/^%s%s%s%s%s%s%s(%s)%s(%s)*%s$/\1/t,tag/i',
        \ blanks, tagstart, ttag, ttag, ttag, ttag, ttag, tag, tagend, ttag, blanks)

  let ctags_cmd = join([
        \ 'ctags',
        \ '--langdef=waikiki',
        \ '--langmap=waikiki:'.s:ext,
        \ '--languages=waikiki',
        \ '--regex-waikiki='''.regex1.'''',
        \ '--regex-waikiki='''.regex2.'''',
        \ '--regex-waikiki='''.regex3.'''',
        \ '--regex-waikiki='''.regex4.'''',
        \ '--regex-waikiki='''.regex5.'''',
        \ '--regex-waikiki='''.regex6.'''',
        \ '--recurse',
        \ '--waikiki-kinds=t',
        \ '.',
        \])
  if a:0
    let ctags_cmd = 'cd '.a:1.' && '.ctags_cmd
  else
    let root = s:GetBufferWikiRoot(expand('%'))
    if root != ""
      let ctags_cmd = 'cd '.root.' && '.ctags_cmd
    endif
  endif
  "call <Sid>Dbg("running:", ctags_cmd)
  silent let ctags_out = system(ctags_cmd)
  "call <Sid>Dbg("output:", ctags_out)
endfun


"------------------------
" Private Functions {{{1
"------------------------

" s:GetPossibleTargetsDict {{{2
function! s:GetPossibleTargetsDict(target) abort
  let target_info = s:GetTargetInfo(a:target)
  let ret = {}
  let ret['raw']    = a:target
  let ret['ext']    = a:target . (target_info['has_ext'] ? '' : s:ext)
  let ret['subdir'] = a:target . s:dirsep . s:index
  return ret
endfun

" s:GetPossibleTargetsOrderedList {{{2
function! s:GetPossibleTargetsOrderedList(name) abort
  let targetlist = []
  let targetdict = s:GetPossibleTargetsDict(a:name)
  for type in s:lookup_order
    let target = get(targetdict, type, '')
    call add(targetlist, target)
  endfor
  "call <Sid>Dbg("Target list:", string(targetlist))
  return targetlist
endfun

" s:GetTargetInfo {{{2
function! s:GetTargetInfo(target) abort
  let tlen = strlen(a:target)
  let elen = strlen(s:ext)
  let ret = {}
  let ret['has_path'] = (stridx(a:target, s:dirsep) != -1)
  let ret['has_ext']  = ((tlen > elen)
        \ && (stridx(a:target, s:ext) == (tlen - elen)))
  return ret
endfun

" s:PromptForTarget {{{2
function! s:PromptForTarget(choices, ...) abort
  let options  = a:0 ? a:1 : {}
  let prompt   = get(options, 'prompt', "Choose new file path:")
  let complete = get(options, 'complete', 0)
  let target   = ''
  while target == ''
    echo prompt
    let i = 1
    for target in a:choices
      echo printf("%d) %s", i, target)
      let i += 1
    endfor
    let last_idx = i
    echo printf("%d) %s", i, "[other]")
    let choice = input('> ')
    let choice_nr = str2nr(choice)
    if choice_nr >= 1 && choice_nr < last_idx
      let target = a:choices[choice_nr-1]
    elseif choice_nr == last_idx
      " User enters path
      let target = complete
            \ ? input('path: ', expand('%:h'), "file")
            \ : input('path: ')
    endif
  endwhile
  "call <Sid>Dbg("Chosen target:", target)
  return target
endfun

" s:EnsurePathExists {{{2
function! s:EnsurePathExists(target) abort
  let path = matchstr(a:target, '.*'.s:dirsep)
  if path != '' && !isdirectory(path)
    if s:mkdir_prompt
      let reply = ''
      while reply !~ 'y\%[es]\c' && reply !~ 'n\%[o]\c'
        echo "create dir(s) '".path."'? [y/n]: "
      endwhile
      if reply =~ 'y\%[es]\c'
        call mkdir(path, 'p')
      else
        echom "Warning: new buffer path won't exist."
      endif
    else
      call mkdir(path, 'p')
    endif
  endif
endfun

" s:InsertLinkCode {{{2
function! s:InsertLinkCode(name, target) abort
  " TODO: test and improve escaping?
  let escaped_name = escape(a:name, '\*^$')
  let repl_fmt     = get(g:, 'waikiki_link_fmt', '[%s](%s)%.0s')
  let is_md_link   = (len(repl_fmt) > 4 && repl_fmt[0:3] is '[%s]')
  let replacement  = printf(repl_fmt, a:name, a:target, a:name)
  let line = substitute(getline('.'),
        \ '\%<'.(col('.')+1).'c'.
        \   (is_md_link ? '\[\?' : '').
        \ escaped_name.
        \ '\%>'.col('.').'c'.
        \   (is_md_link ? '\]\?' : ''),
        \ replacement,
        \ '')
  call setline('.', line)
endfun

" s:JoinPath {{{2
function! s:JoinPath(path, file) abort
  if a:path[strlen(a:path)-1] == s:dirsep
        \ || a:file[0] == s:dirsep
    return a:path . a:file
  else
    return a:path . s:dirsep . a:file
  endif
endfun

" s:IsSubdirOf {{{2
function! s:IsSubdirOf(subdir, parent) abort
  " normalized paths
  let nsubdir   = s:ChompDirSep(a:subdir).s:dirsep
  let nparent   = s:ChompDirSep(a:parent).s:dirsep
  let subdircut = strcharpart(nsubdir, 0, strchars(nparent))
  let is_subdir = (subdircut == nparent)
  "call <Sid>Dbg("is subdir of:", subdircut, nparent, (is_subdir?"yes":"no"))
  return is_subdir
endfun

" s:IsAtDir {{{2
function! s:IsAtDir(dir1, dir2) abort
  " normalized paths
  let ndir1 = s:ChompDirSep(a:dir1).s:dirsep
  let ndir2 = s:ChompDirSep(a:dir2).s:dirsep
  let is_at_dir = (ndir1 == ndir2)
  "call <Sid>Dbg("is at dir:", ndir1, ndir2, (is_at_dir?"yes":"no"))
  return is_at_dir
endfun

" s:IsMatchingWikiPattern {{{2
function! s:IsMatchingWikiPattern(file) abort
  for pat in s:wiki_patterns
    if a:file =~ pat
      return 1
    endif
  endfor
  return 0
endfun

" s:GetBufferWikiRoot {{{2
function! s:GetBufferWikiRoot(file) abort
  let abspath = fnamemodify(a:file, ':p:h')
  for root in s:wiki_roots
    let absroot = fnamemodify(root, ':p')
    if s:IsSubdirOf(abspath, absroot)
      return absroot
    endif
  endfor
  return ""
endfun

" s:IsUnderWikiRoot {{{2
function! s:IsUnderWikiRoot(file) abort
  return (s:GetBufferWikiRoot(a:file) != "")
endfun

" s:IsAtWikiRoot {{{2
function! s:IsPathAtWikiRoot(path) abort
  for root in s:wiki_roots
    let absroot = fnamemodify(root, ':p')
    if s:IsAtDir(a:path, absroot)
      return 1
    endif
  endfor
  return 0
endfun

" s:ChompDirSep {{{2
function! s:ChompDirSep(str) abort
  let l = strchars(a:str)
  let ret = a:str
  if strcharpart(a:str, l -1, 1) == s:dirsep
    let ret = strcharpart(a:str, 0, l - 1)
  endif
  return ret
endfun

" s:Dbg {{{2
function! s:Dbg(msg, ...) abort
  if g:waikiki_debug
    let m = a:msg
    if a:0
      let m .= " [".join(a:000, "] [")."]"
    endif
    echom m
  endif
endfun


let &cpo = s:save_cpo
