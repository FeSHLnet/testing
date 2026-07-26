--[[
═══════════════════════════════════════════════════════════
  BOOST SCRIPT  |  Assetto Corsa - CSP Online Script
  نسخة مع التشخيص المدمج
═══════════════════════════════════════════════════════════

  التركيب:
  ─────────
  الطريقة (أ) - رابط إنترنت:
    ارفع الملف على gist.github.com وخذ رابط Raw
    في cfg/csp_extra_options.ini:
      [SCRIPT_1]
      SCRIPT = "رابط الـ Raw"

  الطريقة (ب) - لان (مفضّلة):
    حط الملف في: assettocorsa\extension\lua\online\boost.lua
    على كل جهاز، وفي cfg/csp_extra_options.ini:
      [SCRIPT_1]
      SCRIPT = "boost.lua"

  التشخيص:
  ─────────
  ادخل السيرفر، افتح Lua Debug -> SCRIPT_1
  وشوف القيم: physics_status / physics_functions / boost_result
═══════════════════════════════════════════════════════════
--]]


-- ══════════════ الإعدادات ══════════════

local BOOST_KEY      = ui.KeyIndex.B   -- زر البوست
local BOOST_FORCE    = 12000           -- قوة الدفع (زودها لبوست أقوى)
local MAX_SPEED_KMH  = 320             -- أقصى سرعة يشتغل عندها البوست
local BOOST_DURATION = 2.0             -- مدة البوست بالثواني
local COOLDOWN       = 3.0             -- ثواني انتظار بعد كل بوست
local SHOW_HUD       = true            -- عرض شريط البوست على الشاشة

-- ═══════════════════════════════════════


local timeLeft     = 0
local cooldownLeft = 0
local didScan      = false
local boostMethod  = nil    -- الدالة اللي نجحت
local lastError    = ""


-- ─── فحص وحدة الفيزياء (يشتغل مرة وحدة) ───

local function scanPhysics()
  didScan = true

  if physics == nil then
    ac.debug("physics_status", "physics غير موجود نهائياً")
    return
  end

  -- سرد كل الدوال المتاحة
  local names = {}
  for k, _ in pairs(physics) do
    names[#names + 1] = k
  end
  table.sort(names)

  ac.debug("physics_status", "موجود - عدد الدوال: " .. #names)
  ac.debug("physics_functions", table.concat(names, ", "))

  -- فحص هل الفيزياء مسموحة
  if physics.allowed ~= nil then
    local ok, allowed = pcall(physics.allowed)
    if ok then
      ac.debug("physics_allowed", tostring(allowed))
    end
  else
    ac.debug("physics_allowed", "ما فيه دالة allowed")
  end
end


-- ─── تطبيق البوست مع تجربة أكثر من طريقة ───

local function applyBoost()
  if physics == nil then
    lastError = "physics غير موجود"
    return false
  end

  -- المحاولة 1: addForce بالصيغة الكاملة
  if physics.addForce ~= nil then
    local ok, err = pcall(function()
      physics.addForce(vec3(0, 0, 0), true, vec3(0, 0, BOOST_FORCE), true)
    end)
    if ok then
      boostMethod = "addForce"
      return true
    end
    lastError = "addForce: " .. tostring(err)

    -- المحاولة 2: addForce بصيغة مختصرة
    local ok2, err2 = pcall(function()
      physics.addForce(vec3(0, 0, 0), vec3(0, 0, BOOST_FORCE))
    end)
    if ok2 then
      boostMethod = "addForce (مختصرة)"
      return true
    end
    lastError = lastError .. " | " .. tostring(err2)
  else
    lastError = "ما فيه دالة addForce"
  end

  -- المحاولة 3: عزم إضافي
  if physics.setExtraTorque ~= nil then
    local ok3 = pcall(function()
      physics.setExtraTorque(BOOST_FORCE / 10)
    end)
    if ok3 then
      boostMethod = "setExtraTorque"
      return true
    end
  end

  return false
end


-- ═══════════════ الحلقة الرئيسية ═══════════════

function script.update(dt)
  if not didScan then
    scanPhysics()
  end

  local car = ac.getCar(0)
  if car == nil then return end

  if cooldownLeft > 0 then cooldownLeft = cooldownLeft - dt end
  if timeLeft > 0 then timeLeft = timeLeft - dt end

  local speedKmh = car.speedKmh

  -- تشغيل البوست
  if ac.isKeyDown(BOOST_KEY)
     and cooldownLeft <= 0
     and timeLeft <= 0
     and speedKmh < MAX_SPEED_KMH
     and car.gear > 0 then

    timeLeft     = BOOST_DURATION
    cooldownLeft = BOOST_DURATION + COOLDOWN
    ac.setMessage("BOOST", "BOOST!")
  end

  -- تطبيق القوة
  if timeLeft > 0 and speedKmh < MAX_SPEED_KMH then
    local success = applyBoost()
    if success then
      ac.debug("boost_result", "نجح - الطريقة: " .. tostring(boostMethod))
    else
      ac.debug("boost_result", "فشل - " .. lastError)
    end
  end

  ac.debug("speed_kmh", math.floor(speedKmh))
  ac.debug("gear", car.gear)
end


-- ═══════════════ الواجهة ═══════════════

function script.drawUI()
  if not SHOW_HUD then return end
  if timeLeft <= 0 then return end

  ui.beginTransparentWindow('boostHud', vec2(20, 300), vec2(220, 60))
  ui.pushFont(ui.Font.Title)
  ui.text('BOOST')
  ui.popFont()
  ui.text(string.format('%.1f s', timeLeft))
  ui.endTransparentWindow()
end
