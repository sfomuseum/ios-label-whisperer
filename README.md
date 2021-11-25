# ios-label-whisperer

iOS application to extract accession numbers from wall labels using Vision and VisionKit frameworks.

## Important

This is experimental work in progress. It is still just a barely modified clone of Apple's [Structuring Recognized Text on a Document](https://developer.apple.com/documentation/vision/structuring_recognized_text_on_a_document) sample project.

It works enough to scan and extract text from a camera source and to print that text to the screen, but that's all it does so far. There is no documentation to speak of. If you're not familiar with your way around an iOS project this may be too soon for you.

### Also

This project was accidentally named `LableWhisperer` in XCode. There are a bunch of things to figure out.

## How does it work

* At start up the application loads one or more accession number "definition" files. These are the JSON files in the `data` directory of the [accession-numbers](https://github.com/sfomuseum/accession-numbers) repository. At the moment there is exactly one definition file ([sfomuseum.json](https://github.com/sfomuseum/accession-numbers/blob/main/data/sfomuseum.json)) and it is hardcoded.

* Given a `VNRecognizedTextObservation` instance the application builds a text string which is then passed to the `ExtractFromText` method (defined in the [swift-accession-numbers](https://github.com/sfomuseum/swift-accession-numbers) package). For example: 

```
    func addRecognizedText(recognizedText: [VNRecognizedTextObservation]) {

        var transcript = ""
        let maximumCandidates = 1
        for observation in recognizedText {
            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
            transcript += candidate.string
            transcript += "\n"
        }

	// var defintions = [Definitions]()
	// populate definitions here...
	
        let rsp = ExtractFromText(text: transcript, definitions: definitions)
        var text = ""
        
        switch rsp {
        case .failure(let error):
            print("Failed to extract accession numbers from text, \(error).")
        case .success(let results):
            for n in results {
                text += "\(n.accession_number) (\(n.organization))\n"
            }
        }
        
        self.scanned_text?.text = text
    }
```

## What does it do?

Currently the application:

* Loads all the "definition" files in [data.bundle](data.bundle) at launch. Although multiple definition files are supported, there is currently only one bundled with the app for reasons discussed below.
* Display a `Scan` button which launches a `VNRecognizedTextObservation` process.
* Call the `ExtractFromText` method (from the [swift-accession-numbers](https://github.com/sfomuseum/accession-numbers) package with the text results of the `VNRecognizedTextObservation` process.
* Display a "table view" with the resulting matches.

## Next steps

Next steps are:

* Some sort of preferences window for enabling or disabling definitions. There are enough variations in the patterns that different organizations use that matching any text against all the supported definitions will result in bunk matches. _Eventually if and when we have sufficient geographic data for organizations (see the `whosonfirst_id` property in definition files) we might be able to load or filter definition files using geo-fencing but that is probably still a ways off from being a reality._

* Better error handling and feedback if there are no matching accession numbers.

* Think about actions (or Protocols) for things to _do_ with an accession number. For example, calling an API to get more information about an object. Maybe that doesn't belong here and maybe this just needs to be a plain vanilla package library, or framework, that hides a bunch of boiler-plate code with "a button" that returns accession numbers.

## Help wanted

I don't live and breathe iOS applications so any suggestions or contributions, particularly on the subjects discussed in the `Next steps` section would be welcome.

The goal is to create a framework, or at least a working reference implementation, for an application that can be configured to extract accession numbers from museum wall labels. It should be possible to configure "extractors" for multiple accession numbers and to associate them with one or more museums.

What happens next is probably out of scope for this package and best left to a custom project that imports it.

## Background

For background have a look at the 2014 blog post [Label Whisperer](https://labs.cooperhewitt.org/2014/label-whisperer/) from the Cooper Hewitt labs.

## Examples

### Hand-drawn

![](docs/images/label-whisperer-001.jpg)

### Cooper Hewitt

_Things I'd forgotten about #1: We did not include accession numbers on the wall labels at Cooper Hewitt after the re-opening in 2014._

![](docs/images/label-whisperer-002.jpg)

### Cooper Hewitt (online)

![](docs/images/label-whisperer-003.jpg)

### Cooper Hewitt (online, print)

_Things I'd forgotten about #2: We made a print stylesheet for the experimental `/label` URL for every object page at Cooper Hewitt._

![](docs/images/label-whisperer-004.jpg)

### SFO Museum (online)

![](docs/images/label-whisperer-005.jpg)

## See also

* https://github.com/sfomuseum/accession-numbers
* https://github.com/sfomuseum/swift-accession-numbers
* https://labs.cooperhewitt.org/2014/label-whisperer/
* https://github.com/cooperhewitt/label-whisperer
* https://developer.apple.com/documentation/vision/structuring_recognized_text_on_a_document
