local DEVICE = "Æon"
local BUNDLE = "com.rogueamoeba.audiohijack"
local SCRIPTS = os.getenv("HOME") .. "/.config/audio-hijack/"
local LOG = os.getenv("HOME") .. "/.hammerspoon/aeon.log"
local SETTLE = 1.0

local applied = nil
local settleTimer = nil

local function log(message)
  print(message)
  local file = io.open(LOG, "a")
  if file then
    file:write(os.date("%Y-%m-%d %H:%M:%S ") .. message .. "\n")
    file:close()
  end
end

local function trigger(script)
  hs.task.new("/usr/bin/open", nil, { "-b", BUNDLE, SCRIPTS .. script }):start()
end

local function reconcile()
  local output = hs.audiodevice.defaultOutputDevice()
  local effect = hs.audiodevice.defaultEffectDevice()
  local wanted = output ~= nil and output:name() == DEVICE

  log(string.format("output=%s alerts=%s wanted=%s applied=%s",
    output and output:name() or "none",
    effect and effect:name() or "none",
    tostring(wanted), tostring(applied)))

  if wanted == applied then return end
  applied = wanted
  trigger(wanted and "aeon-on.ahcommand" or "aeon-off.ahcommand")
end

-- A single device change emits a burst of notifications, and AirPods flap
-- through intermediate states while connecting; only the settled state matters.
local function schedule()
  if settleTimer then settleTimer:stop() end
  settleTimer = hs.timer.doAfter(SETTLE, reconcile)
end

hs.audiodevice.watcher.setCallback(schedule)
hs.audiodevice.watcher.start()

reconcile()
