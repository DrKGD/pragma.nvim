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
				end,

				['doing_tasks'] = function(winid)
					local path	= require('doing.state').tasks.file
					local buf		= vim.fn.bufadd(path)

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
				:winonly	 { }
				:subdivide { select = false, alias = 'left', direction = "left", width = 0.15, winopts = {
					number					= false,
					relativenumber	= false,
					statuscolumn		= ""
				}}
				:subdivide { select = false, alias = 'right', direction = "right", width = 0.15, winopts = {
					number					= false,
					relativenumber	= false,
					statuscolumn		= ""
				}}
				:buffer		 { strategy = "scratch", winalias = 'left', winfixbuf = true }
				:buffer		 { strategy = "scratch", winalias = 'right', winfixbuf = true }
				:buffer		 { strategy = "lastbuffer", winalias = 'root' }
		end,

		['vhh'] = function()
			return require('pragma.pragma-builder').new({ 'vhh' })
				:winonly	 { }
				:subdivide { direction = "below", height = 0.33 }
				:subdivide { direction = "left", width = 0.4 }
				:focus		 { alias = 'root' }
		end,

		['vvvh-nvimtree-tasks-vuffer'] = function()
			return require('pragma.pragma-builder').new({ 'vvh-nvimtree-vuffer-lastused' })
				:winonly	 { }
				:subdivide { direction = "left", alias = 'nvimtree', width = 40 }
				:subdivide { direction = "below", alias = 'doing_tasks', height = 0.60, winopts = {
					number					= true,
					relativenumber	= false,
					wrap						= true,
					statuscolumn		= ""
				}}
				:subdivide { direction = "below", alias = 'vuffers', height = 0.5, winopts = {
					number					= true,
					relativenumber	= false,
					statuscolumn		= "%{str2nr(line('$'))-v:lnum+1}"
				}}
				:buffer		 { strategy = "special", name = 'nvimtree', winalias = 'nvimtree', winfixbuf = true }
				:buffer		 { strategy = "special", name = 'vuffers', winalias = 'vuffers', winfixbuf = true }
				:buffer		 { strategy = "special", name = 'doing_tasks', winalias = 'doing_tasks', winfixbuf = true }
				:buffer		 { strategy = "lastbuffer", winalias = 'root' }
				:focus		 { alias = 'root' }
		end,

		['vvh-nvimtree-vuffer'] = function()
			return require('pragma.pragma-builder').new({ 'vvh-nvimtree-vuffer-lastused' })
				:winonly	 { }
				:subdivide { direction = "left", alias = 'nvimtree', width = 40 }
				:subdivide { direction = "below", alias = 'vuffers', height = 0.35, winopts = {
					number					= true,
					relativenumber	= false,
					wrap						= true,
					statuscolumn		= ""
				}}
				:buffer		 { strategy = "special", name = 'nvimtree', winalias = 'nvimtree', winfixbuf = true }
				:buffer		 { strategy = "special", name = 'vuffers', winalias = 'vuffers', winfixbuf = true }
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

