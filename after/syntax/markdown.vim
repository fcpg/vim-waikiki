" markdown.vim - extra syntax for wiki use

if get(g:, 'waikiki_conceal_markdown_url', 1)
  syn region markdownLink
        \ matchgroup=markdownLinkDelimiter start="(" end=")"
        \ contains=markdownUrl keepend contained conceal
endif
