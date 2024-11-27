#!/usr/local/bin/lua

local PR = nil
local pr_cmd = "gh pr list --json number | jq '.[].number'"
local out = io.popen(pr_cmd)
if out then
	PR = out:read("*l")
else
	error("No pull request number provided")
end

if not PR then
	return {}
end

local gh_pr_comments = function()
	local function gh_api(org, repo, cmd)
		local gh_cmd = "gh api repos/" .. org .. "/" .. repo .. "/" .. cmd
		local gh = io.popen(gh_cmd)
		if gh then
			return gh:read("*a")
		else
			error("gh not configured")
		end
	end

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
			.. PR
			.. '/comments | jq -r \'.[] | "\\(.path):\\(.line):\\(if has("in_reply_to_id") then "⤷" else "🗨" end) @\\(.user.login):  \\(.body)"\''
	)
end

return gh_pr_comments()
