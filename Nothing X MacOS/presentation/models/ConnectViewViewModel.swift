//
//  ConnectViewViewModel.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/2/27.
//
import SwiftUI
import Foundation

class ConnectViewViewModel : ObservableObject {


    private let nothingRepository: NothingRepository
    private let nothingService: NothingService

    @Published var isLoading = false
    @Published var isFailedToConnectPresented = false
    @Published var retry = false
    @Published var savedDevices: [NothingDeviceEntity] = []

    private let isBluetoothOnUseCase: IsBluetoothOnUseCaseProtocol
    @Published var isBluetoothOn = false
    
    
    private var observers: [NSObjectProtocol] = []

    init(nothingRepository: NothingRepository, nothingService: NothingService, bluetoothService: BluetoothService) {

        self.nothingRepository = nothingRepository
        self.nothingService = nothingService
        self.isBluetoothOnUseCase = IsBluetoothOnUseCase(bluetoothService: bluetoothService)

        observers.append(NotificationCenter.default.addObserver(forName: Notification.Name(DataNotifications.REPOSITORY_DATA_UPDATED.rawValue), object: nil, queue: .main) { [weak self] notification in
            self?.isLoading = false
        })


        observers.append(NotificationCenter.default.addObserver(forName: Notification.Name(BluetoothNotifications.FAILED_TO_CONNECT.rawValue), object: nil, queue: .main) { [weak self] notification in
            guard let self else { return }
            withAnimation {
                self.isFailedToConnectPresented = true
                self.isLoading = false
            }
        })

        observers.append(NotificationCenter.default.addObserver(forName: Notification.Name(Notifications.REQUEST_RETRY.rawValue), object: nil, queue: .main) { [weak self] notification in
            guard let self else { return }
            self.connect()
            withAnimation {
                self.isFailedToConnectPresented = false
            }
        })

    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    func checkBluetoothStatus() {
        isBluetoothOn = isBluetoothOnUseCase.isBluetoothOn()
    }
    
    func loadSavedDevices() {
        savedDevices = nothingRepository.getSaved()
    }

    func connect() {
        isLoading = true
        let devices = nothingRepository.getSaved()
        guard !devices.isEmpty else {
            isLoading = false
            return
        }
        nothingService.connectToNothing(device: devices[0].bluetoothDetails)
    }

    func connect(device: NothingDeviceEntity) {
        isLoading = true
        nothingService.connectToNothing(device: device.bluetoothDetails)
    }

    func retryConnect() {
        connect()
        retry = false
        withAnimation {
            isFailedToConnectPresented = false
        }

    }
    
}
