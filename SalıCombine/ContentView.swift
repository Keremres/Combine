//
//  ContentView.swift
//  SalıCombine
//
//  Created by Kerem RESNENLİ on 23.11.2024.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject var contentViewModel: ContentViewModel
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    @State var count: Date = Date()
    
    init() {
        _contentViewModel = StateObject(wrappedValue: ContentViewModel())
    }
    
    var body: some View {
        VStack {
            PhotosPicker(selection: $contentViewModel.photosPickerItem, label: {
                photosPicker()
            })
            clock
            viewModelClock
            startStopViewModelClock
            HStack{
                textField
                viewModelText
                    .frame(width: 50, height: 50)
            }
            .padding()
            connectedButton
            combineService
        }
        .animation(.easeIn, value: contentViewModel.timer)
        .onReceive(timer) { value in
            withAnimation(.easeIn){
                count = value
            }
        }
    }
}

#Preview {
    ContentView()
}

extension ContentView {
    private var clock: some View {
        Text("\(count.formatted(.dateTime.second().minute().hour()))")
            .font(.title2)
    }
    
    private var startStopViewModelClock: some View {
        Button {
            contentViewModel.timer != nil ? contentViewModel.stopTimer() : contentViewModel.startTimer()
        } label: {
            Text("ViewModel Clock Start/Stop")
                .padding(5)
                .background(contentViewModel.timer != nil ? Color.green.clipShape(.capsule) : Color.red.clipShape(.capsule))
                .tint(.white)
        }
        
    }
    
    private var viewModelClock: some View {
        contentViewModel.timer != nil ? Text("\(contentViewModel.timer?.formatted(.dateTime.second().minute().hour()) ?? "")")
            .font(.title2) : Text("")
    }
    
    private var viewModelText: some View {
        Circle().foregroundStyle(contentViewModel.textValue ? .green : .red)
    }
    
    private var textField: some View {
        TextField("Enter Text", text: $contentViewModel.text)
            .padding(.leading)
            .frame(height: 50)
            .font(.title2)
            .background(Color.gray.clipShape(.capsule))
            .overlay {
                Capsule().stroke(lineWidth: 2).fill(contentViewModel.textValue ? Color.green : Color.red).frame(height: 50)
            }
    }
    
    private var connectedButton: some View {
        Button { } label: {
            Text("\(contentViewModel.isButtonEnabled ? "True" : "False")")
                .padding(10)
                .background(contentViewModel.isButtonEnabled ? Color.green.clipShape(.capsule) : Color.red.clipShape(.capsule))
                .opacity(contentViewModel.isButtonEnabled ? 1 : 0.5)
                .tint(.white)
        }
        .disabled(!contentViewModel.isButtonEnabled)
    }
    
    private var combineService: some View {
        HStack(alignment: .top) {
            VStack {
                Text("basicPublisher :")
                ForEach(contentViewModel.basicPublisher, id: \.self){
                    Text($0)
                }
            }
            VStack {
                Text("currentValue :")
                ForEach(contentViewModel.currentValuePublisher, id: \.self){
                    Text($0)
                }
            }
            VStack {
                Text("passThrough :")
                ForEach(contentViewModel.passThroughPublisher, id: \.self){
                    Text($0)
                }
            }
        }
    }
    
    @ViewBuilder
    func photosPicker() -> some View {
        if let image = contentViewModel.uiImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 150)
                .cornerRadius(30)
                .shadow(radius: 10)
        } else {
            Image(systemName: "photo.badge.plus")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .foregroundStyle(.red)
                .cornerRadius(30)
                .shadow(radius: 10)
        }
    }
}
