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
          end
        }
      }
    },

    layouts = {
      ['vhh'] =
        require('pragma.pragma-builder').new({ 'vhh' })
          :winonly   { }
          :subdivide { direction = "below", height = 0.33 }
          :subdivide { direction = "left", width = 0.4 }
          :focus     { alias = 'root' },

      ['vvh-nvimtree-vuffer-lastused'] =
        require('pragma.pragma-builder').new({ 'vvh-nvimtree-vuffer-lastused' })
          :winonly   { }
          :subdivide { direction = "left", alias = 'nvimtree', width = 40 }
          :subdivide { direction = "below", alias = 'vuffers', height = 0.35, winopts = {
            number = false,
            relativenumber = false,
          }}
          :buffer     { strategy = "special", name = 'nvimtree', winalias = 'nvimtree' }
          :buffer     { strategy = "special", name = 'vuffers', winalias = 'vuffers'}
          :buffer     { strategy = "lastbuffer", winalias = 'root' }
          :focus     { alias = 'root' }
    }
  }
}
```


