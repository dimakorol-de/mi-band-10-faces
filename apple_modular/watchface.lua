local lv = require("lvgl")
local sys = require("sys")

-- 1. ИНИЦИАЛИЗАЦИЯ И НАСТРОЙКА ЭКРАНА
local screen = lv.obj_create(nil)
lv.obj_set_style_bg_color(screen, lv.color_black(), 0)
lv.scr_load(screen)

local days_ru = {"ВС", "ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ"}
local months_ru = {"ЯНВ", "ФЕВ", "МАР", "АПР", "МАЙ", "ИЮН", "ИЮЛ", "АВГ", "СЕН", "ОКТ", "НОЯ", "ДЕК"}

local current_style = sys.get_current_style_id()
local prefix = "br"
local accent_color = lv.color_make(205, 127, 50)

if current_style == 2 then
    prefix = "gd"
    accent_color = lv.color_make(255, 215, 0)
elseif current_style == 3 then
    prefix = "sv"
    accent_color = lv.color_make(192, 192, 192)
end

local chosen_widget = sys.get_config_int("widget_type", 1) 

-- ВЕРХНИЙ ВИДЖЕТ (ДАТА)
local date_label = lv.label_create(screen)
lv.obj_align(date_label, lv.ALIGN.TOP_MID, 0, 40)
lv.obj_set_style_text_color(date_label, lv.color_make(180, 180, 180), 0)

-- ЦЕНТРАЛЬНЫЙ ВИДЖЕТ (ЧАСЫ)
local time_container = lv.obj_create(screen)
lv.obj_set_size(time_container, 200, 150)
lv.obj_align(time_container, lv.ALIGN.CENTER, 0, -50)
lv.obj_set_style_bg_opa(time_container, lv.OPA.TRANSP, 0)
lv.obj_set_style_border_width(time_container, 0, 0)

local img_h1 = lv.img_create(time_container)
lv.obj_align(img_h1, lv.ALIGN.LEFT_MID, 0, 0)

local img_h2 = lv.img_create(time_container)
lv.obj_align(img_h2, lv.ALIGN.LEFT_MID, 45, 0)

local img_m1 = lv.img_create(time_container)
lv.obj_align(img_m1, lv.ALIGN.RIGHT_MID, -45, 0)

local img_m2 = lv.img_create(time_container)
lv.obj_align(img_m2, lv.ALIGN.RIGHT_MID, 0, 0)

-- ПОСТОЯННЫЙ НИЖНИЙ КРУГЛЫЙ КОНТУР
local widget_circle = lv.obj_create(screen)
lv.obj_set_size(widget_circle, 90, 90)
lv.obj_align(widget_circle, lv.ALIGN.BOTTOM_MID, 0, -60)
lv.obj_set_style_radius(widget_circle, lv.RADIUS.CIRCLE, 0)
lv.obj_set_style_bg_opa(widget_circle, lv.OPA.TRANSP, 0)
lv.obj_set_style_border_color(widget_circle, accent_color, 0)
lv.obj_set_style_border_width(widget_circle, 2, 0)

local widget_icon = lv.img_create(widget_circle)
lv.obj_align(widget_icon, lv.ALIGN.TOP_MID, 0, 14)

local widget_value = lv.label_create(widget_circle)
lv.obj_align(widget_value, lv.ALIGN.BOTTOM_MID, 0, -14)
lv.obj_set_style_text_color(widget_value, lv.color_white(), 0)

-- 2. ОБРАБОТКА НАЖАТИЯ НА КРУГ (ДЛЯ ФОНАРИКА)
lv.obj_add_event_cb(widget_circle, function(e)
    local code = lv.event_get_code(e)
    -- Если пользователь выбрал режим "Фонарик" (номер 4) и кликнул по кругу
    if code == lv.EVENT.CLICKED and chosen_widget == 4 then
        -- Вызываем системное приложение фонарика встроенной командой HyperOS
        if sys.open_app then
            sys.open_app(sys.APP_FLASHLIGHT or 12) -- 12 - стандартный ID фонарика в NuttX/HyperOS
        end
    end
end, lv.EVENT.CLICKED, nil)

-- 3. ФУНКЦИЯ ОБНОВЛЕНИЯ ДАННЫХ
local function update_watchface()
    local time = sys.get_time()
    local is_aod = false
    if sys.get_screen_mode then is_aod = (sys.get_screen_mode() == 2) end

    if is_aod then
        lv.obj_add_flag(widget_circle, lv.OBJ_FLAG.HIDDEN)
        lv.obj_add_flag(date_label, lv.OBJ_FLAG.HIDDEN)
        local shift_x = (time.min % 5) - 2
        local shift_y = (time.min % 3) - 1
        lv.obj_align(time_container, lv.ALIGN.CENTER, shift_x, -50 + shift_y)
    else
        lv.obj_clear_flag(widget_circle, lv.OBJ_FLAG.HIDDEN)
        lv.obj_clear_flag(date_label, lv.OBJ_FLAG.HIDDEN)
        lv.obj_align(time_container, lv.ALIGN.CENTER, 0, -50)
        
        local date_str = string.format("%s, %d %s", days_ru[time.wday], time.day, months_ru[time.month])
        lv.label_set_text(date_label, date_str)
        
        -- Отрисовка выбранного виджета
        if chosen_widget == 1 then
            lv.img_set_src(widget_icon, "A:ico_steps.png")
            lv.label_set_text(widget_value, tostring(sys.get_steps()))
        elseif chosen_widget == 2 then
            lv.img_set_src(widget_icon, "A:ico_heart.png")
            local hr = sys.get_heart_rate()
            lv.label_set_text(widget_value, hr > 0 and (hr .. " BPM") or "--")
        elseif chosen_widget == 3 then
            lv.img_set_src(widget_icon, "A:ico_battery.png")
            lv.label_set_text(widget_value, sys.get_battery() .. "%")
        elseif chosen_widget == 4 then
            -- РЕЖИМ ФОНАРИКА: выводим статичную иконку и текст-подсказку
            lv.img_set_src(widget_icon, "A:ico_light.png")
            lv.label_set_text(widget_value, "ВКЛ")
        end
    end

    local h1_val = math.floor(time.hour / 10)
    local h2_val = time.hour % 10
    local m1_val = math.floor(time.min / 10)
    local m2_val = time.min % 10
    
    lv.img_set_src(img_h1, string.format("A:%s_%d.png", prefix, h1_val))
    lv.img_set_src(img_h2, string.format("A:%s_%d.png", prefix, h2_val))
    lv.img_set_src(img_m1, string.format("A:%s_%d.png", prefix, m1_val))
    lv.img_set_src(img_m2, string.format("A:%s_%d.png", prefix, m2_val))
end

local timer = lv.timer_create(update_watchface, 1000, nil)
update_watchface()
