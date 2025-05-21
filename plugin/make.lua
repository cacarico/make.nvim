vim.api.nvim_create_user_command('MakeTargets', function()
  require('make.commands').run()
end, {})
