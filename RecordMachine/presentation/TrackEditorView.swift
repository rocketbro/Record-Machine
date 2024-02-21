//
//  TrackEditorView.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/3/24.
//

import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

struct TrackEditorView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var track: Track
    @Binding var path: NavigationPath
    @Query var albums: [Album]
    @State private var audioFileName: String = "Import an audio file"
    @State private var showingAudioPlayer = false
    @State private var presentPdfImporter = false
    
    @State private var showingAlert = false
    @State private var attachedFileName = ""
    @State private var attachedFileUrl: URL? = nil
    
    enum KeyboardFocus {
        case title, writers, bpm, trackNotes, lyrics
    }
    @FocusState private var keyboardFocus: KeyboardFocus?
    
    var body: some View {
        ZStack {
            Form {
                Section {
                    HStack {
                        Text("Title:")
                        Spacer()
                        TextField("Title", text: $track.title)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(primaryOrange)
                            .focused($keyboardFocus, equals: .title)
                            .submitLabel(.done)
                            .onSubmit { keyboardFocus = nil }
                        
                    }
                    HStack {
                        Text("Writers:")
                        Spacer()
                        TextField("Writers", text: $track.writers)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(primaryOrange)
                            .focused($keyboardFocus, equals: .writers)
                            .submitLabel(.done)
                            .onSubmit { keyboardFocus = nil }
                    }
                    
                    HStack {
                        Text("BPM:")
                        Spacer()
                        TextField("BPM", value: $track.bpm, format: .number)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(primaryOrange)
                            .focused($keyboardFocus, equals: .bpm)
                            .submitLabel(.done)
                            .onSubmit { keyboardFocus = nil }
                    }
                    
                    Picker("Key", selection: $track.key) {
                        ForEach(MusicKey.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    Picker("Genre", selection: $track.genre) {
                        ForEach(MusicGenre.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    Picker("Album", selection: $track.album) {
                        ForEach(albums) { album in
                            Text(album.title).tag(album as Album?)
                        }
                        Text("None").tag(nil as Album?)
                    }
                    .pickerStyle(.navigationLink)
                    
                    TextField("Track notes", text: $track.notes, axis: .vertical)
                        .focused($keyboardFocus, equals: .trackNotes)
                    
                } header: {
                    Text("Track Info")
                }
                
                Section {
                    if !track.attachedFiles.isEmpty {
                        List {
                            ForEach(track.attachedFiles) { file in
                                NavigationLink(file.title) {
                                    PDFViewer(for: file.url!)
                                }
                            }
                            .onDelete(perform: deleteFiles)
                            .onMove(perform: moveFiles)
                        }
                    }
                    
                    Button(action: {
                        presentPdfImporter.toggle()
                    }) {
                        Text("Attach PDF or Text File")
                    }
                    .fileImporter(isPresented: $presentPdfImporter, allowedContentTypes: [UTType.pdf, UTType.text]) { result in
                        switch result {
                        case .success(let url):
                            if url.startAccessingSecurityScopedResource() {
                                let localUrl = copyToDocumentDirectory(sourceUrl: url)
                                if let localUrl = localUrl {
                                    print(localUrl)
                                    attachedFileUrl = localUrl
                                }
                                showingAlert.toggle()
                            }
                            url.stopAccessingSecurityScopedResource()
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    }
                    .alert("Name Attached File", isPresented: $showingAlert) {
                        TextField("File name", text: $attachedFileName)
                        Button("Attach") {
                            let file = AttachedFile(title: attachedFileName, url: attachedFileUrl!)
                            print(file)
                            track.attachedFiles.append(file)
                        }
                        Button("Cancel", role: .cancel) {
                            attachedFileName = ""
                            attachedFileUrl = nil
                        }
                    } message: {
                        Text("This name will be an in-app display name. External file names will remain unchanged.")
                    }
                    
                } header: {
                    Text("Attached Files")
                }
                
                Section {
                    TextEditor(text: $track.lyrics)
                        .frame(minHeight: 500)
                        .scrollDismissesKeyboard(.interactively)
                        .focused($keyboardFocus, equals: .lyrics)
                } header: {
                    Text("Lyrics")
                }
            }
            .navigationTitle("Edit Track")
            .navigationBarTitleDisplayMode(.inline)
            .zIndex(1)
            .toolbar {
                
                if keyboardFocus == .trackNotes || keyboardFocus == .lyrics {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { keyboardFocus = nil }
                    }
                }
                
                ToolbarItem {
                    Button(action: {
                        withAnimation {
                            showingAudioPlayer.toggle()
                        }
                    }) {
                        Image(systemName: showingAudioPlayer ? "hifispeaker.2.fill" : "hifispeaker.2")
                    }
                }
            }
            .onAppear {
                if track.audioUrl != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation { showingAudioPlayer = true }
                    }
                }
            }
            
            if showingAudioPlayer {
                withAnimation {
                    VStack {
                        Spacer()
                        AudioFilePlayer(track: track, fileName: $audioFileName)
                            .padding(.horizontal)
                            .shadow(color: .black.opacity(0.35), radius: 20)
                            .transition(.move(edge: .bottom))
                    }
                    .zIndex(2)
                }
            }
            
        }
    }
    
    func deleteFiles(_ indexSet: IndexSet) {
        for i in indexSet {
            print("\nRemoving file at \(track.attachedFiles[i].url!)...")
            deleteFromDocumentDirectory(at: track.attachedFiles[i].url!)
            print("Done.\n")
        }
        track.attachedFiles.remove(atOffsets: indexSet)
    }
    
    func moveFiles(from source: IndexSet, to destination: Int) {
        track.attachedFiles.move(fromOffsets: source, toOffset: destination)
    }
}
