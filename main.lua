local tiles = {}
local empty_squares
local covered_squares
local cost
local score

local equipment = {
    security_camera = {
        cost = 120,
        score = 3,
        range = 3
    },
    movement_detector = {
        cost = 200,
        score = 2,
        range = 4
    },
    laser = {
        cost = 500,
        score = 6,
        range = 5
    }
}


function addScoreToTile(score, x, y)
    if x >= 1 and x <= 12 and y >= 1 and y <= 12 then
        if type(tiles[y][x]) == "number" then
            tiles[y][x] = tiles[y][x] + score
        end
    end
end


function recalculateScores()
    -- Zero out all the empty squares
    for i, row in ipairs(tiles) do
        for j, square in ipairs(row) do
            if type(square) == "number" then
                tiles[i][j] = 0
            end
        end
    end

    -- For each piece of security equipment,
    --   add score to empty squares in range
    for i, row in ipairs(tiles) do
        for j, square in ipairs(row) do
            if type(square) == "string" then
                if square ~= "wall" then
                    local range = equipment[square].range
                    local score = equipment[square].score

                    for y_offset = 0, range-1 do
                        local y = y_offset + i - range
                        for x = (j - y_offset), (j + y_offset) do
                            addScoreToTile(score, x, y)
                        end
                    end

                    for x = (j - range), (j - 1) do
                        addScoreToTile(score, x, i)
                    end
                    for x = (j + 1), (j + range) do
                        addScoreToTile(score, x, i)
                    end

                    for y_offset = range-1, 0, -1 do
                        local y = i + range - y_offset
                        for x = (j - y_offset), (j + y_offset) do
                            addScoreToTile(score, x, y)
                        end
                    end
                end
            end
        end
    end
    recalculateStats()
end


function recalculateStats()
    empty_squares = 0
    covered_squares = 0
    cost = 0
    score = 0
end


function love.load()
    love.window.setMode(1024, 768)
    floor_sprite = love.graphics.newImage("tiles/Floor.png")
    wall_sprite = love.graphics.newImage("tiles/Wall.png")
    camera_sprite = love.graphics.newImage("tiles/CCTV.png")

    for line in love.filesystem.lines("map.txt") do
        local row = {}
        for i = 1, #line do
            if string.sub(line, i, i) == "X" then
                row[i] = "wall"
            else
                row[i] = 0
            end
        end
        table.insert(tiles, row)
    end

    recalculateStats()
end


function love.draw()
    -- Render the tiles.
    for i, row in ipairs(tiles) do
        for j, square in ipairs(row) do
            local y = (i-1) * 64
            local x = (j-1) * 64
            love.graphics.setColor(255, 255, 255)
            
            if type(square) == "string" then
                love.graphics.draw(wall_sprite, x, y)

                if square == "security_camera" then
                    love.graphics.draw(camera_sprite, x, y)
                end
            end
            
            if type(square) == "number" then
                local light = math.min(96 + square*16, 255)
                love.graphics.setColor(light, light, light)
                love.graphics.rectangle("fill", x, y, 64, 64)
                love.graphics.draw(floor_sprite, x, y)
                love.graphics.setColor(0, 0, 0)
                love.graphics.print(square, x+28, y+28)
            end
        end
    end

    local x = 768 + 12
    local y = 0 + 12
    love.graphics.print("Cost: "..cost, x, y)
    y = y + 18
    love.graphics.print("Score: "..score, x, y)
    y = y + 18
    love.graphics.print("Empty squares: "..empty_squares, x, y)
    y = y + 18
    love.graphics.print("Covered squares: "..covered_squares, x, y)
end


function love.mousepressed(mouse_x, mouse_y)
    local x = math.ceil(mouse_x / 64)
    local y = math.ceil(mouse_y / 64)
    local square = tiles[y][x]

    if type(square) == "number" then
        return
    end

    if square == "wall" then
        tiles[y][x] = "security_camera"
    elseif square == "security_camera" then
        tiles[y][x] = "movement_detector"
    elseif square == "movement_detector" then
        tiles[y][x] = "laser"
    else
        tiles[y][x] = "wall"
    end

    recalculateScores()
end
