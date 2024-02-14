//
//  AttachedFile.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/17/24.
//

import Foundation

struct AttachedFile: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var url: URL?
}
