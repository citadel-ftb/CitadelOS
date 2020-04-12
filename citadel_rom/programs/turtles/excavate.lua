--- Logic for extracting blocks
--- TODO: message control and skip diamond, emerald blocks
--- TODO: message control on chunk completion, get next chunk
local vector = vector or require('rom/apis/vector')

local function printUsage()
    print( "Usages:" )
    print( "excavate chunk <x> <z>" )
    print( "excavate move <x> <y> <z>")
end

local tArgs = { ... }
if #tArgs < 1 then
    printUsage()
    return
end

local Extractor = {}

function Extractor:calibrate()
    if self.facing:length() then
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

function Extractor:right()
    turtle.turnRight()
    if self.facing.z > 0 then -- south to west
        self.facing.z = 0
        self.facing.x = -1
    elseif self.facing.x < 0 then -- west to north
        self.facing.x = 0
        self.facing.z = -1
    elseif self.facing.z < 0 then -- north to east
        self.facing.z = 0
        self.facing.x = 1
    elseif self.facing.x > 0 then -- east to south
        self.facing.x = 0
        self.facing.z = 1
    end
end

function Extractor:left()
    turtle.turnLeft()
    if self.facing.z > 0 then
        self.facing.z = 0
        self.facing.x = 1
    elseif self.facing.x > 0 then
        self.facing.x = 0
        self.facing.z = -1
    elseif self.facing.z < 0 then
        self.facing.z = 0
        self.facing.x = -1
    elseif self.facing.x < 0 then
        self.facing.x = 0
        self.facing.z = 1
    end
end

function Extractor:forward()
    if turtle.forward() then
        self.pos = self.pos + self.facing
        return true
    end
    return false
end


function Extractor:move(target)
    while not target == self.pos do
        local delta = target - self.pos
        local amount = self.facing:dot(delta)
    end
end

function Extractor:chunk_move(index, pos)

end

function Extractor.new(position, chunk_origin)
    local self = { pos = position, chunk_origin = chunk_origin, facing = vector.new(0, 0, 0) }
    setmetatable(self, { __index = Extractor })
    return self
end

local gps_ext = require('citadel_rom/apis/gps_ext')
local chunk = require('citadel_rom/apis/chunk')

local home_x, home_y, home_z = gps.locate()
local gps_hosts = gps_ext.locate_hosts()
local robot = Extractor.new(vector.new(home_x, home_y, home_z), chunk.get_origin(gps_hosts))

if tArgs[1] == "chunk" then

elseif tArgs[1] == "move" then
    local target = vector.new(tonumber(tArgs[2]), tonumber(tArgs[3]), tonumber(tArgs[4]))
    robot:calibrate()
    robot:move(target)
end