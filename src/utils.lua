--[[
    Utility Functions
    Common helper functions used across the game
]]

local Config = require("src.config")

local Utils = {}

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.distance(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.normalize(x, y)
    local len = math.sqrt(x * x + y * y)
    if len > 0 then
        return x / len, y / len
    end
    return 0, 0
end

function Utils.getColorIndex(colorName)
    for i, name in ipairs(Config.COLOR_ORDER) do
        if name == colorName then return i end
    end
    return 1
end

function Utils.isPrimaryColor(color)
    return color == "red" or color == "yellow" or color == "blue"
end

function Utils.isSecondaryColor(color)
    return color == "purple" or color == "orange" or color == "green"
end

function Utils.getMixedColor(color1, color2)
    if Config.COLOR_MIX[color1] and Config.COLOR_MIX[color1][color2] then
        return Config.COLOR_MIX[color1][color2]
    end
    return nil
end

function Utils.colorsMatch(bulletColor, enemyColor)
    if bulletColor == enemyColor then return true end
    return false
end

function Utils.mixedBulletDamagesEnemy(bulletColor, enemyColor)
    if not Utils.isSecondaryColor(bulletColor) then return false end
    local parents = Config.COLOR_PARENTS[bulletColor]
    for _, parent in ipairs(parents) do
        if parent == enemyColor then return true end
    end
    return false
end

return Utils
