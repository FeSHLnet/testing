--[[
═══════════════════════════════════════════════════════════
  BOOST SCRIPT v3  |  Assetto Corsa - CSP Online Script
═══════════════════════════════════════════════════════════

  ⚠️ مهم: جرّب وأنت بسرعة بطيئة (٦٠ - ١٠٠ كم/س)
     بسرعة ٣٠٠ الهواء يبلع القوة وما تحس بشي

  إذا ما حسيت بفرق:
    1) غيّر FORWARD_SIGN من 1 إلى -1  (الاتجاه معكوس)
    2) أو غيّر METHOD إلى "torque"
    3) أو زوّد BOOST_FORCE

═══════════════════════════════════════════════════════════
--]]


-- ══════════════ الإعدادات ══════════════

local METHOD         = "force"   -- "force" أو "torque"
local FORWARD_SIGN   = 1         -- جرّب 1 وإذا ما نفع خلها -1

local BOOST_KEY      = ui.KeyIndex.B
local BOOST_FORCE    = 30000     -- قوة الدفع (عالية للتجربة)
local WHEEL_TORQUE   = 3000      -- عزم الكفرات (لطريقة torque)

local MAX_SPEED_KMH  = 320       -- أقصى سرعة يشتغل عندها
local BOOST_DURATION = 2.0       -- مدة البوست بالثواني
local COOLDOWN       = 3.0       -- انتظار بعد كل بوست

local SHOW_HUD       = true
local DEBUG          = true      -- خلها false بعد ما يشتغل

-- ═══════════════════════════════════════


local timeLeft     = 0
local cooldownLeft = 0
local speedAtStart = 0
local gainedSpeed  = 0
local status       = "جاهز"


-- ─── تطبيق البوست ───

local function applyBoost()
  if physics == nil then
    status = "physics غير موجود"
    return
  end

  -- طريقة 1: قوة دفع على جسم السيارة
  if METHOD == "force" then
    local ok, err = pcall(function()
      physics.addForce(
        vec3(0, 0, 0),                          -- نقطة التطبيق
        true,                                   -- محلية
        vec3(0, 0, BOOST_FORCE * FORWARD_SIGN), -- الاتجاه
        true                                    -- قوة محلية
      )
    end)
    status = ok and "قوة مطبّقة" or ("خطأ: " .. tostring(err))

  -- طريقة 2: عزم على الكفرات
  elseif METHOD == "torque" then
    local applied = 0
    for wheel = 0, 3 do
      local ok = pcall(function()
        physics.addWheelTorque(wheel, WHEEL_TORQUE * FORWARD_SIGN)
      end)
      if ok then applied = applied + 1 end
    end
    status = applied > 0
      and ("عزم على " .. applied .. " كفرات")
      or "addWheelTorque فشلت"
  end
end


-- ═══════════════ الحلقة الرئيسية ═══════════════

function script.update(dt)
  local car = ac.getCar(0)
  if car == nil then return end

  if cooldownLeft > 0 then cooldownLeft = cooldownLeft - dt end
  if timeLeft > 0 then timeLeft = timeLeft - dt end

  local speedKmh = car.speedKmh

  -- بدء البوست
  if ac.isKeyDown(BOOST_KEY)
     and cooldownLeft <= 0
     and timeLeft <= 0
     and speedKmh < MAX_SPEED_KMH
     and car.gear > 0 then

    timeLeft     = BOOST_DURATION
    cooldownLeft = BOOST_DURATION + COOLDOWN
    speedAtStart = speedKmh
    gainedSpeed  = 0
    ac.setMessage("BOOST", "BOOST!")
  end

  -- أثناء البوست
  if timeLeft > 0 and speedKmh < MAX_SPEED_KMH then
    applyBoost()
    gainedSpeed = speedKmh - speedAtStart
  end

  if DEBUG then
    ac.debug("1_status", status)
    ac.debug("2_method", METHOD .. "  |  sign: " .. FORWARD_SIGN)
    ac.debug("3_speed_now", math.floor(speedKmh))
    ac.debug("4_speed_gained", math.floor(gainedSpeed) .. " km/h")
    ac.debug("5_boosting", timeLeft > 0)
  end
end


-- ═══════════════ الواجهة ═══════════════

function script.drawUI()
  if not SHOW_HUD or timeLeft <= 0 then return end

  ui.beginTransparentWindow('boostHud', vec2(20, 300), vec2(260, 70))
  ui.pushFont(ui.Font.Title)
  ui.text('BOOST')
  ui.popFont()
  ui.text(string.format('%.1f s   |   +%d km/h', timeLeft, math.floor(gainedSpeed)))
  ui.endTransparentWindow()
end
