  function level_progress(level_element_id, progress){
    var level_element = document.getElementById(level_element_id);
    var progress = parseInt(progress);
    var whitewidth = 100 - progress;
    var imageText = (("linear-gradient(to bottom, #FFFFFF ").concat(whitewidth.toString())).concat("%,#ffc17f 0%)")
    level_element.style.backgroundImage = imageText;
  }

  
$(document).ready(function() {

  console.log($("#chat_dot_display"));
  if( $("#chat_dot_display").html() == "0" || $("#chat_dot_display").html() == "") {
    $("#chat_dot_display").css("opacity", 0);
  }

  $.get('/chat_dot',{}, function(data){
    console.log("get status: " + data);
    if( data != "0") {
      $("#chat_dot_display").css("opacity", 1).html(data);
    } else {
      $("#chat_dot_display").css("opacity", 0);
    }
  });

  var ses = new EventSource('/status_notif');
  ses.onmessage = function(e) {
    console.log("status: " + e.data);
    if( e.data != "0") {
      $("#chat_dot_display").css("opacity", 1).html(e.data);
    } else {
      $("#chat_dot_display").css("opacity", 0);
    }
  };

   
});