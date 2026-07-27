--[[
═══════════════════════════════════════════════════════════
  BOOST / LAUNCH SCRIPT  v6  (النسخة النهائية)
  Assetto Corsa - CSP Online Script
═══════════════════════════════════════════════════════════

  اضغط زر B ← السيارة تنطلق فوراً لأقصى سرعة

  ─────────────── التركيب ───────────────

  الطريقة (أ) - لان (مفضّلة):
    حط الملف في كل جهاز:
      assettocorsa\extension\lua\online\boost.lua
    وفي السيرفر: cfg\csp_extra_options.ini
      [SCRIPT_1]
      SCRIPT = "boost.lua"

  الطريقة (ب) - رابط إنترنت:
    ارفع الملف على gist.github.com وخذ رابط Raw
      [SCRIPT_1]
      SCRIPT = "رابط الـ Raw"

  ملاحظة: يلغي وقت اللفة (طبيعي، ما يفرق في الهجولة)

═══════════════════════════════════════════════════════════
--]]


-- ══════════════ الإعدادات ══════════════

local BOOST_KEY     = ui.KeyIndex.B   -- زر البوست
local TARGET_KMH    = 350             -- السرعة المطلوبة
local LIFT_METERS   = 0.30            -- الرفعة عن الأرض (0 = بدون)
local COOLDOWN      = 3.0             -- ثواني الانتظار بين كل مرة
local MAX_SPEED_KMH = 400             -- حد أمان
local REQUIRE_GEAR  = true            -- يشترط تكون في قير (مو نيوترال)

local SHOW_HUD      = true            -- عرض شاشة البوست
local HUD_POS       = vec2(20, 300)   -- موقع الشاشة
local DEBUG         = false           -- true للتشخيص

-- ═══════════════════════════════════════


local CAR = 0                -- سيارتك دايماً index 0 في السكربتات الأونلاين

local cooldownLeft = 0
local hudTimer     = 0
local speedBefore  = 0
local speedGained  = 0
local status       = "جاهز"


-- ─── الإطلاق ───

local function launch()
  local car = ac.getCar(CAR)
  if car == nil then return end

  local targetMs = TARGET_KMH / 3.6
  local forward  = -car.look          -- ← اتجاه الأمام الصحيح

  -- رفعة خفيفة عشان الكفرات ما تعاند
  if LIFT_METERS > 0 then
    pcall(physics.setCarPosition, CAR,
      car.position + vec3(0, LIFT_METERS, 0), forward)
  end

  -- تحديد السرعة مباشرة
  local ok = pcall(physics.setCarVelocity, CAR, forward * targetMs)
  status = ok and "تم" or "فشل"
end


-- ═══════════════ الحلقة الرئيسية ═══════════════

function script.update(dt)
  local car = ac.getCar(CAR)
  if car == nil then return end

  if cooldownLeft > 0 then cooldownLeft = cooldownLeft - dt end
  if hudTimer > 0 then hudTimer = hudTimer - dt end

  local speed = car.speedKmh

  local gearOk = (not REQUIRE_GEAR) or car.gear > 0

  if ac.isKeyDown(BOOST_KEY)
     and cooldownLeft <= 0
     and speed < MAX_SPEED_KMH
     and gearOk then

    cooldownLeft = COOLDOWN
    speedBefore  = speed
    hudTimer     = 2.0

    launch()
    ac.setMessage("BOOST", "BOOST!")
  end

  if hudTimer > 0 then
    speedGained = speed - speedBefore
  end

  if DEBUG then
    ac.debug("1_status",   status)
    ac.debug("2_speed",    math.floor(speed) .. " km/h")
    ac.debug("3_gained",   math.floor(speedGained) .. " km/h")
    ac.debug("4_gear",     car.gear)
    ac.debug("5_cooldown", string.format("%.1f", math.max(cooldownLeft, 0)))
    ac.debug("6_allowed",  physics.allowed and physics.allowed() or "?")
  end
end


-- ═══════════════ الواجهة ═══════════════

function script.drawUI()
  if not SHOW_HUD or hudTimer <= 0 then return end

  local car = ac.getCar(CAR)
  if car == nil then return end

  ui.beginTransparentWindow('boostHud', HUD_POS, vec2(280, 70))

  ui.pushFont(ui.Font.Title)
  ui.text('BOOST')
  ui.popFont()

  ui.text(string.format('%d km/h   (+%d)',
    math.floor(car.speedKmh), math.floor(speedGained)))

  ui.endTransparentWindow()
end
