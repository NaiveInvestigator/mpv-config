--[[
	mpv-kscreen-doctor

	Use kscreen-doctor to find the best display fps when playing a video

	Author: Nicola Smaniotto <smaniotto.nicola@gmail.com>
	Version: 0.2.1
]]--

utils = require "mp.utils"
msg = require "mp.msg"

function is_empty(t)
	for _, _ in pairs(t) do
		return false
	end
	return true
end

MODESFILE = "/tmp/mpv-screen-doctor.modes"
PIDFILE = "/tmp/mpv-kscreen-doctor.pid"  -- TODO: switch to /run/user/...

function get_available()
	--[[
		Get the current resolution and the available modes
	]]--
	local command = {
		name = "subprocess",
		playback_only = false,
		capture_stdout = true,
		args = {
			"kscreen-doctor",
			"-j",
		},
	}
	-- get screen info in JSON format
	local r = mp.command_native(command)

	assert(r.status == 0, "Could not detect display config")

	local raw_json = r.stdout

	-- https://stackoverflow.com/q/42139363
	-- in case parse_json is removed
	local parsed = utils.parse_json(raw_json)

	local enabled_outputs = {}
	for index, output in pairs(parsed.outputs) do
		if output.enabled then
			table.insert(enabled_outputs, {
				index = index,
				id = output.id,
			})
		end
	end

	local resolutions = {}
	local valid_modes = {}
	local old_modes = {}

	for _, output in pairs(enabled_outputs) do
		local current_mode = parsed.outputs[output.index].currentModeId

		old_modes[output.id] = current_mode

		-- go through the modes and find the current one
		local target = {}
		local all_modes = parsed.outputs[output.index].modes

		-- first find the resolution
		for _, mode in pairs(all_modes) do
			if mode.id == current_mode then
				target = mode.size
				break
			end
		end

		-- then find the available refresh rates for this resolution
		local good_modes = {}
		for _, mode in pairs(all_modes) do
			local s = mode.size
			if target.width == s.width and target.height == s.height then
				table.insert(good_modes, {
					id = mode.id,
					rate = mode.refreshRate,
				})
			end
		end

		table.insert(resolutions, { output = output, resolution = target })
		table.insert(valid_modes, { output = output, modes = good_modes })
	end

	-- save the modes if noone already did
	local modesfile = io.open(MODESFILE, "r")
	if not modesfile then
		-- there is nothing saved yet
		modesfile = io.open(MODESFILE, "w")
		for output, mode in pairs(old_modes) do
			modesfile:write(output .. " " .. mode .. "\n")
		end
	end
	modesfile:close()

	return resolutions, valid_modes
end

function best_fit(target, options)
	--[[
		Try to find the mode that best approximates the target refresh rate
	]]--
	local best = { distance = math.huge, id = nil }

	for mul = 1, 3 do
		for _, mode in pairs(options) do
			local offset = math.abs(target * mul - mode.rate)
			if offset < best.distance then
				best = {
					distance = offset,
					id = mode.id,
				}
			end
		end
	end

	return best.id
end

function kscreen_doctor_set_mode(modes)
	--[[
		Invoke kscreen-doctor and set the mode ids
	]]--
	local command = {
		name = "subprocess",
		playback_only = false,
		capture_stderr = true, -- prints here, don't want to log that
		args = {
			"kscreen-doctor",
		},
	}
	for output, id in pairs(modes) do
		msg.info("Setting output " .. output .. " to mode " .. id)
		local arg = "output." .. output .. ".mode." .. id
		table.insert(command.args, arg)
	end
	-- set the modes
	local r = mp.command_native(command)

	assert(r.status == 0, "Could not change display rate")
end

function set_rate()
	--[[
		Set the best fitting display rates
	]]--
	local _, modes = get_available()

	local container_fps = mp.get_property_native("container-fps")
	if not container_fps then
		-- nothing to do
		return
	end

	local best_modes = {}
	for _, mode in pairs(modes) do
		local best_mode = best_fit(container_fps, mode.modes)
		best_modes[mode.output.id] = best_mode
	end

	kscreen_doctor_set_mode(best_modes)
end

function restore_old()
	--[[
		If we know the previous modes, restore them
	]]--
	local modesfile = assert(io.open(MODESFILE, "r"), "Missing modes backup")

	local old_modes = {}
	while true do
		output, mode = modesfile:read("*n", "*n")
		if not output then
			break
		end
		old_modes[output] = mode
	end

	if is_empty(old_modes) then
		-- we don't have a saved rate, nothing to do
		return
	end

	msg.info("Restoring previous modes")
	kscreen_doctor_set_mode(old_modes)
	os.remove(MODESFILE)
end

function clean_shutdown()
	--[[
		Revert our changes
	]]--
	local pidfile = assert(io.open(PIDFILE, "r"), "Missing pidfile")

	pids = {}
	for line in pidfile:lines() do
		table.insert(pids, tonumber(line))
	end
	local my_pid = mp.get_property_native("pid")

	-- check if processes are still active
	for index, pid in pairs(pids) do
		local command = io.popen("ps -p " .. pid .. " -o comm=")
		if command:read("*l") ~= "mpv" or pid == my_pid then
			-- old pid or our own, remove it
			pids[index] = nil
		end
	end

	if is_empty(pids) then
		-- we are the last instance
		os.remove(PIDFILE)
		restore_old()
	else
		-- write back the list, removing us
		pidfile = io.open(PIDFILE, "w")
		for _, pid in pairs(pids) do
			pidfile:write(pid .. "\n")
		end
	end
end

-- update the pidfile on start
local pidfile = io.open(PIDFILE, "r")

if pidfile then
	-- the pidfile exists, update it
	pids = {}
	for line in pidfile:lines() do
		table.insert(pids, tonumber(line))
	end

	-- check if processes are still active
	for index, pid in pairs(pids) do
		local command = io.popen("ps -p " .. pid .. " -o comm=")
		if command:read("*l") ~= "mpv" then
			-- stale pid, remove it
			pids[index] = nil
		end
	end

	-- add us
	local my_pid = mp.get_property_native("pid")
	table.insert(pids, my_pid)

	-- write back the list, adding us
	pidfile = io.open(PIDFILE, "w")
	for _, pid in pairs(pids) do
		pidfile:write(pid .. "\n")
	end
else
	-- there is no pidfile, we are number one
	pidfile = io.open(PIDFILE, "w")
	local my_pid = mp.get_property_native("pid")
	pidfile:write(my_pid .. "\n")
end
pidfile:close()

-- change the refresh rate when video fps changes
mp.observe_property("container-fps", "native", set_rate)

-- revert changes when the file ends
mp.register_event("shutdown", clean_shutdown)
