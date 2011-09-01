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

The following is a very simple paint application. Supports multi-touch.
    
    -- Fill screen with background color.
    Screen:SetColor(255, 255, 255)
    Screen:Fill()
    Screen:Update()
    
    -- Function that paints a "brush stamp" on the screen.
    function Paint(x, y, touchId)
      if touchId == 0 then 
        Screen:SetColor(0, 0, 0) 
      else
        Screen:SetColor(0, 200, 0) 
      end    
      Screen:FillRect(x - 20, y - 20, 40, 40)
      Screen:Update()
    end    
    
    -- Bind the Paint function to touch events.
    EventMonitor:OnTouchDown(Paint)
    EventMonitor:OnTouchDrag(Paint)

Contact
-------

mikael.kindborg@mosync.com  
mikael.kindborg@gmail.com

License
-------

Unless stated otherwise, the MIT license is used for the source code.

Each source file should contain a license header.
