//
//  CopyToDocDirectory.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/18/24.
//

import Foundation

func copyToDocumentDirectory(sourceUrl: URL) -> URL? {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }

    let destinationURL = documentsDirectory.appendingPathComponent(sourceUrl.lastPathComponent)

    do {
        try FileManager.default.copyItem(at: sourceUrl, to: destinationURL)
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
        print("File deleted successfully!")
    } catch {
        print("\nError deleting file: \(error.localizedDescription)")
        print("sourceUrl: \(url)\n")
    }
}

