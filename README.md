MobileLua
=========

MobileLua is a port of Lua to [MoSync](http://mosync.com/), a C/C++ 
cross-platform development system for mobile devices. This enables Lua 
to be used on a wide range of mobile devices.

MoSync does not yet support exceptions or setjmp/longjmp, so Lua error handling 
is replaced with return in case of errors and check for error status. 
This is not implemented for all error conditions, so for some errors you can 
get incomplete error information, or in the worst case the program may crash.

Example program
---------------

    -- MOBILELUA BEGIN
    
    -- PaintDemoBasic.lua
    -- Author: Mikael Kindborg
    -- Date: 2011-02-23
    -- Description: Simple paint program demo. Supports multi-touch!
    
    -- Fill screen with background color.
    Screen.setColor(255, 255, 255)
    Screen.fillRect(0, 0, Screen.getWidth(), Screen.getHeight())
    Screen.update()
    
    -- Function that paints a "brush stamp" on the screen.
    function paint(x, y, touchId)
      if touchId == 0 then 
        Screen.setColor(0, 0, 0) 
      else
        Screen.setColor(0, 200, 0) 
      end
      Screen.fillRect(x - 20, y - 20, 40, 40)
      Screen.update()
    end
    
    -- Bind the paint function to touch events.
    System.onTouchDown(paint)
    System.onTouchDrag(paint)
    
    -- Enter the system event loop (blocking call, events
    -- will be dispatched to registered event functions).
    System.runEventLoop()


Contact
-------

mikael.kindborg@mosync.com
mikael.kindborg@gmail.com

License
-------

Unless stated otherwise, the MIT license is used for the source code.

Each source file should contain a license heder.
