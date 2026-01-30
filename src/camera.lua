--[[
    Camera System
    Follow player, handle viewport
]]

local Config = require("src.config")
local Game = require("src.game")
local Utils = require("src.utils")

local Camera = {}

function Camera.update()
    local player = Game.player

    local targetX = player.x - Game.VIEWPORT_WIDTH / 2
    local targetY = player.y - Game.VIEWPORT_HEIGHT / 2

    targetX = math.max(0, math.min(Config.ARENA_WIDTH - Game.VIEWPORT_WIDTH, targetX))
    targetY = math.max(0, math.min(Config.ARENA_HEIGHT - Game.VIEWPORT_HEIGHT, targetY))

    Game.camera.x = Utils.lerp(Game.camera.x, targetX, 0.1)
    Game.camera.y = Utils.lerp(Game.camera.y, targetY, 0.1)
end

function Camera.init()
    local player = Game.player

    Game.camera.x = player.x - Game.VIEWPORT_WIDTH / 2
    Game.camera.y = player.y - Game.VIEWPORT_HEIGHT / 2
    Game.camera.x = math.max(0, math.min(Config.ARENA_WIDTH - Game.VIEWPORT_WIDTH, Game.camera.x))
    Game.camera.y = math.max(0, math.min(Config.ARENA_HEIGHT - Game.VIEWPORT_HEIGHT, Game.camera.y))
end

return Camera
