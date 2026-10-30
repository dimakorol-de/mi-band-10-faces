local lv = require("lvgl")
local sys = require("sys")

-- 1. ИНИЦИАЛИЗАЦИЯ И НАСТРОЙКА ЭКРАНА
local screen = lv.obj_create(nil)
lv.obj_set_style_bg_color(screen, lv.color_black(), 0)
lv.scr_load(screen)

-- Словари для перевода даты
local days_ru = {"ВС", "ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ"}
local months_ru = {"ЯНВ", "ФЕВ", "МАР", "АПР", "МАЙ", "ИЮН", "ИЮЛ", "АВГ", "СЕН", "ОКТ", "НОЯ", "ДЕК"}

-- Считываем цвет темы из меню браслета
local current_style = sys.get_current_style_id()
local prefix = "br"
local accent_color = lv.color_make(205, 127, 50) -- Бронзовый по умолчанию

if current_style == 2 then
    prefix = "gd"
    accent_color = lv.color_make(255, 215, 0) -- Золотой
elseif current_style == 3 then
    prefix = "sv"
    accent_color = lv.color_make(192, 192, 192) -- Серебряный
end

-- Считываем выбранный тип нижнего виджета
local chosen_widget = sys.get_config_int("widget_type", 1) 

-- ВЕРХНИЙ ВИДЖЕТ (ДАТА НА РУССКОМ)
local date_label = lv.label_create(screen)
lv.obj_align(date_label, lv.ALIGN.TOP_MID, 0, 40)
lv.obj_set_style_text_color(date_label, lv.color_make(180, 180, 180), 0)

-- ЦЕНТРАЛЬНЫЙ ВИДЖЕТ (ВЫТЯНУТЫЕ ЧАСЫ)
local time_container = lv.obj_create(screen)
lv.obj_set_size(time_container, 200, 150)
lv.obj_align(time_container, lv.ALIGN.CENTER, 0, -50)
lv.obj_set_style_bg_opa(time_container, lv.OPA.TRANSP, 0)
lv.obj_set_style_border_width(time_container, 0, 0)

local img_h1 = lv.img_create(time_container)
lv.obj_align(img_h1, lv.ALIGN.LEFT_MID, 0, 0)

local img_h2 = lv.img_create(time_container)
lv.obj_align(img_h2, lv.ALIGN.LEFT_MID, 45, 0)

local img_dot = lv.img_create(time_container)
lv.obj_align(img_dot, lv.ALIGN.CENTER, 0, 0)

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


-- 2. ФУНКЦИЯ ОБНОВЛЕНИЯ ДАННЫХ И КОНТРОЛЯ РЕЖИМА AOD
local function update_watchface()
    local time = sys.get_time()
    
    -- Проверяем, находится ли браслет в режиме Always-On Display
    -- В зависимости от API это может быть sys.get_screen_mode() == "aod" или sys.is_aod()
    local is_aod = false
    if sys.get_screen_mode then
        is_aod = (sys.get_screen_mode() == 2) -- 2 обычно означает режим AOD/Сон
    end

    if is_aod then
        -------------------------------------------------------------
        -- РЕЖИМ AOD (Энергосбережение и защита от выгорания)
        -------------------------------------------------------------
        -- 1. Полностью скрываем нижний круглый виджет с данными
        lv.obj_add_flag(widget_circle, lv.OBJ_FLAG.HIDDEN)
        
        -- 2. Скрываем дату (или можно оставить, но сделать тусклой)
        lv.obj_add_flag(date_label, lv.OBJ_FLAG.HIDDEN)
        
        -- 3. Скрываем двоеточие, чтобы оно не мигало и не тратило заряд
        lv.obj_add_flag(img_dot, lv.OBJ_FLAG.HIDDEN)
        
        -- 4. Защита от выгорания: сдвигаем часы на случайную величину (-4 до +4 пикселей) раз в минуту
        local shift_x = (time.min % 5) - 2
        local shift_y = (time.min % 3) - 1
        lv.obj_align(time_container, lv.ALIGN.CENTER, shift_x, -50 + shift_y)
        
    else
        -------------------------------------------------------------
        -- ОБЫЧНЫЙ АКТИВНЫЙ РЕЖИМ
        -------------------------------------------------------------
        -- Возвращаем видимость всем скрытым элементам
        lv.obj_clear_flag(widget_circle, lv.OBJ_FLAG.HIDDEN)
        lv.obj_clear_flag(date_label, lv.OBJ_FLAG.HIDDEN)
        lv.obj_clear_flag(img_dot, lv.OBJ_FLAG.HIDDEN)
        
        -- Возвращаем контейнер времени ровно по центру
        lv.obj_align(time_container, lv.ALIGN.CENTER, 0, -50)
        
        -- Обновление даты (только в активном режиме)
        local date_str = string.format("%s, %d %s", days_ru[time.wday], time.day, months_ru[time.month])
        lv.label_set_text(date_label, date_str)
        
        -- Обновление значений внутри круга
        if chosen_widget == 1 then
            lv.img_set_src(widget_icon, "A:images/ico_steps.png")
            lv.label_set_text(widget_value, tostring(sys.get_steps()))
        elseif chosen_widget == 2 then
            lv.img_set_src(widget_icon, "A:images/ico_heart.png")
            local hr = sys.get_heart_rate()
            lv.label_set_text(widget_value, hr > 0 and (hr .. " BPM") or "--")
        elseif chosen_widget == 3 then
            lv.img_set_src(widget_icon, "A:images/ico_battery.png")
            lv.label_set_text(widget_value, sys.get_battery() .. "%")
        elseif chosen_widget == 4 then
            lv.img_set_src(widget_icon, "A:images/ico_sleep.png")
            lv.label_set_text(widget_value, "ЗЗЗ")
        end
    end

    -- Отрисовка кастомных вытянутых цифр (работает в обоих режимах)
    local h1_val = math.floor(time.hour / 10)
    local h2_val = time.hour % 10
    local m1_val = math.floor(time.min / 10)
    local m2_val = time.min % 10
    
    lv.img_set_src(img_h1, string.format("A:images/%s_%d.png", prefix, h1_val))
    lv.img_set_src(img_h2, string.format("A:images/%s_%d.png", prefix, h2_val))
    lv.img_set_src(img_dot, string.format("A:images/%s_dot.png", prefix))
    lv.img_set_src(img_m1, string.format("A:images/%s_%d.png", prefix, m1_val))
    lv.img_set_src(img_m2, string.format("A:images/%s_%d.png", prefix, m2_val))
end

-- Таймер обновлений (1 раз в секунду)
local timer = lv.timer_create(update_watchface, 1000, nil)
update_watchface()
