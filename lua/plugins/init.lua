local present, packer = pcall(require, 'utils.plugins')

if not present then
  return false
end

local use = packer.use

-- cfilter plugin allows filter down an existing quickfix list
vim.cmd 'packadd! cfilter'

return packer.startup(function()
  -- Core Plugin {{{
  use {
    { 'wbthomason/packer.nvim', opt = true },
    { 'nvim-lua/plenary.nvim' },
    { 'lewis6991/impatient.nvim' },
    {
      'lewis6991/gitsigns.nvim',
      config = function()
        require 'plugins.configs.gitsigns'
      end,
    },
    {
      'NTBBloodbath/doom-one.nvim',
      config = function()
        require('doom-one').setup {
          pumblend = {
            enable = true,
            transparency_amount = 3,
          },
        }
        -- Apply my own overwrite
        require('colors.doom').apply()
      end,
      setup = function()
        G.theme_loaded = true
      end,
    },
    {
      'kyazdani42/nvim-web-devicons',
      config = function()
        require 'plugins.configs.icons'
      end,
    },
    {
      'numToStr/Comment.nvim',
      event = 'BufRead',
      config = function()
        require('Comment').setup()
      end,
    },
  }
  -- }}}

  -- UI Plugin {{{
  use {
    {
      'akinsho/bufferline.nvim',
      event = 'BufAdd',
      config = function()
        require 'plugins.configs.bufferline'
      end,
    },
    {
      'lukas-reineke/indent-blankline.nvim',
      event = 'BufRead',
      config = function()
        require 'plugins.configs.blankline'
      end,
    },
    {
      'stevearc/dressing.nvim',
      config = function()
        require('dressing').setup {
          input = {
            insert_only = false,
          },
          select = {
            telescope = {
              theme = 'cursor',
            },
          },
        }
      end,
    },
    {
      'folke/todo-comments.nvim',
      disable = true,
      event = 'BufRead',
      config = function()
        -- this plugin is not safe to reload
        if vim.g.packer_compiled_loaded then
          return
        end
        require('todo-comments').setup {
          highlight = {
            exclude = { 'org', 'orgagenda', 'vimwiki', 'markdown' },
          },
        }
        vim.keymap.set('n', '<leader>lt', '<Cmd>TodoTrouble<CR>')
      end,
    },
  }
  -- }}}

  --- LSP Staff {{{
  use {
    {
      'neovim/nvim-lspconfig',
      ft = { 'lua', 'php', 'liquid' },
      config = function()
        require 'plugins.lsp'
      end,
      requires = {
        { 'folke/lua-dev.nvim' },
        { 'hrsh7th/cmp-nvim-lsp' },
        { 'jose-elias-alvarez/null-ls.nvim' },
        { 'b0o/schemastore.nvim' },
      },
    },
    {
      'ray-x/lsp_signature.nvim',
      after = 'nvim-lspconfig',
      config = function()
        require('lsp_signature').setup {
          bind = true,
          fix_pos = false,
          auto_close_after = 15, -- close after 15 seconds
          hint_enable = false,
          handler_opts = { border = 'rounded' },
        }
      end,
    },
    {
      'j-hui/fidget.nvim',
      config = function()
        require('fidget').setup {
          window = {
            blend = 0, -- BUG: window blend of > 0 interacts with nvim-bqf 😰
          },
        }
      end,
    },
    {
      'folke/trouble.nvim',
      cmd = 'TroubleToggle',
      config = [[require('plugins.configs.trouble')]],
    },
  }
  -- }}}

  --- Completion {{{
  use {
    {
      'hrsh7th/nvim-cmp',
      module = 'cmp',
      branch = 'dev',
      event = { 'InsertEnter' },
      requires = {
        { 'hrsh7th/cmp-nvim-lua', after = 'nvim-cmp' },
        { 'hrsh7th/cmp-cmdline', after = 'nvim-cmp' },
        { 'hrsh7th/cmp-path', after = 'nvim-cmp' },
        { 'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
        { 'saadparwaiz1/cmp_luasnip', after = 'nvim-cmp' },
      },
      config = function()
        require 'plugins.configs.cmp'
      end,
    },
    {
      'L3MON4D3/LuaSnip',
      event = 'InsertEnter',
      module = 'luasnip',
      config = function()
        require 'plugins.configs.luasnip'
      end,
    },
    {
      'windwp/nvim-autopairs',
      after = 'nvim-cmp',
      config = function()
        require('nvim-autopairs').setup {
          close_triple_quotes = true,
          check_ts = false,
        }
      end,
    },
    {
      'github/copilot.vim',
      config = function()
        vim.g.copilot_no_tab_map = true
        vim.g.copilot_assume_mapped = true
        vim.g.copilot_tab_fallback = ''
        vim.g.copilot_filetypes = {
          ['*'] = false,
          gitcommit = false,
          NeogitCommitMessage = false,
          dart = true,
          lua = true,
          php = true,
          javascript = true,
        }
      end,
    },
    {
      'mattn/emmet-vim',
      cmd = 'EmmetInstall',
      setup = function()
        vim.g.user_emmet_complete_tag = 0
        vim.g.user_emmet_install_global = 0
        vim.g.user_emmet_install_command = 0
        vim.g.user_emmet_mode = 'i'
      end,
    },
  }
  -- }}}

  -- Telescope & Treesitter {{{
  use {
    {
      'nvim-telescope/telescope.nvim',
      cmd = 'Telescope',
      keys = { '<c-p>', '<leader>fo', '<leader>ff', '<leader>fs', '<leader>fa', '<leader>fh' },
      module_pattern = 'telescope.*',
      requires = {
        {
          'nvim-telescope/telescope-fzf-native.nvim',
          run = 'make',
          after = 'telescope.nvim',
          config = function()
            require('telescope').load_extension 'fzf'
          end,
        },
        {
          'nvim-telescope/telescope-frecency.nvim',
          after = 'telescope.nvim',
          requires = 'tami5/sqlite.lua',
        },
        {
          'camgraff/telescope-tmux.nvim',
          after = 'telescope.nvim',
          config = function()
            require('telescope').load_extension 'tmux'
          end,
        },
        {
          'nvim-telescope/telescope-smart-history.nvim',
          after = 'telescope.nvim',
          config = function()
            require('telescope').load_extension 'smart_history'
          end,
        },
        {
          'nvim-telescope/telescope-github.nvim',
          after = 'telescope.nvim',
          config = function()
            require('telescope').load_extension 'gh'
          end,
        },
      },
      config = function()
        require 'plugins.configs.telescope'
      end,
    },
    {
      'nvim-treesitter/nvim-treesitter',
      run = ':TSUpdate',
      config = function()
        require 'plugins.configs.treesitter'
      end,
      requires = {
        { 'nvim-treesitter/nvim-treesitter-textobjects' },
      },
    },
  }
  -- }}}

  --- Editor Helper {{{
  use {
    {
      'kyazdani42/nvim-tree.lua',
      requires = 'nvim-web-devicons',
      config = function()
        require 'plugins.configs.nvimtree'
      end,
      setup = function()
        require('core.mappings').nvimtree()
      end,
    },
    {
      'norcalli/nvim-colorizer.lua',
      cmd = {
        'ColorizerToggle',
        'ColorizerAttachToBuffer',
        'ColorizerDetachFromBuffer',
        'ColorizerReloadAllBuffers',
      },
      config = function()
        require('colorizer').setup({ '*' }, {
          RGB = false,
          mode = 'background',
        })
      end,
    },
    {
      'anuvyklack/pretty-fold.nvim',
      event = 'BufRead',
      config = function()
        require 'plugins.configs.prettyfold'
      end,
    },
    {
      'monaqa/dial.nvim',
      keys = { { 'n', '<C-a>' }, { 'n', '<C-x>' }, { 'v', '<C-a>' }, { 'v', '<C-x>' } },
      config = function()
        require 'plugins.configs.dial'
      end,
    },
    {
      'numToStr/FTerm.nvim',
      opt = true,
      config = function()
        require('FTerm').setup {
          border = 'single',
          dimensions = {
            height = 0.6,
            width = 0.9,
          },
        }
      end,
    },
    {
      'mbbill/undotree',
      cmd = 'UndotreeToggle',
      config = function()
        vim.g.undotree_TreeNodeShape = '◉' -- Alternative: '◦'
        vim.g.undotree_SetFocusWhenToggle = 1
      end,
    },
    {
      'chentau/marks.nvim',
      keys = { { 'n', 'm' } },
      config = function()
        require('utils.color').overwrite { { 'MarkSignHL', { foreground = 'Red' } } }
        require('marks').setup {
          bookmark_0 = {
            sign = '⚑',
            virt_text = 'bookmarks',
          },
        }
      end,
    },
    {
      'rmagatti/auto-session',
      config = function()
        require('auto-session').setup {
          log_level = 'error',
          auto_session_root_dir = ('%s/session/auto/'):format(vim.fn.stdpath 'data'),
        }
      end,
    },
  }
  --}}}

  --- Utilities {{{
  use {
    {
      'nvim-neorg/neorg',
      requires = { 'vhyrro/neorg-telescope' },
      config = function()
        require 'plugins.configs.org'
      end,
    },
    { 'kevinhwang91/nvim-bqf', ft = 'qf' },
    {
      'https://gitlab.com/yorickpeterse/nvim-pqf',
      ft = 'qf',
      config = function()
        require('pqf').setup {}
      end,
    },
    {
      'kevinhwang91/nvim-hclipboard',
      event = 'BufRead',
      config = function()
        require('hclipboard').start()
      end,
    },
    {
      'max397574/better-escape.nvim',
      event = 'InsertEnter',
      config = function()
        require('better_escape').setup()
      end,
    },
    {
      'karb94/neoscroll.nvim',
      keys = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', 'zt', 'zz', 'zb' },
      config = function()
        require('neoscroll').setup {
          mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', 'zt', 'zz', 'zb' },
          stop_eof = false,
          hide_cursor = true,
        }
      end,
    },
  }
  --}}}

  -- Text Objects {{{
  use {
    { 'kana/vim-textobj-user' },
    {
      'coderifous/textobj-word-column.vim',
      keys = { { 'x', 'ik' }, { 'x', 'ak' }, { 'o', 'ik' }, { 'o', 'ak' } },
      config = function()
        vim.g.skip_default_textobj_word_column_mappings = 1
        vim.keymap.set(
          'x',
          'ik',
          ':<C-u>call TextObjWordBasedColumn("aw")<CR>',
          { noremap = false }
        )
        vim.keymap.set(
          'x',
          'ak',
          ':<C-u>call TextObjWordBasedColumn("aw")<CR>',
          { noremap = false }
        )
        vim.keymap.set('o', 'ik', ':call TextObjWordBasedColumn("aw")<CR>', { noremap = false })
        vim.keymap.set('o', 'ak', ':call TextObjWordBasedColumn("aw")<CR>', { noremap = false })
      end,
    },
    {
      'kana/vim-textobj-indent',
      keys = { { 'x', 'ii' }, { 'o', 'ii' } },
    },
    {
      'gcmt/wildfire.vim',
      keys = { { 'n', '<CR>' } },
    },
    {
      'phaazon/hop.nvim',
      keys = { { 'n', 's' }, 'f', 'F' },
      config = function()
        require 'plugins.configs.hop'
      end,
    },
    {
      'gbprod/substitute.nvim',
      keys = { { 'n', 'S' }, { 'n', 'X' }, { 'x', 'S' }, { 'x', 'X' } },
      config = function()
        require('substitute').setup()
        vim.keymap.set('n', 'S', function()
          require('substitute').operator()
        end)
        vim.keymap.set('x', 'S', function()
          require('substitute').visual()
        end)
        vim.keymap.set('n', 'X', function()
          require('substitute.exchange').operator()
        end)
        vim.keymap.set('x', 'X', function()
          require('substitute.exchange').visual()
        end)
        vim.keymap.set('n', 'Xc', function()
          require('substitute.exchange').cancel()
        end)
      end,
    },
  }
  -- }}}

  -- Operators {{{
  use {
    { 'kana/vim-operator-user' },
    {
      'kana/vim-operator-replace',
      keys = { { 'x', 'p' } },
      config = function()
        vim.keymap.set('x', 'p', '<Plug>(operator-replace)', { silent = true, noremap = false })
      end,
    },
  }
  -- }}}

  -- Testing and Debugging {{{
  use {
    {
      'vim-test/vim-test',
      -- cmd = { 'Test*' },
      -- keys = { '<localleader>tf', '<localleader>tn', '<localleader>ts' },
      config = function()
        vim.cmd [[
          function! FTermStrategy(cmd) abort
            call luaeval('vim.cmd("packadd FTerm.nvim")')
            call luaeval("require('FTerm').run(_A[1])", [a:cmd])
          endfunction
          let g:test#custom_strategies = {'fterm': function('FTermStrategy')}
        ]]
        vim.g['test#strategy'] = 'fterm'
        vim.keymap.set('n', '<localleader>tf', '<cmd>TestFile<CR>')
        vim.keymap.set('n', '<localleader>tn', '<cmd>TestNearest<CR>')
        vim.keymap.set('n', '<localleader>ts', '<cmd>TestSuite<CR>')
      end,
    },
    {
      'mfussenegger/nvim-dap',
      module = 'dap',
      keys = { '<localleader>dc', '<localleader>db', '<localleader>dut ' },
      config = function()
        require 'plugins.configs.dap-config'
      end,
      require = {
        {
          'rcarriga/nvim-dap-ui',
          after = 'nvim-dap',
          config = function()
            local dapui = require 'dapui'
            dapui.setup()
            vim.keymap.set('n', '<localleader>duc', dapui.close)
            vim.keymap.set('n', '<localleader>dut', dapui.toggle)
            local nvim_dap = require 'dap'
            -- NOTE: this opens dap UI automatically when dap starts
            -- dap.listeners.after.event_initialized['dapui_config'] = function()
            --   dapui.open()
            -- end
            nvim_dap.listeners.before.event_terminated['dapui_config'] = function()
              dapui.close()
            end
            nvim_dap.listeners.before.event_exited['dapui_config'] = function()
              dapui.close()
            end
          end,
        },
        {
          'theHamsta/nvim-dap-virtual-text',
          after = 'nvim-dap',
          config = function()
            require('nvim-dap-virtual-text').setup()
          end,
        },
      },
    },
  }
  -- }}}

  --- Devs {{{
  use {
    -- { 'nanotee/luv-vimdocs' },
    { 'milisims/nvim-luaref' },
    { 'rafcamlet/nvim-luapad', cmd = 'Luapad' },
  }
  --}}}
end)
