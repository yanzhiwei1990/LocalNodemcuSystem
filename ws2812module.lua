--ws2812module define
ws2812module = {}

--public data
ws2812module.total = "ws2812module"

--private data
local powerpin = 1
local debug = false
--init power switch
gpio.mode(powerpin, gpio.OUTPUT)
gpio.mode(powerpin, gpio.LOW)
--init 2812
local buffer1 = nil
local buffer2 = nil

--total power apply switch
function ws2812module.setpower(status)
    print("setpower ", status)
    if (status) then
        gpio.write(powerpin, gpio.HIGH)
    else
        gpio.write(powerpin, gpio.LOW)
    end
end

--debug switch
function ws2812module.setdebug(status)
    print("setdebug ", status)
    debug = status
end

--light all lights with required color data
function ws2812module.lighttrip(red, green, blue, white)
  print(string.format("red = %d, green = %d, blue = %d, white = %d", red, green, blue, white))
  local i = 1
  for i=1,60 do
     buffer1:set(i, green, red, blue)
     buffer2:set(i, green, red, blue , white)
  end
  ws2812.write(buffer1)
  ws2812.write(buffer2)
end

--light lights with raw color data
function ws2812module.lighttripwithrawdata(colordata)
  print(string.format("lighttrip raw data size=%d", string.len(colordata)))
  local i = 1
  for i=1,60 do
     local red = string.byte(colordata, (i - 1) * 3 + 1)
     local green = string.byte(colordata, (i - 1) * 3 + 2)
     local blue = string.byte(colordata, (i - 1) * 3 + 3)
     buffer1:set(i, green, red, blue)
     if (debug) then
        print(string.format("lighttripwithrawdata i=%d: r=%d,g=%d,b=%d", i, red, green, blue))
     end
  end
  local offset = 60 * 3
  local i = 1
  for i=1,60 do
     local red = string.byte(colordata, (i - 1) * 4 + 1 + offset)
     local green = string.byte(colordata, (i - 1) * 4 + 2 + offset)
     local blue = string.byte(colordata, (i - 1) * 4 + 3 + offset)
     local white = string.byte(colordata, (i - 1) * 4 + 4 + offset)
     buffer2:set(i, green, red, blue , white)
     if (debug) then
        print(string.format("lighttripwithrawdata i=%d: r=%d,g=%d,b=%d,w=%d", i, red, green, blue, white))
     end
  end
  ws2812.write(buffer1)
  ws2812.write(buffer2)
end

--init trip
function ws2812module.init2812(r,g,b,w)
    print("init2812")
    ws2812.init()
    buffer1 = ws2812.newBuffer(60, 3)
    buffer1:fill(0, 0, 0)
    buffer2 = ws2812.newBuffer(60, 4)
    buffer2:fill(0, 0, 0, 0)
    --ws2812module.setPower(false)
    ws2812module.lighttrip(r, g, b, w)
end

return ws2812module
