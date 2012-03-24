function add_torrent() {
  var url = $('#torrent_url')[0].value;
  if(url.indexOf('.torrent') != -1) {
    alert('Uh oh, that looks like a torrent file, not a magnet link.');
    return;
  }

  $.ajax({
    type: "POST",
    url: '/add_torrent',
    data: {url: url},
    success: function(msg) {
      $('#torrent_url')[0].value = '';
    }
  });
}

function add_feature_request() {
  var description = $('#feature_request')[0].value;
  if(description == '')
    return;

  $.ajax({
    type: "POST",
    url: '/add_feature_request',
    data: {description: description},
    success: function(result) {
      $('#feature_requests')[0].innerHTML = result;
      $('#feature_request')[0].focus();
    }
  });
}

function featureRequestEnterPressed(evt) {
  if(evt.keyCode == 13) {
    add_feature_request();
    return false;
  }
  else {
    return true;
  }
}

