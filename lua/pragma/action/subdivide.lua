---@class PragmaBuilder
---@field subdivide PragmaBuilderFunction

---@class SubdivideOpts
---@field select		MetaOption
---@field direction MetaOption
---@field width			MetaOption
---@field height		MetaOption
---@field alias			MetaOption
---@field winopts		MetaOption

---@type SubdivideOpts
local subdivide_opts = {
	select =
		{ default		= true,
			required	= true,
			desc			= "Whether or not the newly subdivided window has to retain control",
			validate	= function(_, opt)
				return type(opt) == 'boolean', 'has to be a boolean'
			end },

	direction =
		{ required = true,
			desc		 = "In which direction should the split happen",
			validate = function(_, opt)
				return opt == 'left' or opt == 'right' or opt == 'above' or opt == 'below',
					'only directions are allowed (left,right,above,below)'
			end },

	width			=
		{ required = false,
			desc		 = "Width of the newly created window, if applicable; numbers between 0 and 1 are interpreted as percentages of the whole viewport instead",
			validate = function(_, opt)
				return type(opt) == 'number', 'has to be a number'
			end },

	height		=
		{ required = false,
			desc		 = "Height of the newly created window, if applicable; numbers between 0 and 1 are interpreted as percentages of the whole viewport instead",
			validate = function(_, opt)
				return type(opt) == 'number', 'has to be a number'
			end },

	alias				=
		{ required = false,
			desc		 = "Refer to the window with that alias",
			validate = function(_, opt)
				return type(opt) == 'string', 'has to be a string'
			end },

	-- TODO: Assert these are valid window option(s)
	-- setup window with window options
	winopts		=
		{ required	= false,
			default		= { },
			desc			= "Window local options",
			validate	= function(_, opt)
				return type(opt) == 'table'
					and not vim.iter(opt):find(function(k) return type(k) ~= 'string' end), "winopts should be a table of windows options"
			end },
}

local _meta = require('pragma.action._meta')

---@class Subdivide:_Meta
local Subdivide = { name = "Subdivide" }
setmetatable(Subdivide, _meta)

---@param opts		MetaValues
---@param builder PragmaBuilder
---@return MetaValues
---Validate how the subdivision should be performed
function Subdivide.validate(opts, builder)
	return _meta.validate(Subdivide, subdivide_opts, opts, builder)
end

---@private
local function prop(val, maxd)
	return (val == math.floor(val) and val)
		or math.min(math.floor(val * maxd), maxd)
end

---@return boolean, string?
---Perform subdivision, thus return whether or not it was a success
function Subdivide.perform(runtime, opts)
	-- Attempt to create window
	local winid =
		vim.api.nvim_open_win(0, opts.select, {
			split  = opts.direction,
			width  = opts.width  and prop(opts.width, vim.api.nvim_win_get_width(0)) or nil,
			height = opts.height and prop(opts.height, vim.api.nvim_win_get_height(0))  or nil,
		})

	-- Append to focus list
	if opts.select then
		table.insert(runtime.focus, winid) end

	-- Add alias (and apped a digit)
	table.insert(runtime.windows, winid)
	if opts.alias then
		if runtime.windows[opts.alias] then
			return false, ("There is already a window named %s"):format(opts.alias) end
		runtime.windows[opts.alias] = winid end

	-- Apply window style
	vim.iter(opts.winopts or { })
		:each(function(key, opt)
			vim.api.nvim_set_option_value(key, opt, { win = winid })
		end)

	return true
end


return Subdivide
