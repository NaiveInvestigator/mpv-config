if mp.get_property_bool('osc', true) then return end

-- BEGIN: by 9beach@gmail.com
math.randomseed(os.time())

local quote_id = 1
local quotes = {'Drop (or paste) media files or URLs to play here.'}
local quotes_path

quotes_path = mp.command_native({"expand-path", "~~/"}).."/script-opts/osc-quotes.txt"

local quotes_f = io.open(quotes_path, "r")
if quotes_f then
    quotes_f:close()
    quotes = {}
    for line in io.lines(quotes_path) do
        quotes[#quotes + 1] = line
    end
end

-- END: by 9beach@gmail.com

local assdraw = require "mp.assdraw"
local msg = require "mp.msg"
local opt = require "mp.options"
local utils = require "mp.utils"

local options = {
    scalewindowed = 1,          -- scaling of the controller when windowed
    scalefullscreen = 1,        -- scaling of the controller when fullscreen
    scaleforcedwindow = 2,      -- scaling when rendered on a forced window
    vidscale = true,            -- scale the controller with the video?
    idlescreen = true,          -- show mpv logo on idle
    greenandgrumpy = false,     -- disable santa hat

    -- include all other options to suppress warnings when reading the config file
    valign = 0,
    halign = 0,
    barmargin = 0,
    boxalpha = 0,
    hidetimeout = 0,
    fadeduration = 0,
    deadzonesize = 0,
    minmousemove = 0,
    iamaprogrammer = false,
    layout = "",
    seekbarstyle = "",
    seekbarhandlesize = 0,
    seekrangestyle = "",
    seekrangeseparate = false,
    seekrangealpha = 0,
    seekbarkeyframes = false,
    title = "",
    tooltipborder = 0,
    timetotal = false,
    timems = false,
    tcspace = 0,
    visibility = "",
    boxmaxchars = 0,
    boxvideo = false,
    windowcontrols = "",
    windowcontrols_alignment = "",
    livemarkers = false,
    chapters_osd = false,
    playlist_osd = false,
    chapter_fmt = "",
    unicodeminus = false,
}

-- read options from config and command-line
opt.read_options(options, "osc", function(_) update_options() end)

local osd = mp.create_osd_overlay("ass-events")
local is_december = os.date("*t").month == 12
local render_period = 0.03
local idle = false

local logo_lines = {
    -- White border
    "{\\c&HE5E5E5&\\p6}m 895 10 b 401 10 0 410 0 905 0 1399 401 1800 895 1800 1390 1800 1790 1399 1790 905 1790 410 1390 10 895 10 {\\p0}",
    -- Purple fill
    "{\\c&H682167&\\p6}m 925 42 b 463 42 87 418 87 880 87 1343 463 1718 925 1718 1388 1718 1763 1343 1763 880 1763 418 1388 42 925 42{\\p0}",
    -- Darker fill
    "{\\c&H430142&\\p6}m 1605 828 b 1605 1175 1324 1456 977 1456 631 1456 349 1175 349 828 349 482 631 200 977 200 1324 200 1605 482 1605 828{\\p0}",
    -- White fill
    "{\\c&HDDDBDD&\\p6}m 1296 910 b 1296 1131 1117 1310 897 1310 676 1310 497 1131 497 910 497 689 676 511 897 511 1117 511 1296 689 1296 910{\\p0}",
    -- Triangle
    "{\\c&H691F69&\\p6}m 762 1113 l 762 708 b 881 776 1000 843 1119 911 1000 978 881 1046 762 1113{\\p0}",
}

local santa_hat_lines = {
    -- Pompoms
    "{\\c&HC0C0C0&\\p6}m 500 -323 b 491 -322 481 -318 475 -311 465 -312 456 -319 446 -318 434 -314 427 -304 417 -297 410 -290 404 -282 395 -278 390 -274 387 -267 381 -265 377 -261 379 -254 384 -253 397 -244 409 -232 425 -228 437 -228 446 -218 457 -217 462 -216 466 -213 468 -209 471 -205 477 -203 482 -206 491 -211 499 -217 508 -222 532 -235 556 -249 576 -267 584 -272 584 -284 578 -290 569 -305 550 -312 533 -309 523 -310 515 -316 507 -321 505 -323 503 -323 500 -323{\\p0}",
    "{\\c&HE0E0E0&\\p6}m 315 -260 b 286 -258 259 -240 246 -215 235 -210 222 -215 211 -211 204 -188 177 -176 172 -151 170 -139 163 -128 154 -121 143 -103 141 -81 143 -60 139 -46 125 -34 129 -17 132 -1 134 16 142 30 145 56 161 80 181 96 196 114 210 133 231 144 266 153 303 138 328 115 373 79 401 28 423 -24 446 -73 465 -123 483 -174 487 -199 467 -225 442 -227 421 -232 402 -242 384 -254 364 -259 342 -250 322 -260 320 -260 317 -261 315 -260{\\p0}",
    -- Main cap
    "{\\c&H0000F0&\\p6}m 1151 -523 b 1016 -516 891 -458 769 -406 693 -369 624 -319 561 -262 526 -252 465 -235 479 -187 502 -147 551 -135 588 -111 1115 165 1379 232 1909 761 1926 800 1952 834 1987 858 2020 883 2053 912 2065 952 2088 1000 2146 962 2139 919 2162 836 2156 747 2143 662 2131 615 2116 567 2122 517 2120 410 2090 306 2089 199 2092 147 2071 99 2034 64 1987 5 1928 -41 1869 -86 1777 -157 1712 -256 1629 -337 1578 -389 1521 -436 1461 -476 1407 -509 1343 -507 1284 -515 1240 -519 1195 -521 1151 -523{\\p0}",
    -- Cap shadow
    "{\\c&H0000AA&\\p6}m 1657 248 b 1658 254 1659 261 1660 267 1669 276 1680 284 1689 293 1695 302 1700 311 1707 320 1716 325 1726 330 1735 335 1744 347 1752 360 1761 371 1753 352 1754 331 1753 311 1751 237 1751 163 1751 90 1752 64 1752 37 1767 14 1778 -3 1785 -24 1786 -45 1786 -60 1786 -77 1774 -87 1760 -96 1750 -78 1751 -65 1748 -37 1750 -8 1750 20 1734 78 1715 134 1699 192 1694 211 1689 231 1676 246 1671 251 1661 255 1657 248 m 1909 541 b 1914 542 1922 549 1917 539 1919 520 1921 502 1919 483 1918 458 1917 433 1915 407 1930 373 1942 338 1947 301 1952 270 1954 238 1951 207 1946 214 1947 229 1945 239 1939 278 1936 318 1924 356 1923 362 1913 382 1912 364 1906 301 1904 237 1891 175 1887 150 1892 126 1892 101 1892 68 1893 35 1888 2 1884 -9 1871 -20 1859 -14 1851 -6 1854 9 1854 20 1855 58 1864 95 1873 132 1883 179 1894 225 1899 273 1908 362 1910 451 1909 541{\\p0}",
    -- Brim and tip pompom
    "{\\c&HF8F8F8&\\p6}m 626 -191 b 565 -155 486 -196 428 -151 387 -115 327 -101 304 -47 273 2 267 59 249 113 219 157 217 213 215 265 217 309 260 302 285 283 373 264 465 264 555 257 608 252 655 292 709 287 759 294 816 276 863 298 903 340 972 324 1012 367 1061 394 1125 382 1167 424 1213 462 1268 482 1322 506 1385 546 1427 610 1479 662 1510 690 1534 725 1566 752 1611 796 1664 830 1703 880 1740 918 1747 986 1805 1005 1863 991 1897 932 1916 880 1914 823 1945 777 1961 725 1979 673 1957 622 1938 575 1912 534 1862 515 1836 473 1790 417 1755 351 1697 305 1658 266 1633 216 1593 176 1574 138 1539 116 1497 110 1448 101 1402 77 1371 37 1346 -16 1295 15 1254 6 1211 -27 1170 -62 1121 -86 1072 -104 1027 -128 976 -133 914 -130 851 -137 794 -162 740 -181 679 -168 626 -191 m 2051 917 b 1971 932 1929 1017 1919 1091 1912 1149 1923 1214 1970 1254 2000 1279 2027 1314 2066 1325 2139 1338 2212 1295 2254 1238 2281 1203 2287 1158 2282 1116 2292 1061 2273 1006 2229 970 2206 941 2167 938 2138 918{\\p0}",
}

local function set_osd(res_x, res_y, text)
    if osd.res_x == res_x and
        osd.res_y == res_y and
        osd.data == text then
        return
    end
    osd.res_x = res_x
    osd.res_y = res_y
    osd.data = text
    osd.z = 1000
    osd:update()
end

local osc_param = { -- calculated by osc_init()
    playresy = 0,                           -- canvas size Y
    playresx = 0,                           -- canvas size X
    display_aspect = 1,
    unscaled_y = 0,
}

local message_hide_timer = nil
local message_text = nil
local function render_message()
    if message_text and message_hide_timer and message_hide_timer:is_enabled() then
        local _, lines = string.gsub(message_text, "\\N", "")

        local fontsize = tonumber(mp.get_property("options/osd-font-size"))
        local outline = tonumber(mp.get_property("options/osd-border-size"))
        local maxlines = math.ceil(osc_param.unscaled_y*0.75 / fontsize)
        local counterscale = osc_param.playresy / osc_param.unscaled_y

        fontsize = fontsize * counterscale / math.max(0.65 + math.min(lines / maxlines, 1), 1)
        outline = outline * counterscale / math.max(0.75 + math.min(lines / maxlines, 1) / 2, 1)

        local style = "{\\bord" .. outline .. "\\fs" .. fontsize .. "}"

        local ass = assdraw.ass_new()

        -- submit
        ass:new_event()
        ass:append(style .. message_text)
        set_osd(osc_param.playresy * osc_param.display_aspect, osc_param.playresy, ass.text)
    else
        message_text = nil
        set_osd(0, 0, '')
    end
end

local function render_idle()
    if not options.idlescreen then set_osd(0, 0, '') return end

    -- render idle message
    msg.trace("idle message")
    local _, _, display_aspect = mp.get_osd_size()
    local display_h = 360
    local display_w = display_h * display_aspect
    -- logo is rendered at 2^(6-1) = 32 times resolution with size 1800x1800
    local icon_x, icon_y = (display_w - 1800 / 32) / 2, 140
    local line_prefix = ("{\\rDefault\\an7\\1a&H00&\\bord0\\shad0\\pos(%f,%f)}"):format(icon_x, icon_y)

    local ass = assdraw.ass_new()
    -- mpv logo
    for _, line in ipairs(logo_lines) do
        ass:new_event()
        ass:append(line_prefix .. line)
    end

    -- Santa hat
    if is_december and not options.greenandgrumpy then
        for _, line in ipairs(santa_hat_lines) do
            ass:new_event()
            ass:append(line_prefix .. line)
        end
    end

    ass:new_event()
    ass:pos(display_w / 2, icon_y + 65)
    ass:an(8)
    quote_id = math.random(1, #quotes)
    ass:append(quotes[quote_id])
    set_osd(display_w, display_h, ass.text)
end

local render_last_time = 0
local function render()
    render_last_time = mp.get_time()
    if idle then
        render_idle()
    else
        render_message()
    end
end

local tick_timer = nil
local function request_render()
    if tick_timer == nil then
        tick_timer = mp.add_timeout(0, render)
    end

    if not tick_timer:is_enabled() then
        local now = mp.get_time()
        local timeout = render_period - (now - render_last_time)
        if timeout < 0 then
            timeout = 0
        end
        tick_timer.timeout = timeout
        tick_timer:resume()
    end
end

local function update_dimensions()
    -- set canvas resolution according to display aspect and scaling setting
    local baseResY = 720
    local display_w, display_h, display_aspect = mp.get_osd_size()
    local scale = 1

    if (mp.get_property("video") == "no") then -- dummy/forced window
        scale = options.scaleforcedwindow
    elseif options.fullscreen then
        scale = options.scalefullscreen
    else
        scale = options.scalewindowed
    end

    if options.vidscale then
        osc_param.unscaled_y = baseResY
    else
        osc_param.unscaled_y = display_h
    end
    osc_param.playresy = osc_param.unscaled_y / scale
    if (display_aspect > 0) then
        osc_param.display_aspect = display_aspect
    end
    osc_param.playresx = osc_param.playresy * osc_param.display_aspect
    request_render()
end

---@diagnostic disable-next-line: lowercase-global
function update_options()
    update_dimensions()
    request_render()
end

local function show_message(text, duration)
    if duration == nil then
        duration = tonumber(mp.get_property("options/osd-duration")) / 1000
    elseif not type(duration) == "number" then
        print("duration: " .. duration)
    end

    -- cut the text short, otherwise the following functions
    -- may slow down massively on huge input
    text = string.sub(text, 0, 4000)

    -- replace actual linebreaks with ASS linebreaks
    text = string.gsub(text, "\n", "\\N")

    message_text = text

    if not message_hide_timer then
        message_hide_timer = mp.add_timeout(0, request_render)
    end
    message_hide_timer:kill()
    message_hide_timer.timeout = duration
    message_hide_timer:resume()
    request_render()
end

local nicetypes = {video = "Video", audio = "Audio", sub = "Subtitle"}
local tracks_osc = {video = {}, audio = {}, sub = {}}
local tracks_mpv = {video = {}, audio = {}, sub = {}}

-- updates the OSC internal playlists, should be run each time the track-layout changes
local function update_tracklist(_, tracktable)
    tracktable = tracktable or {}

    -- by osc_id
    tracks_osc.video, tracks_osc.audio, tracks_osc.sub = {}, {}, {}
    -- by mpv_id
    tracks_mpv.video, tracks_mpv.audio, tracks_mpv.sub = {}, {}, {}
    for n = 1, #tracktable do
        if not (tracktable[n].type == "unknown") then
            local type = tracktable[n].type
            local mpv_id = tonumber(tracktable[n].id)

            -- by osc_id
            table.insert(tracks_osc[type], tracktable[n])

            -- by mpv_id
---@diagnostic disable-next-line: need-check-nil
            tracks_mpv[type][mpv_id] = tracktable[n]
            tracks_mpv[type][mpv_id].osc_id = #tracks_osc[type]
        end
    end
end

-- return a nice list of tracks of the given type (video, audio, sub)
local function get_tracklist(type)
    local msg = "Available " .. nicetypes[type] .. " Tracks: "
    if not tracks_osc or #tracks_osc[type] == 0 then
        msg = msg .. "none"
    else
        for n = 1, #tracks_osc[type] do
            local track = tracks_osc[type][n]
            local lang, title, selected = "unknown", "", "○"
            if not(track.lang == nil) then lang = track.lang end
            if not(track.title == nil) then title = track.title end
            if (track.id == tonumber(mp.get_property(type))) then
                selected = "●"
            end
            msg = msg.."\n"..selected.." "..n..": ["..lang.."] "..title
        end
    end
    return msg
end

-- pos is 1 based
local function limited_list(prop, pos)
    local proplist = mp.get_property_native(prop, {})
    local count = #proplist
    if count == 0 then
        return count, proplist
    end

    local fs = tonumber(mp.get_property("options/osd-font-size"))
    local max = math.ceil(osc_param.unscaled_y*0.75 / fs)
    if max % 2 == 0 then
        max = max - 1
    end
    local delta = math.ceil(max / 2) - 1
    local begi = math.max(math.min(pos - delta, count - max + 1), 1)
    local endi = math.min(begi + max - 1, count)

    local reslist = {}
    for i=begi, endi do
        local item = proplist[i]
        item.current = (i == pos) and true or nil
        table.insert(reslist, item)
    end
    return count, reslist
end

local function get_playlist()
    local pos = mp.get_property_number("playlist-pos", 0) + 1
    local count, limlist = limited_list("playlist", pos)
    if count == 0 then
        return "Empty playlist."
    end

    local message = string.format("Playlist [%d/%d]:\n", pos, count)
    for _, v in ipairs(limlist) do
        local title = v.title
        local _, filename = utils.split_path(v.filename)
        if title == nil then
            title = filename
        end
        message = string.format("%s %s %s\n", message,
            (v.current and "●" or "○"), title)
    end
    return message
end

local function get_chapterlist()
    local pos = mp.get_property_number("chapter", 0) + 1
    local count, limlist = limited_list("chapter-list", pos)
    if count == 0 then
        return "No chapters."
    end

    local message = string.format("Chapters [%d/%d]:\n", pos, count)
    for i, v in ipairs(limlist) do
        local time = mp.format_time(v.time)
        local title = v.title
        if title == nil then
            title = string.format("Chapter %02d", i)
        end
        message = string.format("%s[%s] %s %s\n", message, time,
            (v.current and "●" or "○"), title)
    end
    return message
end

mp.observe_property("idle-active", "bool", function(_, val) idle = val request_render() end)
mp.observe_property("osd-dimensions", "native", update_dimensions)
mp.observe_property("track-list", "native", update_tracklist)

mp.register_script_message("osc-message", show_message)
mp.register_script_message("osc-chapterlist", function(dur)
    show_message(get_chapterlist(), dur)
end)
mp.register_script_message("osc-playlist", function(dur)
    show_message(get_playlist(), dur)
end)
mp.register_script_message("osc-tracklist", function(dur)
    local message = {}
    for k,_ in pairs(nicetypes) do
        table.insert(message, get_tracklist(k))
    end
    show_message(table.concat(message, "\n\n"), dur)
end)
mp.register_script_message("osc-idlescreen", function(mode, no_osd)
    if mode == "cycle" then mode = options.idlescreen and "no" or "yes" end
    options.idlescreen = mode == "yes"
    utils.shared_script_property_set("osc-idlescreen", mode)

    if not no_osd and mp.get_property_number("osd-level", 1) >= 1 then
        mp.osd_message("OSC logo visibility: " .. tostring(mode))
    end
    request_render()
end)
