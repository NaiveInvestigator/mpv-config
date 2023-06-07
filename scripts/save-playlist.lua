--local playlist_savepath = (os.getenv('APPDATA') or os.getenv('HOME')..'/.config')..'/mpv/'
local playlist_savepath = mp.get_property('working-directory')

local utils = require("mp.utils")
local msg = require("mp.msg")

local filename = nil

--saves the current playlist into a m3u file
function save_playlist()
  local length = mp.get_property_number('playlist-count', 0)
	if length == 0 then return end
  local savepath = utils.join_path(playlist_savepath, os.time().."-size_"..length.."-playlist.m3u")
  local file, err = io.open(savepath, "w")
  if not file then
	msg.error("Error in creating playlist file, check permissions and paths: "..(err or ""))
  else
	local i=0
	while i < length do
	  local pwd = mp.get_property("working-directory")
	  local filename = mp.get_property('playlist/'..i..'/filename')
	  local fullpath = filename
	  if not filename:match("^%a%a+:%/%/") then
		fullpath = utils.join_path(pwd, filename)
	  end
	  file:write(fullpath, "\n")
	  i=i+1
	end
	msg.info("Playlist written to: "..savepath)
	mp.osd_message("Playlist written to: "..savepath)
	file:close()
  end
end

mp.add_key_binding("alt+s","save-playlist", save_playlist)