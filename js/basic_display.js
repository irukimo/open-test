function level_progress(level_element_id, progress){
	var level_element = document.getElementById(level_element_id);
	var progress = parseInt(progress);
	var whitewidth = 100 - progress;
	var imageText = (("linear-gradient(to bottom, #FFFFFF ").concat(whitewidth.toString())).concat("%,#ffc17f 0%)")
	level_element.style.backgroundImage = imageText;
}

