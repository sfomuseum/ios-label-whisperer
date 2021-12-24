import Foundation

public struct CollectionRecord {
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
