-- Claude Code attention tracker: hooks in ~/.claude/settings.json call
-- ~/.claude/claude-notify.sh, which opens hammerspoon://claude?state=...
local TMUX = "/run/current-system/sw/bin/tmux"
local GHOSTTY = "com.mitchellh.ghostty"
local LOG = os.getenv("HOME") .. "/.hammerspoon/claude.log"
local ICON = hs.image.iconForFile("/Applications/Claude.app")

local STATES = {
  ["needs-input"] = { glyph = "?", sound = "Ping", persistent = true },
  finished = { glyph = "✓", sound = "Glass", persistent = false },
}

local entries = {}
local menu = hs.menubar.new(false)
if ICON then menu:setIcon(ICON:copy():setSize({ w = 18, h = 18 }), false) end

local function log(message)
  local file = io.open(LOG, "a")
  if file then
    file:write(os.date("%Y-%m-%d %H:%M:%S ") .. message .. "\n")
    file:close()
  end
end

local function tmux(args)
  local output, ok = hs.execute(TMUX .. " " .. args)
  return ok and output:gsub("%s+$", "") or nil
end

local function ghosttyFrontmost()
  local app = hs.application.frontmostApplication()
  return app ~= nil and app:bundleID() == GHOSTTY
end

local function paneVisible(pane)
  return ghosttyFrontmost()
    and tmux("display -pt '" .. pane .. "' '#{?session_attached,1,0}#{window_active}#{pane_active}'") == "111"
end

local function prune()
  local alive = {}
  for id in (tmux("list-panes -a -F '#{pane_id}'") or ""):gmatch("%S+") do alive[id] = true end
  for pane, entry in pairs(entries) do
    if not alive[pane] then
      if entry.notification then entry.notification:withdraw() end
      entries[pane] = nil
    end
  end
end

local jump

local function refresh()
  prune()
  local counts, items = {}, {}
  for pane, entry in pairs(entries) do
    counts[entry.state] = (counts[entry.state] or 0) + 1
    table.insert(items, {
      title = string.format("%s  %s — %s", STATES[entry.state].glyph, entry.project, entry.message),
      fn = function() jump(pane) end,
    })
  end
  if #items == 0 then
    menu:removeFromMenuBar()
    return
  end
  table.sort(items, function(a, b) return a.title < b.title end)
  table.insert(items, { title = "-" })
  table.insert(items, { title = "Clear all", fn = function()
    for pane in pairs(entries) do entries[pane] = nil end
    refresh()
  end })
  local title = {}
  for state, spec in pairs(STATES) do
    if counts[state] then table.insert(title, spec.glyph .. " " .. counts[state]) end
  end
  table.sort(title)
  menu:returnToMenuBar()
  menu:setTitle(table.concat(title, "  "))
  menu:setMenu(items)
end

local function clear(pane)
  local entry = entries[pane]
  if not entry then return end
  if entry.notification then entry.notification:withdraw() end
  entries[pane] = nil
  refresh()
end

jump = function(pane)
  local entry = entries[pane]
  if not entry then return end
  local client = tmux("list-clients -F '#{client_activity} #{client_name}' | sort -rn | head -1 | cut -d' ' -f2")
  if client and client ~= "" then
    tmux(string.format("switch-client -c '%s' -t '%s' \\; select-window -t '%s' \\; select-pane -t '%s'",
      client, entry.session, pane, pane))
  end
  hs.application.launchOrFocusByBundleID(GHOSTTY)
  clear(pane)
end

local function track(params)
  local pane, state = params.pane, params.state
  if not pane or not STATES[state] then return end
  local existing = entries[pane]
  -- idle_prompt fires a minute after every turn; only the first signal for a pane matters.
  if existing and params.event == "idle_prompt" then return end
  if existing and existing.notification then existing.notification:withdraw() end

  local entry = {
    state = state,
    session = params.session or "",
    project = params.project or "claude",
    message = params.message or state,
  }
  entries[pane] = entry
  refresh()

  if paneVisible(pane) then
    log(string.format("%s %s %s (visible, silent)", pane, state, entry.project))
    return
  end
  local spec = STATES[state]
  local notification = hs.notify.new(function() jump(pane) end, {
    title = string.format("%s %s", entry.project, state == "finished" and "finished" or "needs you"),
    informativeText = entry.message,
    soundName = spec.sound,
    withdrawAfter = spec.persistent and 0 or 8,
  })
  if ICON then notification:contentImage(ICON) end
  entry.notification = notification:send()
  log(string.format("%s %s %s (notified)", pane, state, entry.project))
end

hs.urlevent.bind("claude", function(_, params)
  if params.state == "clear" then
    clear(params.pane)
  else
    track(params)
  end
end)
