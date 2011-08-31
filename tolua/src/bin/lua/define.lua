-- tolua: define class
-- Written by Waldemar Celes
-- TeCGraf/PUC-Rio
-- Jul 1998
-- $Id: define.lua,v 1.2 1999/07/28 22:21:08 celes Exp $

-- This code is free software; you can redistribute it and/or modify it.
-- The software provided hereunder is on an "as is" basis, and
-- the author has no obligation to provide maintenance, support, updates,
-- enhancements, or modifications. 


-- Define class
-- Represents a numeric const definition
-- The following filds are stored:
--   name = constant name
--   dataType = the type name of the constant type ("number" or "string")
classDefine = {
 name = '',
 dataType = 'unknown'
}
classDefine.__index = classDefine
setmetatable(classDefine,classFeature)

-- register define
function classDefine:register ()
 -- Determine if this is a numeric constant or a string constant
 if self.dataType == "number" then
  output(' tolua_constant(tolua_S,"'..self.lname..'",'..self.name..');')
 elseif self.dataType == "string" then
  output(' tolua_constant_string(tolua_S,"'..self.lname..'",'..self.name..');')
 else
  output(' // #define '..self.lname..' has unknown data type: '..self.dataType..'\n')
 end
end

-- Print method
function classDefine:print (ident,close)
 print(ident.."Define{")
 print(ident.." name = '"..self.name.."',")
 print(ident.." lname = '"..self.lname.."',")
 print(ident.." dataType = '"..self.dataType.."',")
 print(ident.."}"..close)
end


-- Internal constructor
function _Define (t)
 setmetatable(t,classDefine)
 t:buildnames()

 if t.name == '' then
  error("#invalid define")
 end

 append(t)
 return t
end

-- Constructor
-- Expects a string representing the constant name and a value.
function Define (n,t)
 return _Define{
  name = n,
  dataType = t
 }
end


