//
//  PDFView.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/17/24.
//

import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    
    let pdfDocument: PDFDocument
    
    init(showing pdfDoc: PDFDocument) {
        self.pdfDocument = pdfDoc
    }
    
    //you could also have inits that take a URL or Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = pdfDocument
    }
}

struct PDFViewer: View, Hashable {
    var pdfDoc: PDFDocument = PDFDocument()
    
    init(for url: URL) {
        do {
            let data = try Data(contentsOf: url)
            pdfDoc = PDFDocument(data: data)!
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var body: some View {
        PDFKitView(showing: pdfDoc)
    }
}
