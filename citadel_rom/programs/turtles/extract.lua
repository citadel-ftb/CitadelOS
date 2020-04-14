--- Logic for extracting blocks
--- TODO: message control and skip diamond, emerald blocks
--- TODO: message control on chunk completion, get next chunk
local vector = vector or require('rom/apis/vector')

local function printUsage()
    print( "Usages:" )
    print( "extract chunk <x> <z>" )
    print( "extract move <x> <y> <z>")
end

local tArgs = { ... }
if #tArgs < 1 then
    printUsage()
    return
end

local Extractor = {}

function Extractor:calibrate()
    if self.facing:length() > 0 then
        return true
    end

    for i=1,4 do
        if turtle.forward() then
            local new_pos = vector.new(gps.locate())
            self.facing = new_pos - self.pos
            self.pos = new_pos
            self:left()
            self:left()
            self:forward()
            if i == 1 then
                self:left()
                self:left()
            elseif i == 2 then
                self:right()
            elseif i == 4 then
                self:left()
            end
            return true
        else
            turtle.turnRight()
        end
    end
    return false
end

function Extractor:get_forward()
    return vector.new(self.facing.x, self.facing.y, self.facing.z)
end

function Extractor:get_back()
    return vector.new(-1 * self.facing.x, -1 * self.facing.y, -1 * self.facing.z)
end

function Extractor:get_right()
    if self.facing.z > 0 then -- south to west
        return vector.new(-1, 0, 0)
    elseif self.facing.x < 0 then -- west to north
        return vector.new(0, 0, -1)
    elseif self.facing.z < 0 then -- north to east
        return vector.new(1, 0, 0)
    elseif self.facing.x > 0 then -- east to south
        return vector.new(0, 0, 1)
    end
end

function Extractor:get_left()
    if self.facing.z > 0 then
        return vector.new(1, 0, 0)
    elseif self.facing.x > 0 then
        return vector.new(0, 0, -1)
    elseif self.facing.z < 0 then
        return vector.new(-1, 0, 0)
    elseif self.facing.x < 0 then
        return vector.new(0, 0, 1)
    end
end

function Extractor:get_up()
    return vector.new(0, 1, 0)
end

function Extractor:get_down()
    return vector.new(0, -1, 0)
end

function Extractor:right()
    turtle.turnRight()
    self.facing = self:get_right()
end

function Extractor:left()
    turtle.turnLeft()
    self.facing = self:get_left()
end

function Extractor:up()
    if turtle.up() then
        self.pos = self.pos + self:get_up()
        return true
    end
    return false
end

function Extractor:down()
    if turtle.down() then
        self.pos = self.pos + self:get_down()
        return true
    end
    return false
end

function Extractor:forward()
    if turtle.forward() then
        self.pos = self.pos + self:get_forward()
        return true
    end
    return false
end

function Extractor:back()
    if turtle.back() then
        self.pos = self.pos + self:get_back()
        return true
    end
    return false
end

function Extractor:is_dig_allowed(block)
    return not block.name:match("diamond")
end

function Extractor:dig(force)
    local present, block = turtle.inspect()
    if present and (force or self:is_dig_allowed(block)) then
        turtle.dig()
    end
end

function Extractor:move(target)
    while target ~= self.pos do
        local delta = target - self.pos
        local amount = self.facing:dot(delta)

        if amount <= 0 then
            if self:get_right():dot(delta) > 0 then
                self:right()
            elseif self:get_left():dot(delta) > 0 then
                self:left()
            elseif self:get_back():dot(delta) > 0 then
                self:right()
                self:right()
            elseif delta.y < 0 then
                self:down()
            elseif delta.y > 0 then
                self:up()
            else
                return
            end
        elseif amount > 0 then
            while not self:forward() do
                self:up()
            end
        end
    end
end

function Extractor:extract_column_down()
    while self.pos.y > 2 do
        present, _ = turtle.inspectDown()
        if present then
            turtle.digDown()
        end
        self:down()
        self:right()
        for i=1,3 do
            self:dig()
            if i < 3 then
                self:left()
            end
        end
        self:right()
    end
end

function Extractor:extract_column_up()
    while self.pos.y < 70 do
        local present, _ = turtle.inspectUp()
        if present then
            turtle.digUp()
        end
        self:up()
        if self.pos.y == 70 then
            return
        end
        self:right()
        for i=1,3 do
            if self:is_dig_allowed() then
                turtle.dig()
            end
            if i < 3 then
                self:left()
            end
        end
        self:right()
    end
end

function Extractor:chunk_move(index, pos)

end

function Extractor:extract_chunk(offset)
    --local chunk_origin = { x = origin.x + offset.x * 16, z = origin.z + offset.z * 16 }
    --self:move(chunk_origin)
    while self.facing.x < 1 do
        self:right()
    end
    self:forward()
    self:left()
    self:extract_column_down()
    self:move_to_next_column()
    self:extract_column_up()
    self:move_to_next_column()
    self:extract_column_down()
    self:move_to_next_column()
    self:extract_column_up()
end

function Extractor:move_to_next_column()
    self:right()
    self:forward()
    self:dig(true)
    self:forward()
    self:left()
    self:dig(true)
    self:forward()
    self:left()
end

function Extractor.new(position, chunk_origin)
    local self = { pos = position, chunk_origin = chunk_origin, facing = vector.new(0, 0, 0) }
    setmetatable(self, { __index = Extractor })
    return self
end

local gps_ext = require('/citadel_rom/apis/gps_ext')
local chunk = require('/citadel_rom/apis/chunk')

local home_x, home_y, home_z = gps.locate()
local gps_hosts = gps_ext.locate_hosts()
local robot = Extractor.new(vector.new(home_x, home_y, home_z), chunk.get_origin(gps_hosts))

if tArgs[1] == "chunk" then
    local offset = { x = tonumber(tArgs[2]), z = tonumber(tArgs[3]) }
    robot:calibrate()
    robot:extract_chunk(offset)
elseif tArgs[1] == "move" then
    local target = vector.new(tonumber(tArgs[2]), tonumber(tArgs[3]), tonumber(tArgs[4]))
    robot:calibrate()
    robot:move(target)
end