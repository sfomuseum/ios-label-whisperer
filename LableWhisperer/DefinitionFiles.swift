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
    case notFound
}

public class DefinitionFiles {
    
    var root: URL
    var url_map: [String: URL] = [:]
    
    public init() throws {
        
        let data = Bundle.main.resourcePath! + "/data.bundle/"
        
        guard let url = URL(string: data) else {
            throw DefinitionFilesErrors.invalidRoot
        }
        
        root = url
        
        //
        
        var urls: [URL]
        
        let list_rsp = self.List()
        
        switch list_rsp {
        case .failure(let error):
            throw error
        case .success(let results):
            urls = results
        }
                
        for u in urls {
            
            let def_rsp = self.LoadFromURL(url: u)
            
            switch def_rsp {
            case .failure(let error):
                throw error
            case .success(let def):
                url_map[ def.organization_url ] = u
            }
        }
        
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

        // Remember url_map is built during the initializer
        
        for (_, u) in self.url_map {
            
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
    
    public func LoadFromOrganizationURL(organization_url: String) -> Result<Definition, Error> {

        guard let definition_url = self.url_map[organization_url] else {
            return .failure(DefinitionFilesErrors.notFound)
        }
        
        return self.LoadFromURL(url: definition_url)
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
