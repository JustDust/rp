
var memorizer = (function() {

  var startText;
  var curLetter;
  var missCount = 0;
  var maxGuesses = 1;
  var matchSpace = /\s/;
  var indicateSpaces = true;
  var saveLoadStartText;
  var storageName = "memorizerSaved";
  var revealText = false;

  var start = function(text) {
    setValue(text);
  };

  var setValue = function(text) {
    startText = text.trim().replace(/\s+/g,' ');
    createEntryField(startText);
    curLetter = $("#matchField")[0].firstChild;
    $(curLetter).addClass('current');
    $("#top").on("keypress", function(e) { return handleKeyPress(e); });
  };

  var getLetterClass = function(letter) {
    if (letter.match(/\w/) || !indicateSpaces) {
        return 'letter';
    } else if (letter.match(/\s/)) {
        return 'space';
    } else {
        return 'other';
    }
  };

  var createEntryField = function(text) {
    var letters = text.split("");
    var elements = $.map(letters, function(letter) {
      //var letterClass = (indicateSpaces && matchSpace.exec(letter)) ? "space" : "letter";
      var letterClass = getLetterClass(letter);
      if (revealText) {
        letterClass += " hint";
      }
      return '<span class="' + letterClass + '" onclick="memorizer.revealTo(event)">' + letter + '</span>';
    });
    $("#matchField").html(elements.join(""));
  };

  var reset = function() {
    $("#top").off("keypress");
    $(".finished").hide();
    if (curLetter) {
      $(curLetter).removeClass('current');
    }
    curLetter = null;
    missCount = 0;
  };

  var finished = function() {
    reset();
    $(".finished").fadeIn(100);
  };

  var handleKeyPress = function(evt) {
    var target = curLetter.textContent;
    // disregard modifier keys like 'Shift'
    if (evt.key.length > 1) {
      return;
    }
    if (evt.key == target) {
      $(curLetter).addClass('done');
      $(curLetter).removeClass('current');
      curLetter = curLetter.nextSibling;
      $(curLetter).addClass('current');
      missCount = 0;
      if (!curLetter) {
        finished();
      }
    } else {
      if (++missCount >= maxGuesses) {
        $(curLetter).addClass('hint');
      }
    }
    return true;
  };

  var loadText = function(savedItem) {
    $("#text").val(getSavedItems()[savedItem]);
    $('#saveLoad').val(savedItem);
  };

  var setupSavedBox = function() {
    $(".saved").empty();
    if (!localStorage.memorizer) { localStorage.memorizer = []; }
    var saved = getSavedItems();
    if (Object.keys(saved).length > 0) {
      $.each(saved, function(savedName) {
        var item = document.createElement("div");
        item.onclick = function() { loadText(savedName); };
        item.innerHTML = savedName;
        $(".saved").append(item);
      });
    } else {
      $(".saved").html("<span class='nosaved'>No saved text</span>");
    }
    var position = $('#saveLoad').position();
    $(".saved").css({
      position: 'absolute',
      left: position.left,
      top: position.top + $('#saveLoad').outerHeight(),
      width: $('#saveLoad').width()
    });
  };

  var getSavedItems = function() {
    if (!localStorage[storageName]) {
      localStorage[storageName] = JSON.stringify({});
    }
    return JSON.parse(localStorage[storageName]);
  };

  var saveValue = function(saveName, value) {
    var saved = getSavedItems();
    saved[saveName] = value;
    localStorage[storageName] = JSON.stringify(saved);
  };


  return {
    showHelp: function() {
      var position = $('.help').position();
      $(".helpText").css({
        position: 'absolute',
        left: position.left + $('.help').outerWidth(),
        top: position.top
      });
      $('.helpText').fadeIn(250);
    },

    hideHelp: function() {
      $('.helpText').fadeOut(250);
    },

    pause: function() {
      $("#top").off("keypress");
    },

    setMaxGuesses: function() {
      var max = parseInt($("#maxGuesses").val());
      if (max > 0) {
        console.log("setting max to " + max);
        maxGuesses = max;
      }
      $("#top").on("keypress", function(e) { return handleKeyPress(e); });
    },

    setIndicateSpaces: function() {
      indicateSpaces = $('#indicateSpaces')[0].checked;
    },

    reset: function() {
      reset();
      setValue(startText);
    },

    setRevealText: function() {
      var checkbox = $('#revealText')[0];
      revealText = checkbox.checked;
      for (var letter = curLetter; letter !== null; letter = letter.nextSibling) {
        if (revealText) {
          $(letter).addClass('hint');
        } else {
          $(letter).removeClass('hint');
        }
      }
      checkbox.blur();
    },

    showTextDlg: function() {
      reset();
      $('.textentry').slideDown(250);
    },

    showSaved: function() {
      saveLoadStartText = $('#saveLoad').val();
      $('#saveLoad').val("");
      setupSavedBox();
      $('.saved').show();
    },

    hideSaved: function() {
      // Yes, I know, there's a horrible race condition here!
      window.setTimeout(function() { $('.saved').hide(); }, 250);
    },

    saveText: function() {
      var value = $("#text").val();
      if (value) {
        var saveLoadName = $("#saveLoad").val();
        if (saveLoadName != saveLoadStartText) {
          saveValue(saveLoadName, value);
        }
        setValue(value);
      }
      $('.textentry').slideUp(150);
    },

    revealTo: function(evt) {
      var stopAt = evt.target.nextSibling;
      for (var letter = curLetter; letter !== null && letter != stopAt; letter = letter.nextSibling) {
        $(letter).addClass('done');
      }
      for (letter = stopAt; letter !== null; letter = letter.nextSibling) {
        $(letter).removeClass('done').removeClass('hint');
      }
      missCount = 0;
      if (curLetter) {
        $(curLetter).removeClass('current');
      }
      curLetter = stopAt;
      if (curLetter) {
        $(curLetter).addClass('current');
      } else {
        reset();
      }
    }
  };
  
})();
