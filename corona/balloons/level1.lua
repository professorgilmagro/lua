-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()

-- include Corona's "physics" library
local physics = require "physics"
physics.start(); physics.pause()

-- include Corona's "widget" library
local widget = require "widget"

-- config do level
local settings = {
	maxBalloons = 100, 
	timeLimit = 30
}

-----------------------------------------------------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfscreenW = display.contentWidth, display.contentHeight, display.contentWidth * 0.5

function scene:create( event )
	local sceneGroup = self.view

	local background = display.newImage( "images/clouds.png", true )
	background.x = display.contentCenterX
	background.y = display.contentCenterY

	local options = {
		width = 59,
		height = 68,
		numFrames = 7,
		sheetContentWidth = 413, 
		sheetContentHeight = 68
	}

	local balloonSheet = graphics.newImageSheet( "images/sprite_sheet.png", options )
	local balloonSequenceData = {
		{ name="balloon", start=1, count=7, time=600, loopCount=1 },
	}

	local backgroundMusic = audio.loadStream( "sounds/music.mp3" )
	local popSound = audio.loadStream( "sounds/balloonPop.mp3" )
	local backgroundMusicChannel = audio.play( backgroundMusic, { channel=1, loops=-1, fadein=5000 } )

	local screenText = display.newText( "Carregando...", 0, 0, native.systemFont, 12 )
	screenText.x = screenW / 2
	screenText.y = screenH - 40

	local timeText = display.newText( "Time: "..settings["timeLimit"], 0, 0, native.systemFont, 14 )
	timeText.x = 60
	timeText.y = 40
	timeText:setTextColor( 0, 255, 255 )

	score = 0
	local scoreText = display.newText( "Score: "..score, 0, 0, native.systemFont, 14 )
	scoreText.x = screenW - 40
	scoreText.y = 40
	scoreText:setTextColor( 255, 255, 0 )

	physics.setGravity( 0, -0.4 )

	-- Paredes e teto
	local leftWall = display.newRect( 0, 0, 1, screenH * 2 )
	local rightWall = display.newRect( screenW, 0, 1, screenH * 2 )
	local ceiling = display.newRect( 0, 20, screenW * 2, 1 )

	ceiling.alpha = 0
	physics.addBody( leftWall, "static", { bounce=0.1 } )
	physics.addBody( rightWall, "static", { bounce=0.1 } )
	physics.addBody( ceiling, "static", { bounce=0.4 } )

	countBalloons = 0
	timeLeft = false
	playerReady = true

	function startGame()
		local imgBalloon = display.newSprite( balloonSheet, balloonSequenceData )
		imgBalloon:setFrame( 1 )
		imgBalloon:setSequence( "balloon" )

		imgBalloon.x = math.random( 50, screenW - 50 )
		imgBalloon.alpha = math.random( 10, 100 ) / 100
		imgBalloon.y = screenH + 10
		imgBalloon:scale( 0.5, 0.6 )

		physics.start()
		physics.addBody( imgBalloon, "dynamic", {density=0.1, friction=0, bounce=0.9, radius=12 } )
		sceneGroup:insert( imgBalloon )
		countBalloons = countBalloons + 1

		if ( countBalloons == settings["maxBalloons"] ) then
			screenText.isVisible = false
		end

		function imgBalloon:touch( e )
			if ( not timeLeft ) then
				if ( playerReady == true and e.phase == "ended" ) then
					audio.play( popSound, {  duration = 100 } )
					imgBalloon:play()
				end
			end
		end

		function onSpriteEvent( e )
			if ( not timeLeft ) then
				if ( playerReady == true and e.phase == "ended" ) then
					score = score + 1
					removeBalloon( e.target )
				end
			end
		end

		imgBalloon:addEventListener( "touch", imgBalloon )
		imgBalloon:addEventListener( "sprite", onSpriteEvent )
	end

	function removeBalloon( balloon )
		balloon:removeSelf()
		countBalloons = countBalloons - 1
		if ( not timeLeft ) then
			scoreText.text = "Score: "..score
			
			if ( countBalloons == 0 ) then
				gameExec( "winner" )
			elseif ( countBalloons <= 30 ) then
				gameExec( "notbad" )
			elseif ( countBalloons > 30 ) then
				gameExec( "loser" )
			end
		end
	end

	function gameExec( cmd )
		screenText.isVisible = true
		if ( cmd == "winner" ) then
			screenText.text = "Parabéns!"
		elseif ( cmd == "notbad" ) then
			screenText.text = "Nada mal!"
		elseif ( cmd == "loser" ) then
			screenText.text = "Você pode ser melhor."
		end
	end

	function onMenuBtnReturn()
		composer.gotoScene( "menu", "fade", 500 )
		return true
	end

	currentTime = settings["timeLimit"]
	function countDown( e )
		currentTime = currentTime - 1
		
		if ( currentTime == 0 ) then
			playerReady = false
			timeLeft = false
			screenText.text = "Game Over!"
			screenText.size = 40
			screenText.y = display.contentCenterY
			screenText.x = display.contentCenterX
			local s = display.newRect( scoreText.x, scoreText.y, scoreText.width, scoreText.height )
			s.alpha = 0
			s.scaleY = 2
			physics.addBody( s, "static", {bounce=1.5 } )
			audio.stop( backgroundMusicChannel  )

			menuBtn = widget.newButton{
				label = "Menu",
				labelColor = { default={0, 255, 0}, over={128} },
				width = 154, height = 40,
				defaultFile = "images/button.png",
				onRelease = onMenuBtnReturn
			}

			menuBtn.x = display.contentCenterX
			menuBtn.y = display.contentCenterY + 60
			sceneGroup:insert( menuBtn )

		end

		timeText.text = "Time: "..currentTime
	end

	-- all display objects must be inserted into group
	sceneGroup:insert( background )
	sceneGroup:insert( timeText )
	sceneGroup:insert( scoreText )
	sceneGroup:insert( screenText )
	sceneGroup:insert( leftWall )
	sceneGroup:insert( rightWall )
	sceneGroup:insert( ceiling )
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		physics.start()

		local gameTimer = timer.performWithDelay( 20, startGame, settings["maxBalloons"] )
		gameTimer = timer.performWithDelay( 1000, countDown, settings["timeLimit"] )
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	
	local phase = event.phase
	
	if event.phase == "will" then
		physics.stop()
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	
	
end

function scene:destroy( event )
	local sceneGroup = self.view

	if menuBtn then
		menuBtn:removeSelf()
		menuBtn = nil
	end
	
	package.loaded[physics] = nil
	physics = nil
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene