import Foundation

public struct CollectionRecord: Codable {
    public var organization: String
    public var accession_number: String
    public var created: Int64
}

public protocol Collection {
    func Collect(record: CollectionRecord) -> Result<Bool, Error>
    func Remove(record: CollectionRecord) -> Result<Bool, Error>
    func RecordFromOffset(offset: Int) -> Result<CollectionRecord, Error>
    func CountRecords() -> Result<Int, Error>
}

public func NewCollectionRecord(organization: String, accession_number: String) -> CollectionRecord {
    
    let created = Int64(NSDate().timeIntervalSince1970)
    
    let record = CollectionRecord(
        organization: organization,
        accession_number: accession_number,
        created: created
    )
    
    return record
}
