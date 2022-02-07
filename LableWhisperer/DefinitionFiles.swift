//
//  Definitions.swift
//  LableWhisperer
//
//  Created by asc on 1/10/22.
//

import UIKit
import Foundation
import AccessionNumbers
import CryptoKit

public enum DefinitionFilesErrors: Error {
    case invalidRoot
    case invalidURL
    case notFound
    case networkUnavailable
}

public class DefinitionFiles {
    
    let app = UIApplication.shared.delegate as! AppDelegate
    
    var url_map: [String: URL] = [:]
    
    let github_data = "https://raw.githubusercontent.com/sfomuseum/accession-numbers/main/data/"
    
    let fm = FileManager.default
    
    var data_root: URL
    var user_root: URL
    
    public init() throws {
        
        let paths = fm.urls(for: .documentDirectory, in: .userDomainMask)
        user_root = paths[0]
        
        let bundle_root = Bundle.main.bundleURL
        data_root = bundle_root.appendingPathComponent("data.bundle")
        
        let setup_rsp = self.setupUserDefinitionFiles()
        
        switch setup_rsp {
        case .failure(let error):
            throw error
        case .success(_):
            ()
        }
        
        if app.network_available {
            self.FetchIndex()
        }
        
        let map_rsp = self.setupURLMap()
        
        switch map_rsp {
        case .failure(let error):
            throw error
        case .success:
            ()
        }
        
        
    }
    
    private func setupURLMap() -> Result<Bool, Error> {
        
        var urls: [URL]
        
        let list_rsp = self.List(root: self.user_root)
        
        switch list_rsp {
        case .failure(let error):
            return.failure(error)
        case .success(let results):
            urls = results
        }
        
        for u in urls {
            
            let def_rsp = self.LoadFromURL(url: u)
            
            switch def_rsp {
            case .failure(let error):
                return .failure(error)
            case .success(let def):
                url_map[ def.organization_url ] = u
            }
        }
        
        return .success(true)
    }
    
    private func setupUserDefinitionFiles() -> Result<Bool, Error> {
        
        var urls: [URL]
        
        let list_rsp = self.List(root: self.data_root)
        
        switch list_rsp {
        case .failure(let error):
            return .failure(error)
        case .success(let results):
            urls = results
        }
        
        for u in urls {
            
            let fname = u.lastPathComponent
            let local_u = self.user_root.appendingPathComponent(fname)
            
            let local_path = local_u.absoluteString.replacingOccurrences(of: "file://", with: "")
            
            // print(local_path)
            
            if (fm.fileExists(atPath: local_path)){
                // print("SKIP \(fname)")
                continue
            }
            
            // print("CREATE \(local_u)")
            
            let data_rsp = ReadFromURL(url: u)
            
            switch data_rsp {
            case .failure(let error):
                print("FAILED TO READ \(u) : \(error)")
                return .failure(error)
            case .success(let data):
                
                
                do {
                    try data.write(to: local_u)
                } catch (let error) {
                    print("FAILED TO WRITE \(local_u) : \(error)")
                    return .failure(error)
                }
            }
            
        }
        
        return .success(true)
    }
    
    public func FetchIndex() -> Result<Bool, Error> {
        
        if !app.network_available {
            return .failure(DefinitionFilesErrors.networkUnavailable)
        }
        
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
                print("NO DATA")
                return
            }
            
            let str_data = String(decoding: data!, as: UTF8.self)
            let filenames = str_data.split(separator: "\n")
            
            for f in filenames {
                
                let refresh_rsp = self.RefreshDataFile(filename: String(f))
                
                switch refresh_rsp {
                case .failure(let error):
                    print("Unable to refresh \(f) \(error)")
                case .success(_):
                    ()
                }
            }
            
        }
        
        task.resume()
        return .success(true)
    }
    
    public func RefreshDataFile(filename: String) -> Result<Bool, Error> {
        
        if !app.network_available {
            return .failure(DefinitionFilesErrors.networkUnavailable)
        }
        
        let user_url = self.user_root.appendingPathComponent(filename)
        
        // Check
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
            
            // It's very confusing keeping track of which methods need a URI scheme
            // and which don't...
            
            let path_exists = user_url.absoluteString.replacingOccurrences(of: "file://", with: "")
            
            if (fm.fileExists(atPath: path_exists)) {
                
                let data_rsp = ReadFromURL(url: user_url)
                
                switch data_rsp {
                case .failure(let error):
                    print("Failed to read \(user_url) because \(error)")
                    write_data = true
                case .success(let local_data):
                    
                    let local_hashed = SHA256.hash(data: local_data)
                    
                    // print("HASHES \(filename) LOCAL \(local_hashed) REMOTE \(remote_hashed)")
                    
                    if local_hashed != remote_hashed {
                        write_data = true
                    }
                }
                
            } else {
                // print("NO FILE \(user_url.absoluteString)")
                write_data = true
            }
            
            if !write_data {
                return
            }
            
            // print("REFRESH DATA \(filename) -> \(user_url)")
            
            do {
                try data!.write(to: user_url)
            } catch (let error) {
                print("SAD WRITE \(error)")
            }
            
            print("WROTE \(user_url.absoluteString)")
        }
        
        task.resume()
        return .success(true)
    }
    
    public func List(root: URL) -> Result<[URL], Error> {
        
        var directoryContents: [URL]
        
        do {
            directoryContents = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
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
