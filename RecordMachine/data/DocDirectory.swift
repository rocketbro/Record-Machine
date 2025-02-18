//
//  CopyToDocDirectory.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/18/24.
//

import Foundation

struct DocumentsManager {
    
    private init() { }
    
    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func fileExists(filename: String) -> Bool {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    static func getFileUrl(filename: String) -> URL? {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    static func copyToDocumentDirectory(sourceUrl: URL) -> URL? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("DocumentsManager: Failed to get documents directory")
            return nil
        }
        
        let destinationURL = documentsDirectory.appendingPathComponent(sourceUrl.lastPathComponent)
        
        print("\nDocumentsManager: Copying file...")
        print("DocumentsManager: Source URL: \(sourceUrl)")
        print("DocumentsManager: Source path exists: \(fileManager.fileExists(atPath: sourceUrl.path))")
        print("DocumentsManager: Destination URL: \(destinationURL)")
        print("DocumentsManager: Destination path exists: \(fileManager.fileExists(atPath: destinationURL.path))")
        
        // Check if source file is readable
        if !fileManager.isReadableFile(atPath: sourceUrl.path) {
            print("DocumentsManager: Source file is not readable!")
            return nil
        }
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            print("DocumentsManager: File exists at destination, attempting to delete...")
            deleteFromDocumentDirectory(at: destinationURL)
        }
        
        do {
            try FileManager.default.copyItem(at: sourceUrl, to: destinationURL)
            print("DocumentsManager: File copied successfully")
            print("DocumentsManager: Verifying copied file...")
            print("DocumentsManager: File exists at destination: \(fileManager.fileExists(atPath: destinationURL.path))")
            print("DocumentsManager: File is readable: \(fileManager.isReadableFile(atPath: destinationURL.path))")
            
            // Try to read the file attributes
            if let attrs = try? fileManager.attributesOfItem(atPath: destinationURL.path) {
                print("DocumentsManager: File size: \(attrs[.size] ?? 0) bytes")
                print("DocumentsManager: File type: \(attrs[.type] ?? "unknown")")
            }
            
            return destinationURL
        } catch {
            print("\nDocumentsManager: Error copying file: \(error.localizedDescription)")
            print("DocumentsManager: Detailed error: \(error)")
            return nil
        }
    }

    static func deleteFromDocumentDirectory(at url: URL) {
        print("\nDocumentsManager: Attempting to delete file at \(url)")
        print("DocumentsManager: File exists before deletion: \(FileManager.default.fileExists(atPath: url.path))")
        
        do {
            try FileManager.default.removeItem(at: url)
            print("DocumentsManager: File deleted successfully")
            print("DocumentsManager: File exists after deletion: \(FileManager.default.fileExists(atPath: url.path))")
        } catch {
            print("DocumentsManager: Error deleting file: \(error.localizedDescription)")
            print("DocumentsManager: Detailed error: \(error)")
        }
    }
}

