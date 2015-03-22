# coffeelint: disable=max_line_length

random = (limit) -> Math.floor(Math.random() * limit)

stat_bar = (cur, max, ch, style) ->
  $("<span>").addClass(style).text((ch for [0...Math.ceil((cur/max)*10)]).join(""))

item_list = (items, onclick) ->
  console.log(items)
  itemList = $("<span>").addClass("itemlist")
  for i in items
    itemList.append($("<span>").addClass("item").on("click", onclick).text(i.tile.text))
  console.log(itemList)
  itemList
  
class Item
  constructor: (options) ->
    {@id, @mapMarkerCh, @baseStyle, @pos} = options
  tile: -> { style: @baseStyle, text: @mapMarkerCh, move: 1 }
  style: -> @baseStyle
  mapMarker: -> @mapMarkerCh
      
class Creature
  
  constructor: (options) ->
    {@id, @baseStyle, @stamina, @health, @offence, @deffence, @pos} = options
    @maxStamina = @stamina
    @maxHealth = @health
    @dead = false
    @inventory = []

  draw: ->
    stats = $("<div>").addClass("stats")
    stats.append(stat_bar(@stamina, 50, "-", "stamina")).append("<br/>")
    stats.append(stat_bar(@health, 10, "-", "health"))
    stats.append(item_list(@inventory, (item) -> @useItem(item)))
    $("#" + @id).html(stats)
    
  mapMarker: ->
    if @dead then "X" else "U"

  style: ->
    @baseStyle

  tile: -> { style: @baseStyle, text: @mapMarker() }
  
  damageHealth: (amount) ->
    @health = Math.max(@health - amount, 0)
    if @health <= 0
      @die()
      
  die: () ->
    @dead = true
    @maxStamina = 0
    @maxHealth = 0

  take: (mapObj) ->
    # TODO: right now you can take anything!
    console.log("taking " + mapObj)
    @inventory.push(mapObj)

  useItem: (mapObj) ->
    console.log("using " + mapObj)

    
class AsciiAdventure

  mapSize:
    x: 100
    y: 100

  tileMap: [
    { style: 'grass', text: '"', move: 1 }
    { style: 'water', text: '~', move: 10 }
    { style: 'tree',  text: 'Y', move: 1000 }
    { style: 'stone', text: '#', move: 1000 }
  ]

  windowSize:
    x:11
    y:11

  protagonist: new Creature({
    id: "protagonist"
    baseStyle: "curPos"
    stamina: 50
    health: 10
    offence: 5
    defence: 5
    pos: { x: 50, y:50 }})

  startMap: []
  
  mapObjects: {}
  
  mapObjectKey: (pos) -> pos.x + "_" + pos.y

  placeObject: (obj, placeOk) ->
    for i in [0..50]
      x = random(@mapSize.x)
      y = random(@mapSize.y)
      if placeOk(@lookupTile(x,y))
        obj.pos.x = x
        obj.pos.y = y
        break

  genFood: (id) ->
    food = new Item({ id: "food"+id, mapMarkerCh: "o", baseStyle:"food", pos: { x:0, y:0 }})
    @placeObject(food, (tile) -> tile.style != "tree")
    @mapObjects[@mapObjectKey(food.pos)] = food
      
  genRiver: (map) ->
    length = 0
    maxLength = 100
    pos =
      x: random(@mapSize.x)
      y: random(@mapSize.y)
    direction =
      deltaX: random(2) - 1
      deltaY: random(2) - 1
    weightedXAdjust = [ direction.deltaX, 0, -1, 1]
    weightedYAdjust = [ direction.deltaY, 0, -1, 1]

    while pos.x > 0 and pos.x < @mapSize.x and pos.y > 0 and pos.y < @mapSize.y and length < maxLength
      map[pos.y][pos.x] = 1
      adjust =
        deltaX: random(2) - 1
        deltaY: random(2) - 1
      pos.x = pos.x + weightedXAdjust[random(weightedXAdjust.length)]
      pos.y = pos.y + weightedYAdjust[random(weightedYAdjust.length)]
      length++

  genRandomMap: ->
    weightedLookup = [ 0, 0, 2 ]
    map = ((weightedLookup[random(3)] for [0...@mapSize.x]) for [0...@mapSize.y])
    @genRiver(map) for [0...((random(5) + 1) * 3)]
    map

  windowLeft: -> @protagonist.pos.x - Math.floor(@windowSize.x / 2)

  windowRight: -> @protagonist.pos.x + Math.floor(@windowSize.x / 2)

  windowTop: -> @protagonist.pos.y - Math.floor(@windowSize.y / 2)

  windowBottom: -> @protagonist.pos.y + Math.floor(@windowSize.y / 2)

  getCell: (pos) -> $('.row' + pos.y + ' .col' + pos.x)

  drawObjects: ->
    for key, obj of @mapObjects
      @drawObject(obj)
  
  drawObject: (obj) ->
    cell = @getCell(obj.pos)
    if cell?
      cellTile = @lookupTile(obj.pos.x, obj.pos.y)
      if cellTile?
        cell.removeClass(cellTile.style)
        cell.addClass(obj.style())
        cell.text(obj.mapMarker())    
    
  movePos: (deltaX, deltaY) ->
    oldCellTile = @lookupTile(@protagonist.pos.x, @protagonist.pos.y)
    mapObj = @lookupObject(@protagonist.pos.x, @protagonist.pos.y)
    if mapObj?
      if not @protagonist.take(mapObj)
        oldCellTile = mapObj.tile()
        @protagonist.draw()
    oldCell = @getCell(@protagonist.pos)
    oldCell.removeClass(@protagonist.style())
    oldCell.addClass(oldCellTile.style)
    oldCell.text(oldCellTile.text)

    @protagonist.pos.x += deltaX
    @protagonist.pos.y += deltaY

    @drawObject(@protagonist);

  lookupTile: (x, y) ->  @tileMap[@startMap[y][x]]

  lookupObject: (x, y) -> @mapObjects[@mapObjectKey({ x: x, y: y })]
  
  canMove: (creature, deltaX, deltaY) ->
    tile = @lookupTile(creature.pos.x + deltaX, creature.pos.y + deltaY)
    tile.move <= creature.stamina;

  createTileCell: (x, y, tile) ->
    mapObj = @lookupObject(x, y)
    if mapObj?
      tile = mapObj.tile()
    $('<span>').addClass('tile').addClass(tile.style).addClass('col' + x).text(tile.text)

  createTileRow: (y) ->
    tileRow = @startMap[y]
    row = $('<div>').addClass('mapRow').addClass('row' + y)
    for x in [@windowLeft()..@windowRight()]
      tile = @lookupTile(x, y)
      row.append(@createTileCell(x, y, tile))
    row

  drawTiles: ->
    map = $('<div>').addClass('map')
    for y in [@windowTop()..@windowBottom()]
      row = @createTileRow(y)
      map.append(row)
    $('#mapContainer').html(map)

  drawMap: ->
    @drawTiles()
    @drawObject(@protagonist)

  moveMapDown: ->
    if @canMove(@protagonist, 0,-1)
      $('.row' + @windowBottom()).remove()
      @movePos(0, -1)
      $('.map').prepend(@createTileRow(@windowTop()))
      @onMove()

  moveMapUp: ->
    if @canMove(@protagonist, 0 ,1)
      $('.row' + @windowTop()).remove()
      @movePos(0, 1)
      $('.map').append(@createTileRow(@windowBottom()))
      @onMove()

  moveMapLeft: ->
    if @canMove(@protagonist, 1,0)
      $('.col' + @windowLeft()).remove()
      @movePos(1, 0)
      rightCol = @windowRight()
      mapRow = $('.mapRow')
      mapRow.each((i) =>
        row = mapRow[i]
        rowNum = row.className.match(/row(\d+)/)[1]
        tile = @lookupTile(rightCol, rowNum)
        $(row).append(@createTileCell(rightCol, rowNum, tile)))
      @onMove()

  moveMapRight: ->
    if @canMove(@protagonist, -1,0)
      $('.col' + @windowRight()).remove()
      @movePos(-1, 0)
      leftCol = @windowLeft()
      mapRow = $('.mapRow')
      mapRow.each((i) =>
        row = mapRow[i]
        rowNum = row.className.match(/row(\d+)/)[1]
        tile = @lookupTile(leftCol, rowNum)
        $(row).prepend(@createTileCell(leftCol, rowNum, tile)))
      @onMove()

  handleKeyPress: (evt) ->
    switch evt.which
      when 37 then @moveMapRight() # left arrow
      when 38 then @moveMapDown()  # up arrow
      when 39 then @moveMapLeft()  # right arrow
      when 40 then @moveMapUp()    # down arrow

  onMove: ->
    tile = @lookupTile(@protagonist.pos.x, @protagonist.pos.y)
    @protagonist.stamina -= tile.move
    @protagonist.draw()

    
  tick: ->
#    console.log("tick")
    tile = @lookupTile(@protagonist.pos.x, @protagonist.pos.y)
    if tile.style == "water"
      if @protagonist.stamina > 0
        @protagonist.stamina -= 1
      if @protagonist.stamina <= 0
        @protagonist.damageHealth(1)
        if @protagonist.dead
          @drawMap()
    else if @protagonist.stamina < 50
      @protagonist.stamina = Math.min(@protagonist.stamina + 3, @protagonist.maxStamina)
    #@protagonist.draw()
    setTimeout(
      () => @tick()
      1000
    )
    
  init: ->
    @startMap = @genRandomMap()
    @drawMap()
    @genFood(i) for i in [0..100]
    @drawObjects()
    $("#top").on("keydown", (e) => @handleKeyPress(e) )
    @protagonist.draw()
    setTimeout(
      () => @tick()
      1000
    )

$(window).load( -> window.aa = new AsciiAdventure(); window.aa.init() )
