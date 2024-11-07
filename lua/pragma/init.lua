local M = { }


---@param opts PragmaConfiguration
function M.setup(opts)
	opts = opts or { }
	require('pragma.config').setup(opts)

	local config = require('pragma.config').get_config()
	if config.register_command then
		require('pragma.pragma-command').register_command() end
end

return M
