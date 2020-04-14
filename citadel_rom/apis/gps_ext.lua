local gps_ext = {}

gps_ext.CHANNEL_GPS = 65534

function gps_ext.locate_hosts( _nTimeout, _bDebug )
    -- Find a modem
    local sModemSide = nil
    for n,sSide in ipairs( rs.getSides() ) do
        if peripheral.getType( sSide ) == "modem" and peripheral.call( sSide, "isWireless" ) then
            sModemSide = sSide
            break
        end
    end

    -- Open a channel
    local modem = peripheral.wrap( sModemSide )
    local bCloseChannel = false
    if not modem.isOpen( os.getComputerID() ) then
        modem.open( os.getComputerID() )
        bCloseChannel = true
    end

    -- Send a ping to listening GPS hosts
    modem.transmit( gps_ext.CHANNEL_GPS, os.getComputerID(), "PING" )

    -- Wait for the responses
    local hosts = {}
    local timeout = os.startTimer( _nTimeout or 2 )
    while true do
        local e, p1, p2, p3, p4, p5 = os.pullEvent()
        if e == "modem_message" then
            -- We received a reply from a modem
            local sSide, sChannel, sReplyChannel, tMessage, nDistance = p1, p2, p3, p4, p5
            if sSide == sModemSide and sChannel == os.getComputerID() and sReplyChannel == gps_ext.CHANNEL_GPS and nDistance then
                -- Received the correct message from the correct modem: use it to determine position
                if type(tMessage) == "table" and #tMessage == 3 and tonumber(tMessage[1]) and tonumber(tMessage[2]) and tonumber(tMessage[3]) then
                    local host = vector.new( tMessage[1], tMessage[2], tMessage[3] )

                    table.insert( hosts, host )
                    if #hosts >= 3 then
                        break
                    end
                end
            end
        elseif e == "timer" then
            -- We received a timeout
            local timer = p1
            if timer == timeout then
                break
            end
        end
    end

    -- Close the channel, if we opened one
    if bCloseChannel then
        modem.close( os.getComputerID() )
    end

    return hosts
end

return gps_ext