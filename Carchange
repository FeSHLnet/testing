--[[
═══════════════════════════════════════════════════════════
  CAR CHANGER  v1
  Assetto Corsa - CSP Online Script
═══════════════════════════════════════════════════════════

  اضغط زر F ← تفتح قائمة السيارات
  اختار سيارة ← يعيد الاتصال بنفس السيرفر بالسيارة الجديدة

  ملاحظات مهمة:
  ─────────────
  • بيصير تحميل سريع (ثانيتين تقريباً) - هذا طبيعي
    وما فيه طريقة تتجنبه في أسيتو كورسا
  • السيارة لازم يكون لها سلوت فاضي في entry_list.ini
  • السكربت يقرأ السيارات المتاحة تلقائياً من السيرفر

  ─────────────── التركيب ───────────────

  حط الملف في كل جهاز:
    assettocorsa\extension\lua\online\carchange.lua

  وفي السيرفر: cfg\csp_extra_options.ini
    [SCRIPT_2]
    SCRIPT = "carchange.lua"

  (لاحظ SCRIPT_2 عشان ما يتعارض مع سكربت البوست)

═══════════════════════════════════════════════════════════
--]]


-- ══════════════ الإعدادات ══════════════

local MENU_KEY       = ui.KeyIndex.F   -- زر فتح القائمة
local STATIONARY_ONLY = true           -- يشترط السيارة واقفة
local MAX_SPEED_KMH  = 5               -- أقصى سرعة للتبديل
local MENU_POS       = vec2(100, 150)
local MENU_SIZE      = vec2(300, 420)

-- ═══════════════════════════════════════


local menuOpen   = false
local keyWasDown = false
local carList    = nil
local message    = ""
local messageTtl = 0


-- ─── جمع السيارات المتاحة من السلوتات الفاضية ───

local function collectCars()
  local list, seen = {}, {}

  for i, c in ac.iterateCars.serverSlots() do
    if c ~= nil and not c.isConnected then
      local id = c:id()
      if id ~= nil and id ~= "" and not seen[id] then
        seen[id] = true
        list[#list + 1] = { id = id, name = c:name() or id }
      end
    end
  end

  table.sort(list, function(a, b) return a.name < b.name end)
  return list
end


-- ─── تنفيذ التبديل ───

local function switchTo(carID)
  local ok, err = pcall(ac.reconnectTo, { carID = carID })
  if not ok then
    message    = "فشل التبديل: " .. tostring(err)
    messageTtl = 4
  end
end


-- ═══════════════ الحلقة الرئيسية ═══════════════

function script.update(dt)
  if messageTtl > 0 then messageTtl = messageTtl - dt end

  -- فتح/إغلاق القائمة عند الضغط (مو الاستمرار)
  local keyDown = ac.isKeyDown(MENU_KEY)
  if keyDown and not keyWasDown then
    menuOpen = not menuOpen
    if menuOpen then carList = collectCars() end
  end
  keyWasDown = keyDown
end


-- ═══════════════ الواجهة ═══════════════

function script.drawUI()
  -- رسالة خطأ لو فيه
  if messageTtl > 0 then
    ui.beginTransparentWindow('carChangeMsg', vec2(20, 250), vec2(400, 40))
    ui.text(message)
    ui.endTransparentWindow()
  end

  if not menuOpen then return end

  local car = ac.getCar(0)
  if car == nil then return end

  ui.beginToolWindow('carChangeMenu', MENU_POS, MENU_SIZE)

  ui.pushFont(ui.Font.Title)
  ui.text('تغيير السيارة')
  ui.popFont()
  ui.separator()

  -- فحص شرط الوقوف
  local canSwitch = true
  if STATIONARY_ONLY and car.speedKmh > MAX_SPEED_KMH then
    canSwitch = false
    ui.textColored('وقّف السيارة أول', rgbm(1, 0.5, 0.2, 1))
    ui.newLine()
  end

  if carList == nil or #carList == 0 then
    ui.text('ما فيه سيارات متاحة حالياً')
    ui.text('(كل السلوتات مشغولة)')
  else
    ui.childWindow('carList', vec2(0, 300), function()
      for _, entry in ipairs(carList) do
        if not canSwitch then ui.pushDisabled() end

        if ui.selectable(entry.name) then
          menuOpen = false
          switchTo(entry.id)
        end

        if not canSwitch then ui.popDisabled() end
      end
    end)
  end

  ui.separator()
  ui.textDisabled('اضغط F للإغلاق')

  if ui.button('تحديث القائمة', vec2(-1, 0)) then
    carList = collectCars()
  end

  ui.endToolWindow()
end
