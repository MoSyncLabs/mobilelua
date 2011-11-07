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
--]]

--[[

  File: LuaLiveClient.lua
  Author: Mikael Kindborg
  Date Created: 2011-09-27

  LuaLive Client written in Lua.

  Use with the LuaLiveEditor found at https://github.com/divineprog/mobilelua

  Enter the ip address of the editor below in the
  variable SERVER_DEFAULT_ADDRESS.

  Protocol specification:

  The first 4 bytes of a message is a command integer.
  The next 4 bytes is an integer with the size of the rest
  of the message.

  After these binary integer values follows the message content,
  if any. There is always a size integer, event if there is
  no content. This is done to simplify the protocol implementation.
  If there is no data, the size should be zero.

  Thus we have:

    command - 4 byte integer
    data size - 4 byte integer, is 0 if there is no data
    optional data

--]]

-- Command constants.

-- Run Lua code on the client. After this command follows
-- a length int and a string of byte-size characters.
COMMAND_RUN_LUA_SCRIPT = 1

-- Reset the interpreter state.
COMMAND_RESET = 2

-- Reply from client to server. After this command follows
-- a length int and a string of byte-size characters.
COMMAND_REPLY = 3

-- Server address and port.
-- TODO: Change the server address to the one used on your machine.
-- When running in the Android emulator, use 10.0.2.2 for localhost.
--local SERVER_DEFAULT_ADDRESS = "192.168.0.114"
SERVER_DEFAULT_ADDRESS = "10.0.2.2"
SERVER_PORT = ":55555"

-- The connection object.
Connection = nil

-- Function used for printing. Is set below.
Info = nil

function Main()
  UseTextBasedUI()
  --UseGraphicalUI()
end

-- Create a text-based user interface,
-- this will work on all MoSync platforms.
-- But you will have to edit the hardcoded
-- IP-address.
function UseTextBasedUI()
  Info = print
  Info("Welcome to Lua Live !")
  Info("Press BACK or Key 0 to exit.")
  EventMonitor:OnKeyDown(OnKeyDown)
  ConnectToServer(SERVER_DEFAULT_ADDRESS)
end

-- Create a UI with a WebView for the start-up screen
-- of the client. This will work on platforms that
-- support NativeUI.
function UseGraphicalUI()
  Info = log
  
  -- Enable to use back key on Android to exit app.
  EventMonitor:OnKeyDown(OnKeyDown)
  
  -- Create and show a WebView widget.
  local webview = maWidgetCreate(MAW_WEB_VIEW)
  maWidgetSetProperty(webview, MAW_WIDGET_WIDTH, "-1")
  maWidgetSetProperty(webview, MAW_WIDGET_HEIGHT, "-1")
  maWidgetSetProperty(webview, MAW_WEB_VIEW_ENABLE_ZOOM, "true")
  local screen = maWidgetCreate(MAW_SCREEN)
  maWidgetAddChild(screen, webview)
  maWidgetScreenShow(screen)

  -- HTML for the WebView.
  maWidgetSetProperty(webview, MAW_WEB_VIEW_HTML,
[==[
<!DOCTYPE html>
<html>
<head>
<script>
function EvalLuaScript(script)
{
  window.location = "lua://" + script
}

function Connect()
{
  EvalLuaScript("ConnectToServer('10.0.2.2')")
}
</script>
</head>

<body>
<div id="MainUI">
  <div id="Heading">Welcome to the LuaLive client!</div> 
  <div id="Instruction">Enter the ip-address or the LuaLive Editor 
    and connect.</div>
  <input
    id="ServerIPAddress"
    type="text"
    value="10.0.2.2"/>
  <input 
    id="ConnectButton"
    type="button"
    value="Connect"
    onclick="Connect()"/>
</div>
</body>
</html>
]==])

  -- Set hook pattern.
  maWidgetSetProperty(webview, MAW_WEB_VIEW_HARD_HOOK, "lua://.*")
  
  -- Function used for processing hook events.
  EventMonitor:OnWidget(HandleWidgetEvent)
end

function OnKeyDown(key)
  if MAK_BACK == key or MAK_0 == key then
    maExit(0)
  end
end

-- Process the HOOK_INVOKED event.
function HandleWidgetEvent(widgetEvent)
  if MAW_EVENT_WEB_VIEW_HOOK_INVOKED == SysWidgetEventGetType(widgetEvent) then
    -- Get the url string.
    local urlData = SysWidgetEventGetUrlData(widgetEvent)
    local url = SysLoadStringResource(urlData)
    -- Get the Lua script.
    local start,stop = url:find("lua://")
    if nil ~= start then
      local script = url:sub(stop + 1)
      local fun = loadstring(script)
      if nil ~= fun then
        pcall(fun)
      end
    end
    maDestroyObject(urlData)
  end
end

function ConnectToServer(serverAddress)
  Info("Connecting to " .. serverAddress)
  Connection = SysConnectionCreate()
  Connection:Connect(
    "socket://" .. serverAddress .. SERVER_PORT,
    ConnectionEstablished)
end

function ConnectionEstablished(result)
  if result > 0 then
    Info("Successfully connected.")
    -- Read from server.
    ReadCommand()
  else
    Info("Failed to connect - error: " .. result)
  end
end

function ReadCommand()
  -- Read from server.
  log("ReadCommand")
  Connection:Read(8, MessageHeaderReceived)
end

function MessageHeaderReceived(buffer, result)
  -- Process the result.
  log("MessageHeaderReceived")
  if result > 0 then
    local command = BufferReadInt(buffer, 0)
    local dataSize = BufferReadInt(buffer, 4)
    if COMMAND_RUN_LUA_SCRIPT == command then
      -- Read script and evaluate it when recieved.
      Connection:Read(dataSize, ScriptReceived)
    end
  end
  -- Free the result buffer.
  if nil ~= buffer then
    SysFree(buffer)
  end
end

function ScriptReceived(buffer, result)
  -- Process the result.
  log("ScriptReceived")
  if result > 0 then
    -- Convert buffer to string.
    local script = SysBufferToString(buffer)
    local fun
    local resultOrErrorMessage
    local success = false
    -- Parse script.
    fun, resultOrErrorMessage = loadstring(script)
    if nil ~= fun then
      -- Parsing succeeded, evaluate script.
      success, resultOrErrorMessage = pcall(fun)
      if not success then
        resultOrErrorMessage = "Error: " .. resultOrErrorMessage
        log("Failed to evaluate script. " .. resultOrErrorMessage)
      end
    end
    -- Write response.
    WriteResponse(resultOrErrorMessage)
  end
  -- Free the result buffer.
  if nil ~= buffer then
    SysFree(buffer)
  end
end

function WriteResponse(value)
  log("WriteResponse")
  if nil == value then
    value = "Undefined"
  end
  local response = "Lua Result: " .. value
  -- Allocate buffer for the reply, reader plus string data.
  local dataSize = response:len()
  local buffer = SysAlloc(8 + dataSize)
  BufferWriteInt(buffer, 0, COMMAND_REPLY)
  BufferWriteInt(buffer, 4, dataSize)
  BufferWriteString(buffer, 8, response)
  Connection:Write(buffer, 8 + dataSize, WriteResponseDone)
end

function WriteResponseDone(buffer, result)
  log("Response written - result: " .. result)
  if nil ~= buffer then SysFree(buffer) end
  ReadCommand()
end

function BufferReadInt(buffer, index)
  return SysBufferGetInt(buffer, index / 4)
end

function BufferWriteInt(buffer, index, value)
  SysBufferSetByte(buffer, index, SysBitAnd(value, 255));
  SysBufferSetByte(buffer, index + 1, SysBitAnd(SysBitShiftRight(value, 8), 255));
  SysBufferSetByte(buffer, index + 2, SysBitAnd(SysBitShiftRight(value, 16), 255));
  SysBufferSetByte(buffer, index + 3, SysBitAnd(SysBitShiftRight(value, 24), 255));
end

-- Write a Lua string to a buffer.
-- Note that in Lua first element has index one,
-- in a C buffer first byte has index zero.
function BufferWriteString(buffer, index, theString)
  local bufferIndex = index
  local stringIndex = 1
  for c in theString:gmatch(".") do
    local b = theString:byte(stringIndex)
    --log("Char: " .. c)
    --log("Byte: " .. b)
    SysBufferSetByte(buffer, bufferIndex, b)
    bufferIndex = bufferIndex + 1
    stringIndex = stringIndex + 1
  end
end

-- Start the program
Main()
