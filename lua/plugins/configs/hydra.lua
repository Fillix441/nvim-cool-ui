local Hydra = require 'hydra'
local border = G.style.border

Hydra {
  name = 'Buffer management',
  mode = 'n',
  body = '<leader>b',
  invoke_on_body = true,
  color = 'teal',
  config = {
    hint = { border = border },
  },
  heads = {
    { 'l', '<Cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer' } },
    { 'h', '<Cmd>BufferLineCyclePrev<CR>', { desc = 'Prev buffer' } },
    { 'p', '<Cmd>BufferLineTogglePin<CR>', { desc = 'Pin buffer' } },
    { 'c', '<Cmd>BufferLinePick<CR>', { desc = 'Pin buffer' } },
    { 'd', '<Cmd>BufferLinePickClose<CR>', { desc = 'Pick buffer to close', exit = true } },
    { '<Esc>', nil, { exit = true, desc = 'Quit' } },
  },
}

Hydra {
  name = 'Side scroll',
  mode = 'n',
  body = 'z',
  heads = {
    { 'h', '5zh' },
    { 'l', '5zl', { desc = '←/→' } },
    { 'H', 'zH' },
    { 'L', 'zL', { desc = 'half screen ←/→' } },
  },
}

Hydra {
  name = 'Window management',
  config = {
    hint = {
      border = border,
    },
  },
  mode = 'n',
  body = '<C-w>',
  heads = {
    -- Move
    { 'h', '<C-w>h' },
    { 'j', '<C-w>j' },
    { 'k', '<C-w>k' },
    { 'l', '<C-w>l' },
    -- Split
    { 's', '<C-w>s' },
    { 'v', '<C-w>v' },
    { 'q', '<Cmd>Bwipeout<CR>', { desc = 'close window' } },
    -- Size
    { '+', '2<C-w>+' },
    { '-', '2<C-w>-' },
    { '>', '5<C-w>>', { desc = 'increase width' } },
    { '<', '5<C-w><', { desc = 'decrease width' } },
    { '=', '<C-w>=', { desc = 'equalize' } },
    --
    { '<Esc>', nil, { exit = true } },
  },
}

local ok, gitsigns = pcall(require, 'gitsigns')
if ok then
  local hint = [[
 _J_: next hunk   _s_: stage hunk        _d_: show deleted   _b_: blame line
 _K_: prev hunk   _u_: undo stage hunk   _p_: preview hunk   _B_: blame show full
 ^ ^              _S_: stage buffer      ^ ^                 _/_: show base file
 ^
 ^ ^              _<Enter>_: Neogit              _q_: exit
]]

  Hydra {
    name = 'Git Mode',
    hint = hint,
    config = {
      color = 'pink',
      invoke_on_body = true,
      hint = {
        position = 'bottom',
        border = border,
      },
      on_enter = function()
        gitsigns.toggle_linehl(true)
        gitsigns.toggle_deleted(true)
      end,
      on_exit = function()
        gitsigns.toggle_linehl(false)
        gitsigns.toggle_deleted(false)
      end,
    },
    mode = { 'n', 'x' },
    body = '<localleader>G',
    heads = {
      {
        'J',
        function()
          if vim.wo.diff then
            return ']c'
          end
          vim.schedule(function()
            gitsigns.next_hunk()
          end)
          return '<Ignore>'
        end,
        { expr = true },
      },
      {
        'K',
        function()
          if vim.wo.diff then
            return '[c'
          end
          vim.schedule(function()
            gitsigns.prev_hunk()
          end)
          return '<Ignore>'
        end,
        { expr = true },
      },
      { 's', ':Gitsigns stage_hunk<CR>', { silent = true } },
      { 'u', gitsigns.undo_stage_hunk },
      { 'S', gitsigns.stage_buffer },
      { 'p', gitsigns.preview_hunk },
      { 'd', gitsigns.toggle_deleted, { nowait = true } },
      { 'b', gitsigns.blame_line },
      {
        'B',
        function()
          gitsigns.blame_line { full = true }
        end,
      },
      { '/', gitsigns.show, { exit = true } }, -- show the base of the file
      { '<Enter>', '<cmd>Neogit<CR>', { exit = true } },
      { 'q', nil, { exit = true, nowait = true } },
    },
  }
end
