#!/usr/local/bin/lua

local M = {}

local gh_pr_comments = function(pr)
	return string.format(
		"cexpr system(%q)",
		"gh api repos/{owner}/{repo}/pulls/"
			.. pr
			.. "/comments | "
			.. 'jq -r \'.[] | "\\(.path):\\(.line):\\(if has("in_reply_to_id") then "⤷" else "🗨" end) @\\(.user.login):  \\(.body)"\''
	)
end

M.fetch = function()
	local pr = nil
	local out = io.popen("gh pr list --json number | jq '.[].number'")
	if out then
		pr = out:read("*l")
	end

	if not out or not pr then
		return nil
	end

	vim.diagnostic.reset(1)
	vim.fn.setqflist({})

	vim.cmd(gh_pr_comments(pr))

	local qflist = vim.fn.getqflist()
	local diagnostics = vim.diagnostic.fromqflist(qflist)
	for _, diagnostic in ipairs(diagnostics) do
		diagnostic.severity = vim.diagnostic.severity.INFO
	end

	vim.diagnostic.set(1, 0, diagnostics)
end

return M
