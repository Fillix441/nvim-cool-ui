local fn = vim.fn
local api = vim.api
local fmt = string.format
local L = vim.log.levels

-----------------------------------------------------------------------------//
-- Global namespace
-----------------------------------------------------------------------------//
--- Inspired by @tjdevries' astraunauta.nvim/ @TimUntersberger's config
--- store all callbacks in one global table so they are able to survive re-requiring this file
_G.__global_callbacks = __global_callbacks or {}

_G.gl = {
  _store = __global_callbacks,
  --- work around to place functions in the global scope but namespaced within a table.
  --- TODO: refactor this once nvim allows passing lua functions to mappings
  mappings = {},
}

-----------------------------------------------------------------------------//
-- UI
-----------------------------------------------------------------------------//
-- Consistent store of various UI items to reuse throughout my config
gl.style = {
  icons = {
    error = '✗',
    warning = '',
    info = '',
    hint = '',
  },
  lsp = {
    kinds = {
      Text = '',
      Method = '',
      Function = '',
      Constructor = '',
      Field = 'ﰠ',
      Variable = '',
      Class = 'ﴯ',
      Interface = '',
      Module = '',
      Property = 'ﰠ',
      Unit = '塞',
      Value = '',
      Enum = '',
      Keyword = '',
      Snippet = '',
      Color = '',
      File = '',
      Reference = '',
      Folder = '',
      EnumMember = '',
      Constant = '',
      Struct = 'פּ',
      Event = '',
      Operator = '',
      TypeParameter = '',
    },
  },
}

-----------------------------------------------------------------------------//
-- Debugging
-----------------------------------------------------------------------------//
-- The length operator is denoted by the unary operator #.
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :lua P(vim.loop)
---@vararg any
function _G.P(...)
  local objects, v = {}, nil
  for i = 1, select('#', ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, '\n'))
  return ...
end

function _G.dump_text(...)
  local objects, v = {}, nil
  for i = 1, select('#', ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, '\n'), '\n')
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end

local installed
---Check if a plugin is on the system not whether or not it is loaded
---@param plugin_name string
---@return boolean
function gl.plugin_installed(plugin_name)
  if not installed then
    local dirs = fn.expand(fn.stdpath 'data' .. '/site/pack/packer/start/*', true, true)
    local opt = fn.expand(fn.stdpath 'data' .. '/site/pack/packer/opt/*', true, true)
    vim.list_extend(dirs, opt)
    installed = vim.tbl_map(function(path)
      return fn.fnamemodify(path, ':t')
    end, dirs)
  end
  return vim.tbl_contains(installed, plugin_name)
end

---NOTE: this plugin returns the currently loaded state of a plugin given
---given certain assumptions i.e. it will only be true if the plugin has been
---loaded e.g. lazy loading will return false
---@param plugin_name string
---@return boolean?
function gl.plugin_loaded(plugin_name)
  local plugins = packer_plugins or {}
  return plugins[plugin_name] and plugins[plugin_name].loaded
end

-----------------------------------------------------------------------------//
-- Utils
-----------------------------------------------------------------------------//
function gl._create(f)
  table.insert(gl._store, f)
  return #gl._store
end

function gl._execute(id, args)
  gl._store[id](args)
end

---@class Autocommand
---@field events string[] list of autocommand events
---@field targets string[] list of autocommand patterns
---@field modifiers string[] e.g. nested, once
---@field command string | function

---@param command Autocommand
local function is_valid_target(command)
  local valid_type = command.targets and vim.tbl_islist(command.targets)
  return valid_type or vim.startswith(command.events[1], 'User ')
end

---Create an autocommand
---@param name string
---@param commands Autocommand[]
function gl.augroup(name, commands)
  vim.cmd('augroup ' .. name)
  vim.cmd 'autocmd!'
  for _, c in ipairs(commands) do
    if c.command and c.events and is_valid_target(c) then
      local command = c.command
      if type(command) == 'function' then
        local fn_id = gl._create(command)
        command = fmt('lua gl._execute(%s)', fn_id)
      end
      vim.cmd(
        fmt(
          'autocmd %s %s %s %s',
          table.concat(c.events, ','),
          table.concat(c.targets or {}, ','),
          table.concat(c.modifiers or {}, ' '),
          command
        )
      )
    else
      vim.notify(
        fmt('An autocommand in %s is specified incorrectly: %s', name, vim.inspect(name)),
        L.ERROR
      )
    end
  end
  vim.cmd 'augroup END'
end

---Source a lua or vimscript file
---@param path string path relative to the nvim directory
---@param prefix boolean?
function gl.source(path, prefix)
  if not prefix then
    vim.cmd(fmt('source %s', path))
  else
    vim.cmd(fmt('source %s/%s', fn.stdpath 'config', path))
  end
end

---Require a module using [pcall] and report any errors
---@param module string
---@param opts table?
---@return boolean, any
function gl.safe_require(module, opts)
  opts = opts or { silent = false }
  local ok, result = pcall(require, module)
  if not ok and not opts.silent then
    vim.notify(result, L.ERROR, { title = fmt('Error requiring: %s', module) })
  end
  return ok, result
end

---Check if a cmd is executable
---@param e string
---@return boolean
function gl.executable(e)
  return fn.executable(e) > 0
end

-- https://stackoverflow.com/questions/1283388/lua-merge-tables
function gl.deep_merge(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == 'table') and (type(t1[k] or false) == 'table') then
      gl.deep_merge(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end

---A terser proxy for `nvim_replace_termcodes`
---@param str string
---@return any
function gl.replace_termcodes(str)
  return api.nvim_replace_termcodes(str, true, true, true)
end

--- Usage:
--- 1. Call `local stop = utils.profile('my-log')` at the top of the file
--- 2. At the bottom of the file call `stop()`
--- 3. Restart neovim, the newly created log file should open
function gl.profile(filename)
  local base = '/tmp/config/profile/'
  fn.mkdir(base, 'p')
  local success, profile = pcall(require, 'plenary.profile.lua_profiler')
  if not success then
    vim.api.nvim_echo({ 'Plenary is not installed.', 'Title' }, true, {})
  end
  profile.start()
  return function()
    profile.stop()
    local logfile = base .. filename .. '.log'
    profile.report(logfile)
    vim.defer_fn(function()
      vim.cmd('tabedit ' .. logfile)
    end, 1000)
  end
end

---check if a certain feature/version/commit exists in nvim
---@param feature string
---@return boolean
function gl.has(feature)
  return vim.fn.has(feature) > 0
end

--- TODO: Need to Understand how it works
---Find an item in a list
---@generic T
---@param haystack T[]
---@param matcher fun(arg: T):boolean
---@return T
function gl.find(haystack, matcher)
  local found
  for _, needle in ipairs(haystack) do
    if matcher(needle) then
      found = needle
      break
    end
  end
  return found
end

---Determine if a value of any type is empty
---@param item any
---@return boolean
function gl.empty(item)
  if not item then
    return true
  end
  local item_type = type(item)
  if item_type == 'string' then
    return item == ''
  elseif item_type == 'table' then
    return vim.tbl_isempty(item)
  end
end

---Create an nvim command
---@param args table
function gl.command(args)
  local nargs = args.nargs or 0
  local name = args[1]
  local rhs = args[2]
  local types = (args.types and type(args.types) == 'table') and table.concat(args.types, ' ') or ''

  if type(rhs) == 'function' then
    local fn_id = gl._create(rhs)
    rhs = string.format('lua gl._execute(%d%s)', fn_id, nargs > 0 and ', <f-args>' or '')
  end

  vim.cmd(string.format('command! -nargs=%s %s %s %s', nargs, types, name, rhs))
end

function gl.invalidate(path, recursive)
  if recursive then
    for key, value in pairs(package.loaded) do
      if key ~= '_G' and value and vim.fn.match(key, path) ~= -1 then
        package.loaded[key] = nil
        require(key)
      end
    end
  else
    package.loaded[path] = nil
    require(path)
  end
end

function gl.has_map(lhs, mode)
  mode = mode or 'n'
  return vim.fn.maparg(lhs, mode) ~= ''
end
