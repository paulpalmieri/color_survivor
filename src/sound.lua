--[[
    Sound System
    Audio playback with pooling for rapid-fire sounds
]]

local Sound = {}

-- Sound sources (single instances)
Sound.sources = {}

-- Sound pools for rapid-fire sounds (multiple clones)
Sound.pools = {}
Sound.poolIndex = {}

-- Pool size for frequently played sounds
local POOL_SIZE = 8

-- Color to fire sound mapping
local fireColorMap = {
    red = 1,
    yellow = 2,
    blue = 3,
}

-- Sound definitions
local soundDefs = {
    fire = {
        files = {
            "assets/sounds/player_fire_1.mp3",  -- red
            "assets/sounds/player_fire_2.mp3",  -- yellow
            "assets/sounds/player_fire_3.mp3",  -- blue
        },
        pooled = true,
        volume = 0.05,
        pitchVariation = 0.05,
    },
    hit = {
        files = { "assets/sounds/enemy_hit.mp3" },
        pooled = true,
        volume = 0.05,
        pitchVariation = 0.05,
    },
    death = {
        files = { "assets/sounds/enemy_death.mp3" },
        pooled = true,
        volume = 0.05,
        pitchVariation = 0.1,
    },
}

function Sound.init()
    for name, def in pairs(soundDefs) do
        if def.pooled then
            -- Create pools for each variant
            Sound.pools[name] = {}
            Sound.poolIndex[name] = {}

            for i, file in ipairs(def.files) do
                local source = love.audio.newSource(file, "static")
                source:setVolume(def.volume or 1)

                -- Create pool of clones
                local pool = {}
                for j = 1, POOL_SIZE do
                    pool[j] = source:clone()
                end

                Sound.pools[name][i] = pool
                Sound.poolIndex[name][i] = 1
            end
        else
            -- Single source for non-pooled sounds
            Sound.sources[name] = {}
            for i, file in ipairs(def.files) do
                local source = love.audio.newSource(file, "static")
                source:setVolume(def.volume or 1)
                Sound.sources[name][i] = source
            end
        end
    end
end

function Sound.play(name, options)
    options = options or {}
    local def = soundDefs[name]
    if not def then return end

    -- Determine which variant to use
    local variant
    if name == "fire" and options.color and fireColorMap[options.color] then
        -- Use color-mapped variant for fire sounds
        variant = fireColorMap[options.color]
    else
        -- Pick a random variant if multiple files
        local variantCount = #def.files
        variant = math.random(1, variantCount)
    end

    local source
    if def.pooled then
        -- Get from pool
        local pool = Sound.pools[name][variant]
        local index = Sound.poolIndex[name][variant]
        source = pool[index]

        -- Advance pool index
        Sound.poolIndex[name][variant] = (index % POOL_SIZE) + 1
    else
        source = Sound.sources[name][variant]
    end

    if not source then return end

    -- Stop if already playing (for pooled, this shouldn't happen often)
    source:stop()

    -- Apply pitch variation
    local pitchVar = def.pitchVariation or 0
    if pitchVar > 0 then
        local pitch = 1 + (math.random() - 0.5) * 2 * pitchVar
        source:setPitch(pitch)
    end

    -- Apply volume override
    local volume = options.volume or def.volume or 1
    source:setVolume(volume)

    source:play()
end

return Sound
