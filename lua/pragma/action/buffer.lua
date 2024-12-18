---@class PragmaBuilder
---@field buffer PragmaBuilderFunction

---@type table<string, MetaSubStrategyOpt>
local lup_strategy = {
	edit = {
		class = { name = "BufferStrategyEdit" },
		opts	= {
			path =
				{ required	= true,
					desc			= "Open the file at the given path",
					transform = function(_, opt)
						return vim.uv.fs_realpath(opt) or opt
					end,
					validate	= function(_, opt)
						return type(opt) == 'string', 'a string path is required'
					end },

			-- TODO: Assert these are valid window option(s)
			-- setup buffer with buffer options
			bufopts =
				{ required	= false,
					default		= { },
					desc			= "Buffer local options",
					validate	= function(_, opt)
						return type(opt) == 'table'
							and not vim.iter(opt):find(function(k) return type(k) ~= 'string' end), "bufopts should be a table of buffer options"
					end },
		},

		fn = function(_, opts)
			local buf = vim.fn.bufadd(opts.path)

			-- Apply buffer opts
			vim.iter(opts.bufopts or { })
				:each(function(key, opt)
					vim.api.nvim_set_option_value(key, opt, { buf = buf })
				end)

			-- Load buffer and run FileType autocmd 
			vim.fn.bufload(buf)
			vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
			vim.api.nvim_win_set_buf(opts.winid, buf)

			return true
		end
	},

	special = {
		class = { name = "BufferStrategySpecial" },
		opts	= {
			name =
				{ required	= true,
					desc			= "Which special buffer should be opened (specify in configuration)",
					validate	= function(_, opt)
						return type(opt) == 'string', "opt has to be string"
					end },
		},

		fn = function(runtime, opts)
			local pragma_config = require('pragma.config').get_config()
			if not pragma_config.action.buffer.special[opts.name] then
				return false, ("I don't know how to open unknown special buffer %s"):format(opts.name) end
			return assert(pragma_config.action.buffer.special[opts.name])(opts.winid)
		end
	},

	lastbuffer = {
		class = { name = "BufferStrategyLastBuffer" },
		opts	= {
			amount =
				{ required	= true,
					default		= 1,
					desc			= "Lastbuffer relative to the last opened buffer (consult `:ls t`)",
					transform = function(_, opt)
						return math.abs(math.floor(opt))
					end,
					validate	= function(_, opt)
						return type(opt) == 'number', 'amount has to be an integer'
					end },
		},

		fn = function(runtime, opts)
			local buf = (runtime.buffers[opts.amount] or { buf = vim.api.nvim_create_buf(false, false) }).buf
			vim.api.nvim_win_set_buf(opts.winid, buf)
			return true
		end
	},

	scratch = {
		class = { name = "BufferStrategyScratch" },
		opts	= { },
		fn = function(_, opts)
			local buf = vim.api.nvim_create_buf(false, false)
			vim.api.nvim_win_set_buf(opts.winid, buf)
			return true
		end
	}
}

local buffer_opts = {
	strategy =
		{ default		= 'scratch',
			required	= true,
			desc			= "Which strategy to use for the buffer",
			validate	= function(_, opt)
				return lup_strategy[opt],
					('only these strategies are allowed (%s)'):format(table.concat(vim.tbl_keys(lup_strategy), ', '))
			end },

	winalias =
		{ required	= false,
			desc			= "Should open the buffer in a specific window via alias",
			validate	= function(_, opt)
				return type(opt) == 'string' or type(opt) == 'number', "winalias should be either a string or a number"
			end },

	winfixbuf =
		{ required	= true,
			default		= false,
			desc			= "Lock buffer into place",
			validate	= function(_, opt)
				return type(opt) == 'boolean', "winfixbuf has to be a boolean"
			end },
}

local _meta = require('pragma.action._meta')

---@class Buffer:_Meta
local Buffer = { name = "Buffer" }
setmetatable(Buffer, _meta)

---@param opts		MetaValues
---@param builder PragmaBuilder
---@return MetaValues
---Validate which strategy should be adopted to open the buffer
function Buffer.validate(opts, builder)
	local fstep = _meta.validate(Buffer, buffer_opts, { strategy = opts.strategy, winalias = opts.winalias, winfixbuf = opts.winfixbuf }, builder)
	local lup		= assert(lup_strategy[fstep.strategy])

	opts.strategy		= nil
	opts.winalias 	= nil
	opts.winfixbuf	= nil
	local sstep =_meta.validate(lup.class, lup.opts, opts, builder)
	return vim.tbl_extend("error", fstep, sstep)
end

---@return boolean, string?
---Open the buffer in given window via the selected strategy
function Buffer.perform(runtime, opts)
	opts.winid = (opts.winalias and runtime.windows[opts.winalias])
		or (not opts.winalias and runtime.focus[#runtime.focus])
	if not opts.winid then
		return false, "Could not determine winid"  end

	local status, msg = assert(lup_strategy[opts.strategy]).fn(runtime, opts)
	if not status then
		return status, msg end
	vim.api.nvim_set_option_value("winfixbuf", opts.winfixbuf, { win = opts.winid })
	return true
end

return Buffer
