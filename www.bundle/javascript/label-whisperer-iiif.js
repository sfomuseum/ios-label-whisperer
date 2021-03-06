// Given a manifest URL fetch the document and then try to find the first
// IIIF ImageAPI profile URL and display it using Leaflet.IIIF
function label_whisperer_iiif_init(manifest_url){

    console.log("FETCH", manifest_url);
    let req = new Request(manifest_url);

    fetch(req)
	.then(function(rsp) {
        
	    if (!rsp.ok) {
            console.log("ERROR", rsp);
            throw new Error(`HTTP error! status: ${rsp.status}`);
	    }
	    
	    return rsp.blob();
	})
	.then(function(rsp) {

        console.log("IIIF RESPONSE");
	    let reader = new FileReader();

	    reader.onload = function() {
		
		let data = JSON.parse(this.result);
		
		var profile_url = label_whisperer_profile_url_from_manifest(data);
		
            console.log("SHOW", profile_url);
            
		if (profile_url){
		    label_whisperer_iiif_show_tiles(profile_url);
		}
	    };

	    reader.readAsText(rsp);	   
	});
}

function label_whisperer_profile_url_from_manifest(data){

    var profile_url;
    
    let items = data["items"];
    let count_items = items.length;

    for (var i=0; i < count_items; i++) {

	if (items[i]["type"] != "Canvas"){
	    continue;
	}

	profile_url = label_whisperer_profile_url_from_canvas(items[i]);

	if (profile_url){
	    break;
	}
    }

    console.log("label_whisperer_profile_url_from_manifest", profile_url);
    return profile_url;
}

function label_whisperer_profile_url_from_canvas(data){

    var profile_url;
    
    let items = data["items"];
    let count_items = items.length;

    for (var i=0; i < count_items; i++) {

	if (items[i]["type"] != "AnnotationPage"){
	    continue;
	}

	profile_url = label_whisperer_profile_url_from_annotation(items[i]);

	if (profile_url){
	    break;
	}
    }

    console.log("label_whisperer_profile_url_from_canvas", profile_url);
    return profile_url;    
}

function label_whisperer_profile_url_from_annotation(data){

    var profile_url;
    
    let items = data["items"];
    let count_items = items.length;

    for (var i=0; i < count_items; i++) {

	if (items[i]["type"] != "Annotation"){
	    continue;
	}

	if (items[i]["motivation"] != "painting"){
	    continue;
	}

	let body = items[i]["body"];
	
	if (! body["service"]){
	    continue;
	}
	
	profile_url = label_whisperer_profile_url_from_services(body["service"]);

	if (profile_url){
	    break;
	}
    }

    console.log("label_whisperer_profile_url_from_annotation", profile_url);
    
    return profile_url;    
}

function label_whisperer_profile_url_from_services(services){

    var profile_url;

    let count_services = services.length;

    for (var i=0; i < count_services; i++){

	// Allow other image services
	if (services[i]["type"] != "ImageService2"){
	    continue;
	}

	profile_url = services[i]["profile"];
	break;
    }

    console.log("label_whisperer_profile_url_from_services", profile_url);
    return profile_url;        
}

function label_whisperer_iiif_show_tiles(profile_url){
    
    var map_id = "map";
    
    var map_args = {
	center: [0.0, 0.0],
	zoom: 1,
	crs: L.CRS.Simple,
	minZoom: 1,
	// fullscreenControl: true,
	preferCanvas: true,
    };

    map = L.map(map_id, map_args);
	    
    var tile_opts = {
	fitBounds: true,
	quality: "color",
    };
    	    
    var tile_layer = L.tileLayer.iiif(profile_url, tile_opts)
    tile_layer.addTo(map);

}

