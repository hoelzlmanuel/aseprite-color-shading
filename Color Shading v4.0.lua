-- Color Shading v4.0
-- Aseprite Script that opens a dynamic palette picker window with relevant color shading options
-- v1.0-2.0 by Dominick John and David Capello, https://github.com/dominickjohn/aseprite/tree/master
-- v3.0 by yashar98, https://github.com/yashar98/aseprite/tree/main
-- v3.1 by Daeyangae, https://github.com/Daeyangae/aseprite
-- v4.0 by Manuel Hoelzl, https://github.com/hoelzlmanuel/aseprite-color-shading

-- Instructions:
--    Place this file into the Aseprite scripts folder (File -> Scripts -> Open Scripts Folder)
--    Run the "Color Shading" script (File -> Scripts -> Color Shading v4.0) to open the palette window.
-- Usage:
--    Base: Clicking on either base color will switch the shading palette to that saved color base.
--    "Get" Button: Updates base colors using the current foreground and background color and regenerates shading.
--    Left click: Set clicked color as foreground color.
--    Right click: Set clicked color as background color.
--    Middle click: Set clicked color as fore- or background color, depending on which one was set last (if auto pick is on) and regenerate all shades based on this new color.

-- variables -------------------------------------------------------------------------
-- main variables
local dlg
local autoPick = true
local advanced = true
local fgListenerCode
local bgListenerCode
local eyeDropper = true
local slots = 7
local shadingColors = {}
local lighthessColors = {}
local saturationColors = {}
local nuanceColors = {}
local mixedColors = {}
local hueColors = {}
local lastColor

-- BG AND FG COLORS
local FGcache
local BGcache

-- CORE COLOR
local coreColor

-- helper functions ------------------------------------------------------------------
local function lerp(first, second, by) return first * (1 - by) + second * by end

local function shiftHue(color, amount)
    local newColor = Color(color)
    newColor.hue = (newColor.hue + amount * 360) % 360
    return newColor
end

local function shiftSaturation(color, amount)
    local newColor = Color(color)
    if (amount > 0) then
        newColor.saturation = lerp(newColor.saturation, 1, amount)
    elseif (amount < 0) then
        newColor.saturation = lerp(newColor.saturation, 0, -amount)
    end
    return newColor
end

local function shiftLightness(color, amount)
    local newColor = Color(color)
    if (amount > 0) then
        newColor.lightness = lerp(newColor.lightness, 1, amount)
    elseif (amount < 0) then
        newColor.lightness = lerp(newColor.lightness, 0, -amount)
    end
    return newColor
end

local function shiftHSL(color, hue, saturation, lightness)
    return shiftHue(
               shiftSaturation(shiftLightness(color, lightness), saturation),
               hue)
end

local function mixColors(color1, color2, proportion)
    return Color {
        red = lerp(color1.red, color2.red, proportion),
        green = lerp(color1.green, color2.green, proportion),
        blue = lerp(color1.blue, color2.blue, proportion)
    }
end

local function shiftShading(color, hue, proportion)
    local hueShifted = Color(color)
    hueShifted.hue = hue
    return mixColors(color, hueShifted, proportion)
end

-- main functions ----------------------------------------------------------------

local function calculateColors(baseColor)
    coreColor = baseColor
    shadingColors = {}
    lighthessColors = {}
    saturationColors = {}
    nuanceColors = {}
    mixedColors = {}
    hueColors = {}
    for i = 1, slots do
        mixedColors[i] = mixColors(FGcache, BGcache, 1 / (slots + 1) * i)
        hueColors[i] = shiftHue(baseColor, 1 / (slots + 1) * i)

        if i == (slots + 1) / 2 then
            shadingColors[i] = baseColor
            lighthessColors[i] = baseColor
            saturationColors[i] = baseColor
            nuanceColors[i] = baseColor
        else
            factor = ((slots - 1) / 2 - i + 1) / ((slots - 1) / 2)
            neg = -1
            temp = dlg.data.lowtemp
            if i > slots / 2 then
                factor = (-1) * factor
                neg = 1
                temp = dlg.data.hightemp
            end
            shadingColors[i] = shiftShading(
                                   shiftHSL(baseColor, 0,
                                            dlg.data.intensity / 100 * factor,
                                            dlg.data.peak / 100 * factor * neg),
                                   temp, dlg.data.sway / 100 * factor)
            lighthessColors[i] = shiftLightness(baseColor, 0.4 * factor * neg)
            saturationColors[i] =
                shiftSaturation(baseColor, 0.75 * factor * neg)
            nuanceColors[i] = shiftHue(baseColor, ((slots + 1) / 2 - i) * 1 /
                                           (slots + 1) * 2 / (slots + 1))
        end
    end
end

local function updateDialogData()
    dlg:modify{id = "base", colors = {FGcache, BGcache}}
    dlg:modify{id = "sha", colors = shadingColors}
    dlg:modify{id = "lit", colors = lighthessColors}
    dlg:modify{id = "sat", colors = saturationColors}
    dlg:modify{id = "nuance", colors = nuanceColors}
    dlg:modify{id = "mix", colors = mixedColors}
    dlg:modify{id = "hue", colors = hueColors}
    dlg:modify{id = "intensity", visible = advanced}
    dlg:modify{id = "peak", visible = advanced}
    dlg:modify{id = "sway", visible = advanced}
    dlg:modify{id = "slots", visible = advanced}
end

local function onShadesClick(ev)
    eyeDropper = false
    if (ev.button == MouseButton.LEFT) then
        app.fgColor = ev.color
    elseif (ev.button == MouseButton.MIDDLE) then
        if FGcache == lastColor then
            app.fgColor = ev.color
            FGcache = ev.color
        else
            app.bgColor = ev.color
            BGcache = ev.color
        end
        lastColor = ev.color
        calculateColors(ev.color)
        updateDialogData()
    elseif (ev.button == MouseButton.RIGHT) then
        app.bgColor = ev.color
    end
end

local function createDialog()
    FGcache = app.fgColor
    BGcache = app.bgColor

    dlg = Dialog {
        title = "Color Shading",
        onclose = function()
            app.events:off(fgListenerCode)
            app.events:off(bgListenerCode)
        end
    }

    -- dialog
    dlg:shades{
        -- saved color bases
        id = "base",
        label = "Base",
        colors = {FGcache, BGcache},
        onclick = function(ev)
            lastColor = ev.color
            calculateColors(ev.color)
            updateDialogData()
        end
    }:button{
        -- get-button
        id = "get",
        text = "Get",
        onclick = function()
          cacheLastColor = lastColor
          FGcache = app.fgColor
          BGcache = app.bgColor
            if cacheLastColor == BGcache then
              lastColor = app.bgColor
              calculateColors(BGcache)
                lastColor = app.fgColor
                calculateColors(FGcache)
            else
              lastColor = app.fgColor
              calculateColors(FGcache)
            end
            updateDialogData()
        end
    }:shades{
        -- shades
        id = "sha",
        label = "Shade",
        onclick = onShadesClick
    }:shades{
        -- lightness gradient
        id = "lit",
        label = "Light",
        onclick = onShadesClick
    }:shades{
        -- saturation gradient
        id = "sat",
        label = "Sat",
        onclick = onShadesClick
    }:shades{
        -- mix gradient
        id = "mix",
        label = "Mix",
        onclick = onShadesClick
    }:shades{
        -- nuances
        id = "nuance",
        label = "Nuance",
        onclick = onShadesClick
    }:shades{
        -- hues
        id = "hue",
        label = "Hue",
        onclick = onShadesClick
    }:newrow{
        -- hue slider for shades
        dlg:slider{
            id = "lowtemp",
            label = "Temp.",
            min = 0,
            max = 359.999,
            value = 215,
            onchange = function()
                dlg:modify{
                    id = "lowtempcol",
                    color = Color {
                        hue = dlg.data.lowtemp,
                        saturation = 1,
                        lightness = 0.5
                    }
                }
                calculateColors(lastColor)
                updateDialogData()
            end
        }:slider{
            id = "hightemp",
            min = 0,
            max = 359.999,
            value = 50,
            onchange = function()
                dlg:modify{
                    id = "hightempcol",
                    color = Color {
                        hue = dlg.data.hightemp,
                        saturation = 1,
                        lightness = 0.5
                    }
                }
                calculateColors(lastColor)
                updateDialogData()
            end
        }
    }:newrow{
        dlg:color{
            id = "lowtempcol",
            color = Color {
                hue = dlg.data.lowtemp,
                saturation = 1,
                lightness = 0.5
            }
        }:color{
            id = "hightempcol",
            color = Color {
                hue = dlg.data.hightemp,
                saturation = 1,
                lightness = 0.5
            }
        }
    }:slider{
        -- slider to set shade saturation gradient
        id = "intensity",
        label = "Intensity",
        min = 1,
        max = 200,
        value = 40,
        onchange = function()
            calculateColors(lastColor)
            updateDialogData()
        end
    }:slider{
        -- slider to set light gradient in shading
        id = "peak",
        label = "Peak",
        min = 1,
        max = 100,
        value = 60,
        onchange = function()
            calculateColors(lastColor)
            updateDialogData()
        end
    }:slider{
        -- slider to apply shade temperature
        id = "sway",
        label = "Sway",
        min = 1,
        max = 100,
        value = 60,
        onchange = function()
            calculateColors(lastColor)
            updateDialogData()
        end
    }:slider{
        -- slider to change number of slots
        id = "slots",
        label = "Slots",
        min = 3,
        max = 25,
        value = 7,
        onchange = function()
            local value = dlg.data.slots
            if value % 2 == 0 then
                dlg:modify{id = "slots", value = value + 1}
            end
            slots = dlg.data.slots
            calculateColors(lastColor)
            updateDialogData()
        end
    }:check{
        -- toggle auto pick
        id = "mode",
        text = "Auto Pick",
        selected = autoPick,
        onclick = function() autoPick = not autoPick end
    }:check{
        -- topple visibility of advanced features
        id = "mode",
        text = "Advanced",
        selected = advanced,
        onclick = function()
            advanced = not advanced
            updateDialogData()
        end
    }

    dlg:show{wait = false}
end

local function onFgChange()
    if (eyeDropper == true and autoPick == true) then
        FGcache = app.fgColor
        calculateColors(app.fgColor)
        lastColor = FGcache
        updateDialogData()
    elseif (eyeDropper == false) then
        -- print("inside shades")
    end
    eyeDropper = true
end

local function onBgChange()
    if (eyeDropper == true and autoPick == true) then
        BGcache = app.bgColor
        calculateColors(app.bgColor)
        lastColor = BGcache
        updateDialogData()
    elseif (eyeDropper == false) then
        -- print("inside shades")
    end
    eyeDropper = true
end

-- run the script ------------------------------------------------------------------
do
    FGcache = app.fgColor
    BGcache = app.bgColor
    lastColor = FGcache
    createDialog()
    calculateColors(app.fgColor)
    updateDialogData()
    fgListenerCode = app.events:on('fgcolorchange', onFgChange)
    bgListenerCode = app.events:on('bgcolorchange', onBgChange)
end
