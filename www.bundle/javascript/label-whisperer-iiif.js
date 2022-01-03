function label_whisperer_iiif_init(iiif_profile){

    var map_id = "map";
    
    var map_args = {
	center: center,
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
    	    
    var tile_layer = L.tileLayer.iiif(iiif_profile, tile_opts)
    tile_layer.addTo(map);
    
}
