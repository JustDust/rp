var aa = (function(){

    var random = function(limit) {
	return Math.floor(Math.random() * limit);
};

    var _genRandomMap = function() {
	var weightedLookup = [ 0, 0, 2 ];
	var map = [];
	for (var i = 0; i < mapSize.y; i++) {
	    var row = [];
	    for (var j = 0; j < mapSize.x; j++) {
		row.push(weightedLookup[random(3)]);
	    }
	    map.push(row);
	}
	var numRivers = (random(5) + 1) * 3;
	for (i = 0; i < numRivers; i++) {
	    var pos = { x: random(mapSize.x), y: random(mapSize.y) };
	    var direction = { deltaX: random(2) - 1, deltaY: random(2) - 1 };
	    var weightedXAdjust = [ direction.deltaX, 0, -1, 1];
	    var weightedYAdjust = [ direction.deltaY, 0, -1, 1];
	    var length = 0;
	    var maxLength = 100;
	    while (pos.x > 0 && pos.x < mapSize.x && pos.y > 0 && pos.y < mapSize.y && length < maxLength) {
		map[pos.y][pos.x] = 1;
		var adjust = { deltaX: random(2) - 1, deltaY: random(2) - 1};
		pos.x = pos.x + weightedXAdjust[random(weightedXAdjust.length)];
		pos.y = pos.y + weightedYAdjust[random(weightedYAdjust.length)];
		length++;
	    }
	}
	return map;
};

    var mapSize = { x:100, y:100 };

    var startMap = _genRandomMap();

    var tileMap = [
	{ style: 'grass', text: '"', move: 1 },
	{ style: 'water', text: '~', move: 10 },
	{ style: 'tree', text: 'Y', move: 1000 },
	{ style: 'stone', text: '#', move: 1000 }
    ];

    var curPos = { x: 50, y: 50 };
    var windowSize = { x:11, y:11 };

    var protagonist = { stamina: 100, health: 10, defence: 5, offence: 5 };

    var windowLeft = function() {
	return curPos.x - Math.floor(windowSize.x / 2);
};

    var windowRight = function() {
	return curPos.x + Math.floor(windowSize.x / 2);
};

    var windowTop = function() {
	return curPos.y - Math.floor(windowSize.y / 2);
};

    var windowBottom = function() {
	return curPos.y + Math.floor(windowSize.y / 2);
};

    var getCurPosCell = function() {
	return $('.row' + curPos.y + ' .col' + curPos.x);
};

    var drawCurPos = function() {
	var cell = getCurPosCell();
	var cellTile = lookupTile(curPos.x, curPos.y);
	cell.removeClass(cellTile.style);
	cell.addClass('curPos');
	cell.text('U');
};

    var movePos = function(deltaX, deltaY) {
	var oldCell = getCurPosCell();
	var oldCellTile = lookupTile(curPos.x, curPos.y);
	oldCell.removeClass('curPos');
	oldCell.addClass(oldCellTile.style);
	oldCell.text(oldCellTile.text);

	curPos.x += deltaX;
	curPos.y += deltaY;

	drawCurPos();
};

    var lookupTile = function(x, y) {
	var tileCode = startMap[y][x];
	return tileMap[tileCode];
};

    var canMove = function(deltaX, deltaY) {
	var tile = lookupTile(curPos.x + deltaX, curPos.y + deltaY);
	return tile.move <= protagonist.stamina;
};

    var createTileCell = function(x, tile) {
	return $('<span>').addClass('tile').addClass(tile.style).addClass('col' + x).text(tile.text);
};

    var createTileRow = function(y) {
	var tileRow = startMap[y];
	var row = $('<div>').addClass('mapRow').addClass('row' + y);
	for (var x = windowLeft(); x <= windowRight(); x++) {
	    var tile = lookupTile(x, y);
	    row.append(createTileCell(x, tile));
	}
	return row;
};

    var drawTiles = function() {
	var map = $('<div>').addClass('map');
	for (var y = windowTop(); y <= windowBottom(); y++) {
	    var row = createTileRow(y);
	    map.append(row);
	}
	$('#mapContainer').html(map);
};

    var drawMap = function() {
	drawTiles();
	drawCurPos();
};

    var moveMapDown = function() {
	if (!canMove(0,-1)) { return; }
	$('.row' + windowBottom()).remove();
	movePos(0, -1);
	$('.map').prepend(createTileRow(windowTop()));
};

    var moveMapUp = function() {
	if (!canMove(0,1)) { return; }
	$('.row' + windowTop()).remove();
	movePos(0, 1);
	$('.map').append(createTileRow(windowBottom()));
};

    var moveMapLeft = function() {
	if (!canMove(1,0)) { return; }
	$('.col' + windowLeft()).remove();
	movePos(1, 0);
	var rightCol = windowRight();
	var mapRow = $('.mapRow');
	mapRow.each(function(i) {
	    var row = mapRow[i];
	    var rowNum = row.className.match(/row(\d+)/)[1];
	    var tile = lookupTile(rightCol, rowNum);
	    $(row).append(createTileCell(rightCol, tile));
	});

};

    var moveMapRight = function() {
	if (!canMove(-1,0)) { return; }
	$('.col' + windowRight()).remove();
	movePos(-1, 0);
	var leftCol = windowLeft();
	var mapRow = $('.mapRow');
	mapRow.each(function(i) {
	    var row = mapRow[i];
	    var rowNum = row.className.match(/row(\d+)/)[1];
	    var tile = lookupTile(leftCol, rowNum);
	    $(row).prepend(createTileCell(leftCol, tile));
	});

};

    var handleKeyPress = function(evt) {
	switch (evt.key) {
	case "Up":
	    moveMapDown();
	    break;
	case "Down":
	    moveMapUp();
	    break;
	case "Right":
	    moveMapLeft();
	    break;
	case "Left":
	    moveMapRight();
	    break;
	}
};

    return {
	init: function() {
	    drawMap();
	    $("#top").on("keypress", function(e) { return handleKeyPress(e); });
	}
    };

})();

$(window).load(function() { aa.init(); });
