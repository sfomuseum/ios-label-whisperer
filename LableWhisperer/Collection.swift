import Foundation

public protocol Collection {
    func Collect(organization: String, accession_number: String) -> Result<Bool, Error>
}
