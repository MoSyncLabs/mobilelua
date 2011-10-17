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
  Date: 2011-09-27

  LuaLive Client written in Lua.

  Still debugging the code...

  Use with the LuaLiveEditor found at mobilelua.org.

  Enter the ip address of the editor below in the
  variable SERVER_DEFAULT_ADDRESS.


  Protocol specification

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
local COMMAND_RUN_LUA_SCRIPT = 1

-- Reset the interpreter state.
local COMMAND_RESET = 2

-- Reply from client to server. After this command follows
-- a length int and a string of byte-size characters.
local COMMAND_REPLY = 3

-- Server address and port.
-- TODO: Change the server address to the one used on your machine.
-- When running in the Android emulator, use 10.0.2.2 for localhost.
local SERVER_DEFAULT_ADDRESS = "192.168.0.114"
--local SERVER_DEFAULT_ADDRESS = "10.0.2.2"
local SERVER_PORT = ":55555"

-- The connection object
local Connection

function Main()
  print("Welcome to Lua Live !")
  print("Press BACK or Key 0 to exit.")
  EventMonitor:OnKeyDown(OnKeyDown)
  ConnectToServer()
end

function OnKeyDown(key)
  if MAK_BACK == key or MAK_0 == key then
    maExit(0)
  end
end

function ConnectToServer()
  print("Connecting to " .. SERVER_DEFAULT_ADDRESS)
  Connection = SysConnectionCreate()
  Connection:Connect(
    "socket://" .. SERVER_DEFAULT_ADDRESS .. SERVER_PORT,
    ConnectionEstablished)
end

function ConnectionEstablished(result)
  if result > 0 then
    print("Successfully connected.")
    -- Read from server.
    ReadCommand()
  else
    print("Failed to connect - error: " .. result)
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
  local fun
  local resultOrErrorMessage
  local success = false
  -- Process the result.
  log("ScriptReceived")
  if result > 0 then
    -- Convert buffer to string.
    local script = SysBufferToString(buffer)
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

-- Create a low level type of connection object.
function SysConnectionCreate()
  local self = {}

  local mConnectionHandle

  local mConnectedFun
  local mReadDoneFun
  local mWriteDoneFun

  local mInBuffer
  local mNumberOfBytesToRead
  local mNumberOfBytesRead

  local mOutBuffer

  -- Connection listener function.
  self.ConnectionListener = function(connection, opType, result)
    if CONNOP_CONNECT == opType then
      -- First we get an event that confirms that the connection is created.
      log("CONNOP_CONNECT result: " .. result)
      mConnectedFun(result)
    elseif CONNOP_READ == opType then
      -- This is a confirm of a read or write operation.
      log("CONNOP_READ result: " .. result)
      if result > 0 then
        -- Update byte counters.
        mNumberOfBytesRead = mNumberOfBytesRead + result
        mNumberOfBytesToRead = mNumberOfBytesToRead - result
        if mNumberOfBytesToRead > 0 then
          -- There is more data to read, continue reading bytes
          -- into the input buffer.
          local pointer = SysBufferGetBytePointer(mInBuffer, mNumberOfBytesRead)
          maConnRead(mConnectionHandle, pointer, mNumberOfBytesToRead)
        else
          -- Done reading, zero terminate buffer and call callback function.
          SysBufferSetByte(mInBuffer, mNumberOfBytesRead, 0)
          mReadDoneFun(mInBuffer, result)
        end
      else
        -- There was an error, free input buffer and report it.
        SysFree(mInBuffer)
        mReadDoneFun(nil, result)
      end
    elseif CONNOP_WRITE == opType then
      log("CONNOP_WRITE result: " .. result)
      mWriteDoneFun(mOutBuffer, result)
    end
  end

  -- Connect to an address.
  self.Connect = function(self, connectString, connectedFun)
    mConnectionHandle = maConnect(connectString)
    mConnectedFun = connectedFun
    log("maConnect result: " .. mConnectionHandle)
    if mConnectionHandle > 0 then
      EventMonitor:SetConnectionFun(mConnectionHandle, self.ConnectionListener)
    else
      -- Error
      mConnectedFun(-1)
    end
  end

  -- Close a connection.
  self.Close = function()
    EventMonitor:RemoveConnectionFun(mConnectionHandle)
    maConnClose(mConnectionHandle)
  end

  -- Kicks off reading to a byte buffer. The connection
  -- listener function handles the read result.
  self.Read = function(self, numberOfBytes, readDoneFun)
    mNumberOfBytesToRead = numberOfBytes
    mNumberOfBytesRead = 0
    mReadDoneFun = readDoneFun
    -- Allocate input buffer. This will be handed to the readDoneFun
    -- on success. That function is responsible for deallocating it.
    -- We add one byte for a zero termination character.
    mInBuffer = SysAlloc(mNumberOfBytesToRead + 1)
    -- Start reading bytes into the input buffer.
    maConnRead(mConnectionHandle, mInBuffer, mNumberOfBytesToRead)
  end

  -- Kicks off writing from a byte buffer. The connection
  -- listener function handles the write result.
  self.Write = function(self, buffer, numberOfBytesToWrite, writeDoneFun)
    mOutBuffer = buffer
    mWriteDoneFun = writeDoneFun
    -- Start writing bytes.
    maConnWrite(mConnectionHandle, buffer, numberOfBytesToWrite)
  end

  return self
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
