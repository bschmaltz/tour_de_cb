$(function() {
	if ($('#user-pic')[0])
		$('#user-pic').attr('src', get_gravatar($.trim($('#email').text()), 205));

	for(var i=0; i<$('.time').length; i++){
		$('.time').eq(i).after("Time: "+sec_to_time(parseFloat($('.time').eq(i).val())));
	}
	for(var i=0; i<$('.place').length; i++){
		$('.place').eq(i).after("Place: "+num_to_place(parseInt($('.place').eq(i).val())));
	}
});