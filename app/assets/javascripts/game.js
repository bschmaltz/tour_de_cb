
var geocoder;
var map;		//road map
var lobby_map;  //lobby road map
var marker;  	//users marker
var polyline; 	//line on roadmap
var pan;		//streetview
var seconds		//in race time in seconds
var timer;		//in race time display
var lobby_map_markers = []; //other player markers on lobby map
var map_markers = [];//other player markers on minimap
var pan_markers = [];//other player markers on panorama
var paused = true;
$(function() {
	if ($('#game')[0]) {
		/*
		******************************************SET UP WEBSOCKETS*****************************************************
		*/
		var starts;
		var emails;
		var statuses;
		starts = $("#other_starts").attr("value");
		if(starts=="[]"){
			starts = [];
		}else{
			starts = starts.substring(1, starts.length-1).split(", ");
		}
		emails = $("#other_emails").attr("value").replace("\"", "");
		if(emails=="[]"){
			emails = [];
		}else{
			emails = emails.substring(1, emails.length-2).split("\", \"");
		}
		statuses = $("#other_statuses").attr("value").replace("\"", "");
		if(statuses=="[]"){
			statuses = [];
		}else{
			statuses = statuses.substring(1, statuses.length-2).split("\", \"");
		}
		var user_email = $("#email").attr("value");
		var dispatcher = new WebSocketRails(wsUrl);
		var lobby_id = $("#lobby_id").attr("value");
		var limit = $("#limit").attr("value");
		var channel = dispatcher.subscribe(lobby_id);

		var racing = $("#lobby_racing").attr("value");
		if(racing=="true"){
			$(".open_player_slot").hide();
			racing=true;
		}else{
			racing=false;
			$("#end_race_btn").hide();
		}

		//on connect, we need send the user's info to the controller to be broadcasted to clients (in this lobby).
		dispatcher.on_open = function(data) {
		  // You can trigger new server events inside this callback if you wish.
		  var connected_user = {email: user_email, distance_travelled: parseInt($("#start").attr("value")), chan: lobby_id};
		  dispatcher.trigger('connect.initiate_session', connected_user);

			if($("#lobby_racing").attr("value")=="true"){

				$('#distance').html((Math.round($("#start").val()*0.000621371*100.0)/100.0)+" Miles");
				$('#speed').html("0.00 mph");

				if($("#user_racing").attr("value")=='true'){
					seconds=parseFloat($('#time').val());
					$('#clock').html(sec_to_time(seconds));
					timer = window.setInterval(function() { seconds+=1; $('#clock').html(sec_to_time_ch(seconds)); }, 1000);
				}
				$(document.getElementById(user_email)).append("<span class=\"glyphicon glyphicon-road\"></span>");
				for(var i=0; i<statuses.length ; i++){
					if(statuses[i]=="racing"){
						$(document.getElementById(emails[i])).append("<span class=\"glyphicon glyphicon-road\"></span>");
					}
				}
			}
		};

		//Broadcast recieved that a new user has connected and give needed info to mark them on the map
		channel.bind('new_user', function(data) {
			if(user_email!=data.email){
				var new_gravatar = get_gravatar(data.email);
		  		var new_player_pos =polyline.GetPointAtDistance(parseInt(data.distance));
		  		lobby_map_markers.push(
		  			new google.maps.Marker({
						position: new_player_pos,
						map: lobby_map,
						title: data.email,
						icon: new_gravatar
		  			})
		  		);
		  		map_markers.push(
		  			new google.maps.Marker({
						position: new_player_pos,
						map: map,
						title: data.email,
						icon: new_gravatar
		  			})
		  		);
		  		pan_markers.push(
		  			new google.maps.Marker({
						position: new_player_pos,
						map: pan,
						title: data.email,
						icon: new_gravatar
		  			})
		  		);
		  		//add to lobby
		  		$(".open_player_slot").first().after("<div class=\"player_tag\" id=\""+ data.email +"\"><img class=\"player_pic\" src=\""+ get_gravatar(data.email, 22) +"\"><span class=\"player_name_added\">"+ data.email +"</div></div>");
		  		$(".open_player_slot").first().remove()
		  		$("#info-players").html("Players "+(map_markers.length+1)+"/"+limit);
		  		if(racing){
		  			$(document.getElementById(data.email)).append("<span class=\"glyphicon glyphicon-road\"></span>");
		  		}
			}
		});

		//on disconnect, we need to send the user's info to the controller to be broadcasted to all clients
		window.onbeforeunload= function(data) {
			var disconnected_user = {email: user_email, chan: lobby_id};
			dispatcher.trigger('disconnect.terminate_session', disconnected_user);
		};

		//broadcast recived that this user has disconnected, so we need to remove them from the map
		channel.bind('dc_user', function(data) {
			var index_of_user = index_of_email(data.email);

			if(user_email!=data.email && index_of_user!=-1){ //sanity: other user being removed is in game
				lobby_map_markers[index_of_user].setMap(null);
				map_markers[index_of_user].setMap(null);
				pan_markers[index_of_user].setMap(null);
				lobby_map_markers.splice(index_of_user, 1);
				map_markers.splice(index_of_user, 1);
				pan_markers.splice(index_of_user, 1);

				//remove from lobby
				document.getElementById(data.email).remove();
				$(".open_player_slot").remove();
				for(var i=map_markers.length+2; i<=limit; i++){
					if(racing){
						$(".player_tag").last().after("<div class=\"open_player_slot\" style=\"display: none;\"><div id=\"waiting_"+i+"\" class=\"waiting_gif\"></div>Waiting for player...</div>");
					}else{
						$(".player_tag").last().after("<div class=\"open_player_slot\"><div id=\"waiting_"+i+"\" class=\"waiting_gif\"></div>Waiting for player...</div>");
					}
					var cl = new CanvasLoader("waiting_"+i);
					cl.setColor('#ffffff'); // default is '#000000'
					cl.setDiameter(22); // default is 40
					cl.setDensity(45); // default is 40
					cl.show(); // Hidden by default
				}
				
				$("#info-players").html("Players "+(map_markers.length+1)+"/"+limit);

				if(data.host_name!=$("#lobby_host").attr("value")){
					$("#lobby_host").attr("value", data.host_name);
					if(user_email==data.host_name && !racing){
						$("#lobby_btn").attr("value", "Start Game");
					}
				}
			}
		});	
	    
	    //user wants to update distance, so we tell the server. The server will broadcast that this user has moved
	    $('#update_dist').click(function(){
	    	var d = parseInt($('#dist').val());

	    	var update = {
			  update_distance: d
			}

			dispatcher.trigger('update_position.new_distance', update);
	    });

		//when a controller broadcast is recieved about a player moved, the markers are updated appropriately
		channel.bind('new_distance', function(data) {
			seconds = data.game_time
			if(data.email==user_email){//current user moved
		    	var player_pos = polyline.GetPointAtDistance(data.distance);
		    	marker.setPosition(player_pos);
		    	lobby_marker.setPosition(player_pos);
		    	pan.setPosition(player_pos);
		    	pan.setPov({heading: polyline.Bearing(player_pos, polyline.GetPointAtDistance(data.distance+0.01)), pitch: 0});
		    	map.setCenter(player_pos);
				map.setZoom(14);
			}else{//other user moved
				var i = index_of_email(data.email)
				if(i!=-1){	//sanity: other user that moved is in game
					var pos = polyline.GetPointAtDistance(data.distance);
					lobby_map_markers[i].setPosition(pos);
					map_markers[i].setPosition(pos);
					pan_markers[i].setPosition(pos);
				}
			}
			//update hud
			if(data.email==user_email){
				if(data.distance!=null){
					$('#distance').html((Math.round(data.distance*0.000621371*100.0)/100.0)+" Miles");
					if(data.update_time!=null && data.update_time!=0){
						$('#speed').html((Math.round((data.update_distance/data.update_time)*2.23694*100.0)/100.0)+" mph");
					}
				}
			}
			if(data.done==0){
				for(var i=0; i<data.standings.length; i++){
					if(data.standings[i][0]==user_email){
						$('#place').html(num_to_place(data.standings[i][1]));
						break;
					}
				}
			}

			if(data.done!=0){
				$(document.getElementById(data.email)).children().last().remove();
				if(data.email==user_email){
					points = [];
					for(var i=1; i<data.points.length; i++){
						points.push([data.points[i].game_time, Math.round(((data.points[i].distance-data.points[i-1].distance)/(data.points[i].game_time-data.points[i-1].game_time))*2.23694*100)/100])
					}
				    $('#container').highcharts({
				        chart: {
				            type: 'line'
				        },
				        title: {
				            text: 'Speed'
				        },
				        xAxis: {
				        	labels: {
							  enabled: false
							}
				        },
				        yAxis: {
				            title: {
				                text: 'Miles/Hour'
				            },
				            min: 0
				        },
				        series: [{
				            name: user_email,
				            data: points
				        }],
				        tooltip: {
						    formatter: function() {
						        return 'Time: <b>' + sec_to_time(this.x) + '</b><br> MPH: <b>' + this.y + '</b>';
						    }
						}
				    });
					seconds = 0.0;
					
					$('#finish_summary').html("<h5>Stats</h5><span id=\"stat-left\">Place: "+num_to_place(data.done)+"<br>Time: "+sec_to_time(data.time)+"<br>Distance Travelled: "+Math.round(data.distance*0.000621371192*100)/100+" miles<br></span><span id=\"stat-right\">Average Speed: "+Math.round((data.distance/data.time)*2.23694*100)/100+" mph<br>Est. Calories Burned: "+data.calories+"</span>");
					$("#lobby").fadeIn( "fast", function() {
						$('#finishModal').modal();
					});
				}
			}
		});

		/*
		*********************************************SET UP LOBBY********************************************************
		*/
		if(user_email==$("#lobby_host").attr("value")){
			$("#info").hide();
		}else{
			$("#edit").hide();
		}
		var filled_slots = $(".player_tag");
		var empty_slots = $(".open_player_slot");
		for(var i=0; i<filled_slots.length; i++){
			filled_slots.eq(i).children().first().attr("src", get_gravatar(filled_slots.eq(i).attr("id"), 22));
		}
		for(var i=0; i<empty_slots.length; i++){
			var cl = new CanvasLoader("waiting_"+(filled_slots.length+i));
			cl.setColor('#ffffff'); // default is '#000000'
			cl.setDiameter(22); // default is 40
			cl.setDensity(45); // default is 40
			cl.show(); // Hidden by default
		}

		//add map
		lobby_map = new google.maps.Map(document.getElementById('lobby-map'), {
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
		lobby_directionsDisplay = new google.maps.DirectionsRenderer({ map: lobby_map });

		lobby_directionsService = new google.maps.DirectionsService();
		lobby_directionsService.route(get_map($("#map_name").attr("value")), function(response, status) {
			if (status == google.maps.DirectionsStatus.OK) {
				lobby_directionsDisplay.setDirections(response);
			}
			else
				alert ('failed to get directions');
		});
		$("#chat-input-text").keyup(function(event){
		    if(event.keyCode == 13){
		        $("#chat-input-btn").click();
		    }
		});
		$("#chat-messages").hide();
		$("#chat-input").fadeTo(0, 0.10);
		$("#chat-input").click(function(){
			$("#chat-input").fadeTo(0, 1.0);
			$("#chat-messages").fadeIn("fast");
		});
		$("#chat").click( function(e){  
		   e.stopPropagation();
		});
		$("body").click(function(){
			$("#chat-input").fadeTo(0, 0.10);
			$("#chat-messages").fadeOut("fast");
		});
		$("#chat-input-text").val("");
		$("#chat-input-btn").click(function(){
			var mes = {
			  text: $("#chat-input-text").val()
			}
			$("#chat-input-text").val("");
			dispatcher.trigger("new_chat_message.chat_message", mes);
		});
		channel.bind('new_mes', function(data) {
			$('#chat-messages').append("<div class=\"chat-message\">"+data.sender+": "+data.message_text+"</p>");
			var objDiv = document.getElementById("chat-messages");
			objDiv.scrollTop = objDiv.scrollHeight;

		});
		$("#lobby_btn").click(function(){
			if($("#lobby_host").attr("value")==user_email &&  $("#lobby_btn").attr("value")=="Start Game"){
				dispatcher.trigger('start_race.start', {id: 'blank'});
			}else{
				if($("#lobby_btn").attr("value")=="Race"){
					$("#lobby").fadeOut()
					$("#chat-input").fadeTo(0, 1.0);
				}
			}
		});
		$("body").on("click","#end_race_btn",function(){
			if($("#lobby_host").attr("value")==user_email){
				dispatcher.trigger('end_race.end', {id: 'blank'});
			}
		});

		$("#edit_lobby_map").val($("#map_name").attr("value"));
		$("#edit_lobby_map").change(function(){
			dispatcher.trigger('edit_lobby_map.edit_map', {map: this.value});
		});
		channel.bind('change_map', function(data) {
			$("#edit_lobby_map").val(data.new_map);
			$("#info-map").html("Map "+data.new_map);


			request = get_map(data.new_map);
			//setup lobby map
			lobby_directionsService.route(request, function(response, status) {
				if (status == google.maps.DirectionsStatus.OK) {
					lobby_directionsDisplay.setDirections(response);
				}
				else
					alert ('failed to get directions');
			});


			directionsService.route(request, function(response, status) {
						if (status == google.maps.DirectionsStatus.OK) {
							directionsDisplay.setDirections(response);
						}
						else
							alert ('failed to get directions');
					});


			//add polyline based on route
			polyline = new google.maps.Polyline({
				path: [],
				strokeColor: '#0000FF',
				strokeWeight: 5
			});
			var bounds = new google.maps.LatLngBounds();

			directionsService.route(request, function(result, status) {
				var legs = result.routes[0].legs;
				for (i=0;i<legs.length;i++) {
				  var steps = legs[i].steps;
				  for (j=0;j<steps.length;j++) {
				    var nextSegment = steps[j].path;
				    for (k=0;k<nextSegment.length;k++) {
				      polyline.getPath().push(nextSegment[k]);
				      bounds.extend(nextSegment[k]);
				    }
				  }
				}

				polyline.setMap(map);
				map.fitBounds(bounds);


			  	//add all other player pins to minimap and panorama
			  	new_start = polyline.GetPointAtDistance(0);
				map.setCenter(new_start);

				//move all markers to new start
				for(var i=0; i<emails.length; i++){
					lobby_map_markers[i].setPosition(new_start);
					map_markers[i].setPosition(new_start);
					pan_markers[i].setPosition(new_start);
				}
				marker.setPosition(new_start);
		    	lobby_marker.setPosition(new_start);
		    	pan.setPosition(new_start);
		    	pan.setPov({heading: polyline.Bearing(new_start, polyline.GetPointAtDistance(0.01)), pitch: 0});
			});



		});
		
		$("#edit_limit").val(limit.toString());
		$("#edit_limit").change(function(){
			if(parseInt(this.value)>map_markers.length){
				dispatcher.trigger('edit_lobby_max.edit_max', {max: parseInt(this.value)});
			}else{
				$("#edit_limit").val(limit.toString());
			}
		});

		channel.bind('change_max', function(data) {
			limit = data.new_max
			$(".open_player_slot").remove();
			for(var i=map_markers.length+2; i<=limit; i++){
				if(racing){
					$(".player_tag").last().after("<div class=\"open_player_slot\" style=\"display: none;\"><div id=\"waiting_"+i+"\" class=\"waiting_gif\"></div>Waiting for player...</div>");
				}else{
					$(".player_tag").last().after("<div class=\"open_player_slot\"><div id=\"waiting_"+i+"\" class=\"waiting_gif\"></div>Waiting for player...</div>");
				}
				var cl = new CanvasLoader("waiting_"+i);
				cl.setColor('#ffffff'); // default is '#000000'
				cl.setDiameter(22); // default is 40
				cl.setDensity(45); // default is 40
				cl.show(); // Hidden by default
			}
			$("#edit_limit").val(limit.toString());
			$("#info-players").html("Players "+(map_markers.length+1)+"/"+limit);
		});

		channel.bind('start', function(data) {
			racing = true;
			$("#end_race_btn").show();
			$("#lobby_btn").attr("value", "Race");
			$(".open_player_slot").hide();
			$('#distance').html("0.00 Miles");
			$('#speed').html("0.00 mph");
			$('#place').html("-");
			$("#lobby").fadeOut();
	    	var player_pos = polyline.GetPointAtDistance(0);
			map.setCenter(player_pos);
			map.setZoom(14);
			seconds=0.0
			$('#clock').html(sec_to_time(seconds));
			timer = window.setInterval(function() { seconds+=1; $('#clock').html(sec_to_time_ch(seconds)); }, 1000);
			for(var i=0; i<$(".player_tag").length; i++){
				$(".player_tag").eq(i).append("<span class=\"glyphicon glyphicon-road\"></span>")
			}
			if(user_email==$("#lobby_host").attr("value")){
				$("#edit").hide();
				$("#info").show();
			}
		});


		channel.bind('restart', function(data) {
			racing = false;
			$("#end_race_btn").hide();
			$(".glyphicon").remove();
			if(user_email==$("#lobby_host").val()){
				$("#lobby_btn").attr("value", "Start Game");
				$("#info").hide();
				$("#edit").show();
			}else{
				$("#lobby_btn").attr("value", "Waiting for host...");
			}
			$(".open_player_slot").show();
			$("#lobby").fadeIn();
			//reset user position
	    	var player_pos = polyline.GetPointAtDistance(0);
	    	marker.setPosition(player_pos);
	    	lobby_marker.setPosition(player_pos);
	    	map.setCenter(player_pos);
	    	pan.setPosition(player_pos);
	    	pan.setPov({heading: polyline.Bearing(player_pos, polyline.GetPointAtDistance(0.01)), pitch: 0});
			for(var i=0; i<map_markers.length; i++){
				var pos = polyline.GetPointAtDistance(0);
				lobby_map_markers[i].setPosition(pos);
				map_markers[i].setPosition(pos);
				pan_markers[i].setPosition(pos);
			}
			$('#scoreboard').children().remove();
			for(var i=data.finishes.length-1; i>=0; i--){
				if(data.finishes[i].place==0){
					$('#scoreboard').append("<tr><td>DNF</td><td>"+data.finishes[i].email+"</td><td> - </td></tr>");
				}else{
					$('#scoreboard').prepend("<tr><td>"+data.finishes[i].place+"</td><td>"+data.finishes[i].email+"</td><td>"+sec_to_time(data.finishes[i].time)+"</td></tr>");
				}
			}
			window.clearInterval(timer);
			$('#endModal').modal();
		});

		channel.bind('new_host', function(data) {
			$("#info-host").html("Host: "+data.new_host_name);
			$("#lobby_host").attr("value", data.new_host_name);
			if(user_email==data.new_host_name){
				$("#controls").prepend("<input type=\"submit\" value=\"End Race\" id=\"end_race_btn\" class=\"btn btn-large btn-primary\" style=\"display: inline-block;\">");
				if(!racing){
					$("#info").hide();
					$("#edit").show();
					$("#end_race_btn").hide();
					$("#lobby_btn").attr("value", "Start Game");
				}
			}
		});

		$('body').keyup(function(e){
		   if(e.keyCode == 32 && racing && !$("#chat-input-text").is(":focus")){
		       // user has pressed space
		       $("#lobby").fadeToggle();

			$(".gm-style").first().eq(1).remove();
		   }
		});
		/*
		******************************************SET UP GOOGLE MAPS*****************************************************
		*/
		//create map
		map = new google.maps.Map(document.getElementById('map'), {
			mapTypeId: google.maps.MapTypeId.ROADMAP,
	  		streetViewControl: false
		});

		//add route
		var rendererOptions = { map: map };
		directionsDisplay = new google.maps.DirectionsRenderer(rendererOptions);

		var request = get_map($("#map_name").attr("value"));

		directionsService = new google.maps.DirectionsService();
		directionsService.route(request, function(response, status) {
					if (status == google.maps.DirectionsStatus.OK) {
						directionsDisplay.setDirections(response);
					}
					else
						alert ('failed to get directions');
				});


		//add polyline based on route
		polyline = new google.maps.Polyline({
		path: [],
		strokeColor: '#0000FF',
		strokeWeight: 5
		});
		var bounds = new google.maps.LatLngBounds();

		directionsService.route(request, function(result, status) {
			var legs = result.routes[0].legs;
			for (i=0;i<legs.length;i++) {
			  var steps = legs[i].steps;
			  for (j=0;j<steps.length;j++) {
			    var nextSegment = steps[j].path;
			    for (k=0;k<nextSegment.length;k++) {
			      polyline.getPath().push(nextSegment[k]);
			      bounds.extend(nextSegment[k]);
			    }
			  }
			}

			polyline.setMap(map);
			map.fitBounds(bounds);

			//add a users pin
			var distance = parseInt($("#start").val());
			var player_pos = polyline.GetPointAtDistance(distance);
			var gravatar = get_gravatar(user_email);

			marker = new google.maps.Marker({
				position: player_pos,
				map: map,
				title: user_email,
				icon: gravatar
		  	});
			lobby_marker = new google.maps.Marker({
				position: player_pos,
				map: lobby_map,
				title: user_email,
				icon: gravatar
		  	});

		  	//add panorama
			pan = new google.maps.StreetViewPanorama(document.getElementById('pan'), {
				position: player_pos,
			    addressControlOptions: {
			      position: google.maps.ControlPosition.BOTTOM_CENTER
			    },
			    linksControl: false,
			    panControl: false,
			    zoomControl: false,
			    enableCloseButton: false,
			    clickToGo: false,
			    scrollwheel: false,
			    disableDefaultUI: true,
			    pov: {
			    	heading: polyline.Bearing(player_pos, 
			    	polyline.GetPointAtDistance(distance+0.01)), pitch: 0
			    }
			});
		  	//add all other player pins to minimap and panorama
		  	for(var i=0; i<emails.length; i++){
		  		other_gravatar = get_gravatar(emails[i]);
		  		other_player_pos =polyline.GetPointAtDistance(parseInt(starts[i]));
		  		lobby_map_markers.push(
		  			new google.maps.Marker({
						position: other_player_pos,
						map: lobby_map,
						title: emails[i],
						icon: other_gravatar
		  			})
		  		);
		  		map_markers.push(
		  			new google.maps.Marker({
						position: other_player_pos,
						map: map,
						title: emails[i],
						icon: other_gravatar
		  			})
		  		);
		  		pan_markers.push(
		  			new google.maps.Marker({
						position: other_player_pos,
						map: pan,
						title: emails[i],
						icon: other_gravatar
		  			})
		  		);
		  	}
		});
		map.setCenter(polyline.GetPointAtDistance(0));
		map.setZoom(14);

	}
});

function index_of_email(email){
	for(var i=0;i<map_markers.length;i++){
		if(map_markers[i].getTitle()==email){
			return i;
		}
	}
	return -1;
}