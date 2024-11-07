---@class PragmaBuilder
---@field focus PragmaBuilderFunction

local directions = {
	['left']	= 'h',
	['h']			= 'h',

	['right'] = 'l',
	['l']			= 'l',

	['above'] = 'k',
	['k']			= 'k',

	['below'] = 'j',
	['j']			= 'j',
}


---@type table<string, MetaSubStrategyOpt>
local lup_strategy = {
	alias			= {
		class = { name = "FocusStrategyAlias" },
		opts	= {
			alias =
				{ required	= true,
					desc			= "Which alias should be focussed",
					validate	= function(_, opt)
						return type(opt) == 'string' or type(opt) == 'number', "alias should be either a string or a number"
					end },
		},

		fn = function(runtime, opts)
			local winid = runtime.windows[opts.alias]
			if not winid then
				return false, ('No window named "%s" was found'):format(opts.alias) end

			vim.api.nvim_set_current_win(winid)
			table.insert(runtime.focus, winid)
			return true
		end
	},

	direction = {
		class = { name = "FocusStrategyDirection" },
		opts  = {
			direction =
				{ required	= true,
					desc			= "In which direction should the focus attempt to move",
					transform = function(_, opt)
						return directions[opt]
					end,
					validate	= function(_, opt)
						return directions[opt], "direction should be described as (left|right|above|below) or (h|j|k|l)"
					end },
		},

		fn = function(runtime, opts)
			local current_window = runtime.focus[#runtime.focus]

			vim.cmd.wincmd(opts.direction)
			local newid = vim.api.nvim_get_current_win()
			if current_window== newid then
				return false, ("Could not focus a window in the given direction %s"):format(opts.direction) end

			table.insert(runtime.focus, newid)
			return true
		end
	},

	backtrack = {
		class = { name = "FocusStrategyBacktrack" },
		opts  = {
			amount =
				{ required	= true,
					default		= -1,
					desc			= "Attempt this much amount of backtracking",
					validate	= function(_, opt)
						if type(opt) ~= 'number' then
							return false, "amount has to be specified as a number" end

						if opt == 0 then
							return false, "amount cannot be zero!" end

						return true
					end },

			slice =
				{ required  = true,
					default		= true,
					desc			= "Should the focus list be sliced on a backtrack action?",
					validate  = function(_, opt)
						return type(opt) == 'boolean', 'has to be a boolean'
					end }
		},

		fn = function(runtime, opts)
			local index = #runtime.focus + opts.amount
			local winid = runtime.focus[index]
			if not winid then
				return false, ('Coudl not backtrack to index %d, as it is out of bounds [1 - %02d]'):format(index, #runtime.focus) end
			vim.api.nvim_set_current_win(winid)

			-- Remove 
			if opts.slice then
				for ix=index, #runtime.focus do
					runtime.focus[ix] = nil end end
			table.insert(runtime.focus, winid)

			return true
		end
	}
}

---@class FocusOpts
---@field strategy MetaOption

---@type FocusOpts
local focus_opts = {
	strategy =
		{ default		= 'alias',
			required	= true,
			desc			= "Which strategy should be applied in changing the window focus",
			validate	= function(_, opt)
				return lup_strategy[opt],
					('only these strategies are allowed (%s)'):format(table.concat(vim.tbl_keys(lup_strategy), ', '))
			end },
}

local _meta = require('pragma.action._meta')

---@class Focus:_Meta
local Focus = { name = "Focus" }
setmetatable(Focus, _meta)

---@param opts		MetaValues
---@param builder PragmaBuilder
---@return MetaValues
---Validate which strategy should be adopted to focus window
function Focus.validate(opts, builder)
	local fstep = _meta.validate(Focus, focus_opts, { strategy = opts.strategy }, builder)
	local lup		= assert(lup_strategy[fstep.strategy])

	opts.strategy = nil
	local sstep =_meta.validate(lup.class, lup.opts, opts, builder)
	return vim.tbl_extend("error", fstep, sstep)
end

---@return boolean, string?
---Focus a new window via the selected strategy
function Focus.perform(runtime, opts)
	return assert(lup_strategy[opts.strategy]).fn(runtime, opts)
end

return Focus
