//
//  Definitions.swift
//  LableWhisperer
//
//  Created by asc on 1/10/22.
//

import Foundation
import AccessionNumbers
import CryptoKit

public enum DefinitionFilesErrors: Error {
    case invalidRoot
    case invalidURL
    case notFound
}

public class DefinitionFiles {
    
    var root: URL
    var url_map: [String: URL] = [:]
    
    let github_data = "https://raw.githubusercontent.com/sfomuseum/accession-numbers/main/data/"
    
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
        
        print("FETCH INDEX")
        self.FetchIndex()
    }
    
    public func FetchIndex() -> Result<Bool, Error> {
        
        guard let url = URL(string: github_data + "index.txt") else {
            return .failure(DefinitionFilesErrors.invalidURL)
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = TimeInterval(10)
        
        let task = URLSession.shared.dataTask(with: req) { [self] data, response, error in
            
            guard let rsp = response as? HTTPURLResponse else {
                print("WHAT")
                return
            }
            
            if error != nil {
                print(error)
                return
            }
            
            guard (200) ~= rsp.statusCode else {
                print(rsp.statusCode)
                return
            }
            
            if data == nil {
                return
            }
            
            let str_data = String(decoding: data!, as: UTF8.self)
            let filenames = str_data.split(separator: "\n")
            
            for f in filenames {
                self.RefreshDataFile(filename: String(f))
            }
            
        }
        
        task.resume()
        return .success(true)
    }
    
    public func RefreshDataFile(filename: String) -> Result<Bool, Error> {
        
        guard let url = URL(string: github_data + filename) else {
            return .failure(DefinitionFilesErrors.invalidURL)
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = TimeInterval(10)
        
        let task = URLSession.shared.dataTask(with: req) { [self] data, response, error in
            
            guard let rsp = response as? HTTPURLResponse else {
                print("WHAT")
                return
            }
            
            if error != nil {
                print(error)
                return
            }
            
            guard (200) ~= rsp.statusCode else {
                print(rsp.statusCode)
                return
            }
            
            if data == nil {
                return
            }
            
            let remote_hashed = SHA256.hash(data: data!)
            var write_data = false
            
            let local_path = Bundle.main.resourcePath! + "/data.bundle/" + filename
            let local_uri = "file://" + local_path
            let local_url = URL(string: local_uri)
            
            if local_url != nil {
                
                let data_rsp = ReadFromURL(url: local_url!)
                
                switch data_rsp {
                case .failure(let error):
                    print("Failed to read \(local_url) because \(error)")
                    write_data = true
                case .success(let local_data):
                    
                    let local_hashed = SHA256.hash(data: local_data)
                    
                    if local_hashed != remote_hashed {
                        write_data = true
                    }
                }
                
            } else {
                write_data = true
            }
            
            if !write_data {
                return
            }
            
            print("WRITE DATA \(filename)")
            
            do {
                try data!.write(to: local_url!)
            } catch (let error) {
                print("SAD WRITE \(error)")
            }
            
        }
        
        task.resume()
        return .success(true)
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
        
        let data_rsp = ReadFromURL(url: url)
        
        switch data_rsp {
        case .failure(let error):
            return .failure(error)
        case .success(let d):
            data = d
        }
        
        let decoder = JSONDecoder()
        
        do {
            def = try decoder.decode(Definition.self, from: data)
        } catch (let error){
            return .failure(error)
        }
        
        return .success(def)
    }
    
    private func ReadFromURL(url: URL) -> Result<Data, Error> {
        
        var data: Data
        
        do {
            data = try Data(contentsOf: url)
        } catch (let error){
            return .failure(error)
        }
        
        return .success(data)
    }
    
}
