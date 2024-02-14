//
//  AttachedFileView.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/17/24.
//

import SwiftUI

struct AttachedFileView: View {
    @Binding var file: AttachedFile
    @State private var fileName: String = ""
    
    var body: some View {
        VStack {
            PDFViewer(for: file.url!)
            TextField("File name", text: $fileName)
                .textFieldStyle(.roundedBorder)
                .onAppear { fileName = file.title }
                .onSubmit { file.title = fileName }
        }
    }
}
