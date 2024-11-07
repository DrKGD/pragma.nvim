local M = { }

---@class PragmaConfiguration
---@field register_command	boolean
---@field	action						table<string, table>
---@field	layouts						table<string, function>


---@type PragmaConfiguration
local _default = {
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
		['fakezen'] = function()
			return require('pragma.pragma-builder').new({ 'fakezen' })
				:winonly	 { }
				:subdivide { select = false, alias = 'fakezen', direction = "left", width = 0.15 }
				:subdivide { select = false, direction = "right", width = 0.15 }
				:buffer		 { strategy = "scratch", winalias = 'fakezen' }
				:buffer		 { strategy = "lastbuffer", winalias = 'root' }
		end,

		['vhh'] = function()
			return require('pragma.pragma-builder').new({ 'vhh' })
				:winonly	 { }
				:subdivide { direction = "below", height = 0.33 }
				:subdivide { direction = "left", width = 0.4 }
				:focus		 { alias = 'root' }
		end,

		['vvh-nvimtree-vuffer-lastused'] = function()
			return require('pragma.pragma-builder').new({ 'vvh-nvimtree-vuffer-lastused' })
				:winonly	 { }
				:subdivide { direction = "left", alias = 'nvimtree', width = 40 }
				:subdivide { direction = "below", alias = 'vuffers', height = 0.35, winopts = {
					number = false,
					relativenumber = false,
				}}
				:buffer		 { strategy = "special", name = 'nvimtree', winalias = 'nvimtree' }
				:buffer		 { strategy = "special", name = 'vuffers', winalias = 'vuffers'}
				:buffer		 { strategy = "lastbuffer", winalias = 'root' }
				:focus		 { alias = 'root' }
		end
	}
}

function M.default()
	return _default
end

local config
function M.get_config()
	return config or _default
end

---@param opts PragmaConfiguration
function M.setup(opts)
	assert(not opts or type(opts) == 'table', 'opts has to be a table to perform setup')
	config = vim.tbl_deep_extend("force", vim.deepcopy(_default), opts)
end

return M

