Vim-Waikiki
------------

> Fisherman's Wiki
```
               .--.
     *lol*   _/__  )
        \     é)è`>|_
        /V\   \-_.-_ `;
       /'_/\_ /_.   './
      ;._ `/ ``      |
      |^ '-;._   _.' |
      |   v ||```    |
    .'| v   ||       |
   `'`|  v  |\__,.--;'
      |v  v | |     |
      ;  v  ; |     /
       \   /\)|    |
```

Waikiki is a <del>poor man</del> fisherman's wiki: it provides
a minimal set of features to:

- Navigate pages (follow links, go back)
- Create links and pages ("follow" words or non-existent links)
- Use tags (via `ctags`) to index pages

Mappings are buffer-local by default; `filetype` is not touched, and
syntax/formatting (except for checkboxes) is left to other files/plugins.

If you just want to jot down simple (eg. markdown) notes in some hierarchical
way, and realized that you used only 10% of the features of the great vimwiki,
then that's why Waikiki was created <'((>< .

Usage
------
See [the documentation](doc/waikiki.txt).

FAQ
----

*What is it?*  
In a nutshell, this plugin lets you "follow" textual links in markdown files,
the same way you can `gf` on paths in vim. It also lets you easily turn words 
into links. Plus a few other goodies.

*Why don't you use vimwiki?*  
Because it's much bigger and more feature-full than what I need. In other words,
great but overkill for me.

*Is is subtle, modern and elegant?*  
As much as an orange life jacket.

Installation
-------------
Use your favorite method:
*  [Pathogen][1] - git clone https://github.com/fcpg/vim-waikiki ~/.vim/bundle/vim-waikiki
*  [NeoBundle][2] - NeoBundle 'fcpg/vim-waikiki'
*  [Vundle][3] - Plugin 'fcpg/vim-waikiki'
*  [Plug][4] - Plug 'fcpg/vim-waikiki'
*  manual - copy all files into your ~/.vim directory

License
--------
[Attribution-ShareAlike 4.0 Int.](https://creativecommons.org/licenses/by-sa/4.0/)

[1]: https://github.com/tpope/vim-pathogen
[2]: https://github.com/Shougo/neobundle.vim
[3]: https://github.com/gmarik/vundle
[4]: https://github.com/junegunn/vim-plug

(ascii art modified from jgs)
