webview = maWidgetCreate(MAW_WEB_VIEW)
maWidgetSetProperty(webview, "width", "-1")
maWidgetSetProperty(webview, "height", "-1")
maWidgetSetProperty(webview, "enableZoom", "true")
screen = maWidgetCreate(MAW_SCREEN)
maWidgetAddChild(screen, webview)
maWidgetScreenShow(screen)

maWidgetSetProperty(webview, "html",
[==[
<!DOCTYPE html>
<html>
<head>
<style>
html
{
	/* Set page attributes. */
	margin: 0;
	padding: 0;
	width: 100%;
	height: 100%;
	background-color: #FFFFFF;

	/* Disable text selection in all browsers. */
	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-o-user-select: none;
	user-select: none;
}

#LogoBox
{
	/* Center element horizontally. */
	display: table;
	margin: auto auto;

	/* Set width of box. */
	width: 16em;

	/* Use a hand pointer. */
	cursor: pointer;
}

#TextBox
{
	/* Text attributes. */
	font-size: 2.5em;
	font-family: sans-serif;
	font-weight: bold;
	text-align: center;
}
</style>

<script>
function OnTouch()
{
	var textBox = document.getElementById("TextBox");
	textBox.innerHTML = "Hello!";
}
</script>
</head>

<body>
<div id="LogoBox" onclick="OnTouch()">
	<div id="TextBox">Click Me!</div>
</div>
</body>
</html>
]==])



maWidgetSetProperty(webview, "url", 
[=[javascript:
	var textBox = document.getElementById("TextBox");
	textBox.innerHTML = "Click Me!";
]=])

maWidgetRemoveChild(webview)

maWidgetSetProperty(webview, 
  MAW_WEB_VIEW_URL, 
  "javascript:alert('Hello\\nWorld')")

maWidgetSetProperty(webview, 
  "url", 
  "javascript:alert('Hello\\nWorld')")
  
maWidgetSetProperty(webview,"url",
   "javascript:document.location=\"lua://log('Hello')\"")

maWidgetSetProperty(webview,MAW_WEB_VIEW_HARD_HOOK,
				"lua://.*")
EventMonitor:OnWidget(function(widgetEvent)
  log("OnWidget1 "..SysWidgetEventGetType(widgetEvent))
  if MAW_EVENT_WEB_VIEW_HOOK_INVOKED == SysWidgetEventGetType(widgetEvent) then 
    log("OnWidget2 "..SysWidgetEventGetUrlData(widgetEvent))
    maDestroyObject(SysWidgetEventGetUrlData(widgetEvent))
  end
end)



maWidgetSetProperty(webview, "url", "javascript:"..js)


maWidgetSetProperty(webview, "html",
[==[
<!DOCTYPE html>
<!--
	This application shows how to communicate from JavaScript to C++.
	When the LogoBox is touched, a call is made to C++ to make the
	device vibrate. The C++ code that gets called is in main.cpp.
-->
<html>
<head>
<style>
html
{
	/* Set page attributes. */
	margin: 0;
	padding: 0;
	width: 100%;
	height: 100%;
	background-color: #FFFFFF;

	/* Disable text selection in all browsers. */
	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-o-user-select: none;
	user-select: none;
}

#LogoBox
{
	/* Center element horizontally. */
	display: table;
	margin: auto auto;

	/* Set width of box. */
	width: 16em;

	/* Use a hand pointer. */
	cursor: pointer;
}

#TextBox
{
	/* Text attributes. */
	font-size: 2.5em;
	font-family: sans-serif;
	font-weight: bold;
	text-align: center;
}
</style>

<!--
	Import the bridge library for communication between
	JavaScript and C++.
-->
<script src="js/bridge.js"></script>

<script>
/**
 * Array with texts for the TextBox.
 */
var TextArray = ["Hello World! Touch Me!", "Welcome to MoSync and HTML5!"];

/**
 * Change the text in the TextBox. Swaps between array elements.
 */
function SwapText()
{
	var textBox = document.getElementById("TextBox");
	if (textBox.innerHTML == TextArray[0])
	{
		textBox.innerHTML = TextArray[1];
	}
	else
	{
		textBox.innerHTML = TextArray[0];
	}
}

/**
 * Make device vibrate and update the text shown
 * in the user interface.
 */
function OnTouch()
{
	SwapText();
}
</script>
</head>

<body>
<div id="LogoBox" onclick="OnTouch()">
	<div id="TextBox"></div>
</div>
</body>
<script>
	// Page elements has loaded, show initial text.
	SwapText();
</script>
</html>
]==])
