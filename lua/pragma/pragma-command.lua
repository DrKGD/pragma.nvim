
---@class CommandSubcommand
---@field impl			fun(args:string[], opts: table)					The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback, taking the lead of the subcommand's arguments

---@type table<string, CommandSubcommand>
local lup_command = {
	apply = {
		impl = function(args, _)
			local layout_list = require('pragma.config').get_config().layouts
			local selected = layout_list and layout_list[args[1]]
			if not selected then
				vim.notify(("No layout named `%s` was found!"):format(args[1]), vim.log.levels.WARN, { title = "PragmaApply", kind = "pragma" })
				return end

			-- Evaluate once
			if type(selected) == 'function' then
				selected = selected()
				layout_list[args[1]] = selected end
			selected:apply()
		end,

		complete = function(lead)
			return vim.iter(vim.tbl_keys(require('pragma.config').get_config().layouts))
							:filter(function(k)
								return k:find(lead)
							end):totable()
		end
	}
}

local function lup_main(opts)
	local sub, args = opts.fargs[1], vim.list_slice(opts.fargs, 2, #opts.fargs) or { }

	-- Attempt to find subcommand
	local subcommand = lup_command[sub]
	if not subcommand then
		vim.notify(("No subcommand named `%s` was found!"):format(sub), vim.log.levels.ERROR, { title = "PragmaCommand", kind = "pragma" }) 
		return end

	-- Run subcommand
	subcommand.impl(args, opts)
end

local function lup_complete(arg_lead, cmdline, _)
	-- Command selected
	local sub, lead = cmdline:match("^['<,'>]*Pragma*%s(%S+)%s(.*)$")
	if sub and lead and lup_command[sub] and lup_command[sub].complete then
		return lup_command[sub].complete(lead) end

	-- Still selecting a command
	if cmdline:match("['<,'>]*Pragma*%s+%w*$") then
			local subcommand_keys = vim.tbl_keys(lup_command)
			return vim.iter(subcommand_keys)
				:filter(function(key) return key:find(arg_lead) end)
				:totable() end
end

local M = { }

-- THANKS: https://github.com/nvim-neorocks/nvim-best-practices?tab=readme-ov-file#speaking_head-user-commands
function M.register_command()
	vim.api.nvim_create_user_command("Pragma", lup_main, {
		desc			= "Apply a pragma layout, stored in the configuration",
		complete	= lup_complete,
		nargs			= "+",
	})
end

return M
