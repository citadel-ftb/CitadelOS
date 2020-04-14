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

    for _=1,4 do
        if turtle.forward() then
            local new_pos = vector.new(gps.locate())
            self.facing = new_pos - self.pos
            self.pos = new_pos
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

function Extractor:chunk_move(index, pos)

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

elseif tArgs[1] == "move" then
    local target = vector.new(tonumber(tArgs[2]), tonumber(tArgs[3]), tonumber(tArgs[4]))
    robot:calibrate()
    robot:move(target)
end