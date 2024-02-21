//
//  CopyToDocDirectory.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/18/24.
//

import Foundation

func copyToDocumentDirectory(sourceUrl: URL) -> URL? {
    let fileManager = FileManager.default
    guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }
    
    let destinationURL = documentsDirectory.appendingPathComponent(sourceUrl.lastPathComponent)
    
    print("SOURCE: \(sourceUrl.absoluteString)")
    print("DESTINATION: \(destinationURL.absoluteString)")
    
    if fileManager.fileExists(atPath: destinationURL.path) {
        print("File with same name found at destination path. Attempting to delete...")
        deleteFromDocumentDirectory(at: destinationURL)
    }
    
    do {
        try FileManager.default.copyItem(at: sourceUrl, to: destinationURL)
        print("New file copied to app documents directory at path \(destinationURL.path())")
        return destinationURL
    } catch {
        print("\nError copying file: \(error.localizedDescription)")
        print("sourceUrl: \(sourceUrl)\n")
        return nil
    }
}

func deleteFromDocumentDirectory(at url: URL) {
    do {
        try FileManager.default.removeItem(at: url)
        print("File deleted successfully at path \(url.path())")
    } catch {
        print("\nError deleting file: \(error.localizedDescription)")
        print("sourceUrl: \(url)\n")
    }
}

