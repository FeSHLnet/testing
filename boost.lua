--[[
  Simple Boost Script for Assetto Corsa (CSP Online Script)
  ---------------------------------------------------------
  اضغط زر B عشان تاخذ دفعة سرعة.

  التركيب:
  1. ارفع هذا الملف على GitHub Gist (Raw) أو أي استضافة ملفات
  2. في مجلد cfg بسيرفرك، ملف csp_extra_options.ini:

     [SCRIPT_1]
     SCRIPT = "رابط الـ raw هنا"

     [EXTRA_TWEAKS]
     ALLOW_PHYSICS = 1

  ملاحظة: تعديل الفيزياء يحتاج صلاحيات من السيرفر.
  إذا ما اشتغل، شوف الأخطاء في Lua Debug داخل اللعبة.
--]]

-- ═══════════ الإعدادات ═══════════

local BOOST_KEY      = ui.KeyIndex.B   -- الزر
local BOOST_FORCE    = 12000           -- قوة الدفع (نيوتن) - زودها لبوست أقوى
local MAX_SPEED_KMH  = 320             -- أقصى سرعة يشتغل عندها البوست
local COOLDOWN       = 3.0             -- ثواني انتظار بين كل بوست
local BOOST_DURATION = 2.0             -- مدة البوست بالثواني

-- ═════════════════════════════════

local timeLeft = 0
local cooldownLeft = 0

function script.update(dt)
  local car = ac.getCar(0)
  if not car then return end

  -- تقليل المؤقتات
  if cooldownLeft > 0 then cooldownLeft = cooldownLeft - dt end
  if timeLeft > 0 then timeLeft = timeLeft - dt end

  local speedKmh = car.speedKmh

  -- تشغيل البوست عند الضغط
  if ac.isKeyDown(BOOST_KEY)
     and cooldownLeft <= 0
     and timeLeft <= 0
     and speedKmh < MAX_SPEED_KMH
     and car.gear > 0 then

    timeLeft = BOOST_DURATION
    cooldownLeft = BOOST_DURATION + COOLDOWN
    ac.setMessage("BOOST", "🔥 بوست!")
  end

  -- تطبيق قوة الدفع للأمام
  if timeLeft > 0 and speedKmh < MAX_SPEED_KMH then
    physics.addForce(
      vec3(0, 0, 0),        -- نقطة التطبيق (مركز السيارة)
      true,                 -- إحداثيات محلية
      vec3(0, 0, BOOST_FORCE), -- الاتجاه: للأمام
      true                  -- قوة محلية
    )
  end
end

-- عرض شريط البوست على الشاشة
function script.drawUI()
  if timeLeft > 0 then
    ui.beginTransparentWindow('boostHud', vec2(20, 300), vec2(200, 40))
    ui.text('BOOST: ' .. string.format('%.1f', timeLeft) .. 's')
    ui.endTransparentWindow()
  end
end
