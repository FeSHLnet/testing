--[[
═══════════════════════════════════════════════════════════
  BOOST / LAUNCH SCRIPT v5
  Assetto Corsa - CSP Online Script
═══════════════════════════════════════════════════════════

  ✅ تم تصحيح استدعاءات الفيزياء حسب التوثيق الرسمي
     (المعامل الأول في كل دوال physics هو carIndex)

  الطرق المتاحة (غيّر METHOD):
    "launch"  = سرعة فورية (زي سيرفرات الهجولة)
    "force"   = دفع تدريجي بقوة
    "torque"  = عزم على الكفرات

  ملاحظة: كل هذي الطرق تلغي وقت اللفة (طبيعي، مو مشكلة للهجولة)

═══════════════════════════════════════════════════════════
--]]


-- ══════════════ الإعدادات ══════════════

local METHOD        = "launch"   -- launch / force / torque

local BOOST_KEY     = ui.KeyIndex.B
local COOLDOWN      = 3.0        -- ثواني انتظار بين كل مرة

-- إعدادات launch
local TARGET_KMH    = 350        -- السرعة المطلوبة
local LIFT_METERS   = 0.30       -- رفعة خفيفة عن الأرض (0 = بدون رفعة)

-- إعدادات force
local BOOST_FORCE   = 25000      -- قوة الدفع بالنيوتن
local FORCE_TIME    = 2.0        -- مدة الدفع بالثواني
local FORWARD_SIGN  = 1          -- إذا دفع للخلف، غيّرها لـ -1

-- إعدادات torque
local WHEEL_TORQUE  = 4000

local MAX_SPEED_KMH = 400        -- حد أمان
local SHOW_HUD      = true
local DEBUG         = true       -- خلها false بعد ما يشتغل

-- ═══════════════════════════════════════


local CAR = 0                    -- سيارتك دايماً index 0 في السكربتات الأونلاين

local cooldownLeft = 0
local forceLeft    = 0
local hudTimer     = 0
local status       = "جاهز"
local speedBefore  = 0
local speedGained  = 0


-- ─── إطلاق فوري ───

local function doLaunch()
  local car = ac.getCar(CAR)
  if car == nil then return end

  local targetMs = TARGET_KMH / 3.6
  local forward  = car.look          -- متجه الأمام (عالمي)

  -- رفعة خفيفة عن الأرض
  if LIFT_METERS > 0 and physics.setCarPosition ~= nil then
    pcall(physics.setCarPosition, CAR,
      car.position + vec3(0, LIFT_METERS, 0), forward)
  end

  -- تحديد السرعة مباشرة
  local ok = pcall(physics.setCarVelocity, CAR, forward * targetMs)
  status = ok and ("إطلاق " .. TARGET_KMH .. " كم/س") or "setCarVelocity فشلت"
end


-- ─── دفع بقوة ───

local function doForce()
  -- التوقيع الصحيح: (carIndex, position, posLocal, force, forceLocal)
  pcall(physics.addForce,
    CAR,                                     -- رقم السيارة
    vec3(0, 0, 0),                           -- نقطة التطبيق
    true,                                    -- موقع محلي
    vec3(0, 0, BOOST_FORCE * FORWARD_SIGN),  -- متجه القوة
    true                                     -- قوة محلية
  )
  status = "دفع " .. BOOST_FORCE .. "N"
end


-- ─── عزم على الكفرات ───

local function doTorque()
  -- التوقيع الصحيح: (carIndex, wheels, torque)
  pcall(physics.addWheelTorque, CAR, ac.Wheel.All, WHEEL_TORQUE)
  status = "عزم " .. WHEEL_TORQUE
end


-- ═══════════════ الحلقة الرئيسية ═══════════════

function script.update(dt)
  local car = ac.getCar(CAR)
  if car == nil then return end

  if cooldownLeft > 0 then cooldownLeft = cooldownLeft - dt end
  if hudTimer > 0 then hudTimer = hudTimer - dt end
  if forceLeft > 0 then forceLeft = forceLeft - dt end

  local speed = car.speedKmh

  -- بدء البوست
  if ac.isKeyDown(BOOST_KEY)
     and cooldownLeft <= 0
     and speed < MAX_SPEED_KMH
     and car.gear > 0 then

    speedBefore = speed
    hudTimer    = 2.0

    if METHOD == "launch" then
      cooldownLeft = COOLDOWN
      doLaunch()
    else
      cooldownLeft = COOLDOWN + FORCE_TIME
      forceLeft    = FORCE_TIME
    end

    ac.setMessage("BOOST", "BOOST!")
  end

  -- استمرار الدفع/العزم
  if forceLeft > 0 and speed < MAX_SPEED_KMH then
    if METHOD == "force" then doForce()
    elseif METHOD == "torque" then doTorque() end
  end

  if hudTimer > 0 then
    speedGained = speed - speedBefore
  end

  if DEBUG then
    ac.debug("1_status",   status)
    ac.debug("2_method",   METHOD)
    ac.debug("3_speed",    math.floor(speed) .. " km/h")
    ac.debug("4_gained",   math.floor(speedGained) .. " km/h")
    ac.debug("5_allowed",  physics.allowed and physics.allowed() or "?")
    ac.debug("6_cooldown", string.format("%.1f", math.max(cooldownLeft, 0)))
  end
end


-- ═══════════════ الواجهة ═══════════════

function script.drawUI()
  if not SHOW_HUD or hudTimer <= 0 then return end

  ui.beginTransparentWindow('boostHud', vec2(20, 300), vec2(280, 70))
  ui.pushFont(ui.Font.Title)
  ui.text('BOOST')
  ui.popFont()
  ui.text(string.format('%d km/h   (+%d)',
    math.floor(ac.getCar(CAR).speedKmh), math.floor(speedGained)))
  ui.endTransparentWindow()
end
