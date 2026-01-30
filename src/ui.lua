--[[
    UI System
    HUD, level-up screen, death screen, color wheel
]]

local Config = require("src.config")
local Game = require("src.game")
local Utils = require("src.utils")
local Rendering = require("src.rendering")

local UI = {}

-- Base font sizes (at 1080p reference)
UI.BASE_FONT_SMALL = 32
UI.BASE_FONT_MEDIUM = 48
UI.BASE_FONT_LARGE = 96

-- Fonts (recreated on resize)
UI.font = nil
UI.fontSmall = nil
UI.fontLarge = nil
UI.currentScale = 1

-- Upgrade definitions
UI.UPGRADE_DEFS = {
    {id = "fireRate", name = "Rapid Fire", desc = "+25% fire rate"},
    {id = "moveSpeed", name = "Swift Feet", desc = "+20% move speed"},
    {id = "damage", name = "Power Shot", desc = "+30% damage"},
    {id = "projectileCount", name = "Multi Shot", desc = "+1 projectile"},
    {id = "cooldownReduction", name = "Quick Change", desc = "-15% color cooldown"},
    {id = "maxHp", name = "Vitality", desc = "+25 max HP (heals)"}
}

-- Recreate fonts at current scale
function UI.updateScale()
    local winH = love.graphics.getHeight()
    local uiScale = math.max(winH / 1080, 0.5)

    -- Only recreate if scale changed significantly
    if math.abs(uiScale - UI.currentScale) < 0.01 then return end
    UI.currentScale = uiScale

    local sizeSmall = math.floor(UI.BASE_FONT_SMALL * uiScale)
    local sizeMedium = math.floor(UI.BASE_FONT_MEDIUM * uiScale)
    local sizeLarge = math.floor(UI.BASE_FONT_LARGE * uiScale)

    UI.fontSmall = love.graphics.newFont("m5x7.ttf", sizeSmall)
    UI.fontSmall:setFilter("linear", "linear")
    UI.font = love.graphics.newFont("m5x7.ttf", sizeMedium)
    UI.font:setFilter("linear", "linear")
    UI.fontLarge = love.graphics.newFont("m5x7.ttf", sizeLarge)
    UI.fontLarge:setFilter("linear", "linear")
    love.graphics.setFont(UI.font)
end

function UI.init()
    UI.currentScale = 0  -- Force initial creation
    UI.updateScale()
end

function UI.triggerLevelUp()
    Game.state = "levelup"
    Game.levelUpChoices = {}

    local available = {}
    for i, u in ipairs(UI.UPGRADE_DEFS) do
        table.insert(available, i)
    end

    for i = 1, 3 do
        local idx = math.random(#available)
        table.insert(Game.levelUpChoices, UI.UPGRADE_DEFS[available[idx]])
        table.remove(available, idx)
    end
end

function UI.applyUpgrade(choice)
    local id = choice.id
    if id == "fireRate" then
        Game.upgrades.fireRate = Game.upgrades.fireRate + 0.25
    elseif id == "moveSpeed" then
        Game.upgrades.moveSpeed = Game.upgrades.moveSpeed + 0.2
    elseif id == "damage" then
        Game.upgrades.damage = Game.upgrades.damage + 0.3
    elseif id == "projectileCount" then
        Game.upgrades.projectileCount = Game.upgrades.projectileCount + 1
    elseif id == "cooldownReduction" then
        Game.upgrades.cooldownReduction = Game.upgrades.cooldownReduction + 1
    elseif id == "maxHp" then
        Game.upgrades.maxHp = Game.upgrades.maxHp + 25
        Game.player.maxHp = Config.PLAYER_MAX_HP + Game.upgrades.maxHp
        Game.player.hp = Game.player.maxHp
    end

    Game.state = "play"
end

local function drawBlobShape(x, y, radius, intensity)
    Rendering.drawSoftCircle(x, y, radius, intensity)
end

local function drawColorWheel(screenX, screenY, uiScale)
    local cw = Config.COLOR_WHEEL
    local cwScale = Rendering.colorWheelScale or 1
    local canvasSize = math.ceil(cw.canvasSize * cwScale)
    local canvasCenter = canvasSize / 2

    -- Scale blob and orbit radius with canvas scale
    local blobRadius = cw.blobRadius * cwScale
    local orbitRadius = cw.orbitRadius * cwScale
    local wobbleTime = Game.colorWheelAnim.wobbleTime
    local wheelAngle = Game.colorWheelAnim.currentAngle

    local baseAngles = {
        red = -math.pi / 2,
        yellow = -math.pi / 2 + math.pi * 2/3,
        blue = -math.pi / 2 + math.pi * 4/3,
    }

    local currentColorIndex = Utils.getColorIndex(Game.player.color)
    local blobData = {}

    for i, colorName in ipairs(Config.COLOR_ORDER) do
        local baseAngle = baseAngles[colorName]
        local angle = baseAngle + wheelAngle
        local isCurrent = (i == currentColorIndex)

        local finalRadius = blobRadius
        if isCurrent then
            finalRadius = finalRadius * 1.15
        end

        blobData[colorName] = {
            x = canvasCenter + math.cos(angle) * orbitRadius,
            y = canvasCenter + math.sin(angle) * orbitRadius,
            radius = finalRadius,
            isCurrent = isCurrent,
        }
    end

    -- Draw color masks
    for _, colorName in ipairs(Config.COLOR_ORDER) do
        local blob = blobData[colorName]
        local mask = Rendering.colorWheelMasks[colorName]

        love.graphics.setCanvas(mask)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setBlendMode("add")

        local intensity = blob.isCurrent and 1.2 or 1.0
        drawBlobShape(blob.x, blob.y, blob.radius, intensity)

        love.graphics.setBlendMode("alpha")
        love.graphics.setCanvas()
    end

    -- Draw at 1:1 scale since canvas is already sized for uiScale
    local drawScale = 1
    local drawX = screenX - canvasCenter * drawScale
    local drawY = screenY - canvasCenter * drawScale

    local function drawBlobThresholded(mask, color)
        love.graphics.setShader(Rendering.thresholdShader)
        Rendering.thresholdShader:send("threshold", Config.BLOB_THRESHOLD)
        Rendering.thresholdShader:send("blobColor", color)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(mask, drawX, drawY, 0, drawScale, drawScale)
        love.graphics.setShader()
    end

    drawBlobThresholded(Rendering.colorWheelMasks.red, Config.COLORS.red)
    drawBlobThresholded(Rendering.colorWheelMasks.yellow, Config.COLORS.yellow)
    drawBlobThresholded(Rendering.colorWheelMasks.blue, Config.COLORS.blue)

    local secondaries = {
        {name = "purple", p1 = "red", p2 = "blue", color = Config.COLORS.purple},
        {name = "orange", p1 = "red", p2 = "yellow", color = Config.COLORS.orange},
        {name = "green", p1 = "yellow", p2 = "blue", color = Config.COLORS.green},
    }

    for _, sec in ipairs(secondaries) do
        love.graphics.stencil(function()
            love.graphics.setShader(Rendering.stencilShader)
            Rendering.stencilShader:send("threshold", Config.BLOB_THRESHOLD)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(Rendering.colorWheelMasks[sec.p1], drawX, drawY, 0, drawScale, drawScale)
            love.graphics.setShader()
        end, "replace", 1)

        love.graphics.setStencilTest("greater", 0)
        drawBlobThresholded(Rendering.colorWheelMasks[sec.p2], sec.color)
        love.graphics.setStencilTest()
    end

    love.graphics.stencil(function()
        love.graphics.setShader(Rendering.stencilShader)
        Rendering.stencilShader:send("threshold", Config.BLOB_THRESHOLD)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Rendering.colorWheelMasks.red, drawX, drawY, 0, drawScale, drawScale)
        love.graphics.setShader()
    end, "replace", 1)

    love.graphics.stencil(function()
        love.graphics.setShader(Rendering.stencilShader)
        Rendering.stencilShader:send("threshold", Config.BLOB_THRESHOLD)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Rendering.colorWheelMasks.yellow, drawX, drawY, 0, drawScale, drawScale)
        love.graphics.setShader()
    end, "increment", 1, true)

    love.graphics.stencil(function()
        love.graphics.setShader(Rendering.stencilShader)
        Rendering.stencilShader:send("threshold", Config.BLOB_THRESHOLD)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Rendering.colorWheelMasks.blue, drawX, drawY, 0, drawScale, drawScale)
        love.graphics.setShader()
    end, "increment", 1, true)

    love.graphics.setStencilTest("equal", 3)
    drawBlobThresholded(Rendering.colorWheelMasks.blue, {1, 1, 1})
    love.graphics.setStencilTest()
end

function UI.draw()
    local winW, winH = love.graphics.getDimensions()
    local uiScale = winH / 1080
    uiScale = math.max(uiScale, 0.5)

    local player = Game.player
    local c = Config.COLORS[player.color]
    local margin = 32 * uiScale

    -- HP + XP + Level
    love.graphics.setFont(UI.font)

    local hpBarX = margin
    local hpBarY = margin
    local hpBarW = 200 * uiScale
    local hpBarH = 28 * uiScale

    love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
    love.graphics.rectangle("fill", hpBarX, hpBarY, hpBarW, hpBarH, 4 * uiScale)

    local hpRatio = player.hp / player.maxHp
    love.graphics.setColor(c[1], c[2], c[3], 0.95)
    love.graphics.rectangle("fill", hpBarX, hpBarY, hpBarW * hpRatio, hpBarH, 4 * uiScale)

    love.graphics.setFont(UI.fontSmall)
    love.graphics.setColor(1, 1, 1, 1)
    local hpText = math.floor(player.hp) .. "/" .. math.floor(player.maxHp)
    local hpTextY = hpBarY + (hpBarH - UI.fontSmall:getHeight()) / 2
    love.graphics.print(hpText, hpBarX + 8 * uiScale, hpTextY)

    local xpBarY = hpBarY + hpBarH + 6 * uiScale
    local xpBarH = 12 * uiScale

    love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
    love.graphics.rectangle("fill", hpBarX, xpBarY, hpBarW, xpBarH, 3 * uiScale)

    love.graphics.setColor(0.9, 0.85, 0.4, 0.95)
    love.graphics.rectangle("fill", hpBarX, xpBarY, hpBarW * (player.xp / player.xpToLevel), xpBarH, 3 * uiScale)

    love.graphics.setFont(UI.font)
    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    love.graphics.print("Lv" .. player.level, hpBarX + hpBarW + 12 * uiScale, hpBarY + 2 * uiScale)

    -- Wave Timer
    local mins = math.floor(Game.waveTime / 60)
    local secs = math.floor(Game.waveTime % 60)
    local timeStr = string.format("%d:%02d", mins, secs)
    love.graphics.setFont(UI.font)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.printf(timeStr, 0, margin, winW, "center")

    -- Dash indicators (bottom-right)
    local dashBarW = 36 * uiScale
    local dashBarH = 10 * uiScale
    local dashGap = 5 * uiScale
    local dashTotalW = Config.DASH_MAX_CHARGES * dashBarW + (Config.DASH_MAX_CHARGES - 1) * dashGap

    -- Color Wheel + Dash (bottom-right position, wheel closer to dash)
    local cwScale = Rendering.colorWheelScale or uiScale
    local wheelRadius = Config.COLOR_WHEEL.canvasSize * cwScale / 2
    local wheelCenterX = winW - margin - wheelRadius

    -- Position dash at bottom, wheel just above it
    local dashY = winH - margin - dashBarH
    local wheelCenterY = dashY - wheelRadius + 12 * uiScale  -- Overlap slightly to reduce visual gap
    local dashStartX = wheelCenterX - dashTotalW / 2

    drawColorWheel(wheelCenterX, wheelCenterY, uiScale)

    for i = 1, Config.DASH_MAX_CHARGES do
        local bx = dashStartX + (i - 1) * (dashBarW + dashGap)

        love.graphics.setColor(0.4, 0.4, 0.4, 0.4)
        love.graphics.rectangle("fill", bx, dashY, dashBarW, dashBarH, 3 * uiScale)

        if i <= player.dashCharges then
            love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
            love.graphics.rectangle("fill", bx, dashY, dashBarW, dashBarH, 3 * uiScale)
        elseif i == player.dashCharges + 1 and player.dashRechargeTimer > 0 then
            local progress = 1 - (player.dashRechargeTimer / Config.DASH_CHARGE_COOLDOWN)
            love.graphics.setColor(0.35, 0.35, 0.35, 0.8)
            love.graphics.rectangle("fill", bx, dashY, dashBarW * progress, dashBarH, 3 * uiScale)
        end
    end

    if player.colorCooldown > 0 then
        local maxCooldown = Config.COLOR_SWITCH_COOLDOWN * (1 - Game.upgrades.cooldownReduction * 0.15)
        local progress = 1 - (player.colorCooldown / maxCooldown)

        local cdY = dashY + dashBarH + 8 * uiScale
        local cdBarW = dashTotalW
        local cdBarH = 6 * uiScale

        love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        love.graphics.rectangle("fill", dashStartX, cdY, cdBarW, cdBarH, 2 * uiScale)

        love.graphics.setColor(c[1], c[2], c[3], 0.8)
        love.graphics.rectangle("fill", dashStartX, cdY, cdBarW * progress, cdBarH, 2 * uiScale)
    end

    love.graphics.setFont(UI.font)
end

function UI.drawLevelUpScreen()
    local winW, winH = love.graphics.getDimensions()
    local uiScale = winH / 1080
    uiScale = math.max(uiScale, 0.5)

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, winW, winH)

    -- "LEVEL UP!" title with dynamic positioning
    love.graphics.setFont(UI.fontLarge)
    local titleHeight = UI.fontLarge:getHeight()
    local titleY = 120 * uiScale
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("LEVEL UP!", 0, titleY, winW, "center")

    -- "Choose an upgrade:" with proper spacing from title
    love.graphics.setFont(UI.font)
    local subtitleHeight = UI.font:getHeight()
    local subtitleY = titleY + titleHeight + 20 * uiScale
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Choose an upgrade:", 0, subtitleY, winW, "center")

    -- Buttons start after subtitle with proper spacing
    local buttonStartY = subtitleY + subtitleHeight + 40 * uiScale
    local buttonW = 600 * uiScale
    local buttonH = 120 * uiScale
    local buttonGap = 20 * uiScale
    local buttonX = winW / 2 - buttonW / 2

    for i, choice in ipairs(Game.levelUpChoices) do
        local y = buttonStartY + (i - 1) * (buttonH + buttonGap)
        local mx, my = love.mouse.getPosition()
        local hover = mx > buttonX and mx < buttonX + buttonW and my > y and my < y + buttonH

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", buttonX - 4 * uiScale, y - 4 * uiScale, buttonW + 8 * uiScale, buttonH + 8 * uiScale)

        if hover then
            love.graphics.setColor(0.85, 0.85, 0.85, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.rectangle("fill", buttonX, y, buttonW, buttonH)

        -- Center text vertically within button
        love.graphics.setFont(UI.font)
        local nameHeight = UI.font:getHeight()
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(i .. ". " .. choice.name, buttonX, y + 20 * uiScale, buttonW, "center")

        love.graphics.setFont(UI.fontSmall)
        local descHeight = UI.fontSmall:getHeight()
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.printf(choice.desc, buttonX, y + 20 * uiScale + nameHeight + 8 * uiScale, buttonW, "center")
    end
    love.graphics.setFont(UI.font)
end

function UI.drawDeathScreen()
    local winW, winH = love.graphics.getDimensions()
    local uiScale = winH / 1080

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, winW, winH)

    love.graphics.setFont(UI.fontLarge)
    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.printf("GAME OVER", 0, 360 * uiScale, winW, "center")

    love.graphics.setFont(UI.font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Level " .. Game.player.level, 0, 520 * uiScale, winW, "center")
    love.graphics.printf("Survived " .. math.floor(Game.waveTime) .. "s", 0, 580 * uiScale, winW, "center")

    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Press R to Restart", 0, 740 * uiScale, winW, "center")
end

function UI.handleLevelUpClick(x, y)
    local winW, winH = love.graphics.getDimensions()
    local uiScale = math.max(winH / 1080, 0.5)

    -- Match button positioning from drawLevelUpScreen
    local titleY = 120 * uiScale
    local titleHeight = UI.fontLarge:getHeight()
    local subtitleY = titleY + titleHeight + 20 * uiScale
    local subtitleHeight = UI.font:getHeight()
    local buttonStartY = subtitleY + subtitleHeight + 40 * uiScale

    local buttonW = 600 * uiScale
    local buttonH = 120 * uiScale
    local buttonGap = 20 * uiScale
    local buttonX = winW / 2 - buttonW / 2

    for i, choice in ipairs(Game.levelUpChoices) do
        local cy = buttonStartY + (i - 1) * (buttonH + buttonGap)
        if x > buttonX and x < buttonX + buttonW and y > cy and y < cy + buttonH then
            UI.applyUpgrade(choice)
            return true
        end
    end
    return false
end

return UI
