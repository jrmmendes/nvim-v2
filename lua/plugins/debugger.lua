return {
  "rcarriga/nvim-dap-ui",
  commit="bc81f8d3440aede116f821114547a476b082b319",
  dependencies = {
    "mfussenegger/nvim-dap",
    "theHamsta/nvim-dap-virtual-text",
    "nvim-telescope/telescope-dap.nvim",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    local dap_virtual_text = require("nvim-dap-virtual-text")

    -- Setup dap-ui
    dapui.setup()

    -- Setup dap-virtual-text
    dap_virtual_text.setup()

    -- Automatically open/close dap-ui when debugging starts/stops
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end

    -- Configure adapters and configurations
    dap.adapters.node2 = {
      type = "executable",
      command = "node",
      args = {
        require("mason-registry").get_package("node-debug2-adapter"):get_install_path()
        .. "/out/src/nodeDebug.js",
      },
    }

    dap.configurations.javascript = {
      {
        type = "node2",
        request = "launch",
        program = "${file}",
        cwd = vim.fn.getcwd(),
        sourceMaps = true,
        protocol = "inspector",
        console = "integratedTerminal",
      },
    }

    dap.configurations.typescript = {
      {
        type = "node2",
        request = "launch",
        name = "Launch Current File",
        program = "${workspaceFolder}/dist/${fileBasenameNoExtension}.js",
        cwd = vim.fn.getcwd(),
        sourceMaps = true,
        protocol = "inspector",
        outFiles = { "${workspaceFolder}/dist/**/*.js" },
        console = "integratedTerminal",
      },
      {
        type = "node2",
        request = "launch",
        name = "Launch with npm script (start:debug)",
        runtimeExecutable = "npm",
        runtimeArgs = { "run", "start:debug" },
        cwd = vim.fn.getcwd(),
        sourceMaps = true,
        protocol = "inspector",
        console = "integratedTerminal",
        port = 9229,
      },
    }


    -- User command to set breakpoints
    vim.api.nvim_create_user_command("ToggleBreakpoint", function() dap.toggle_breakpoint() end, { desc = "Toggle a breakpoint at the current line" })
    -- User commands for debugging
    vim.api.nvim_create_user_command("DapContinue", function() dap.continue() end, { desc = "Continue Debugging" })
    vim.api.nvim_create_user_command("DapStepOver", function() dap.step_over() end, { desc = "Step Over" })
    vim.api.nvim_create_user_command("DapStepInto", function() dap.step_into() end, { desc = "Step Into" })
    vim.api.nvim_create_user_command("DapStepOut", function() dap.step_out() end, { desc = "Step Out" })
    vim.api.nvim_create_user_command("DapPause", function() dap.pause() end, { desc = "Pause Debugging" })
    vim.api.nvim_create_user_command("DapTerminate", function() dap.terminate() end, { desc = "Terminate Debugging" })

    -- Toggle Debugger UI
    vim.api.nvim_create_user_command("Debugger", function() dapui.toggle() end, { desc = "Toggle Debugger UI" })

    -- Configure breakpoint icons
    vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
    vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })
    vim.fn.sign_define("DapBreakpointRejected", { text = "◌", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })
    vim.fn.sign_define("DapBreakpointDisabled", { text = "◌", texthl = "DapBreakpointDisabled", linehl = "", numhl = "" })
    --
    -- Set highlight groups for red color
    vim.cmd("highlight DapBreakpoint guifg=#FF0000 guibg=NONE")
    vim.cmd("highlight DapLogPoint guifg=#FF0000 guibg=NONE")
    vim.cmd("highlight DapBreakpointRejected guifg=#FF0000 guibg=NONE")
    vim.cmd("highlight DapBreakpointDisabled guifg=#FF0000 guibg=NONE")
  end,
}

