import Foundation
import FMDB

public enum SQLiteCollectionErrors: Error {
    case missingDatabaseRoot
    case databaseOpen
    case databaseCreate
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
        
        let sql = "CREATE TABLE IF NOT EXISTS collection(organization TEXT, accession_number TEXT);" +
            "CREATE UNIQUE INDEX by_pair ON collection(organization, accession_number);"
        
        do {
            try db.executeUpdate(sql, values: [])
        } catch (let error) {
            return .failure(error)
        }
                    
        return .success(true)
    }
    
    public func Collect(organization: String, accession_number: String) -> Result<Bool, Error> {
        
        do {
            let sql = "REPLACE INTO collection(organization, accession_number) VALUES(?,?)"
            
            print("\(sql) \(organization) \(accession_number)")
            
            try db.executeUpdate(sql, values: [organization, accession_number])
        } catch (let error){
            return .failure(error)
        }
        
        return .success(true)
    }
    
}
