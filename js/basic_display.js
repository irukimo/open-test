  function level_progress(level_element_id, progress){
    var level_element = document.getElementById(level_element_id);
    var progress = parseInt(progress);
    var whitewidth = 100 - progress;
    var imageText = (("linear-gradient(to bottom, #FFFFFF ").concat(whitewidth.toString())).concat("%,#ffc17f 0%)")
    level_element.style.backgroundImage = imageText;
  }

  
$(document).ready(function() {


  if( $("#chat_dot_display").html() == "0") {
    $("#chat_dot_display").css("opacity", 0);
  }

  var ses = new EventSource('/status_notif');
  ses.onmessage = function(e) {
    if( $("#chat_dot_display").html() != "0") {
      $("#chat_dot_display").css("opacity", 1).html(e.data);
    } else {
      $("#chat_dot_display").css("opacity", 0);
    }
  };

});