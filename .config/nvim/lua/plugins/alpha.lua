return {
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
      if vim.fn.argc() ~= 0 then return end

      local alpha = require("alpha")
      local uv = vim.loop
      local api = vim.api

      local W, H = 100, 50
      local A, B = 0, 0
      local chars = ".,-~:;=!*#$@"
      local clen = #chars

      local function donut_lines()
        local z, b = {}, {}
        for i = 1, W * H do z[i], b[i] = 0, " " end

        local sA, cA = math.sin(A), math.cos(A)
        local sB, cB = math.sin(B), math.cos(B)

        for j = 0, 6.28318, 0.07 do
          local sj, cj = math.sin(j), math.cos(j)
          for i = 0, 6.28318, 0.02 do
            local si, ci = math.sin(i), math.cos(i)
            local h = cj + 2
            local D = 1 / (si * h * sA + sj * cA + 5)
            local t = si * h * cA - sj * sA

            local x = math.floor(W / 2 + 60 * D * (ci * h * cB - t * sB))
            local y = math.floor(H / 2 + 30 * D * (ci * h * sB + t * cB))

            if x >= 0 and x < W and y >= 0 and y < H then
              local o = x + W * y + 1
              local N = math.floor(
                (((sj * sA - si * cj * cA) * cB) - si * cj * sA - ci * cj * sB) * 8
              )
              if D > (z[o] or 0) then
                z[o] = D
                local idx = math.min(clen, math.max(1, N + 1))
                b[o] = chars:sub(idx, idx)
              end
            end
          end
        end

        local lines = {}
        for r = 0, H - 1 do
          lines[#lines + 1] = table.concat(b, "", r * W + 1, r * W + W)
        end

        A = A + 0.04
        B = B + 0.02
        return lines
      end

      local function center_lines(lines, win_w, win_h)
        local maxw = 0
        for i = 1, #lines do
          local w = vim.fn.strdisplaywidth(lines[i])
          if w > maxw then maxw = w end
        end
        local left = math.max(0, math.floor((win_w - maxw) / 2))
        local top = math.max(0, math.floor((win_h - #lines) / 2))

        local pad_left = string.rep(" ", left)
        local out = {}
        for _ = 1, top do out[#out + 1] = "" end
        for i = 1, #lines do out[#out + 1] = pad_left .. lines[i] end
        return out
      end

      alpha.setup({ layout = { { type = "text", val = { "" } } } })

      local timer = uv.new_timer()
      local started = false

      api.nvim_create_autocmd("User", {
        pattern = "AlphaReady",
        callback = function()
          if started then return end
          started = true

          local buf = api.nvim_get_current_buf()

          vim.bo[buf].buftype = "nofile"
          vim.bo[buf].bufhidden = "wipe"
          vim.bo[buf].swapfile = false
          vim.bo[buf].modifiable = false
          vim.bo[buf].readonly = false
          vim.wo.number = false
          vim.wo.relativenumber = false
          vim.wo.signcolumn = "no"

          local function stop()
            if timer and not timer:is_closing() then
              timer:stop()
              timer:close()
            end
            if api.nvim_buf_is_valid(buf) then
              pcall(api.nvim_buf_delete, buf, { force = true })
            end
          end

          vim.keymap.set("n", "e", function()
            stop()
            vim.cmd("ene | startinsert")
          end, { buffer = buf, nowait = true, silent = true })

          vim.keymap.set("n", "q", function()
            stop()
            vim.cmd("qa")
          end, { buffer = buf, nowait = true, silent = true })

          vim.keymap.set("n", "<Esc>", function()
            stop()
            vim.cmd("ene")
          end, { buffer = buf, nowait = true, silent = true })

          vim.api.nvim_create_autocmd({ "BufLeave", "BufHidden", "BufUnload", "BufWipeout" }, {
            buffer = buf,
            once = true,
            callback = function()
              if timer and not timer:is_closing() then
                timer:stop()
                timer:close()
              end
            end,
          })

          local function draw()
            if timer:is_closing() then return end
            if not api.nvim_buf_is_valid(buf) then return end
            if api.nvim_get_current_buf() ~= buf then return end

            local win_w = api.nvim_win_get_width(0)
            local win_h = api.nvim_win_get_height(0)

            local d = donut_lines()
            local merged = {}
            for i = 1, #d do merged[#merged + 1] = d[i] end
            local out = center_lines(merged, win_w, win_h)

            api.nvim_buf_set_option(buf, "modifiable", true)
            api.nvim_buf_set_lines(buf, 0, -1, false, out)
            api.nvim_buf_set_option(buf, "modifiable", false)
          end

          timer:start(0, 60, vim.schedule_wrap(draw))

          vim.on_key(function(ch)
            if api.nvim_get_current_buf() ~= buf then return end
            if ch == "" then return end
            if ch == "e" or ch == "q" or ch == "\027" then return end
            vim.schedule(function()
              stop()
            end)
          end, api.nvim_create_namespace("donut_alpha_key_exit"))
        end,
      })
    end,
  },
}

