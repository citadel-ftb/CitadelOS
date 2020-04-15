--- Logic for extracting blocks
--- TODO: message control and skip diamond, emerald blocks
--- TODO: message control on chunk completion, get next chunk
local vector = vector or require('rom/apis/vector')

local function printUsage()
    print( "Usages:" )
    print( "extract chunk <x> <z> <begin_sub_chunk> <end_sub_chunk>" )
    print( "extract move <x> <y> <z>")
end

local tArgs = { ... }
if #tArgs < 1 then
    printUsage()
    return
end

local Extractor = {
    west = vector.new(-1, 0, 0),
    east = vector.new(1, 0, 0),
    north = vector.new(0, 0, -1),
    south = vector.new(0, 0, 1)
}

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
    return block and not block.name:match("diamond")
end

function Extractor:dig(force)
    local present, block = turtle.inspect()
    if present and (force or self:is_dig_allowed(block)) then
        turtle.dig()
    end
end

function Extractor:move(target, facing, dig)
    while true do
        local delta = target - self.pos
        local amount = self.facing:dot(delta)

        if amount <= 0 and not stuck then
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
                if not self:up() then
                    self:forward()
                end
            else
                if not facing then
                    return
                elseif self:get_right():dot(facing) > 0 then
                    self:right()
                elseif self:get_left():dot(facing) > 0 then
                    self:left()
                elseif self:get_back():dot(facing) > 0 then
                    self:left()
                    self:left()
                end
                return
            end
        elseif amount > 0 then
            while not self:forward() do
                if dig then
                    self:dig(true)
                else
                    self:up()
                end
            end
        end
    end
end

function Extractor:extract_column(y)
    while self.pos.y ~= y do
        if y < pos.y then
            local present, _ = turtle.inspectDown()
            if present then
                turtle.digDown()
            end
            self:down()
        end

        self:right()
        for i=1,3 do
            self:dig()
            if i < 3 then
                self:left()
            end
        end
        self:right()

        if y > pos.y then
            local present, _ = turtle.inspectUp()
            if present then
                turtle.digUp()
            end
            self:up()
        end
    end
end

function Extractor:extract_sub_chunk(offset, sub_offset)
    local offset_origin = vector.new(self.chunk_origin.x + offset.x * 16, 70,self.chunk_origin.z + offset.z * 16)
    local target = vector.new(offset_origin.x + sub_offset.x * 4, offset_origin.y, offset_origin.z + sub_offset.z * 4)
    local up = 70
    local down = 65
    local columns = {
        { v_begin = vector.new(target.x + 1, up, target.z), v_end = vector.new(target.x + 1, down, target.z), dir = self.south, dig_to = false },
        { v_begin = vector.new(target.x + 3, down, target.z + 1), v_end = vector.new(target.x + 3, up, target.z + 1), dir = self.west, dig_to = true },
        { v_begin = vector.new(target.x + 2, up, target.z + 3), v_end = vector.new(target.x + 2, down, target.z + 3), dir = self.north, dig_to = false },
        { v_begin = vector.new(target.x, down, target.z + 2), v_end = vector.new(target.x, up, target.z + 2), dir = self.east, dig_to = true }
    }
    for i,column in ipairs(columns) do
        self:move(column.v_begin, column.dir, column.dig_to)
        self:extract_column(column.v_end.y)
        sleep(4)
        if i % 2 == 0 then
            self:move(vector.new(331, 70, -129), self.west)
            self:offload()
        end
    end
end

function Extractor:offload()
    for i=1,16 do
        turtle.select(i)
        turtle.drop()
    end
end

function Extractor:extract_chunk(offset, start_at, end_at)
    start_at = start_at or 0
    end_at = end_at or 15
    for i=start_at,end_at do
        local sub_offset = { x = i % 4, z = math.floor(i / 4)}
        self:extract_sub_chunk(offset, sub_offset)
    end
    self:move(vector.new(332, 70, -116))
end

function Extractor:move_to_next_column()
    self:right()
    self:forward()
    self:left()
    self:dig(true)
    self:forward()
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
    local start_at = (tArgs[4] and tonumber(tArgs[4])) or 0
    local end_at = (tArgs[5] and tonumber(tArgs[5])) or 15
    robot:calibrate()
    robot:extract_chunk(offset, start_at, end_at)
elseif tArgs[1] == "move" then
    local target = vector.new(tonumber(tArgs[2]), tonumber(tArgs[3]), tonumber(tArgs[4]))
    robot:calibrate()
    robot:move(target)
end