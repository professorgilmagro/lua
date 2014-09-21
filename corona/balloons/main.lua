system.activate( "multitouch" )

local physics = require( "physics" )
physics.setDrawMode("normal")

local background = display.newImage( "images/clouds.png", true )
background.x = display.contentCenterX
background.y = display.contentCenterY


display.setStatusBar( display.HiddenStatusBar )

local ball = display.newImageRect( "images/balloon.png", 25, 25 )

H = display.contentHeight
W = display.contentWidth

local backgroundMusic = audio.loadStream( "sounds/music.mp3" )
local popSound = audio.loadStream( "sounds/balloonPop.mp3" )

local backgroundMusicChannel = audio.play( backgroundMusic, { channel=1, loops=-1, fadein=5000 } )

local screenText = display.newText( "Carregando...", 0, 0, native.systemFont, 12 )
screenText.x = W / 2
screenText.y = H - 40

currentTime = 20
local timeText = display.newText( "Time: "..currentTime, 0, 0, native.systemFont, 14 )
timeText.x = 60
timeText.y = 40
timeText:setTextColor( 0, 255, 255 )

score = 0
local scoreText = display.newText( "Score: "..score, 0, 0, native.systemFont, 14 )
scoreText.x = W - 40
scoreText.y = 40
scoreText:setTextColor( 255, 255, 0 )

physics.start()
physics.setGravity( 0, -0.4 )

-- Paredes e teto
local leftWall = display.newRect( 0, 0, 1, H * 2 )
local rightWall = display.newRect( W, 0, 1, H * 2 )
local ceiling = display.newRect( 0, 0, W * 2, 1 )
totalTime = 20

physics.addBody( leftWall, "static", { bounce=0.1 } )
physics.addBody( rightWall, "static", { bounce=0.1 } )
physics.addBody( ceiling, "static", { bounce=0.1 } )

countBalloons = 0
timeLeft = false
playerReady = true
numBalloons = 100
local function startGame()
	local imgBalloon = display.newImageRect( "images/balloon.png", 25, 25 )
	imgBalloon.x = math.random( 50, W - 50 )
	imgBalloon.alpha = math.random( 1, 100 ) / 100
	imgBalloon.y = (H + 10)
	physics.addBody( imgBalloon, "dynamic", {density=0.1, friction=0, bounce=0.9, radius=12 } )
	countBalloons = countBalloons + 1

	if ( countBalloons == numBalloons ) then
		screenText.isVisible = false
	end

	function imgBalloon:touch(e)
		if ( not timeLeft ) then
			if ( playerReady == true and e.phase == "ended" ) then
				audio.play( popSound )
				score = score + 1
				removeBalloon( self )
			end
		end
	end

	imgBalloon:addEventListener( "touch", imgBalloon )
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

local function countDown( e )
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
		physics.addBody( s, "static", {bounce=0.5 } )
		audio.stop( backgroundMusicChannel  )
	end

	timeText.text = "Time: "..currentTime
end

local gameTimer = timer.performWithDelay( 20, startGame, numBalloons )
gameTimer = timer.performWithDelay( 1000, countDown, totalTime )
