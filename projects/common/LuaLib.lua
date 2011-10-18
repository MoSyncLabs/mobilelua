--[[
 * Copyright (c) 2010 MoSync AB
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Parts of the code contributed by Paul Kulchenko, https://github.com/pkulchenko
--]]

--[[
File: LuaLib.lua
Author: Mikael Kindborg
Date: 2011-09-01

This is a Lua library built directly on top of the MoSync API.

Call EventMonitor:RunEventLoop() to enter the MoSync event loop.
This can be done from Lua or from C/C++ by evaluating Lua code.
]]

-- Create the global EventMonitor object.
EventMonitor = (function ()

  local self = {}
  local touchDownFun = nil
  local touchUpFun = nil
  local touchDragFun = nil
  local keyDownFun = nil
  local keyUpFun = nil
  local sensorFun = nil
  local defaultFun = nil
  local anyFun = nil
  local connectionFuns = {}
  local isRunning = false

  self.OnTouchDown = function(self, fun)
    touchDownFun = fun
  end

  self.OnTouchUp = function(self, fun)
    touchUpFun = fun
  end

  self.OnTouchDrag = function(self, fun)
    touchDragFun = fun
  end

  self.OnKeyDown = function(self, fun)
    keyDownFun = fun
  end

  self.OnKeyUp = function(self, fun)
    keyUpFun = fun
  end

  self.OnSensor = function(self, fun)
    sensorFun = fun
  end

  self.OnDefault = function(self, fun)
    defaultFun = fun
  end

  self.OnAny = function(self, fun)
    anyFun = fun
  end
  
  self.SetConnectionFun = function(self, connection, fun)
    connectionFuns[connection] = fun
  end

  self.RemoveConnectionFun = function(self, connection)
    connectionFuns[connection] = nil
  end
  
  self.ExitEventLoop = function(self)
    isRunning = false
  end

  self.RunEventLoop = function(self)

    -- Create a MoSync event object.
    local event = SysEventCreate()

    -- Set isRunning flag to true.
    isRunning = true
    
    -- This is the event loop.
    while isRunning do
      maWait(1000)
      while 0 ~= maGetEvent(event) do
        local eventType = SysEventGetType(event)
        if EVENT_TYPE_CLOSE == eventType then
          break -- Exit while loop.
        elseif EVENT_TYPE_KEY_PRESSED == eventType then
          if nil ~= keyDownFun then
            keyDownFun(SysEventGetKey(event))
          end
        elseif EVENT_TYPE_KEY_RELEASED == eventType then
          if nil ~= keyUpFun then
            keyUpFun(SysEventGetKey(event))
          end
        elseif EVENT_TYPE_POINTER_PRESSED == eventType then
          if nil ~= touchDownFun then
            touchDownFun(
              SysEventGetX(event),
              SysEventGetY(event),
              SysEventGetTouchId(event))
          end
        elseif EVENT_TYPE_POINTER_RELEASED == eventType then
          if nil ~= touchUpFun then
            touchUpFun(
              SysEventGetX(event),
              SysEventGetY(event),
              SysEventGetTouchId(event))
          end
        elseif EVENT_TYPE_POINTER_DRAGGED == eventType then
          if nil ~= touchDragFun then
            touchDragFun(
              SysEventGetX(event),
              SysEventGetY(event),
              SysEventGetTouchId(event))
          end
        elseif EVENT_TYPE_CONN == eventType then
          local connectionFun = connectionFuns[SysEventGetConnHandle(event)]
          if nil ~= connectionFun then
            connectionFun(
              SysEventGetConnHandle(event),
              SysEventGetConnOpType(event),
              SysEventGetConnResult(event))
          end
        elseif EVENT_TYPE_SENSOR == eventType then
          if nil ~= sensorFun then
            sensorFun(
              SysEventSensorGetType(event),
              SysEventSensorGetValue1(event),
              SysEventSensorGetValue2(event),
              SysEventSensorGetValue3(event))
          end
        else
          -- Handle other events in the default function.
          if nil ~= defaultFun then
            defaultFun(event)
          end
        end -- End of ifs

        -- Always pass the event to the any function.
        if nil ~= anyFun then
          anyFun(event, result)
        end
      end -- End of inner event loop
    end -- End of outer event loop

    -- Free the event object.
    SysFree(event)

  end -- End of function runEventLoop

  return self

end)()

-- Create the global Screen object
Screen = (function()

  local self = {}

  self.Width = function(self)
    return EXTENT_X(maGetScrSize())
  end

  self.Height = function(self)
    return EXTENT_Y(maGetScrSize())
  end

  self.SetColor = function(self, red, green, blue)
    maSetColor(blue + (green * 256) + (red * 65536))
  end

  self.FillRect = function(self, top, left, width, height)
    maFillRect(top, left, width, height)
  end

  self.Fill = function(self)
    self:FillRect(0, 0, self:Width(), self:Height())
  end

  self.Update = function(self)
    maUpdateScreen()
  end

  return self

end)()

