--load module
local ws2812module = require("ws2812module")
print("ws2812module", ws2812module.total)
ws2812module.init2812(0,0,0,0)

--constant
--nodemcu#+20byte+20byte+4byte+data
local protool_start =   {"nodemcu#"}
local protool_command = {"0120123456789command"}
local protool_extra =   {"0123450123456789data"}
--nodemcu#0120123456789command0123450123456789data
--60 * 7 = 420 = 0x1a4
local protool_length =   {0, 0, 1, 164}
--define length
local protool = {8, 20, 20, 4}

local isconnect = 0
local mysocket = nil
local firstpart = false
local restpart = false
local receivecount = 0
local buffer = nil
local datasize = 0
local readdatasize = 0
local srv = nil
local isreconnecting = false

local DEBUG = false

function resetTcpConnect()
    if (srv ~= nil) then
        --srv:close()
        srv = nil
    end
    srv = net.createConnection()
    --"dns", "connection", "reconnection", "disconnection", "receive" or "sent"
    srv:on("connection", function(sck, c)
        print("connection", c)
        isconnect = 1
        mysocket = sck
        if (mysocket ~= nil) then
            mysocket:send("online\n")
            print("answer online")
        end
    end)
    srv:on("reconnection", function(sck, c)
        if (sck == nil) then
            print("reconnection sck nil")
        end
        print("reconnection", c)
    end)
    srv:on("disconnection", function(sck, c)
        if (sck == nil) then
            print("disconnection sck nil")
        end
        print("disconnection:", c)
        isconnect = 0
        --mysocket = nil
    end)
    srv:on("receive", function(sck, c)
        --print("receive:", c)
        --getbyte(c)
        --parse(sck, c)
        if (isfirstpart(c)) then
            datasize = 0
            readdatasize = 0
            firstpart = true
            restpart = false
            buffer = c
            datasize = geteffectivedatasize(c)
            readdatasize = geteffectivereceivedatasize(c)
            print(string.format("receive in first part length=%d,datasize=%d,readdatasize=%d", #c, datasize, readdatasize))
            if (readdatasize == datasize) then
                print("receive complete in first part")
                consumereceivedata(sck)
                resetreceive()
            end
            receivecount = receivecount + 1
        elseif (firstpart) then
            restpart = true
            buffer = buffer..c
            readdatasize = readdatasize + geteffectivereceivedatasize(c)
            print(string.format("receive in rest part length=%d,datasize=%d,readdatasize=%d", #c, datasize, readdatasize))
            if (readdatasize == datasize) then
                print("receive complete in rest part")
                consumereceivedata(sck)
                resetreceive()
            end
            receivecount = receivecount + 1
        else
            print("receive erro", #c)
            resetreceive()
        end
        print(string.format("receive-------%d--------", receivecount))
    end)
    
    srv:on("sent", function(sck, c)
        --print("sent:", c)
    end)
    connectToServer()
end

function connectToServer()
    srv:connect(19911,"opendiylib.com")
    --srv:connect(19912,"192.168.188.150")
end

function resetreceive()
    firstpart = false
    restpart = false
    buffer = nil
    datasize = 0
    readdatasize = 0
    receivecount = 0
end

function consumereceivedata(sck)
    print("consumereceivedata");
    if (datasize == readdatasize and buffer ~= nil) then
        local consumeBuff = buffer
        local consumeDatasize = datasize
        local consumeDataHead = string.sub(buffer, 1, 52)
        print(string.format("consumereceivedata datasize=%d,head=%s", datasize, consumeDataHead))
        local command = geteffectivecommandstrfromfirstpart(consumeDataHead)
        doCommand(sck, command)
    end
end

function isfirstpart(strdata)
    local result = false
    local startdata
    if (strdata ~= nil) then
        startdata = string.sub(strdata, 1, 8)
        if (startdata == protool_start[1]) then
            result = true
        end
    end
    local switchtostr = "false"
    if (result) then
        switchtostr = "true"
    end
    print(string.format("isfirstpart->%s", switchtostr))
    return result
end

function geteffectivecommandstrfromfirstpart(strdata)
    local result
    local needdata
    local startindex
    if (strdata ~= nil) then
        needdata = string.sub(strdata, 9, 28)
        if (needdata ~= nil) then
            startindex = string.find(needdata, "[A-Za-z]+")
            if (startindex ~= nil) then
                result = string.sub(needdata, startindex)
            else
                result = needdata
            end
        end
    end
    print(string.format("geteffectivecommandstrfromfirstpart->%s", result))
    return result
end

function geteffectiveextrastrfromfirstpart(strdata)
    local result
    local needdata
    local startindex
    if (strdata ~= nil) then
        needdata = string.sub(strdata, 29, 48)
        if (needdata ~= nil) then
            startindex = string.find(needdata, "[A-Za-z]+")
            if (startindex ~= nil) then
                result = string.sub(needdata, startindex)
            else
                result = needdata
            end
        end
    end
    print(string.format("geteffectiveextrastrfromfirstpart->%s", result))
    return result
end

function geteffectivedatasize(strdata)
    local result = 0
    local needdata
    local startindex
    if (strdata ~= nil and string.len(strdata) > 52) then
        needdata = string.sub(strdata, 49, 52)
        if (needdata ~= nil) then
            local first = string.byte(needdata, 1)
            local second = string.byte(needdata, 2)
            local third = string.byte(needdata, 3)
            local fourth = string.byte(needdata, 4)
            if (first == nil or second == nil or third == nil or fourth == nil) then
                return result
            else
                print(string.format("geteffectivedatasize->%d,%d,%d,%d", first, second, third, fourth))
                result = fourth + third * 256 +
                        second * 256 * 256 + first * 256 * 256 * 256
            end
        end
    end
    print(string.format("geteffectivedatasize->%d", result))
    return result
end


function geteffectivereceivedatasize(strdata)
    local result = 0
    local needdata
    local startindex
    if (isfirstpart(strdata) and string.len(strdata) >= 52) then
        result = string.len(strdata) - 52
    elseif (strdata ~= nil) then
        result = string.len(strdata)
    end
    print(string.format("geteffectivereceivedatasize->%d", result))
    return result
end

function getbyte(strvalue) 
    if (strvalue ~= nil) then
        local length = string.len(strvalue)
        print("getbyte length:", length)
        --[[for i=1,length do
            print("getbyte single:", string.byte(strvalue,i))
        end]]--
    else 
      print("getbyte nil")  
    end
end

function doCommand(sck, command)
    if (command == "poweron") then
        powerSwitch(1)
        sck:send("poweron_ok\n")
    elseif (command == "poweroff") then
        powerSwitch(0)
        sck:send("poweroff_ok\n")
    elseif (command == "check") then
        sendPower(sck)
        sck:send("check_ok\n")
    elseif (command == "restart") then
        sck:send("restart_ok\n")
        restart()
    elseif (command == "rgbled") then
        lightRgbwLed()
        sck:send("rgbled_ok\n")
    else
        print("doCommand ukown command")  
        sck:send("ukown command_ok\n")
    end
end

function lightRgbwLed()
    if (DEBUG) then
        local tenNum = (datasize - 52) / 12
        if (tenNum > 0) then
            local i = 1
            for i=1,tenNum do
                print(string.format("consumereceivedata i=%3d:", i), string.byte(buffer, 53 + (i - 1) * 12, 53 + (i) * 12 - 1))
            end
        end
    end
    ws2812module.lighttripwithrawdata(string.sub(buffer, 53))
end

function checkconnection()
    if isconnect == 1 then
        --srv.send("adc=")
    else
        print("checkconnection connect AGAIN")
        if (srv ~= nil) then
            --srv:close()
        end
        resetTcpConnect()
    end
end

function powerSwitch(value)
    print("powerSwitch value=", value)
    if value == 1 then
        --gpio.write(5, gpio.HIGH)
        gpio.serout(5,gpio.HIGH,{500000,50})
    else
        gpio.write(5, gpio.LOW)
    end
end

function sendPower(sck)
    local value = adc.read(0)
    print("sendPower value=", string.format("value:%d",value))
    if value > 500 then
        sck:send("poweronok\n")
    else
       sck:send("poweroffok\n") 
    end
end

function answer()
    if isconnect == 1 and mysocket ~= nil then
        mysocket:send("online\n")
        print("answer online")
    else
        print("answer offline")
    end
end

function restart()
    print("restart")
    node.restart()
end

mytimer2 = tmr.create()
mytimer2:register(3000, tmr.ALARM_AUTO, checkconnection)
mytimer2:start()
resetTcpConnect()

--[[mytimer3 = tmr.create()
mytimer3:register(1000, tmr.ALARM_AUTO, answer)
mytimer3:start()]]--
