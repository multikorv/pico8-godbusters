pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- functions
function debug_print(text, pos_x, pos_y, color)
    print (text, camera_pos.x + pos_x, camera_pos.y + pos_y, color)
end

function lerp(a, b, t)
    local result = a + t * (b - a)
    return result
end

function text_hcenter(s)
    return 64-#s*2
end

function text_vcenter(s)
    return 61
end

-->8
-- structs, classes etc

-- vector class
vec = {
    x = 0,
    y = 0,
    z = 0,
    length = function(self)
        return sqrt(self.x^2 + self.y^2 + self.z^2)
    end,
    normalize = function(self)
        local len = self:length()
        if len == 0 then
            return vec:new()
        end
        return vec:new({x = self.x / len, y = self.y / len, z = self.z / len})
    end
}
vec.__index = vec

function vec:new(o)
    return setmetatable(o or {}, self)
end

vec.__sub = function(a, b)
    return vec:new({
        x = a.x - b.x,
        y = a.y - b.y
    })
end

vec.__add = function(a, b)
    return vec:new({
        x = a.x + b.x,
        y = a.y + b.y
    })
end

-- Defined as element-wise multiplication
vec.__mul = function(a, b)
    return vec:new({
        x = a.x * b.x,
        y = a.y * b.y
    })
end

vec.__eq = function(a, b)
    return a.x == b.x and a.y == b.y
end

-- TODO: Move to toolbox
box = {
    position = vec:new(),
    height = 1,
    width = 1,
    intersects = function(self, other)
        self_x_min = self.position.x
        self_x_max = self.position.x + self.width
        self_y_min = self.position.y
        self_y_max = self.position.y + self.height
        other_x_min = other.position.x
        other_x_max = other.position.x + other.width
        other_y_min = other.position.y
        other_y_max = other.position.y + other.width
        return self_x_max >= other_x_min and 
               other_x_max >= self_x_min and
               self_y_max >= other_y_min and 
               other_y_max >= self_y_min
    end,
    draw = function(self)
        rect(self.position.x, self.position.y, self.position.x + self.width, self.position.y + self.height, 7)
    end
}
box.__index = box

function box:new(o)
    return setmetatable(o or {}, self)
end

game_camera = {
    predefined_shake_magnitude = { small = 1, medium = 2, large = 5, extreme = 10 },
    position = vec:new(),
    offset = vec:new(),
    x_offset = 0,
    y_offset = 0,
    -- follow_target: { position: vec, velocity: vec }
    follow_target = nil,
    shake_duration_seconds = 0,
    current_shake_magnitude = 0,
    update = function(self)
        if self.follow_target != nil then
            if self.follow_target.velocity.y <= 0 then
                self.position.y = lerp(self.position.y, self.follow_target.position.y - 80, 0.05)
            else
                self.position.y = lerp(self.position.y, self.follow_target.position.y - 60, 0.25)
            end
        end

        if self.shake_duration_seconds > 0 then
            local duration_left_seconds = max(0, self.shake_duration_seconds - dt)

            self.offset.x = rnd({-1, -0.5, 0, 0.5, 1}) * (self.current_shake_magnitude / 10)
            self.offset.y = rnd({-1, -0.5, 0, 0.5, 1}) * (self.current_shake_magnitude / 10)

            self.current_shake_magnitude *= (duration_left_seconds / self.shake_duration_seconds)
            self.shake_duration_seconds = duration_left_seconds
        else 
            self.offset.x = 0
            self.offset.y = 0
        end
    end,
    draw = function(self)
        camera(self.position.x + self.offset.x, self.position.y + self.offset.y)
        --self.debug_draw();
    end,
    debug_draw = function(self)
    end,
    shake = function(self, magnitude)
        -- magnitude: predefined_shake_magnitude {...}
        self.shake_duration_seconds = 0.2
        self.current_shake_magnitude = magnitude
    end
}

particle_system = {
    particles = {},
    update = function(self) 
    end,
    draw = function(self)
        for particle in all(self.particles) do
            local particle_color = 8

            -- TODO: Update to handle different kinds, i.e blood drops, explosion, sprite based etc
            --if particle.red then
            --    particle_color = self.map_red(particle.age)
            --else
            --    particle_color = self.map_red(particle.age)
            --end

            if particle.spark then
                pset(particle.position.x, particle.position.y, particle_color)
            else
                circfill(particle.position.x, particle.position.y, particle.size, particle_color)
            end

            particle.position.x = particle.position.x + (particle.velocity.x * dt)
            particle.position.y = particle.position.y + (particle.velocity.y * dt)

            if particle.gravity then
                particle.velocity = particle.velocity + particle.vgravity
            end
            --particle.velocity.x *= 0.85-- /(1 - dt)
            --particle.velocity.y *= 0.85-- /(1 - dt)

            particle.age += 1 * dt

            if particle.age > particle.max_age then
                particle.size -= 0.5
                if particle.size < 0 then
                    del(self.particles, particle)
                end
            end
        end
        --self:debug_draw()
    end,
    debug_draw = function(self)
        debug_print("num particles:"..#self.particles, 0, 16, 7)
        for particle in all(self.particles) do
            debug_print("particle[0]: age:"..particle.age..", x:"..particle.position.x..", y:"..particle.position.y, 0, 24, 7)
            break
        end
    end,
    blood_splatter = function(self, position)
        for i=0,10 do
            local particle = {}
            particle.position = vec:new({ x = position.x + (rnd(4) - 2), y = position.y + (rnd(4) - 2) })
            -- TODO: do not hardcode random direction, base it on hit vector
            particle.velocity = vec:new({ x = rnd() * 10 - 5, y = rnd() * 10 - 5 })

            particle.age = rnd(0.3)
            particle.size = 2 + rnd(1)
            particle.max_age = 0.5 + rnd(0.5)
            particle.spark = true
            particle.red = true
            particle.gravity = false

            add(self.particles, particle)
        end
    end,
    map_blue = function(age) 
        local color = 7
 
        if age > 1.5 then
            color = 6
        elseif age > 1.2 then
            color = 12
        elseif age > 1.0 then
            color = 13
        elseif age > 0.7 then
            color = 1
        elseif age > .5 then
            color = 1
        end

        return color 
    end,
    map_red = function(age) 
        local color = 7
 
        if age > 1.5 then
            color = 5
        elseif age > 1.2 then
            color = 2
        elseif age > 1.0 then
            color = 8
        elseif age > 0.7 then
            color = 10
        elseif age > 0.5 then
            color = 9
        end

        return color 
    end,
}
-->8
-- core statics
dt = 0
previous_time = 0

camera_pos = vec:new()

input_cooldown = 0

-->8

action_states = {
    walking = "walking",
    attacking = "attacking",
    dashing = "dashing"
}

direction_states = {
    left = "walking",
    right = "right",
    up = "up",
    down = "down"
}

player = {
    position = vec:new(),
    velocity = vec:new(),
    acceleration = {
        left = vec:new({x = -0.04}),
        right = vec:new({x = 0.04}),
        up = vec:new({y = -0.04}),
        down = vec:new({y = 0.04})
    },
    deceleration = {
        left = vec:new({x = 0.08}),
        right = vec:new({x = -0.08}),
        up = vec:new({y = 0.08}),
        down = vec:new({y = -0.08})
    },
    walking_speed = 1,
    dashing_speed = 4,
    hitbox = box:new({position = vec:new(), width = 7, height = 12}),
    weapon_hitbox = box:new({position = vec:new(), width = 16, height = 16}),
    dash_speed = 5,
    num_dashes = 3,
    max_dashes = 3,
    dash_recharge_cooldown_seconds = 0,
    dash_recharge_speed_seconds = 2,
    state = action_states.walking,
    direction = direction_states.up,
    time_left_in_state = 0,
    health = 2000,
    max_health = 2000,
    is_alive = true,
    -- TODO: This needs to support animation etc, temp
    update = function(self)
        self:update_recharges()
        self:update_input()

        local direction = self.direction
        local weight = 0
 
        if self.velocity.x > 0 then
            direction = direction_states.right
            weight = abs(self.velocity.x)
        elseif self.velocity.x < 0 then
            direction = direction_states.left
            weight = abs(self.velocity.x)
        end

        if abs(self.velocity.y) > weight then
            if self.velocity.y > 0 then
                direction = direction_states.down
                weight = abs(self.velocity.y)
            elseif self.velocity.y < 0 then
                direction = direction_states.up
                weight = abs(self.velocity.y)
            end
        end

        -- Clamp at max speed but keep at lower length to enable changing direction
        -- without the length check it always snaps back, making it impossible to change direction
        if self.velocity:length() > 1 then
            self.velocity = self.velocity:normalize()
        end
        if self.state == action_states.dashing then
            self.velocity = self.velocity * vec:new({
                x = self.dashing_speed, 
                y = self.dashing_speed, 
                z = self.dashing_speed
            })
        else
            self.velocity = self.velocity * vec:new({
                x = self.walking_speed, 
                y = self.walking_speed, 
                z = self.walking_speed
            })
        end


        self.direction = direction
        self.position = self.position + self.velocity

        self:clamp_to_edge_of_map()

        self:update_hitboxes()
    end,
    update_recharges = function(self)
        if self.num_dashes >= self.max_dashes then return end

        self.dash_recharge_cooldown_seconds = max(0, self.dash_recharge_cooldown_seconds - dt)
        if self.dash_recharge_cooldown_seconds == 0 then
            self.num_dashes = self.num_dashes + 1
            if self.num_dashes < self.max_dashes then
                self.dash_recharge_cooldown_seconds = self.dash_recharge_speed_seconds;
            end
        end
    end,
    update_input = function(self)
        -- ****** MOVEMENT ******
        local desire_horizontal_movement = false
        if btn(0) then
            desire_horizontal_movement = true
            self.velocity = self.velocity + self.acceleration.left
        elseif self.velocity.x < 0 then 
            self.velocity = self.velocity + self.deceleration.left
        end

        if btn(1) then
            desire_horizontal_movement = true
            self.velocity = self.velocity + self.acceleration.right
        elseif self.velocity.x > 0 then 
            self.velocity = self.velocity + self.deceleration.right
        end

        -- TODO: This is not good if we want different decelleration on the same axis
        -- could be reworked with just a decelleration that works in any direction, 
        -- using vector here just for convenience 
        if not desire_horizontal_movement then
            if abs(self.velocity.x) < abs(self.deceleration.left.x) then
                self.velocity.x = 0
            end
        end

        local desire_vertical_movement = false
        if btn(2) then
            desire_vertical_movement = true
            self.velocity = self.velocity + self.acceleration.up
        elseif self.velocity.y < 0 then 
            self.velocity = self.velocity + self.deceleration.up
        end

        if btn(3) then
            desire_vertical_movement = true
            self.velocity = self.velocity + self.acceleration.down
        elseif self.velocity.y > 0 then 
            self.velocity = self.velocity + self.deceleration.down
        end

        -- TODO: This is not good if we want different decelleration on the same axis
        -- could be reworked with just a decelleration that works in any direction, 
        -- using vector here just for convenience 
        if not desire_vertical_movement then
            if abs(self.velocity.y) < abs(self.deceleration.up.y) then
                self.velocity.y = 0
            end
        end

        -- ****** STATE ******
        if self.time_left_in_state == 0 then
            if self.state != action_states.walking then
                if self.state == action_states.dashing then
                    self.velocity = self.velocity * vec:new({x = 1/self.dash_speed, y = 1/self.dash_speed, z = 1/self.dash_speed})
                end
                self.state = action_states.walking
            elseif btnp(5) and self.num_dashes > 0 then
                self.state = action_states.dashing
                self.time_left_in_state = 0.1;
                self.num_dashes = self.num_dashes - 1
                self.dash_recharge_cooldown_seconds = self.dash_recharge_speed_seconds
                self.velocity = self.velocity * vec:new({x = self.dash_speed, y = self.dash_speed, z = self.dash_speed})
            elseif btnp(4) then
                self.state = action_states.attacking
                self.time_left_in_state = 0.2;
                if (self.weapon_hitbox:intersects(boss.hitbox)) then
                    boss.health = mid(0, boss.health - 100, boss.max_health)
                    if boss.health == 0 then
                        boss.is_alive = false
                        input_cooldown = 1
                    end

                    game_camera:shake(game_camera.predefined_shake_magnitude.small)
                    particle_system:blood_splatter(vec:new({
                        x = boss.position.x + 8,
                        y = boss.position.y + 8,
                        z = 0
                    }))
                    sfx(60)
                end
            end
        else
            self.time_left_in_state = max(0, self.time_left_in_state - dt)
        end
    end,
    update_hitboxes = function(self)
        self.hitbox.position.x = self.position.x + 4
        self.hitbox.position.y = self.position.y + 3

        local weapon_x_offset = 0
        local weapon_y_offset = 0
        if self.direction == direction_states.up then
            weapon_x_offset = -1
            weapon_y_offset = -4
        elseif self.direction == direction_states.down then
            weapon_x_offset = -1
            weapon_y_offset = 7
        elseif self.direction == direction_states.left then
            weapon_x_offset = -5
            weapon_y_offset = 0 
        elseif self.direction == direction_states.right then
            weapon_x_offset = 5
            weapon_y_offset = 0
        end
        self.weapon_hitbox.position.x = self.position.x + weapon_x_offset
        self.weapon_hitbox.position.y = self.position.y + weapon_y_offset
    end,
    clamp_to_edge_of_map = function(self)
        -- Avoid moving outside of the screen
        local offset_endpoint = 128 - 16
        if self.position.x <= 0 then
            self.position.x = 0
        elseif self.position.x >= offset_endpoint then
            self.position.x = offset_endpoint
        end

        if self.position.y <= 0 then
            self.position.y = 0
        elseif self.position.y >= offset_endpoint then
            self.position.y = offset_endpoint
        end

    end,
    draw = function(self)
        if self.state == action_states.attacking then
            local attack_sprite_idx
            if self.direction == direction_states.up then
                attack_sprite_idx = 98
            elseif self.direction == direction_states.down then
                attack_sprite_idx = 66
            elseif self.direction == direction_states.left then
                -- TODO: Temp sprite
                attack_sprite_idx = 100
            elseif self.direction == direction_states.right then
                -- TODO: Temp sprite
                attack_sprite_idx = 68
            end

            spr(attack_sprite_idx, self.position.x, self.position.y, 2, 2)

            -- Slash sprite
            local slash_offset = 3
            if self.direction == direction_states.up then
                spr(32, self.position.x, self.position.y - slash_offset, 2, 2)
            elseif self.direction == direction_states.down then
                spr(32, self.position.x, self.position.y + slash_offset + 4, 2, 2, false, true) 
            elseif self.direction == direction_states.left then
                spr(34, self.position.x - slash_offset, self.position.y, 2, 2) 
            elseif self.direction == direction_states.right then
                spr(34, self.position.x + slash_offset, self.position.y, 2, 2, true) 
            end
        else
            local walk_sprite_idx
            if self.direction == direction_states.up then
                walk_sprite_idx = 96
            elseif self.direction == direction_states.down then
                walk_sprite_idx = 64
            elseif self.direction == direction_states.left then
                walk_sprite_idx = 100
            elseif self.direction == direction_states.right then
                walk_sprite_idx = 68
            end
            spr(walk_sprite_idx, self.position.x, self.position.y, 2, 2)
            --print (self.direction)
        end
        --print (self.state)
        --print (self.health)
        --self.hitbox:draw()
        --self.weapon_hitbox:draw()
    end,
}

boss = {
    position = vec:new({x = 64, y = 64}),
    velocity = vec:new(),
    acceleration = {
        left = vec:new({x = -0.04}),
        right = vec:new({x = 0.04}),
        up = vec:new({y = -0.04}),
        down = vec:new({y = 0.04})
    },
    deceleration = {
        left = vec:new({x = 0.08}),
        right = vec:new({x = -0.08}),
        up = vec:new({y = 0.08}),
        down = vec:new({y = -0.08})
    },
    hitbox = box:new({position = vec:new(), width = 15, height = 15}),
    weapon_hitbox = box:new({position = vec:new(), width = 12, height = 12}),
    state = action_states.walking,
    direction = direction_states.up,
    time_left_in_state = 0,
    health = 2000,
    max_health = 2000,
    is_alive = true,
    -- TODO: This needs to support animation etc, temp
    update = function(self)

        local direction_to_player = (player.position - self.position):normalize()

        self.velocity = direction_to_player * vec:new({x = 0.4, y = 0.4, z = 0.4})
        self.position = self.position + self.velocity
        self:update_hitboxes()

        if self.hitbox:intersects(player.hitbox) then
            player.health = mid(0, player.health - 60, player.max_health)
            if player.health == 0 then
                player.is_alive = false
                input_cooldown = 1
            end
            game_camera:shake(game_camera.predefined_shake_magnitude.medium)
            player.velocity = direction_to_player

            sfx(61)
        end
    end,
    update_hitboxes = function(self)
        self.hitbox.position = self.position

        weapon_x_offset = 0
        weapon_y_offset = 0
        if self.direction == direction_states.up then
            weapon_x_offset = 8
            weapon_y_offset = -8
        elseif self.direction == direction_states.down then
            weapon_x_offset = 8
            weapon_y_offset = 16
        elseif self.direction == direction_states.left then
            weapon_x_offset = -8
            weapon_y_offset = 8
        elseif self.direction == direction_states.right then
            weapon_x_offset = 16
            weapon_y_offset = 8
        end
        self.weapon_hitbox.position.x = self.position.x + weapon_x_offset
        self.weapon_hitbox.position.y = self.position.y + weapon_y_offset
    end,
    draw = function(self)
        local walk_sprite_idx
        if self.direction == direction_states.up then
            walk_sprite_idx = 72
        elseif self.direction == direction_states.down then
            walk_sprite_idx = 72
        elseif self.direction == direction_states.left then
            walk_sprite_idx = 72
        elseif self.direction == direction_states.right then
            walk_sprite_idx = 72
        end
        spr(walk_sprite_idx, self.position.x, self.position.y, 2, 2)
        --self.hitbox:draw()
        --print (self.health)
        --self.weapon_hitbox:draw()
    end,
}
-- game
function init()
    music(0)

    input_cooldown = 0

    player.is_alive = true
    player.position = vec:new({x = 56, y = 100, z = 0})
    player.health = player.max_health
    
    boss.is_alive = true
    boss.position = vec:new({x = 56, y = 15, z = 0})
    boss.health = boss.max_health

    -- Remove repeating buttons with btnp
    poke(0x5f5c, 255)
end

function update()
    game_camera:update()
    particle_system:update()
    if boss.is_alive and player.is_alive then
        player:update()
        boss:update()
    else
        if input_cooldown == 0 then
            if btn(4) or btn(5) then 
                init()
            end
        else
            input_cooldown = max(input_cooldown - dt, 0)
        end
    end
end

function draw()
    game_camera:draw()
    map(0, 0, 0, 0, 16, 16)
    if not boss.is_alive or not player.is_alive then
        local cycle_ends_text = "the cycle ends"
        print(cycle_ends_text, text_hcenter(cycle_ends_text), 60, 7)
        if player.is_alive then 
            local win_text = "MARIX HAS BEEN BROKEN"
            print(win_text, text_hcenter(win_text), 65, 6)
        else 
            local lose_text = "BUT THE FIGHT IS NOT OVER"
            print(lose_text, text_hcenter(lose_text), 65, 6) 
        end
    else
        player:draw()
        boss:draw()
    end
    particle_system:draw()
    draw_ui()
end

function draw_ui()
    -- Boss
    local boss_name = "MARIX"
    print (boss_name, text_hcenter(boss_name), 24, 7)

    -- Boss health
    local boss_health_left_ratio = boss.health / boss.max_health

    local boss_bar_y = 32
    local boss_bar_thickness = 2

    rectfill(
        12, 
        boss_bar_y,  
        114, 
        boss_bar_y - boss_bar_thickness, 7
    )
    rectfill(
        12, 
        boss_bar_y, 
        16 + ceil(98 * boss_health_left_ratio), 
        boss_bar_y - boss_bar_thickness, 8
    )
    rect(
        12, 
        boss_bar_y, 
        114, 
        boss_bar_y - boss_bar_thickness, 0
    )

    -- Player 
    -- Player Health
    local player_health_left_ratio = player.health / player.max_health

    local player_bar_y = 126
    local player_bar_thickness = 4
    rectfill(
        3 + game_camera.position.x, 
        player_bar_y + game_camera.position.y, 
        48 + game_camera.position.x, 
        player_bar_y - player_bar_thickness + game_camera.position.y, 7
    )
    rectfill(
        3 + game_camera.position.x, 
        player_bar_y + game_camera.position.y, 
        3 + ceil(45 * player_health_left_ratio) + game_camera.position.x, 
        player_bar_y - player_bar_thickness + game_camera.position.y, 11
    )
    rect(
        3 + game_camera.position.x, 
        player_bar_y + game_camera.position.y, 
        48 + game_camera.position.x, 
        player_bar_y - player_bar_thickness + game_camera.position.y, 0
    )

    -- Player Stamina
    local num_dashes_left = player.num_dashes
    local stamina_x_pos = 54
    local stamina_y_pos = 124
    local stamina_padding = 6
    for i = 0, player.max_dashes - 1, 1 do
        circfill(stamina_x_pos + (i * stamina_padding), stamina_y_pos, 2, 0)
        if num_dashes_left > 0 then
            circfill(stamina_x_pos + (i * stamina_padding), stamina_y_pos, 1, 7)
            num_dashes_left = num_dashes_left - 1
        end
    end
end

-->8
-- update loops

function _init()
    -- init need to be defined
    init()
end

function _update60()
    update_time()
    -- update need to be defined
    update()
end

function _draw()
    cls()
    -- draw need to be defined
    draw()
    --mouse:draw()
end

function update_time()
    local time = time()
    dt = time - previous_time
    previous_time = time
end

__gfx__
00000000000000000000000000000000000000000000000011111111111111111111111111111111899999988999999811111111189999988999998111111111
000000000000000000000000000000000000000000000000111111111c1111111111111111111111899aaa98899999881d111d11899999988999999811111111
0070070000000000000000000000000000000000000000001101011111111111111111111111111188899a988999aaa811111118999999988999999a81115111
000770000000000000000000000000000000000000000000111051111111111111110111111111118889aa988999a998111111899999999889999999a8111111
000770000000000000000000000000000000000000000000110101111111111111111081111111118999a9981899a9981111189999998888888899999a811111
007007000000000000000000000000000000000000000000105111111111111111111001116011118a99a9981899a998101189999988a8888888889999981111
000000000000000000000000000000000000000000000000111111111111111111111110110011118a99a998189aa988111899999888aa88aaaaa88999998111
000000000000000000000000000000000000000000000000111111111111111111111118160511118a999998899a99981189999888888a88a988a88889999811
0000000000000000000000000000000000000000000000001111111111111100111111111001111189aa99988999aaa818999998aaaa8888a988aaaa89999981
00000000000000000000000000000000000000000000000011111111111110011111111110511111888a99988999a9988999998a988aa888a988a888a8999998
00000000000000000000000000000000000000000000000011111111111100111111111111111111888a99988999a888999998aa8888a98aa88aa888a9899999
000000000000000000000000000000000000000000000000111111111111111111101111111111118889999889999888a999988a9888aaaaa88a8888a9899999
000000000000000000000000000000000000000000000000111111111111111111108111111111118889aa9818aaa888999988aa88888888888a8888a9889999
0000000000000000000000000000000000000000000000001111111111111111111000111111111189a9998889a99998999988a888888888888a888aaaa89999
0000000000000000000000000000000000000000000000001111111111111111111180811111111189a99981899a99989999888888888888888a888888a89999
0000000000000000000000000000000000000000000000001111111111111111111111111111111189999981899a999888888888888888888888888888888888
000000000100000000000000000000000000000000000000888888888888888888888888888888888aaa99988a9999a888888888888888888a98888888a88888
000001111c11000000000011100000000000000000000000988999888899998999889998998889988999aaa88a9999a899998988888888888a9888aaaaa89999
00001ccccccc1000000111cc00000000000000000000000099999988aa999a999999999899888aa9889999988a9999a899998aaaa888a88aa98888888888999a
0001cc77777cc100001ccc70000000000000000000000000999aa99a9aaa99999999aa99aaaa9999899999988a99a9a8a9998888aaaaa88888888888a8889999
001cc7777777c10001cc77000000000000000000000000009999aaaa999aaa99999aa99999999999888a99988a99a888999998888888a888888888aaa8899999
001c77770007c10001c770000000000000000000000000009999999999999aa9999999999aaa9999888a99988a99a888999998aaa888a988888888a898899999
01c7770000007c101cc77000000000000000000000000000999aaa9988888999988aaa9999999999888999988aa9a9a889999988a888a988888888a988999998
01c7700000000c1001c770000000000000000000000000008888888811111888811888888888888889a9999889a999a818999998a888a8a8aaa888a989999981
01c770000000001001c777000000000000000000000000008888811888118888881111888888811889a9998189a999a81189999888aaa8a888a8aaa889999811
01c700000000000001c777000000000000000000000000009999988999889999998888999999988a88899a9889a999981158999998a888a888aaa8899999811d
01c700000000000001cc77700000000000000000000000009aaa9a999999aaa99aaaaa9999999aa988899a988aa99988111189999988aaa88888889999981111
01c7000000000000001cc7777000001000000000000000009999999aaa9999999999999aaaaa9a99888899988a99998811111899999988888888999999811111
001c0000000000000001cc777777c1000000000000000000999999998889999999988899999a9a99888899981899999811111189999999988999999998111111
0001000000000000000011cccccc1000000000000000000098899999888a989999988899999aaa888899a9981899a99811111118999999988999999981111111
0000100000000000000000111111000000000000000000009888988a8889999898a88898899899888899a9981899a99811d111118a9999988999999811111111
0000000000000000000000000000000000000000000000008888888888888888888888888888888888999998899999981111111118999a988999998111111111
00000000000000000000000000000000000000000000000000000000000000000000088888800000000000000000000000000000000000000000000000000000
00000000000006000000000000000000000000070000000000000000000000000000081111800000000000000000000000000000000000000000000000000000
000000000000d00000000000000000000000000d000000000000000000000000000008e11e800000000000000000000000000000000000000000000000000000
00000000000d00000000000000000000000000d66600000000000000000000008800081111800088000000000000000000000000000000000000000000000000
0000000660d000000000000000000000000000d66d00000000000000000000008808081ee1808088000000000000000000000000000000000000000000000000
0000006dd60000000070000660000000000000d66600000000000000000000008888888888888888000000000000000000000000000000000000000000000000
00000b6556b0000000ddd06dd6000000000000d65500000000000000000000008888888888888888000000000000000000000000000000000000000000000000
0000055bb50500000000db6556b0000000000555b50000000000000000000000000008e88e800000000000000000000000000000000000000000000000000000
0000055bb50500000000055bb5500000000005d55500000000000000000000000000088ee8800000000000000000000000000000000000000000000000000000
00005d5bb50000000000055bb5dd000000000d05b500000000000000000000000000008888000000000000000000000000000000000000000000000000000000
0000d05555000000000000555500c70000000c055500000000000000000000000000008888000000000000000000000000000000000000000000000000000000
007c0006600000000000000660000cc000000706600000000000000000000000000000dddd000000000000000000000000000000000000000000000000000000
06c0006006000000000000600600000000000c006000000000000000000000000000000880000000000000000000000000000000000000000000000000000000
7c000060060000000000006006000000000007006000000000000000000000000000008008000000000000000000000000000000000000000000000000000000
c000006006000000000000000000000000000c006000000000000000000000000000080000800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000880000880000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d000000000000000000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d000000000000000000000000000000000666d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000d06600000000000000000000000000000d66d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000d6660000000000000660000700000000666d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000b6d56b0000000000066660ddd00000000556d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005055d550000000000b655ddd00000000005b5550000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000050555d500000000005ddd5500000000000555d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005665d500000000dd56655000000000005b50d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055550d0000007c0055550000000000005550c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000066000c7000cc0000660000000000000066070000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000006006000c6000000060060000000000000600c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000060060000c70000006006000000000000060070000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000600600000c00000000000000000000000600c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2e2f2629282629262727292826262c2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e3f1616161616161616161616163c3d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a16161619161616161616161616070b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a16161616161616161616161616171b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a16161616161616161616161616162b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a16161616161617081616161616162b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a16181616161616161616161616161b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a16071616161616161616161616163b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a16161616161616161616191616160b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a16161616161616161616161616161b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a16161616161616161616161616160b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a16161616161616161616161616083b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a16161616161616070616161616070b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a09161616161616161616161616162b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0f1616171617161716171616170c0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f3637373938383739363839381c1d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
19020000186701867018660186500c6550c6450c63500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500000
33020000157730c7700c7600c74000735007350073500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000009070090700a0400a0400a0400a0400a0300a0300a0300a0200a0200a0200a0100a0100a0100a0100a0100a0150a0150a0150000000000000000000009070090700a0400a0400a0400a0400a0300a030
090c00002107021070220402204022040220402203022030220302202022020220202201022010220100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000009070090700a0400a0400a0400a0400a0300a0300a0300a0200a0200a0200a0100a0100a0100a0100a0100000000000000000000000000000000000009070090700a0400a0400a0400a0400a0300a030
010c000009070090700a0400a0400a0400a0400a0300a0300c7700c7700a7400a7400a7400a7400a7300a73009070090700a0400a0400a0400a0400a0300a03009070090700a0400a0400a0400a0400a0300a030
010c000009070090700a0400a0400a0400a0400a0300a0300a0200a0200a0200a0200a0100a0100a0100000009070090700a0400a0400a0400a0400a0300a03009070090700a0400a0400a0400a0400a0300a030
010c00000a0200a0200a0200a0200a0100a0100a0100a01009070090700a0400a0400a0400a0400a0300a03009070090700a0400a0400a0400a0400a0300a03009070090700a0400a0400a0400a0400a0300a030
010c000009070090700a0600a0600a013000000000000000000000000000000000000000000000000000000009070090700a0600a0600a01000000000000000009070090700a0600a0600a010000000000000000
010c0000000000000000000000000000000000000000000009070090700a0600a0600a01000000000000000009070090700a0600a0600a0100000000000000000000000000000000000000000000000000000000
000c000009070090700a0600a0600a01000000000000000009070090700a0600a0600a0100000000000000000c0700c0700a0600a0600a0100000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0000189550000018955000000000000000000000000000000000000000000000189601a950189601a95018955000000000000000000000000000000000001895500000189550000000000000000000000000
050c0000008750000000875000000000000000000000000000000000000000000000188401a830188401a83018825000000000000000000000000000000000000087500000008750000000000000000000000000
010c000018955000001895500000189601a950189601a950189550000000000000000000000000000000000000000000000000000000000000000000000000001895500000189550000000000000000000000000
050c000000875000000087500000188401a830188401a830188250000000000000000000000000000000000000000000000000000000000000000000000000000087500000008750000000000000000000000000
010c00001895500000189550000000000000000000000000189550000018955000000000000000000000000018955000001895500000000000000000000000001895518960189551a950189601a9501895500000
050c00000087500000008750000000000000000000000000008750000000875000000000000000000000000000875000000087500000000000000000000000000087518840008751a830188401a8301882500000
010c00001895500000189550000000000000000000000000000000000000000000000000000000000000000018955000001895500000000000000000000000001895500000189550000000000000000000000000
050c00000087500000008750000000000000000000000000000000000000000000000000000000000000000000875000000087500000000000000000000000000087500000008750000000000000000000000000
010c0000189550000018955189601a950189601a95018955000000000000000000000000000000000000000018955189601a950189601a95018955000000000018955189601a950189601a950189550000000000
010c0000008750000000845188201a810188201a83018815000000000000000000000000000000000000000000845188201a810188201a83018815000000000000845188201a810188201a830188150000000000
010c00000000000000000000000000000000000000000000189550000018955000000000000000000000000018955000001895500000000000000000000000001895500000189550000000000000000000000000
010c00000000000000000000000000000000000000000000008750000000875000000000000000000000000000875000000087500000000000000000000000000087500000008750000000000000000000000000
010c000018955189601a950189601a95018955000000000018955189601a950189601a95018955000000000018955189601a950189601a95018955000000000018955189601a950189601a950189550000000000
010c000000845188201a810188201a83018815000000000000845188201a810188201a83018815000000000000845188201a810188201a83018815000000000000845188201a810188201a830188150000000000
010c000018955189601a950189601a95018955000000000018955189601a950189601a95018955000000000018955189601a950189601a95018955000000000018955189601a950189601a950189550000000000
010c000000845188201a810188201a83018815000000000000845188201a810188201a83018815000000000000845188201a810188201a83018815000000000000845188201a810188201a830188150000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000018010190301b040180001b0501b0501b0501b0501b0501805018010170201703017040000001b0401b0401305013050170501705017050150501505014050140521405214052
090c00001805018050180501a0401a04000000000000000019050190501905019051180011b0511b050000001a0601a0601a0621a0621a0621a0601a0601a0621a0621a062000000000000000000000000000000
010c000018010190301b040180001b0501b0501b0501b0501b0501805018010170201703017040000001b0401b040130501305017050170501705015050150501405014052140521405200000000000000000000
090c00001805018050180501a0401a04000000000000000019050190501905019051180011b0511b050000001a0601a0601a0621a0621a0621a0601a0601a0621a0621a062000000000000000000000000000000
090c000018010190301b040180001b0501b0501b0501b0501b0501805018010170201703017040000001b0401b04013050130501705017050170501505015050140501405214052140521b0501b0501b0501b050
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000e4400f4400e4400d4400a440074400744007440084400743003430024300043000430014100140002400024000040000400004000040000400004000040000400004000040000400004000040000400
000200001d0401d0401c040190401504015040150401504014040130300e0300d0300c03007030040100205002600026000060000600006000060000600006000060000600006000060000600006000060000600
__music__
00 0a0b1415
00 0c421617
00 0d421819
00 0e421a1b
00 0f421e1f
00 10281c1d
01 11292021
00 122a2223
00 112b2021
02 122c2223

