" waikiki.vim - fisherman's wiki

nnoremap  <silent>  <Plug>(waikikiFollowLink)       :call waikiki#FollowLink()<cr>
nnoremap  <silent>  <Plug>(waikikiFollowLinkSplit)  :call waikiki#FollowLink({'action':'split'})<cr>
nnoremap  <silent>  <Plug>(waikikiFollowLinkVSplit) :call waikiki#FollowLink({'action':'vsplit'})<cr>
xnoremap  <silent>  <Plug>(waikikiFollowLink)       y:call waikiki#FollowLink({'name': @@})<cr>
xnoremap  <silent>  <Plug>(waikikiFollowLinkSplit)  y:call waikiki#FollowLink({'name': @@, 'action':'split'})<cr>
xnoremap  <silent>  <Plug>(waikikiFollowLinkVSplit) y:call waikiki#FollowLink({'name': @@, 'action':'vsplit'})<cr>
nnoremap  <silent>  <Plug>(waikikiGoUp)             :call waikiki#GoUp()<cr>
nnoremap  <silent>  <Plug>(waikikiGoUpSplit)        :call waikiki#GoUp({'action':'split'})<cr>
nnoremap  <silent>  <Plug>(waikikiGoUpVSplit)       :call waikiki#GoUp({'action':'vsplit'})<cr>
nnoremap  <silent>  <Plug>(waikikiNextLink)         :call waikiki#NextLink()<cr>
nnoremap  <silent>  <Plug>(waikikiPrevLink)         :call waikiki#PrevLink()<cr>
nnoremap  <silent>  <Plug>(waikikiToggleListItem)   :call waikiki#ToggleListItem()<cr>
nnoremap  <silent>  <Plug>(waikikiTags)             :call waikiki#Tags()<cr>

if !get(g:, 'waikiki_noauto', 0)
  augroup WaikikiSetup
    au!
    autocmd BufNewFile,BufRead *
          \ call waikiki#CheckBuffer(expand('<afile>:p'))
  augroup END
endif

com! -nargs=? -bar -complete=dir WaikikiTags
      \ call waikiki#Tags(<f-args>)

let g:waikiki_loaded = 1
