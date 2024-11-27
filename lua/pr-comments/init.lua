#!/usr/local/bin/lua

local M = {}

local function gh_api(org, repo, cmd)
	local gh_cmd = "gh api repos/" .. org .. "/" .. repo .. "/" .. cmd
	local gh = io.popen(gh_cmd)
	if gh then
		return gh:read("*a")
	else
		error("gh not configured")
	end
end

local gh_pr_comments = function(pr)
	local remote = io.popen("git config --get remote.origin.url")
	if not remote then
		error("Not in a repo")
	end

	local str = string.match(remote:read("*a"), "([^:]+)", 10)
	local s = string.gmatch(str, "([^/]+)")
	s()
	local org = s()
	local repo = string.match(s(), "([%a]+)%.git")
	return gh_api(
		org,
		repo,
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
