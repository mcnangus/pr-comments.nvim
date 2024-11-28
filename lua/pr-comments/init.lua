#!/usr/local/bin/lua

local M = {}

local function gh_api(cmd)
	local gh_cmd = "gh api repos/{owner}/{repo}/" .. cmd
	return vim.system({ "bash", "-c", gh_cmd }):wait().stdout
end

local gh_pr_comments = function(pr)
	return gh_api(
		"pulls/"
			.. pr
			.. '/comments | jq -r \'.[] | "\\(.path):\\(.line):\\(if has("in_reply_to_id") then "⤷" else "🗨" end) @\\(.user.login):  \\(.body)"\''
	)
end

M.fetch = function()
	local pr = nil
	local pr_cmd = "gh pr list --json number | jq '.[].number'"
	local out = io.popen(pr_cmd)
	if out then
		pr = out:read("*l")
	else
		error("No pull request number provided")
	end

	if not pr then
		return nil
	end

	vim.diagnostic.reset(1)
	vim.fn.setqflist({})

	local buffer = gh_pr_comments(pr)
	vim.print(buffer)
	return

	if buffer ~= nil then
		local current_file = vim.fn.expand("%:p")

		for line in buffer:gmatch("([^\n]+)") do
			-- local file, lineno = line:match("(.-):(%d+)")
			-- if file and lineno then
			-- 	if file == current_file then
			-- 		vim.cmd('caddexpr "' .. line .. '"')
			-- 	end
			-- end
			vim.cmd('caddexpr "' .. line .. '"')
		end

		local qflist = vim.fn.getqflist()
		local diagnostics = vim.diagnostic.fromqflist(qflist)

		for _, diagnostic in ipairs(diagnostics) do
			diagnostic.severity = vim.diagnostic.severity.INFO
		end

		vim.diagnostic.set(1, 0, diagnostics)
	end
end

return M
