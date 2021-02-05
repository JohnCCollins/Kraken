function love.load()

    -- love.window.setMode(1000, 800)
    math.randomseed(os.time())

   
    anim8 = require 'libraries/anim8/anim8'
    Timer = require "libraries/hump/timer"

    defaultFont = love.graphics.newFont('Ocean-9mZL.ttf', 30)
    titleFont = love.graphics.newFont('Ocean-9mZL.ttf', 200)

    love.graphics.setBackgroundColor( 0, .4, .73 )
    love.mouse.setVisible(false)

    -- sounds = {}
    -- sounds.music = love.audio.newSource('sounds/krakentheme.mp3', 'stream')
    -- sounds.splash = love.audio.newSource('sounds/Splash.mp3', 'static')
    -- sounds.wreck = love.audio.newSource('sounds/Wreckage.mp3', 'static')
    -- sounds.growl = love.audio.newSource('sounds/Growl.mp3', 'static')
    -- splash = sounds.splash:clone()
    -- wreck = sounds.wreck:clone()

    sprites = {}
    sprites.background = love.graphics.newImage('sprites/ocean.png')
    sprites.kraken = love.graphics.newImage('sprites/kraken.png')
    sprites.eye = love.graphics.newImage('sprites/eyes.png')
    sprites.arm = love.graphics.newImage('sprites/tentacle.png')
    sprites.ship = love.graphics.newImage('sprites/galleon.png')
    sprites.shipScore = love.graphics.newImage('sprites/shipscore.png')
    sprites.wake = love.graphics.newImage('sprites/wake.png')

    kraken = {}
    kraken.x = love.graphics.getWidth() / 2
    kraken.y = love.graphics.getHeight() / 2

    eyes = {}
    eyes.x = kraken.x
    eyes.y = kraken.y

    ships = {}
    arms = {}

    local grid = anim8.newGrid(164, 128, sprites.arm:getWidth(), sprites.arm:getHeight())
    local hGrid = anim8.newGrid(142, 142, sprites.kraken:getWidth(), sprites.kraken:getHeight())
    local oGrid = anim8.newGrid(800, 600, sprites.background:getWidth(), sprites.background:getHeight())
    local sGrid = anim8.newGrid(143, 118, sprites.ship:getWidth(), sprites.ship:getHeight())
    local wGrid = anim8.newGrid(2, 2, sprites.wake:getWidth(), sprites.wake:getHeight())
    animations = {}
    animations.background = anim8.newAnimation(oGrid('4-1',1), 0.2)
    animations.arm = anim8.newAnimation(grid('1-15',1), 0.044)
    animations.surface = anim8.newAnimation(grid('1-14',2), 0.025)
    animations.submerge = anim8.newAnimation(grid('1-15',3), 0.030)
    animations.head = anim8.newAnimation(hGrid('1-5',1), 0.125)
    animations.cursor = anim8.newAnimation(grid('1-2',2), 0.55)
    animations.shipFront = anim8.newAnimation(sGrid('1-4',1), 0.15)
    animations.shipBack = anim8.newAnimation(sGrid('1-4',2), 0.15)
    animations.shipSide = anim8.newAnimation(sGrid('1-4',3), 0.15)
    animations.wreck = anim8.newAnimation(sGrid('1-4',4), 0.15)
    animations.wake = anim8.newAnimation(wGrid('1-4',1), 0.15)

    kraken.animation = animations.arm

    gameState = 1
    maxTime = 45
    timer = maxTime

    shipCount = 500
    armCount = 0

    killcount = 0 

    if gameState == 2 then
        spawnShip()
        -- love.audio.play(sounds.music)
    end    
end

function love.update(dt)
    empty()
    if armCount >= 8 then
        armCount = 8
    elseif armCount < 0 then
        armCount = 0
    end
    
    if gameState == 2 then
        for i,s in ipairs(ships) do
            if s.type == 5 then
                s.x = s.x + math.cos( shipKrakenAngle(s) + 20 ) * s.speed * dt
                s.y = s.y + math.sin( shipKrakenAngle(s) + 20) * s.speed * dt
            elseif s.type == 6 then
                s.x = s.x + math.cos( shipKrakenAngle(s) - 20) * s.speed * dt
                s.y = s.y + math.sin( shipKrakenAngle(s) - 20) * s.speed * dt
            else
                s.x = s.x + math.cos( shipKrakenAngle(s)) * s.speed * dt
                s.y = s.y + math.sin( shipKrakenAngle(s)) * s.speed * dt    
            end
            if s.dying == false then
                if s.y > love.graphics.getHeight()/2 + 50 then
                    if s.x > love.graphics.getWidth()/2 + 110 or s.x < love.graphics.getWidth()/2 -110 then
                        if s.x < love.graphics.getWidth()/2 -110 then
                            s.side = true
                            s.flip = true
                            s.animation = animations.shipSide
                        else 
                            s.side = true
                            s.animation = animations.shipSide    
                        end    
                        
                    else
                        s.side = false
                        s.flip =false
                        s.animation = animations.shipBack    
                    end
                end   
                if s.y < love.graphics.getHeight()/2 - 50 then
                    if s.x > love.graphics.getWidth()/2 + 110  or s.x < love.graphics.getWidth()/2 -110 then
                        if s.x < love.graphics.getWidth()/2 -110 then 
                            s.side = true
                            s.flip = true
                            s.animation = animations.shipSide
                        else
                            s.side = true
                            s.animation = animations.shipSide
                        end    
                    else
                        s.side = false
                        s.flip = false
                        s.animation = animations.shipFront    
                    end
                end   
            end


            if distanceBetween(s.x, s.y, kraken.x, kraken.y) < 50 then
                for i,s in ipairs(ships) do
                    ships[i] = nil
                    for i,a in ipairs(arms) do
                        a.animation = animations.submerge:clone() 
                        Timer.after(0.30, function() a.dead = true  end)
                        if a.dead == true then
                           table.remove(arms, i)
                           armCount = 0
                        end   
                   end 
                    gameState = 1
                    -- love.audio.stop()

                end    
            end    
        end 
    end

    for i,s in ipairs(ships) do
        for j,a in ipairs(arms) do
            if distanceBetween(s.x, s.y, a.x, a.y) < 60 then
                if s.dying == false then
                    s.animation = animations.wreck:clone()
                    -- love.audio.play(splash)
                    s.speed = s.speed / 2
                    s.dying = true
                    Timer.after(0.15, function()  s.dead = true end)
                end    
                if a.dying == false then
                    a.animation = animations.submerge:clone()
                    -- love.audio.play(splash)
                    a.dying = true
                    Timer.after(0.25, function() a.dead = true end)
                end    
                

            end    
        end
    end  
    
    for i=#ships,1,-1 do
        local s = ships[i]
        if s.dead == true then 
            table.remove(ships, i)
            killcount = killcount + math.random(29, 57) 
            spawnShip()
        end    
    end    

    for i=#arms,1,-1 do
        local a = arms[i]
        if a.dead == true then 
            table.remove(arms, i)
            armCount = armCount - 1
        end    
    end    

    if gameState == 2 then
        timer = timer - dt
        if timer <= 0 then
            spawnShip()
            maxTime = 0.95 * maxTime
            timer = maxTime
        end    
    end    

    animations.background:update(dt)
    animations.head:update(dt)
    animations.cursor:update(dt)

    for i,s in ipairs(ships) do
        s.animation:update(dt)
    end
    for i,a in ipairs(arms) do
        a.animation:update(dt)
        table.remove(arms, 9)
        table.remove(arms, -1)
    end    

    Timer.update(dt)
    

end

function love.draw()
    love.graphics.setColor(1, 0.8, 1)
    animations.background:draw(sprites.background, 0, 0)
    love.graphics.setColor(1, 1, 1, 2)
    if gameState == 2 then 
    animations.head:draw(sprites.kraken, kraken.x, kraken.y, nil, 0.85, nil, 71, 71)

    love.graphics.draw(sprites.eye, kraken.x-22, kraken.y+30, krakenMouseAngle(), 1.30, nil, sprites.eye:getWidth()/2, sprites.eye:getHeight()/2)
    love.graphics.draw(sprites.eye, kraken.x+22, kraken.y+30, krakenMouseAngle(), 1.30, nil, sprites.eye:getWidth()/2, sprites.eye:getHeight()/2)

    for i,s in ipairs(ships) do
        if s.type == 5 or s.type == 6 then
            love.graphics.setColor(0.80, 0.80, 80)
        else 
            love.graphics.setColor(1, 1, 1)         
        end    
            if s.side == true then
                if s.flip == true then
                s.animation:draw(sprites.ship, s.x, s.y, nil, -0.70, 0.70, 71.5, 59)
                else
                s.animation:draw(sprites.ship, s.x, s.y, nil, 0.70, nil, 71.5, 59)
                end   
            elseif s.side == false then
                s.animation:draw(sprites.ship, s.x, s.y, nil, 0.85, nil, 71.5, 59)
            end
        end 
    end
        love.graphics.setColor(1, 1, 1)
        if distanceBetween(love.mouse.getX(), love.mouse.getY(), kraken.x, kraken.y) > 55 then
            animations.cursor:draw(sprites.arm, love.mouse.getX() - 82, love.mouse.getY() - 120)
        end
    
    for i,a in ipairs(arms) do
        if a.x <= love.graphics.getWidth()/2 then
            a.animation:draw(sprites.arm, a.x, a.y, nil, -0.75, 0.75, 82, 120)
        else 
            a.animation:draw(sprites.arm, a.x, a.y, nil, 0.75, nil, 82, 120)
        end
    end    
    
        love.graphics.print("Land-Apes Eaten: " .. killcount, 5, 5, nil, 1)
    
        love.graphics.print(shipCount, love.graphics.getWidth()-55, 5, nil, 1)
        love.graphics.draw(sprites.shipScore, love.graphics.getWidth()-80, 20, nil, -0.5, nil, sprites.shipScore:getWidth()/2, sprites.shipScore:getHeight()/2)
    
    
    if gameState == 1 then 
        love.graphics.setColor(0.80, 0.30, 0.10)
        love.graphics.setFont(titleFont)
        love.graphics.newFont('Ocean-9mZL.ttf', 200)
        love.graphics.print("Kraken", love.graphics.getWidth()/2, love.graphics.getHeight()/2, nil, 1, nil, 245, 148.5)
        love.graphics.setColor(0.50, 0.10, 0.10)
        love.graphics.print("Kraken", love.graphics.getWidth()/2, love.graphics.getHeight()/2, nil, 1, nil, 250, 150)
        love.graphics.setFont(defaultFont)
        love.graphics.setColor(1, 1, 1)
    end    
    love.graphics.print(collectgarbage("count"), 675, 500)
end    

function love.keypressed( key )
    if key == "space" then
        
        for i,a in ipairs(arms) do
            a.animation = animations.submerge:clone() 
            Timer.after(0.30, function() a.dead = true  end)
            if a.dead == true then
                table.remove(arms, i)
                armCount = 0
            end   
        end 
    
        if gameState == 1 then
            gameState = 2
                shipCount = 501
                killcount = 0
                spawnShip()
                -- love.audio.play(sounds.music)
        end    
    end    
end    

function love.mousepressed(x, y, button)
    if button == 1 then 
            if armCount < 8 and distanceBetween(love.mouse.getX(), love.mouse.getY(), kraken.x, kraken.y) > 50 then
            spawnArm()
            end

    
    end    
end    

function krakenMouseAngle()
    return math.atan2( kraken.y - love.mouse.getY(), kraken.x - love.mouse.getX())
end

function shipKrakenAngle(enemy)
    return math.atan2( kraken.y - enemy.y, kraken.x - enemy.x)
end    

function spawnShip()
    if shipCount > 0 then
        local ship = {}
        ship.type = math.random(1, 10)
        ship.x = 0
        ship.y = 0
        ship.speed = math.random(100, 170)
        ship.dying = false
        ship.dead = false
        ship.animation = animations.shipFront
        ship.flip = false
        ship.side = false
        local side = math.random(1, 4)

        
            

        if side == 1 then
            ship.x = -30
            ship.y = math.random(100, love.graphics.getHeight())
            ship.animation = animations.shipSide
            ship.side = true
            ship.flip = true
            
        elseif side == 2 then
            ship.x =love.graphics.getWidth() + 30
            ship.y = math.random(100, love.graphics.getHeight())
            ship.animation = animations.shipSide
            ship.side = true
            
        elseif side == 3 then  
            ship.x = math.random(100, love.graphics.getWidth())
            ship.y = -30
        elseif side == 4 then
            ship.x = math.random(100, love.graphics.getWidth())
            ship.y = love.graphics.getHeight() + 30
            ship.animation = animations.shipBack
        end    

        table.insert(ships, ship)

        shipCount = shipCount - 1
    end    
end    

function spawnArm()
    if armCount < 8 then
        
        local arm = {}
        arm.x = love.mouse.getX()
        arm.y = love.mouse.getY()
        arm.animation = animations.surface:clone()
        arm.dying = false
        arm.dead = false
        armCount = armCount + 1
        
        table.insert(arms, arm)
        Timer.after(0.35, function() arm.animation = kraken.animation:clone() end)
    end
end    
-- function collision() 
    
--     for i,s in ipairs(ships) do
--         for j,a in ipairs(arms) do
--             if s.dying or a.dying then
--                 a.animation = animations.submerge:clone()
--                 s.animation = animations.wreck:clone()
--                 love.audio.play(splash)
--             end    
--         end
--     end  

-- end


function distanceBetween(x1, y1, x2, y2)
    return math.sqrt( (x2 - x1)^2 +(y2 -y1)^2 )
end    

function empty()
    collectgarbage("collect")
end    