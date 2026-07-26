--[[
═══════════════════════════════════════════════════════════
  LAUNCH SCRIPT v4  |  Assetto Corsa - CSP Online Script
  إطلاق فوري لأقصى سرعة (زي سيرفرات الهجولة)
═══════════════════════════════════════════════════════════

  الفكرة:
    بدل ما ندفع السيارة بقوة، نحدد سرعتها مباشرة
    ونرفعها شوي عن الأرض عشان الكفرات ما تعاند

  الطرق المتاحة (غيّر METHOD):
    "launch"  = سرعة فورية + رفعة خفيفة  ← المطلوب
    "speed"   = سرعة فورية بدون رفعة
    "force"   = دفع تدريجي بقوة

═══════════════════════════════════════════════════════════
--]]


-- ══════════════ الإعدادات ══════════════

local METHOD        = "launch"

local BOOST_KEY     = ui.KeyIndex.B
local TARGET_KMH    = 350        -- السرعة المطلوبة
local LIFT_METERS   = 0.35       -- ارتفاع الرفعة (ربع/نص متر)
local COOLDOWN      = 3.0        -- انتظار بين كل إطلاق

local BOOST_FORCE   = 30000      -- لطريقة force فقط
local FORWARD_SIGN  = -1         -- اتجاه الأمام (تأكدنا: -1)

local SHOW_HUD      = true
local DEBUG         = true

-- ═══════════════════════════════════════


local cooldownLeft = 0
local status       = "جاهز"
local lastGain     = 0
local hudTimer     = 0


-- ─── الإطلاق الفوري ───

local function launch()
  local car = ac.getCar(0)
  if car == nil then return end
  if physics == nil then status = "physics غير موجود" return end

  local speedBefore = car.speedKmh
  local targetMs    = TARGET_KMH / 3.6
  local forward     = car.look          -- اتجاه السيارة للأمام
  local ok1, ok2    = false, false

  -- 1) رفع السيارة شوي عن الأرض
  if METHOD == "launch" and physics.setCarPosition ~= nil then
    ok1 = pcall(function()
      physics.setCarPosition(
        0,
        car.position + vec3(0, LIFT_METERS, 0),
        forward
      )
    end)
  end

  -- 2) تحديد السرعة مباشرة
  if physics.setCarVelocity ~= nil then
    ok2 = pcall(function()
      physics.setCarVelocity(0, forward * targetMs)
    end)
  end

  lastGain = car.speedKmh - speedBefore

  if ok2 then
    status = ok1 and "إطلاق كامل (رفعة + سرعة)" or "سرعة فقط (الرفعة فشلت)"
  else
    status = "setCarVelocity غير متاحة"
  end
end


-- ─── الدفع بقوة (احتياطي) ───

local function pushForce()
  if physics == nil or physics.addForce == nil then return end
  pcall(function()
    physics.addForce(
      vec3(0, 0, 0), true,
      vec3(0, 0, BOOST_FORCE * FORWARD_SIGN), true
    )
  end)
  status = "قوة مطبّقة"
end


-- ═══════════════ الحلقة الرئيسية ═══════════════

function script.update(dt)
  local car = ac.getCar(0)
  if car == nil then return end

  if cooldownLeft > 0 then cooldownLeft = cooldownLeft - dt end
  if hudTimer > 0 then hudTimer = hudTimer - dt end

  if ac.isKeyDown(BOOST_KEY) and cooldownLeft <= 0 and car.gear > 0 then
    cooldownLeft = COOLDOWN
    hudTimer     = 2.0

    if METHOD == "force" then
      pushForce()
    else
      launch()
    end

    ac.setMessage("BOOST", "LAUNCH!")
  end

  if DEBUG then
    ac.debug("1_status", status)
    ac.debug("2_method", METHOD)
    ac.debug("3_speed_now", math.floor(car.speedKmh))
    ac.debug("4_gained", math.floor(lastGain) .. " km/h")
    ac.debug("5_cooldown", string.format("%.1f", math.max(cooldownLeft, 0)))
    ac.debug("6_has_setPos", physics ~= nil and physics.setCarPosition ~= nil)
    ac.debug("7_has_setVel", physics ~= nil and physics.setCarVelocity ~= nil)
  end
end


-- ═══════════════ الواجهة ═══════════════

function script.drawUI()
  if not SHOW_HUD or hudTimer <= 0 then return end

  ui.beginTransparentWindow('boostHud', vec2(20, 300), vec2(260, 70))
  ui.pushFont(ui.Font.Title)
  ui.text('LAUNCH')
  ui.popFont()
  ui.text(TARGET_KMH .. ' km/h')
  ui.endTransparentWindow()
end
