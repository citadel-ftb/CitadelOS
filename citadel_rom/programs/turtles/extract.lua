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

function Extractor:is_behind_turtle()
    local present, block = turtle.inspect()
    if not present or not block.name:match("turtle") then
        return false
    end

    if block.state and block.state.facing then
        if self.facing == self.west and block.state.facing == "west" then
            return true
        elseif self.facing == self.east and block.state.facing == "east" then
            return true
        elseif self.facing == self.south and block.state.facing == "south" then
            return true
        elseif self.facing == self.north and block.state.facing == "north" then
            return true
        end
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
                if not self:down() then
                    sleep(1)
                end
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
                    if not self:up() then
                        if not self:is_behind_turtle() then
                            self:right()
                        end
                    end
                end
            end
        end
    end
end

function Extractor:extract_column(y)
    while self.pos.y ~= y do
        if y < self.pos.y then
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

        if y > self.pos.y then
            local present, _ = turtle.inspectUp()
            if present then
                turtle.digUp()
            end
            self:up()
        end
    end
end

function Extractor:get_offload_point()
    local offload = {}
    if index.x <= 1 and index.x >= -1 and index.z <= 1 and index.z >= -1 then
        offload.dir = self.south
        offload.pos = vector.new(self.chunk_origin.x + 9, 70, self.chunk_origin.z + 5)
    elseif index.x > 1 and index.z == 0 then
        offload.dir = self.west
        offload.pos = vector.new(self.chunk_origin.x + 32, 70, self.chunk_origin.z + 8)
        while offload.pos.x + 48 <= target.x do
            offload.pos.x = offload.pos.x + 48
        end
    elseif index.x < -1 and index.z == 0 then
        offload.dir = self.east
        offload.pos = vector.new(self.chunk_origin.x - 17, 70, self.chunk_origin.z + 8)
        while offload.pos.x - 48 >= target.x do
            offload.pos.x = offload.pos.x - 48
        end
    elseif index.z > 1 and index.x == 0 then
        offload.dir = self.north
        offload.pos = vector.new(self.chunk_origin.x + 8, 70, self.chunk_origin.z + 32)
        while offload.pos.z + 48 <= target.z do
            offload.pos.z = offload.pos.z + 48
        end
    elseif index.z < -1 and index.x == 0 then
        offload.dir = self.south
        offload.pos = vector.new(self.chunk_origin.x + 8, 70, self.chunk_origin.z - 17)
        while offload.pos.z - 48 >= target.z do
            offload.pos.z = offload.pos.z - 48
        end
    else
        return nil
    end
    return offload
end

function Extractor:extract_sub_chunk(index, sub_offset, dig_from, dig_to)
    local offset_origin = vector.new(self.chunk_origin.x + index.x * 16, dig_from,self.chunk_origin.z + index.z * 16)
    local target = vector.new(offset_origin.x + sub_offset.x * 4, offset_origin.y, offset_origin.z + sub_offset.z * 4)

    local columns = {
        { v_begin = vector.new(target.x + 1, dig_from, target.z), v_end = vector.new(target.x + 1, dig_to, target.z), dir = self.south, move_dig = false },
        { v_begin = vector.new(target.x + 3, dig_to, target.z + 1), v_end = vector.new(target.x + 3, dig_from, target.z + 1), dir = self.west, move_dig = true },
        { v_begin = vector.new(target.x + 2, dig_from, target.z + 3), v_end = vector.new(target.x + 2, dig_to, target.z + 3), dir = self.north, move_dig = false },
        { v_begin = vector.new(target.x, dig_to, target.z + 2), v_end = vector.new(target.x, dig_from, target.z + 2), dir = self.east, move_dig = true }
    }

    local offload = self:get_offload_point()
    if not offload then
        print("Can't extract chunk, no offload point found!")
    end

    for i,column in ipairs(columns) do
        self:move(column.v_begin, column.dir, column.move_dig)
        self:extract_column(column.v_end.y)
        if i % 2 == 0 then
            --- Go to offload point
            self:move(offload.pos, offload.dir)
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

    --- Extract all assigned sub chunks
    for i=start_at,end_at do
        local sub_offset = { x = i % 4, z = math.floor(i / 4)}
        self:extract_sub_chunk(offset, sub_offset, 70, 2)
    end

    --- Go to the charging station
    self:move(vector.new(332, 70, -116))
    while turtle.getFuelLevel() < turtle.getFuelLimit() do
        sleep(1)
    end

    --- Finished charging, move and queue in a stack to the west
    self:move(self.pos, self.west)
    self:forward()
    while not self:forward() do
        self:up()
    end
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
    local index = { x = tonumber(tArgs[2]), z = tonumber(tArgs[3]) }
    local start_at = (tArgs[4] and tonumber(tArgs[4])) or 0
    local end_at = (tArgs[5] and tonumber(tArgs[5])) or 15
    robot:calibrate()
    robot:extract_chunk(index, start_at, end_at)
elseif tArgs[1] == "move" then
    local target = vector.new(tonumber(tArgs[2]), tonumber(tArgs[3]), tonumber(tArgs[4]))
    robot:calibrate()
    robot:move(target)
end