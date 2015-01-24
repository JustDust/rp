# coffeelint: disable=max_line_length

random = (limit) -> Math.floor(Math.random() * limit)

class Creature
  stamina: 100
  health: 10
  defence: 5
  offence: 5

  draw: () ->
    console.log("draw something here")


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

  curPos:
    x: 50
    y: 50

  windowSize:
    x:11
    y:11

  protagonist:
    stamina: 100
    health: 10
    defence: 5
    offence: 5

  startMap: []

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

  windowLeft: -> @curPos.x - Math.floor(@windowSize.x / 2)

  windowRight: -> @curPos.x + Math.floor(@windowSize.x / 2)

  windowTop: -> @curPos.y - Math.floor(@windowSize.y / 2)

  windowBottom: -> @curPos.y + Math.floor(@windowSize.y / 2)

  getCurPosCell: -> $('.row' + @curPos.y + ' .col' + @curPos.x)

  drawCurPos: ->
    cell = @getCurPosCell()
    cellTile = @lookupTile(@curPos.x, @curPos.y)
    cell.removeClass(cellTile.style)
    cell.addClass('curPos')
    cell.text('U')

  movePos: (deltaX, deltaY) ->
    oldCellTile = @lookupTile(@curPos.x, @curPos.y)
    oldCell = @getCurPosCell()
    oldCell.removeClass('curPos')
    oldCell.addClass(oldCellTile.style)
    oldCell.text(oldCellTile.text)

    @curPos.x += deltaX
    @curPos.y += deltaY

    @drawCurPos();

  lookupTile: (x, y) ->  @tileMap[@startMap[y][x]]

  canMove: (deltaX, deltaY) ->
    tile = @lookupTile(@curPos.x + deltaX, @curPos.y + deltaY)
    tile.move <= @protagonist.stamina;

  createTileCell: (x, tile) ->
    $('<span>').addClass('tile').addClass(tile.style).addClass('col' + x).text(tile.text)

  createTileRow: (y) ->
    tileRow = @startMap[y]
    row = $('<div>').addClass('mapRow').addClass('row' + y)
    for x in [@windowLeft()...@windowRight()]
      tile = @lookupTile(x, y)
      row.append(@createTileCell(x, tile))
    row

  drawTiles: ->
    map = $('<div>').addClass('map')
    for y in [@windowTop()...@windowBottom()]
      row = @createTileRow(y)
      map.append(row)
    $('#mapContainer').html(map)

  drawMap: ->
    @drawTiles()
    @drawCurPos()

  moveMapDown: ->
    if @canMove(0,-1)
      $('.row' + @windowBottom()).remove()
      @movePos(0, -1)
      $('.map').prepend(@createTileRow(@windowTop()))

  moveMapUp: ->
    if @canMove(0,1)
      $('.row' + @windowTop()).remove()
      @movePos(0, 1)
      $('.map').append(@createTileRow(@windowBottom()))

  moveMapLeft: ->
    if @canMove(1,0)
      $('.col' + @windowLeft()).remove()
      @movePos(1, 0)
      rightCol = @windowRight()
      mapRow = $('.mapRow')
      mapRow.each((i) =>
        row = mapRow[i]
        rowNum = row.className.match(/row(\d+)/)[1]
        tile = @lookupTile(rightCol, rowNum)
        $(row).append(@createTileCell(rightCol, tile)))

  moveMapRight: ->
    if @canMove(-1,0)
      $('.col' + @windowRight()).remove()
      @movePos(-1, 0)
      leftCol = @windowLeft()
      mapRow = $('.mapRow')
      mapRow.each((i) =>
        row = mapRow[i]
        rowNum = row.className.match(/row(\d+)/)[1]
        tile = @lookupTile(leftCol, rowNum)
        $(row).prepend(@createTileCell(leftCol, tile)))

  handleKeyPress: (evt) ->
    switch evt.key
      when "Up" then @moveMapDown()
      when "Down" then @moveMapUp()
      when "Right" then @moveMapLeft()
      when "Left" then @moveMapRight()

  init: ->
    @startMap = @genRandomMap()
    @drawMap()
    $("#top").on("keypress", (e) => @handleKeyPress(e) )

$(window).load( -> window.aa = new AsciiAdventure(); window.aa.init() )
