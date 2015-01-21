$(function() {
	if ($(".lobby_result")[0]) {
		$(".lobby_result").click(function(){
			window.location = ("../game/gamemode?id="+$(this).attr("id"));
		});
	}

	if($('#map-prev')[0]){
		//create map
		map = new google.maps.Map(document.getElementById('map-prev'), {
			zoom: 13,
			mapTypeId: google.maps.MapTypeId.ROADMAP,
	  		streetViewControl: false,
	  		panControl: false,
	  		zoomControlOptions: {
				style: google.maps.ZoomControlStyle.SMALL,
				position: google.maps.ControlPosition.RIGHT_TOP
			}
		});

		//add route
		var rendererOptions = { map: map };
		directionsDisplay = new google.maps.DirectionsRenderer(rendererOptions);

		var request = get_map($("#new_lobby_map").val());

		directionsService = new google.maps.DirectionsService();
		directionsService.route(request, function(response, status) {
			if (status == google.maps.DirectionsStatus.OK) {
				directionsDisplay.setDirections(response);
			}
			else
				alert ('failed to get directions');
		});

		$('#new_lobby_map').on('change', function() {
			var request = get_map(this.value);
			directionsService.route(request, function(response, status) {
				if (status == google.maps.DirectionsStatus.OK) {
					directionsDisplay.setDirections(response);
				}
				else
					alert ('failed to get directions');
			});
		});
	}
});