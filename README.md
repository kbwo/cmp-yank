cmp-yank
========

yank completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp).

Installation
------------

Use your favorite plugin manager:

- [vim-plug](https://github.com/junegunn/vim-plug)
  ```vim
  Plug 'kbwo/cmp-yank'
  ```

Usage
-----
```lua
require('cmp').setup({
  sources = {
    {
       name = 'yank',
       -- you can specify the directory to save yank history (optional)
       yank_source_path = vim.getenv('HOME') .. '/dotfiles/history'
    },
  }
})
```

