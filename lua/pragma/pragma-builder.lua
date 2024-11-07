
---@class PragmaBuilderOptions
---@field name? string
---@field [1]?	string

---@alias PragmaBuilderFunction function(action: PragmaBuilderAction): PragmaBuilder
---@class PragmaBuilder
---@field name			string
---@field actions		table[]
---@field add				PragmaBuilderFunction
local PragmaBuilder = { }

---@return PragmaBuilder | function(action: PragmaBuilderAction): PragmaBuilder
---Automatically addresses extended functions
PragmaBuilder.__index = function(_, key)
	return PragmaBuilder[key]
		or function(self, opts) return PragmaBuilder.add(self, { kind = key, opts = opts }) end
end

---@param		opts PragmaBuilderOptions
---@return	PragmaBuilder
---Returns a new PragmaBuilder, which will then store all required steps
function PragmaBuilder.new(opts)
	assert(not opts or type(opts) == 'table', 'opts is not of required type table')
	opts = opts or { }
		opts.name = opts.name or opts[1] or 'unnamed_layout'

	assert(type(opts.name) == 'string', 'opts.name is not of required type string')

	local o = setmetatable({ }, PragmaBuilder)
		o.name		= opts.name
		o.actions	= { }
	return o
end

---@param name string
---@return PragmaBuilder, PragmaBuilder
---Creates a duplicate for the PragmaBuilder
function PragmaBuilder:dup(name)
	local o = vim.deepcopy(self)
		o.name = name or ('%s-clone'):format(o.name)
	return self, o
end

---@param		kind? string
---@return	integer
---Returns the number of defined instruction(s) in the builder
function PragmaBuilder:count(kind)
	return (not kind and #self.actions)
		or #(vim.iter(self.actions):filter(function(entry) return entry.kind == kind end):totable())
end

---@class PragmaBuilderAction
---@field kind string
---@field opts table<string, MetaOption>

---@param action PragmaBuilderAction
function PragmaBuilder:add(action)
	assert(type(action) == 'table', 'action is not of required type table')
		action.kind = action.kind or action[1]
		action.opts = action.opts or action[2] or { }

	assert(type(action.kind) == 'string', 'action.kind is not of required type string')
	assert(type(action.opts) == 'table', 'action.opts is not of required type table')

	local status, module = pcall(require, ('pragma.action.%s'):format(action.kind))
	if not status then
		error(('PragmaBuilder could not find action of kind %s:\n%s'):format(action.kind, module)) end
	table.insert(self.actions, { kind = action.kind, fn = module.perform, opts = module.validate(action.opts, self) })
	return self
end

---@class PragmaBuilderRuntime
---@field windows	table<string | integer, integer>	Key-pair of windows (alias - window)
---@field buffers	integer[]													List of buffers, ordered by lastused
---@field focus		integer[] 												List of windows which had the focus

---@private
---@return PragmaBuilderRuntime
---Prepare runtime for the builder
local function setup_runtime()
	local current_window = vim.api.nvim_get_current_win()

	-- Setup runtime
	local runtime = { }
		runtime.windows	= { [0] = current_window, root = current_window }
		runtime.buffers = vim.iter(vim.fn.getbufinfo({ buflisted = 1 }))
			:filter(function(entry) return vim.fn.empty(entry.name) == 0 end)
			:map(function(entry)
				return { buf = entry.bufnr, lastused = entry.lastused, name = entry.name }
			end):totable()
			table.sort(runtime.buffers, function(a,b) return a.lastused > b.lastused end)
		runtime.focus		= { current_window }

	return runtime
end

---Apply the layout built via PragmaBuilder
function PragmaBuilder:apply()
	local rt						= setup_runtime()
	for ix, step in ipairs(self.actions) do
		local status, message = step.fn(rt, step.opts)
		if not status then
			local msg = ("• Step %s [%d]\nFailed for reason: %s!\n \nStep specifications: %s"):format(step.kind, ix, message or 'unknown reason', vim.inspect(step.opts))
			vim.notify(msg, vim.log.levels.ERROR, { kind = 'pragma', title = ('pragma-apply: %s'):format(self.name) })
			return false
		end
	end
end

return PragmaBuilder
