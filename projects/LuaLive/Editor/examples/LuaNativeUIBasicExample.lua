--[[
File: LuaNativeUIBasicExample.lua
Author: Mikael Kindborg
Description: Very basic demo of NativeUI in Lua.

This example uses global variables for the Widgets, to make
it possible to interactively experiment with the UI using
the LuaLive editor.

First press "Run program" in the editor to run all of the
code in this file. That will create the UI.

Then you can run code interactively. Here are some things
to try. Select a line of code, then press "Do selection".

maWidgetSetProperty(MessageLabel, MAW_LABEL_FONT_SIZE, "60")
maWidgetRemoveChild(MessageLabel)
maWidgetAddChild(MainLayout, MessageLabel)
maExit(0)
--]]

-- Widget size values as strings (the MAW_CONSTANT_* values
-- are integers and cannot be used with maWidgetSetProperty).
FILL_PARENT = ""..MAW_CONSTANT_FILL_AVAILABLE_SPACE
WRAP_CONTENT = ""..MAW_CONSTANT_WRAP_CONTENT

-- Create screen with widgets.
Screen = maWidgetCreate(MAW_SCREEN)

MainLayout = maWidgetCreate(MAW_VERTICAL_LAYOUT)
maWidgetSetProperty(MainLayout, MAW_WIDGET_WIDTH, FILL_PARENT)
maWidgetSetProperty(MainLayout, MAW_WIDGET_HEIGHT, FILL_PARENT)
maWidgetSetProperty(MainLayout, MAW_WIDGET_BACKGROUND_COLOR, "000000")
maWidgetAddChild(Screen, MainLayout)

MessageLabel = maWidgetCreate(MAW_LABEL)
maWidgetSetProperty(MessageLabel, MAW_WIDGET_WIDTH, FILL_PARENT)
maWidgetSetProperty(MessageLabel, MAW_WIDGET_HEIGHT, WRAP_CONTENT)
maWidgetSetProperty(MessageLabel, MAW_LABEL_FONT_SIZE, "36")
maWidgetSetProperty(MessageLabel, MAW_LABEL_FONT_COLOR, "AAAAAA")
maWidgetSetProperty(MessageLabel, MAW_LABEL_TEXT, "Demo of MoSync NativeUI")
maWidgetAddChild(MainLayout, MessageLabel)

ButtonSayHello = maWidgetCreate(MAW_BUTTON)
maWidgetSetProperty(ButtonSayHello, MAW_WIDGET_WIDTH, FILL_PARENT)
maWidgetSetProperty(ButtonSayHello, MAW_WIDGET_HEIGHT, WRAP_CONTENT)
maWidgetSetProperty(ButtonSayHello, MAW_BUTTON_TEXT_VERTICAL_ALIGNMENT, MAW_ALIGNMENT_CENTER)
maWidgetSetProperty(ButtonSayHello, MAW_BUTTON_TEXT_HORIZONTAL_ALIGNMENT, MAW_ALIGNMENT_CENTER)
maWidgetSetProperty(ButtonSayHello, MAW_BUTTON_FONT_SIZE, "24")
maWidgetSetProperty(ButtonSayHello, MAW_BUTTON_TEXT, "Say Hello")
maWidgetAddChild(MainLayout, ButtonSayHello)

ButtonSayHi = maWidgetCreate(MAW_BUTTON)
maWidgetSetProperty(ButtonSayHi, MAW_WIDGET_WIDTH, FILL_PARENT)
maWidgetSetProperty(ButtonSayHi, MAW_WIDGET_HEIGHT, WRAP_CONTENT)
maWidgetSetProperty(ButtonSayHi, MAW_BUTTON_TEXT_VERTICAL_ALIGNMENT, MAW_ALIGNMENT_CENTER)
maWidgetSetProperty(ButtonSayHi, MAW_BUTTON_TEXT_HORIZONTAL_ALIGNMENT, MAW_ALIGNMENT_CENTER)
maWidgetSetProperty(ButtonSayHi, MAW_BUTTON_FONT_SIZE, "24")
maWidgetSetProperty(ButtonSayHi, MAW_BUTTON_TEXT, "Say Hi")
maWidgetAddChild(MainLayout, ButtonSayHi)

-- Show screen.
maWidgetScreenShow(Screen)

-- Create a widget event listener.
EventMonitor:OnWidget(function(widgetEvent)
  if ButtonSayHello == SysWidgetEventGetHandle(widgetEvent) then
    maWidgetSetProperty(MessageLabel, MAW_LABEL_TEXT, "Hello World!")
  elseif ButtonSayHi == SysWidgetEventGetHandle(widgetEvent) then
    maWidgetSetProperty(MessageLabel, MAW_LABEL_TEXT, "Hi there!")
  end
end)
