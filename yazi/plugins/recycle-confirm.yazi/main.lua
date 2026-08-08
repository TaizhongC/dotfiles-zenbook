--- @since 26.5.6

local function notify(level, content)
	return ya.notify {
		title = "Recycle Bin",
		content = content,
		timeout = 5,
		level = level,
	}
end

local function trash_files_dir()
	local data_home = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
	return data_home .. "/Trash/files"
end

local function refresh_trash_view()
	-- Re-entering the directory makes Yazi discard any stale file-list entries.
	ya.emit("cd", { Url(trash_files_dir()) })
end

return {
	entry = function(_, job)
		local days = tonumber(job.args[1])
		local detail = days
			and string.format("This permanently deletes items older than %d days.", days)
			or "This permanently deletes every item in the Recycle Bin."

		local confirmed = ya.confirm {
			pos = { "center", w = 64, h = 10 },
			title = "Empty Recycle Bin?",
			body = ui.Text(detail .. " This cannot be undone."):wrap(ui.Wrap.YES),
		}
		if not confirmed then
			return
		end

		local args = { "-f" }
		if days then
			table.insert(args, tostring(days))
		end

		local status, err = Command("trash-empty"):arg(args):status()
		if not status then
			notify("error", "Could not start trash-empty: " .. tostring(err))
			return
		end
		if not status.success then
			notify("error", "trash-empty failed (exit code " .. tostring(status.code) .. ")")
			return
		end

		refresh_trash_view()
		notify("info", days and "Old Recycle Bin items removed." or "Recycle Bin emptied.")
	end,
}
