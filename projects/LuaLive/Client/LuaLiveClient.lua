--[[

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
local = COMMAND_RUN_LUA_SCRIPT 1

-- Reset the interpreter state.
local = COMMAND_RESET 2

-- Reply from client to server. After this command follows
-- a length int and a string of byte-size characters.
local = COMMAND_REPLY 3

-- Server address and port.
local SERVER_DEFAULT_ADDRESS = "192.168.0.187"
--#define SERVER_DEFAULT_ADDRESS "modev.mine.nu"
local SERVER_PORT = ":55555"
local SERVER_URL_LOCALHOST = "socket://localhost:55555"

-- The connection object
local Connection

function ConnectToServer()
  Connection = SysConnectionCreate()
  Connection:Connect(
    "socket://" .. SERVER_DEFAULT_ADDRESS .. SERVER_PORT,
	ConnectionEstablished)
end

function ConnectionEstablished(result)
  -- Read from server.
  ReadCommand()
end

function ReadCommand()
  -- Read from server.
  Connection:Read(8, MessageHeaderRecieved)
end

function MessageHeaderReceived(buffer, result)
  -- Process the result.
  if result > 0 then
    local command = BufferReadInt(buffer, 0)
    local dataSize = BufferReadInt(buffer, 4)
	if COMMAND_RUN_LUA_SCRIPT == command then
	  -- Read script and evaluate it when recieved.
	  Connection:Read(dataSize, ScriptRecieved)
	end
  end
  -- Free the result buffer.
  if nil ~= buffer then
    SysFree(buffer)
  end
end

function ScriptReceived(buffer, result)
  -- Process the result.
  if result > 0 then
    -- Convert buffer to string.
	local script = SysBufferToString(buffer)
    -- Evaluate script.
	local fun = loadstring(script)
    pcall(fun)
	-- Write response.
	WriteResponse()
  end
  -- Free the result buffer.
  if nil ~= buffer then
    SysFree(buffer)
  end
end

function WriteResponse()
  local response = "Script Evaluated"
  local buffer = SysAlloc(response:len())
  BufferWriteString(buffer, 0, response)
  Connection:Write(buffer, response:len(), WriteResponseDone)
end

function WriteResponseDone(buffer, result)
  print("Response written - result: " .. result)
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
  
  -- Connect to an address.
  self.Connect(self, connectString, connectedFun)
    mConnectionHandle = maConnect(connectString)
	mConnectedFun = connectedFun
    print("maConnect result: " .. connectionHandle)
    if connectionHandle > 0 then
      EventMonitor:SetConnectionFun(mConnectionHandle, mConnectionListenerFun)
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
  
  -- Connection listener function.
  local mConnectionListenerFun = function(connection, opType, result)
    if CONNOP_CONNECT == opType then
	  -- First we get an event that confirms that the connection is created.
      print("CONNOP_CONNECT result: " .. result)
	  mConnectionDoneFun(result)
    elseif CONNOP_READ == opType then
	  -- This is a confirm of a read or write operation.
      print("CONNOP_READ result: " .. result)
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
      print("CONNOP_WRITE result: " .. result)
	  mWriteDoneFun(mOutBuffer, result)
    end
  end
  
  return self
end

function BufferReadInt(buffer, index)
  return SysBufferGetInt(buffer, index / 4)
end

function BufferWriteInt(buffer, index, value)
  SysBufferSetByte(buffer, index, SysBitAnd(value, 255));
  SysBufferSetByte(buffer, index + 1, SysBitAnd(SysBitShiftRight(value, 8), 255)));
  SysBufferSetByte(buffer, index + 2, SysBitAnd(SysBitShiftRight(value, 16), 255)));
  SysBufferSetByte(buffer, index + 3, SysBitAnd(SysBitShiftRight(value, 24), 255)));
end

-- Write string to a buffer.
-- Note that in Lua first element has index one,
-- in a C buffer first byte has index zero.
function BufferWriteString(buffer, index, theString)
  --print(theString)
  local i = index
  for c in theString:gmatch(".") do
    i = i + 1
    local b = theString:byte(i)
    --print("Char: " .. c)
    --print("Byte: " .. b)
    SysBufferSetByte(buffer, i - 1, b)
  end
  -- Return number of bytes written to buffer.
  return i
end

