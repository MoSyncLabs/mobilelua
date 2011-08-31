# Script to generate bindings with tolua.
# First concatenates header files, then generates bindings.

require "FileUtils"

def sh(cmd)
  #TODO: optimize by removing the extra shell
  #the Process class should be useful.
  $stderr.puts cmd
  if (!system(cmd)) then
    error "Command failed: '#{$?}'"
  end
end

def convertPointerTypesToVoid(data)
  data.
    gsub("MAEvent*", "void*").
    gsub("MAPoint2d*", "void*").
    gsub("MARect*", "void*").
    gsub("MACopyData*", "void*").
    gsub("MAConnAddr*", "void*")
end

filesToConcatenate = 
  [
  "lua_maapi.h",
  "lua_special_bindings.h", 
  "lua_systemapi.h"
  ]

File.open("lua_maapi.pkg", "w") do |outFile|
  outFile.puts filesToConcatenate.map { |fileName| 
    convertPointerTypesToVoid(IO.read(fileName))
  }
end

sh "../../../tolua/bin/tolua.exe -o lua_maapi.c lua_maapi.pkg"
