---@class MetaOption
---@field	default?		boolean | string | number | function | table
---@field	required?		boolean
---@field	desc				string
---@field	transform?	function
---@field	validate		function

---@alias MetaValues table<string, boolean | string | number | function | table>

---@class MetaSubStrategyOpt
---@field class	table
---@field opts	table<string, MetaOption>
---@field	fn		function(runtime: PragmaBuilderRuntime, opts: MetaValues[]): boolean, string?

---@class _Meta
local _meta = { }
_meta.__index = _meta

local function prepare(opts)
	-- Whether or not a value is required to perform that very action
	--  If a default value was specified
	local requirements =
		vim.iter(opts)
			:filter(function(_, conf) return conf.required and conf.default == nil end)
			:map(function(k) return k end)
			:totable()

	local defaults =
		vim.iter(opts)
			:filter(function(_, conf) return conf.default end)
			:fold({ }, function(acc, key, opt)
				acc[key] = opt.default
				return acc
			end)

	return requirements, defaults
end

local function unknown_field(class_name, field, value)
	return false,
		("no field named '%s', with value '%s', was recognised for action named '%s'")
			:format(class_name, field, value)
end

---@protected
---@param		class			table
---@param 	defaults	table<string, MetaOption>
---@param 	opts			table<string, boolean | string | number | function | table>
---@return	table<string, boolean | string | number | function | table> 
---Returns the validated key-value table if successful
---raises error if validation failed instead
function _meta.validate(class, defaults, opts, builder)
	assert(type(defaults) == 'table', 'defaults has to be of required type table')
	assert(type(opts) == 'table', 'opts is not of required type table')
	if not class.req or not class.def then
		class.req, class.def = prepare(defaults) end

	-- Some of the requirements are missing
	local missing_requirements =
		vim.iter(vim.deepcopy(class.req))
			:filter(function(k) return not opts[k] end)
			:totable()
	assert(#missing_requirements == 0,
		("%s is missing the following required fields: [%s]"):format(class.name or 'unnamed', table.concat(missing_requirements, ', ')))

	-- Append defaults in the dictionary
	opts = vim.tbl_deep_extend("keep", opts, vim.deepcopy(class.def))

	-- Perform validation
	local retval, errors = { }, { }
	for key, value in pairs(opts) do
		local eval						= (type(value) == 'function' and value(builder)) or value
		local status, message = (defaults[key] or { validate = unknown_field }).validate(key, eval)
		if not status then
			table.insert(errors, ("%s: %s [provided %s]"):format(key, message, vim.inspect(eval)))
		else
			retval[key] = (defaults.transform and defaults.transform(value)) or value
		end
	end

	assert(#errors == 0,
		("%s reported the following errors:\n\t%s"):format(class.name or 'unnamed', table.concat(errors, "\n\t")))

	return retval
end

---@private
function _meta.perform()
	error("not implemented")
end

return _meta
