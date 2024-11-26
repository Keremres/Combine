//
//  ContentViewModel.swift
//  SalıCombine
//
//  Created by Kerem RESNENLİ on 23.11.2024.
//

import Foundation
import SwiftUI
import PhotosUI
import Combine

final class ContentViewModel: ObservableObject {
    @Published private(set) var timer: Date? = Date()
    
    
    @Published var photosPickerItem: PhotosPickerItem? = nil {
        didSet {
            setImage(from: photosPickerItem)
        }
    }
    @Published private(set) var uiImage: UIImage? = nil
    
    
    @Published var text: String = ""
    @Published private(set) var textValue: Bool = false
    @Published private(set) var isButtonEnabled: Bool = false
    
    
    private let combineService = CombineDataService()
    @Published private(set) var basicPublisher: [String] = []
    @Published private(set) var currentValuePublisher: [String] = []
    @Published private(set) var passThroughPublisher: [String] = []
    
    
    private var cancellable: AnyCancellable? = nil
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        startTimer()
        subscribeTextField()
        dubleSubscription()
        subscribeToBasicPublisher()
        subscribeToCurrentValuePublisher()
        subscribeToPassThroughPublisher()
    }
    
    func stopTimer() {
        cancellable?.cancel()
        cancellable = nil
        timer = nil
    }
    
    func startTimer() {
        cancellable = Timer.publish(every: 1, on: .current, in: .common)
            .autoconnect()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    withAnimation{
                        self?.timer = nil
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] value in
                //                self kontrol edilir ise self'in olmadığı durumda kod bloğu atlanır
                //                self kontrol edilmez ve optional olarak bırakılırsa kod bloğu çalışır ama self ler işlenmez
                //                selfin kontol edilmesi performans artışı sağlayabilir
                //                guard let self = self else { return }
                //                withAnimation{
                self?.timer = value
                //                }
            })
    }
    
    func stopSubscription() {
        cancellables.removeAll()
        cancellables = []
    }
    
    func subscribeTextField() {
        $text
        //        kulanıcı yazı yazarken her harf girdiğinde abonelik tetiklenir ve kod bloğu her seferinde çalışır
        //        bunu engellemek için biraz zaman ekliyoruz her etkileşimden belirlediğimiz süre sonra kod bloğu çalışır
        //        kullanıcı belirlediğimiz süre içirisinde etkileşimde bulunmaya devam ederse işlem yapmadan etkileşimin bitmesini bekleriz
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .map { $0.count > 3 ? true : false }
        //        to: Publisher'dan gelen değerin atanacağı property.
        //        on: Değerin atanacağı nesne (örneğin, bir sınıf ya da bir @Published değişkenin sahibi olan nesne).
        //        .assign de self'i weak yapamıyoruz onun yerine .sink kullanarak weak self yapabiliriz
            .assign(to: \.textValue, on: self)
            .store(in: &cancellables)
    }
    
    func dubleSubscription() {
        Publishers.CombineLatest($text, $textValue)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] text, textValue in
                guard let self else { return }
                self.isButtonEnabled = text.count > 5 && textValue
            }
            .store(in: &cancellables)
    }
    
    private func subscribeToBasicPublisher() {
        combineService.$basicPublisher
            .sink { [weak self] value in
                guard let self else { return }
                self.basicPublisher.append(value)
            }
            .store(in: &cancellables)
    }
    
    private func subscribeToCurrentValuePublisher() {
        combineService.currentValuePublisher
            .sink { [weak self] value in
                guard let self else { return }
                self.currentValuePublisher.append(value)
            }
            .store(in: &cancellables)
    }
    
    private func subscribeToPassThroughPublisher() {
        combineService.passThroughPublisher
            .sink { [weak self] value in
                guard let self else { return }
                self.passThroughPublisher.append(value)
            }
            .store(in: &cancellables)
    }
    
    private func setImage(from selection: PhotosPickerItem?) {
        guard let selection else {
            self.uiImage = nil
            return
        }
        Task{
            guard let data = try? await selection.loadTransferable(type: Data.self) else { return }
            guard let image = UIImage(data: data) else { return }
            self.uiImage = image
            return
        }
    }
}

final class CombineDataService {
    private let value: [String] = ["Hello", "World", "SwiftUI", "Combine"]
    
    //    en çok kullanılan yayıncı örneği
    //    bu şekilde verileri saklayarak yayarız
    @Published var basicPublisher: String = ""
    
    //    bu yayıncının başlangıç değeri olması zorunludur
    //    her zaman bellekte bir değer tutacaktır
    //    Never yerine Error koyabiliriz
    let currentValuePublisher = CurrentValueSubject<String, Never>("")
    
    //    bu yayıncımız başlangıç değeri gerektirmez
    //    değeri yayınladıktan sonra saklamaz bu şekilde bellekte yer kaplamaz
    //    Never yerine Error koyabiliriz
    let passThroughPublisher = PassthroughSubject<String, Never>()
    
    init() {
        publishBasic()
        publishCurrentValue()
        publishPassThrough()
    }
    
    private func publishBasic() {
        for index in value.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index)) {
                self.basicPublisher = self.value[index]
            }
        }
    }
    
    private func publishCurrentValue() {
        for index in value.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index)) {
                self.currentValuePublisher.send(self.value[index])
            }
        }
    }
    
    private func publishPassThrough() {
        for index in value.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index)) {
                self.passThroughPublisher.send(self.value[index])
            }
        }
    }
}

// https://www.youtube.com/watch?v=RUZcs0SWqnI&t=13s
