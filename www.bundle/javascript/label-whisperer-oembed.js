// Given a oEmbed URL fetch the document and then render web page
function label_whisperer_oembed_init(oembed_url){

    console.log("FETCH", oembed_url);
    let req = new Request(oembed_url);

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

		render_oembed_data(data);
	    };

	    reader.readAsText(rsp);	   
	});
}

function render_oembed_data(data){

    console.log("RENDER", data);
}
