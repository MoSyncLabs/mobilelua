---------------------------------------------------
-- Welcome to the Wonderful World of Mobile Lua! --
--                                               --
-- Read file ReadMe.txt for instructions.        --
-- Have fun!                                     --
---------------------------------------------------

-- Run this code to display a coloured rectangle.
Screen:SetColor(255, 255, 255)
Screen:Fill()
Screen:Update()

return 200 % 255

local result = maSensorStart(1, -2)
maSensorStop(1)
EventMonitor:OnSensor(function(type, x, y, z)
  log("OnSensor " .. x .. " " .. y .. " " .. z)
  local red = ((x * 255) / 10) % 255
  local green = (y * 255) % 255
  local blue = (y * 255) % 255
  Screen:SetColor(red, green, blue)
  Screen:Fill()
  Screen:Update()
end)
