---@class PragmaBuilder
---@field winonly PragmaBuilderFunction

---@class WinOnly

---@type WinOnly
local winonly_opts = {

}

local _meta = require('pragma.action._meta')

---@class WinOnly:_Meta
local WinOnly = { name = "WinOnly" }
setmetatable(WinOnly, _meta)

---@param opts		MetaValues
---@param builder PragmaBuilder
---@return MetaValues
---Nothing much to validate, just ensure no opts were passed I guess
function WinOnly.validate(opts, builder)
	return _meta.validate(WinOnly, winonly_opts, opts, builder)
end

---@return boolean, string?
---Closes all windows but the one underneath the cursor
---Does not modify the buffer order (which is kept in lastused)
function WinOnly.perform(runtime, _)
	vim.iter(vim.api.nvim_tabpage_list_wins(0))
		:filter(function(wid) return wid ~= runtime.windows.root end)
		:each(function(wid) vim.api.nvim_win_close(wid, true) end)

	local cbuf = vim.api.nvim_create_buf(false, false)
	vim.api.nvim_set_current_buf(cbuf)
	return true
end

return WinOnly
