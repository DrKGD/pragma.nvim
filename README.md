# Pragma.nvim

## Purpose
This plugin gives you a fast, programmable way to store and reproduce editors layout, just like you would with built-in sessions.

I really built the plugin out of my own necessities, for getting comfortable with luals annotations, 
and because I rather have the layout stored in an easy-to-read format, feel free to provide suggestions and/or open pull requests.

## Features
- Replace current layout, closing all windows, or enjoy your own matrioska of an editor.
- Store and customize custom callbacks for special buffers.
  - For example [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) and [vuffers](https://github.com/Hajime-Suzuki/vuffers.nvim), which already provide an api to `open` its specific buffer in a specific window, could be opened with ease via `buffer`!
- Switch in between layouts by binding them to keybindings
- No setup required, you decide if and when to load the plugin.
- Store custom layouts directly in the plugin configuration at `layout`, thus apply them via `Pragma apply <name>`!

## Ideas for improvements
- [ ] Given the current layout, automagically provide its pragma counterpart
- [ ] Add handling for more special buffers
- [ ] Add more actions
- [ ] Read/Import layout from json/toml
- [ ] More default layouts
- [ ] More Pragma actions 
  - [ ] Define one or more layout cycles (e.g. `[fakezen, vvh, vv]`), which provides a better solution when the user
		cannot decide which layout is the better one


## Setup and Installation

Default setup with [lazy.nvim](https://github.com/folke/lazy.nvim) (opts is not required, but it is present nonetheless as you may want to change it)
```lua
return {
  "DrKGD/pragma.nvim"
  cmd = { 'Pragma' },
  opts  = {
    register_command = true,

    action = {
      buffer = {
        special = {
          ['nvimtree'] = function(winid)
            local ntapi = require('nvim-tree.api')
              ntapi.tree.close_in_all_tabs()
              ntapi.tree.open { winid = winid }
            return true
          end,

          ['vuffers'] = function(winid)
            local vuffers = require('vuffers')
              vuffers.close()
              vuffers.open { win = winid }
            return true
          end,

          ['doing_tasks'] = function(winid)
            local path  = require('doing.state').state.tasks.file
            local buf    = vim.fn.bufadd(path)

            -- Load buffer and run FileType autocmd 
            vim.api.nvim_set_option_value("filetype", "doing_tasks", { buf = buf })
            vim.fn.bufload(buf)
            vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
            vim.api.nvim_win_set_buf(winid, buf)

            return true
          end
        }
      }
    },

    layouts = {
      ['fakezen'] = function()
        return require('pragma.pragma-builder').new({ 'fakezen' })
          :winonly   { }
          :subdivide { select = false, alias = 'left', direction = "left", width = 0.15, winopts = {
            number          = false,
            relativenumber  = false,
            statuscolumn    = ""
          }}
          :subdivide { select = false, alias = 'right', direction = "right", width = 0.15, winopts = {
            number          = false,
            relativenumber  = false,
            statuscolumn    = ""
          }}
          :buffer     { strategy = "scratch", winalias = 'left', winfixbuf = true }
          :buffer     { strategy = "scratch", winalias = 'right', winfixbuf = true }
          :buffer     { strategy = "lastbuffer", winalias = 'root' }
      end,

      ['vhh'] = function()
        return require('pragma.pragma-builder').new({ 'vhh' })
          :winonly   { }
          :subdivide { direction = "below", height = 0.33 }
          :subdivide { direction = "left", width = 0.4 }
          :focus     { alias = 'root' }
      end,

      ['vvvh-nvimtree-tasks-vuffer'] = function()
        return require('pragma.pragma-builder').new({ 'vvh-nvimtree-vuffer-lastused' })
          :winonly   { }
          :subdivide { direction = "left", alias = 'nvimtree', width = 40 }
          :subdivide { direction = "below", alias = 'doing_tasks', height = 0.60, winopts = {
            number          = true,
            relativenumber  = false,
            wrap            = true,
            statuscolumn    = ""
          }}
          :subdivide { direction = "below", alias = 'vuffers', height = 0.5, winopts = {
            number          = true,
            relativenumber  = false,
            statuscolumn    = "%{str2nr(line('$'))-v:lnum+1}"
          }}
          :buffer     { strategy = "special", name = 'nvimtree', winalias = 'nvimtree', winfixbuf = true }
          :buffer     { strategy = "special", name = 'vuffers', winalias = 'vuffers', winfixbuf = true }
          :buffer     { strategy = "special", name = 'doing_tasks', winalias = 'doing_tasks', winfixbuf = true }
          :buffer     { strategy = "lastbuffer", winalias = 'root' }
          :focus     { alias = 'root' }
      end,

      ['vvh-nvimtree-vuffer'] = function()
        return require('pragma.pragma-builder').new({ 'vvh-nvimtree-vuffer-lastused' })
          :winonly   { }
          :subdivide { direction = "left", alias = 'nvimtree', width = 40 }
          :subdivide { direction = "below", alias = 'vuffers', height = 0.35, winopts = {
            number          = true,
            relativenumber  = false,
            wrap            = true,
            statuscolumn    = ""
          }}
          :buffer     { strategy = "special", name = 'nvimtree', winalias = 'nvimtree', winfixbuf = true }
          :buffer     { strategy = "special", name = 'vuffers', winalias = 'vuffers', winfixbuf = true }
          :buffer     { strategy = "lastbuffer", winalias = 'root' }
          :focus     { alias = 'root' }
      end
    }
  }
}
```

