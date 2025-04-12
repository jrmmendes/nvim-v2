return {
  "rcarriga/nvim-dap-ui",
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
    -- Key mappings for nvim-dap
    vim.keymap.set("n", "<F5>", function() dap.continue() end, { desc = "Start/Continue Debugging" })
    vim.keymap.set("n", "<F10>", function() dap.step_over() end, { desc = "Step Over" })
    vim.keymap.set("n", "<F11>", function() dap.step_into() end, { desc = "Step Into" })
    vim.keymap.set("n", "<F12>", function() dap.step_out() end, { desc = "Step Out" })

    -- User command to set breakpoints
    vim.api.nvim_create_user_command("ToggleBreakpoint", function() dap.toggle_breakpoint() end, { desc = "Toggle a breakpoint at the current line" })
    -- User commands for debugging
    vim.api.nvim_create_user_command("Continue", function() dap.continue() end, { desc = "Continue Debugging" })
    vim.api.nvim_create_user_command("StepOver", function() dap.step_over() end, { desc = "Step Over" })
    vim.api.nvim_create_user_command("StepInto", function() dap.step_into() end, { desc = "Step Into" })
    vim.api.nvim_create_user_command("StepOut", function() dap.step_out() end, { desc = "Step Out" })
    vim.api.nvim_create_user_command("Pause", function() dap.pause() end, { desc = "Pause Debugging" })
    vim.api.nvim_create_user_command("Terminate", function() dap.terminate() end, { desc = "Terminate Debugging" })

    -- Toggle Debugger UI
    vim.api.nvim_create_user_command("Debugger", function() dapui.toggle() end, { desc = "Toggle Debugger UI" })
  end,
}

