-- bandpass filter
--
-- ----------
--
-- key1: alt
-- enc1: filter type
--
-- enc2: freq
-- enc3: band width
--
-- alt + key2/3: set hold values
-- key2/3: restore held values
--
-- ----------
-- 
-- llllllll.co/t/27988
--
-- v1.1 @justmat

engine.name = "Bandpass"

local FilterGraph = require "filtergraph"

local alt = false

local held = {}
for i = 1, 2 do
  held[i] = {}
end

local lfo = include("lib/hnds_bandpass")
local lfo_targets = {
  "none",
  "freq",
  "band_width"
}


local function update_fg()
  -- keeps the filter graph current
  filter:edit("bandpass", 12, params:get("freq"), 0.28)
end


function lfo.process()
  -- for lib hnds
  for i = 1, 4 do
    local target = params:get(i .. "lfo_target")
    if params:get(i .. "lfo") == 2 then
      -- frequency
      if target == 2 then
        params:set(lfo_targets[target], lfo.scale(lfo[i].slope, -1.0, 1.0, 0.00, 20000.00))
      -- band width
      elseif target == 3 then
        params:set(lfo_targets[target], lfo.scale(lfo[i].slope, -1.0, 1.0, 0.01, 10.00))
      end
    end
  end
end


local function hold(n)
  -- clear old holds
  held[n] = {}
  -- hold parameter values
  table.insert(held[n], params:get("freq"))
  table.insert(held[n], params:get("band_width"))
end


local function restore(n)
  -- restore parameter values to held values
  params:set("freq", held[n][1])
  params:set("band_width", held[n][2])
end

  
function init()
  
  screen.aa(1)
  -- add filter parameters
  -- freq
  params:add_control("freq", "freq", controlspec.WIDEFREQ)
  params:set_action("freq", function(v) engine.freq(v) end)
  -- resonance/q
  params:add_control("band_width", "band width", controlspec.new(0.01, 10.0, "lin", 0, 1.0, ""))
  params:set_action("band_width", function(v) engine.bandWidth(v) end)
  
  -- for hnds
  for i = 1, 4 do
    lfo[i].lfo_targets = lfo_targets
  end
  lfo.init()

  params:bang()

  norns.enc.sens(1, 5)
  -- setup for the filter graph
  filter = FilterGraph.new()
  filter:set_position_and_size(5, 5, 118, 35)
  -- redraw metro
  local norns_redraw_timer = metro.init()
  norns_redraw_timer.time = 0.025
  norns_redraw_timer.event = function() update_fg() redraw() end
  norns_redraw_timer:start()
end


function key(n, z)
  -- key1 is momentary alt
  if n == 1 then
    if z == 1 then
      alt = true
    else
      alt = false
    end
  end
  -- key2/3 are parameter recalls
  if n > 1 and z == 1 then
    if alt then
      hold(n - 1)
    else
      if #held[n - 1] > 0 then
        restore(n - 1)
      end
    end
  end
end


function enc(n, d)
  -- filter controls
  if n == 2 then
    params:delta("freq", d / 10)
  elseif n == 3 then
    params:delta("band_width", d / 10)
  end
end


function redraw()
  screen.clear()
  screen.level(alt and 2 or 8)
  -- freq
  screen.move(32, 49)
  screen.text_center("freq: ")
  screen.move(91, 49)
  screen.text_center(string.format("%.2f", params:get('freq')))
  -- width
  screen.move(32, 59)
  screen.text_center("band width: ")
  screen.move(91, 59)
  screen.text_center(string.format("%.2f", params:get('band_width')))

  -- filtergraph
  filter:redraw()

  screen.update()
end

