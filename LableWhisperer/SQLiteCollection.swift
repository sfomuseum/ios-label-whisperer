import Foundation
import FMDB

public enum SQLiteCollectionErrors: Error {
    case missingDatabaseRoot
    case databaseOpen
    case databaseCreate
    case recordNotFound
}

public class SQLiteCollection: Collection {
    
    private var db: FMDatabase
    
    private var db_name = "collection.db"
    
    public init() throws {
        
        let fm = FileManager.default
        
        let paths = fm.urls(for: .documentDirectory, in: .userDomainMask)
        let root = paths[0]
        
        let db_uri = root.appendingPathComponent(self.db_name)

        /*
        let wtf = db_uri.absoluteString.replacingOccurrences(of: "file://", with: "")
        print(wtf)
        
        if fm.fileExists(atPath: wtf) {
            print("DELET")
            try fm.removeItem(atPath: wtf)
        }
        */
        
        db = FMDatabase(url: db_uri)
        
        guard db.open() else {
            throw SQLiteCollectionErrors.databaseOpen
        }
        
        let create_rsp = self.createTable()
        
        switch create_rsp {
        case .failure(let error):
            throw error
        case .success:
            ()
        }        
    }

    private func createTable() -> Result<Bool, Error> {
        
        let sql = "CREATE TABLE IF NOT EXISTS collection(organization TEXT, accession_number TEXT, created INTEGER);" +
            "CREATE UNIQUE INDEX by_pair ON collection(organization, accession_number);" +
            "CREATE INDEX on_timestamp ON collection(created)"
        
        do {
            try db.executeUpdate(sql, values: [])
        } catch (let error) {
            return .failure(error)
        }
                    
        return .success(true)
    }
    
    /*
     
     OKAY
     2021-12-24 10:02:31.466381-0800 LableWhisperer[1949:354764] Error: the bind count is not correct for the # of variables (executeQuery)
     Error Domain=FMDatabase Code=0 "not an error" UserInfo={NSLocalizedDescription=not an error}

     */
    
    public func CountRecords() -> Result<Int, Error> {
        
        let sql = "SELECT COUNT(accession_number) AS count FROM collection"
        var count = 0
        
        var rs: FMResultSet
        
        do {
            rs = try db.executeQuery(sql, values: nil)            
        } catch (let error){
            print("SAD \(sql) \(error)")
            return .failure(error)
        }
        
       rs.next()
            
        let i = rs.int(forColumn: "count")
        
        if i != 0 {
                count = Int(i)
        }
        
        return .success(count)
    }
    
    public func RecordFromOffset(offset: Int) -> Result<CollectionRecord, Error> {
        
        let sql = "SELECT organization, accession_number, created FROM collection ORDER BY created DESC LIMIT 1 OFFSET ?"
        
        var rs: FMResultSet
        
        print("\(sql) \(offset)")
        
        do {
            rs = try db.executeQuery(sql, values: [offset])
            
        } catch (let error){
            print("SAD WHAT \(error)")
            return .failure(error)
        }
        
       rs.next()
        
        print("NEXT")
        
        guard let org = rs.string(forColumn: "organization") else {
            return .failure(SQLiteCollectionErrors.recordNotFound)
        }
        
        guard let num = rs.string(forColumn: "accession_number") else {
            return .failure(SQLiteCollectionErrors.recordNotFound)
        }
        
        let i = rs.int(forColumn: "created")
        var ts = Int64(0)
        
        if i != 0 {
            ts = Int64(i)
        }
        
        let rec = CollectionRecord(organization: org, accession_number: num, created: ts)
        return .success(rec)
    }
        
    public func Collect(record: CollectionRecord) -> Result<Bool, Error> {
        
        do {
            let sql = "INSERT INTO collection(organization, accession_number, created) VALUES(?,?,?)" +
                "  ON CONFLICT DO UPDATE SET organization=?"
                        
            try db.executeUpdate(sql, values: [record.organization, record.accession_number, record.created, record.organization])
        } catch (let error){
            return .failure(error)
        }
        
        return .success(true)
    }
    
    public func Remove(record: CollectionRecord) -> Result<Bool, Error> {
        
        do {
            let sql = "DELETE FROM collection WHERE organization = ? AND  accession_number = ?"
                        
            try db.executeUpdate(sql, values: [record.organization, record.accession_number])
        } catch (let error){
            return .failure(error)
        }
        
        return .success(true)
    }
}
