//
//  Definitions.swift
//  LableWhisperer
//
//  Created by asc on 1/10/22.
//

import Foundation
import AccessionNumbers

public enum DefinitionFilesErrors: Error {
    case invalidRoot
}

public class DefinitionFiles {
    
    var root: URL
    
    public init() throws {
        
        let data = Bundle.main.resourcePath! + "/data.bundle/"
        
        guard let url = URL(string: data) else {
            throw DefinitionFilesErrors.invalidRoot
        }
        
        root = url
    }
    
    public func List() -> Result<[URL], Error> {                
        
        var directoryContents: [URL]
        
        do {
            directoryContents = try FileManager.default.contentsOfDirectory(at: self.root, includingPropertiesForKeys: nil)
        } catch (let error) {
            return .failure(error)
        }
        
        let definitions = directoryContents.filter({ $0.pathExtension == "json" })
        return .success(definitions)
    }
    
    public func Load() -> Result<[Definition], Error> {
        
        var definitions = [Definition]()
        var urls: [URL]
        
        let list_rsp = self.List()
        
        switch list_rsp {
        case .failure(let error):
            return .failure(error)
        case .success(let results):
            urls = results
        }
        
        // TO DO: This, but asynchronously
        
        for u in urls {
            
            let def_rsp = self.LoadFromURL(url: u)
            
            switch def_rsp {
            case .failure(let error):
                return .failure(error)
            case .success(let def):
                definitions.append(def)
            }
        }
        
        return .success(definitions)
    }
    
    public func LoadFromURL(url: URL) -> Result<Definition, Error> {
        
        var data: Data
        var def: Definition
        
        do {
            data = try Data(contentsOf: url)
        } catch (let error){
            return .failure(error)
        }
        
        let decoder = JSONDecoder()
        
        do {
            def = try decoder.decode(Definition.self, from: data)
        } catch (let error){
            return .failure(error)
        }
        
        return .success(def)
    }
}
