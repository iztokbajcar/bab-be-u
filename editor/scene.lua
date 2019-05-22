local scene = {}
local paintedtiles = 0
local buttons = {}
local button_over = nil
local button_pressed = nil

function scene.load()
  brush = nil
  selector_open = false

  buttons = {}
  table.insert(buttons, {"load", scene.loadLevel})
  table.insert(buttons, {"save", scene.saveLevel})
  table.insert(buttons, {"cog", scene.openSettings})

  clear()
  resetMusic(current_music, 0.1)
  loadMap()
  local now = os.time(os.date("*t"))
  presence = {
    state = "in editor",
    details = "making a neat new level",
    largeImageKey = "cover",
    largeimageText = "bab be u",
    smallImageKey = "edit",
    smallImageText = "editor",
    startTimestamp = now
  }
  nextPresenceUpdate = 0
end

function scene.keyPressed(key)
  if key == "s" then
    scene.saveLevel()
  elseif key == "l" then
    scene.loadLevel()
  end

  if key == "tab" then
    selector_open = not selector_open
    if selector_open then
      presence["details"] = "browsing selector"
    end
  end
end

function scene.update(dt)
  width = love.graphics.getWidth()
  height = love.graphics.getHeight()

  button_over = nil
  local btnx = 0
  for _,btn in ipairs(buttons) do
    local sprite = sprites["ui/" .. btn[1]]
    if mouseOverBox(btnx, 0, sprite:getWidth(), sprite:getHeight()) then
      button_over = btn
    end
    btnx = btnx + sprite:getWidth() + 4
  end

  if button_over then
    if love.mouse.isDown(1) then
      if not button_pressed then
        button_over[2]()
      end
      button_pressed = button_over
    else
      button_pressed = nil
    end
  else
    local hx,hy = getHoveredTile()
    if hx ~= nil then
      local tileid = hx + hy * mapwidth

      local hovered = {}
      if units_by_tile[tileid] then
        for _,v in ipairs(units_by_tile[tileid]) do
          table.insert(hovered, v)
        end
      end

      if love.mouse.isDown(1) then
        if not selector_open then
          if #hovered > 1 or (#hovered == 1 and hovered[1].tile ~= brush) or (#hovered == 0 and brush ~= nil) then
            if brush then
              map[tileid+1] = {brush}
            else
              map[tileid+1] = {}
            end
            paintedtiles = paintedtiles + 1
            presence["details"] = "painted "..paintedtiles.." tiles"
            clear()
            loadMap()
          end
        else
          local selected = hx + hy * tile_grid_width
          if tile_grid[selected] then
            brush = tile_grid[selected]
          else
            brush = nil
          end
        end
      end
      if love.mouse.isDown(2) and not selector_open then
        if #hovered >= 1 then
          brush = hovered[1].tile
        else
          brush = nil
        end
      end
    end
  end
end

function scene.getTransform()
  local transform = love.math.newTransform()

  local roomwidth, roomheight

  if not selector_open then
    roomwidth = mapwidth * TILE_SIZE
    roomheight = mapheight * TILE_SIZE
  else
    roomwidth = tile_grid_width * TILE_SIZE
    roomheight = tile_grid_height * TILE_SIZE
  end

  local screenwidth = love.graphics.getWidth()
  local screenheight = love.graphics.getHeight()

  if screenwidth >= roomwidth * 2 and screenheight >= roomheight * 2 then
    transform:translate(-screenwidth / 2, -screenheight / 2)
    transform:scale(2, 2)
  end

  transform:translate(screenwidth / 2 - roomwidth / 2, screenheight / 2 - roomheight / 2)

  return transform
end

last_hovered_tile = {0,0}
function scene.draw(dt)
  love.graphics.setBackgroundColor(0.10, 0.1, 0.11)

  local roomwidth, roomheight
  if not selector_open then
    roomwidth = mapwidth * TILE_SIZE
    roomheight = mapheight * TILE_SIZE
  else
    roomwidth = tile_grid_width * TILE_SIZE
    roomheight = tile_grid_height * TILE_SIZE
  end

  love.graphics.push()
  love.graphics.applyTransform(scene.getTransform())

  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, roomwidth, roomheight)

  if not selector_open then
    for i=1,max_layer do
      if units_by_layer[i] then
        for _,unit in ipairs(units_by_layer[i]) do
          local sprite = sprites[unit.sprite]
          if not sprite then sprite = sprites["wat"] end
          
          local rotation = 0
          if unit.rotate then
            rotation = (unit.dir - 1) * 90
          end
          
          love.graphics.setColor(unit.color[1]/255, unit.color[2]/255, unit.color[3]/255)
          love.graphics.draw(sprite, (unit.x + 0.5)*TILE_SIZE, (unit.y + 0.5)*TILE_SIZE, math.rad(rotation), unit.scalex, unit.scaley, sprite:getWidth() / 2, sprite:getHeight() / 2)
        end
      end
    end
  else
    for x=0,tile_grid_width-1 do
      for y=0,tile_grid_height-1 do
        local gridid = x + y * tile_grid_width
        local i = tile_grid[gridid]
          if i ~= nil then
          local tile = tiles_list[i]
          local sprite = sprites[tile.sprite]
          if not sprite then sprite = sprites["wat"] end

          local x = tile.grid[1]
          local y = tile.grid[2]

          love.graphics.setColor(tile.color[1]/255, tile.color[2]/255, tile.color[3]/255)
          love.graphics.draw(sprite, (x + 0.5)*TILE_SIZE, (y + 0.5)*TILE_SIZE, 0, 1, 1, sprite:getWidth() / 2, sprite:getHeight() / 2)

          if brush == i then
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("line", x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
          end
        elseif gridid == 0 and brush == nil then
          love.graphics.setColor(1, 0, 0)
          love.graphics.rectangle("line", x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
        end
      end
    end
  end

  local hx,hy = getHoveredTile()
  if hx ~= nil then
    if brush and not selector_open then
      local sprite = sprites[tiles_list[brush].sprite]
      if not sprite then sprite = sprites["wat"] end
      local color = tiles_list[brush].color

      love.graphics.setColor(color[1]/255, color[2]/255, color[3]/255, 0.25)
      love.graphics.draw(sprite, (hx + 0.5)*TILE_SIZE, (hy + 0.5)*TILE_SIZE, 0, 1, 1, sprite:getWidth() / 2, sprite:getHeight() / 2)
    end

    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("line", hx * TILE_SIZE, hy * TILE_SIZE, TILE_SIZE, TILE_SIZE)

    last_hovered_tile = {hx, hy}
  end

  if selector_open then
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(last_hovered_tile[1] .. ', ' .. last_hovered_tile[2], 0, roomheight)
  end

  love.graphics.pop()

  local btnx = 0
  for _,btn in ipairs(buttons) do
    local sprite = sprites["ui/" .. btn[1]]

    if button_pressed then
      if button_pressed == btn then
        love.graphics.setColor(0.5, 0.5, 0.5)
      else
        love.graphics.setColor(1, 1, 1)
      end
    else
      if button_over == btn then
        love.graphics.setColor(0.8, 0.8, 0.8)
      else
        love.graphics.setColor(1, 1, 1)
      end
    end

    love.graphics.draw(sprite, btnx, 0)

    btnx = btnx + sprite:getWidth() + 4
  end
end

function scene.saveLevel()
  local mapdata = love.data.compress("string", "zlib", dump(map))
  local savestr = love.data.encode("string", "base64", mapdata)

  local data = {
    name = "test",
    width = mapwidth,
    height = mapheight,
    map = savestr
  }

  love.filesystem.createDirectory("levels")
  love.filesystem.write("levels/" .. data.name .. ".bab", json.encode(data))
end

function scene.loadLevel()
  local file = love.filesystem.read("levels/test.bab")

  if file ~= nil then
    local data = json.decode(file)

    local loaddata = love.data.decode("string", "base64", data.map)
    local mapstr = love.data.decompress("string", "zlib", loaddata)

    map = loadstring("return " .. mapstr)()

    clear()
    loadMap()
  end
end

function scene.openSettings()
  -- not implemented
end

return scene