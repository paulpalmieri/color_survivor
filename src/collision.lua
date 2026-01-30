--[[
    Collision System
    Projectile-enemy collision detection and resolution
]]

local Config = require("src.config")
local Game = require("src.game")
local Utils = require("src.utils")
local Particles = require("src.particles")
local Sound = require("src.sound")

local Collision = {}

function Collision.check(spawnShard)
    for i = #Game.projectiles, 1, -1 do
        local p = Game.projectiles[i]
        if p.dying then goto continue end
        if p.piercing then goto continue end

        for j = #Game.enemies, 1, -1 do
            local e = Game.enemies[j]
            local dist = Utils.distance(p.x, p.y, e.x, e.y)
            local bulletRadius = p.baseRadius + (p.radiusWobble or 0)
            local enemyRadius = e.baseRadius + (e.radiusWobble or 0)

            if dist < bulletRadius + enemyRadius then
                local fullDamage = false
                local reducedDamage = false
                local pierceAndMix = false

                if p.color == e.color then
                    fullDamage = true
                elseif p.hasPierced then
                    p.dying = true
                    p.deathTimer = 0.1
                    e.pulseTimer = 0.15
                    e.pulseAmount = 2
                    Particles.spawnFizzle(p.x, p.y, p.color)
                    break
                elseif Utils.isPrimaryColor(p.color) and Utils.isPrimaryColor(e.color) then
                    pierceAndMix = true
                elseif Utils.isSecondaryColor(p.color) and p.color == e.color then
                    fullDamage = true
                elseif Utils.isSecondaryColor(p.color) and Utils.mixedBulletDamagesEnemy(p.color, e.color) then
                    reducedDamage = true
                elseif Utils.isSecondaryColor(p.color) and Utils.isPrimaryColor(e.color) then
                    p.dying = true
                    p.deathTimer = 0.1
                    e.pulseTimer = 0.15
                    e.pulseAmount = 2
                    Particles.spawnFizzle(p.x, p.y, p.color)
                    break
                elseif Utils.isPrimaryColor(p.color) and Utils.isSecondaryColor(e.color) then
                    pierceAndMix = true
                else
                    p.dying = true
                    p.deathTimer = 0.1
                    break
                end

                if fullDamage then
                    local dmg = Config.PROJECTILE_DAMAGE * Game.upgrades.damage
                    e.hp = e.hp - dmg

                    p.vx = p.vx * 0.95
                    p.vy = p.vy * 0.95

                    e.radiusOffset = -3
                    e.radiusRecovery = 0.1

                    Particles.spawnSplatter(p.x, p.y, e.color, 4)
                    if Game.showHitFX then
                        Particles.spawnPaintMixFX(p.x, p.y, p.color, e.color, p.vx, p.vy, "pierce")
                    end

                    if e.hp <= 0 then
                        Particles.spawnDeath(e.x, e.y, e.color, 8)
                        spawnShard(e.x, e.y)
                        Game.shakeScreen(1, 0.1)
                        Sound.play("death")
                        table.remove(Game.enemies, j)
                    else
                        Sound.play("hit")
                    end

                elseif reducedDamage then
                    local dmg = (Config.PROJECTILE_DAMAGE * Game.upgrades.damage) * 0.5
                    e.hp = e.hp - dmg

                    p.vx = p.vx * 0.9
                    p.vy = p.vy * 0.9

                    e.radiusOffset = -2
                    e.radiusRecovery = 0.1

                    Particles.spawnSplatter(p.x, p.y, e.color, 2)
                    if Game.showHitFX then
                        Particles.spawnPaintMixFX(p.x, p.y, p.color, e.color, p.vx, p.vy, "pierce")
                    end

                    if e.hp <= 0 then
                        Particles.spawnDeath(e.x, e.y, e.color, 8)
                        spawnShard(e.x, e.y)
                        Game.shakeScreen(1, 0.1)
                        Sound.play("death")
                        table.remove(Game.enemies, j)
                    else
                        Sound.play("hit")
                    end

                elseif pierceAndMix then
                    local newColor = nil
                    if Utils.isPrimaryColor(p.color) and Utils.isPrimaryColor(e.color) then
                        newColor = Utils.getMixedColor(p.color, e.color)
                    elseif Utils.isPrimaryColor(p.color) and Utils.isSecondaryColor(e.color) then
                        newColor = e.color
                    end

                    if newColor and not p.piercing then
                        p.piercing = true
                        p.piercingEnemy = e
                        p.originalColor = p.color
                        p.pendingColor = newColor

                        -- Take enemy's color while piercing
                        p.color = e.color
                        Particles.spawnSplatter(p.x, p.y, p.originalColor, 3)

                        p.vx = p.vx * 0.9
                        p.vy = p.vy * 0.9

                        e.pulseTimer = 0.15
                        e.pulseAmount = 1.5

                        if Game.showHitFX then
                            Particles.spawnPaintMixFX(p.x, p.y, p.originalColor, e.color, p.vx, p.vy, "mix")
                        end
                    end
                end
            end
        end
        ::continue::
    end
end

return Collision
