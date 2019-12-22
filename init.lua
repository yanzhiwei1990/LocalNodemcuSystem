station_cfg={}

station_cfg.ssid="TP-LINK_WEI"
station_cfg.pwd="wwlww@3344"
station_cfg.save=true
wifi.setmode(wifi.STATION)
wifi.sta.config(station_cfg)
--uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)

--wait for wifi connected
b = 0
function connect()
   b = b + 1;
   if (wifi.sta.getip()==nil) then
       print("connecting to TP-LINK_WEI AP...num = ", b)
   else
      print("get ip: ", wifi.sta.getip())
      dofile("tcpclient.lua")
      print("do file tcpclient.lua")
      mytimer:unregister()
      mytimer1:start()
   end
end

ledtimecount = 0
ledstatus = 0
function runstatus()
    if ledtimecount >= 0 and ledtimecount < 1000 then
        if ledtimecount % 20 == 0 then
            gpio.write(0, gpio.LOW)
            ledstatus = 1
        else
            gpio.write(0, gpio.HIGH)
            ledstatus = 0
        end
    elseif ledtimecount == 100 then
        gpio.write(0, gpio.HIGH)
        ledpwmcount = 0
        ledstatus = 0
    end
    if (ledtimecount == 0 or ledtimecount == 1000) then
        feeddog()
    end
    ledtimecount = ledtimecount + 1
    if (ledtimecount > 2000) then
        ledtimecount = 0
    end
end

function feeddog()
    tmr.wdclr()
end

node.setcpufreq(node.CPU160MHZ)
gpio.mode(0, gpio.OUTPUT)
gpio.write(0, gpio.HIGH)
--led power off
gpio.mode(1, gpio.OUTPUT)
gpio.write(1, gpio.LOW)
--led desktop off
gpio.mode(5, gpio.OUTPUT)
gpio.write(5, gpio.LOW)

mytimer = tmr.create()
mytimer:register(1000, tmr.ALARM_AUTO, connect)
mytimer:start()

mytimer1 = tmr.create()
mytimer1:register(1, tmr.ALARM_AUTO, runstatus)
mytimer1:start()

--[[function closetrip()
    --init trip
    ws2812.init()
    local buffer1 = ws2812.newBuffer(60, 4)
    buffer1:fill(0, 0, 0, 0)
    local buffer2 = ws2812.newBuffer(60, 3)
    buffer2:fill(0, 0, 0)
    for i=1,60 do
    buffer1:set(i, 0, 0, 0, 0)
    buffer2:set(i, 0, 0, 0)
    end
    ws2812.write(buffer2)
    ws2812.write(buffer1)
end

closetrip()]]--




