//
//  ControlsDetailViewViewModel.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/3/9.
//

import Foundation
class ControlsDetailViewViewModel : ObservableObject {

    private let switchControlsUseCase: SwitchControlsUseCaseProtocol

    @Published var ancCycleANC: Bool = true
    @Published var ancCycleTransparency: Bool = true
    @Published var ancCycleOff: Bool = true
    var isUpdatingCycle = false

    // Double Tap & Hold ANC cycle state
    @Published var dthAncCycleANC: Bool = true
    @Published var dthAncCycleTransparency: Bool = true
    @Published var dthAncCycleOff: Bool = true
    var isUpdatingDTHCycle = false

    init(nothingService: NothingService) {
        self.switchControlsUseCase = SwitchControlsUseCase(nothingService: nothingService)
    }
    

    func switchTripleTapAction(device: DeviceType, action: TripleTapOptions) {
 
        var convertedAction: TripleTapGestureActions = .NO_EXTRA_ACTION
        
        switch action {
        case .no_action:
            convertedAction = .NO_EXTRA_ACTION
        case .skip_back:
            convertedAction = .SKIP_BACK
        case .skip_forward:
            convertedAction = .SKIP_FORWARD
        case .voice_assistant:
            convertedAction = .VOICE_ASSISTANT
        }
        
        switchControlsUseCase.switchGesture(device: device, gesture: .TRIPLE_TAP, action: convertedAction.rawValue)
    }
    
    func switchTapAndHoldAction(device: DeviceType, action: TapAndHoldOptions) {
        var convertedAction: TapAndHoldGestureActions = .NO_EXTRA_ACTION

        switch action {
        case .no_extra_action:
            convertedAction = .NO_EXTRA_ACTION
        case .noise_control:
            convertedAction = .NOISE_CONTROL
        case .voice_assistant:
            convertedAction = .VOICE_ASSISTANT
        case .volume_up:
            convertedAction = .VOLUME_UP
        case .volume_down:
            convertedAction = .VOLUME_DOWN
        }
        switchControlsUseCase.switchGesture(device: device, gesture: .TAP_AND_HOLD, action: convertedAction.rawValue)
    }
    
    func convertTripleTapActionToOption(action: TripleTapGestureActions) -> TripleTapOptions {
        
        var convertedOption: TripleTapOptions = .no_action
        
        switch action {
        case .NO_EXTRA_ACTION:
            convertedOption = .no_action
        case .SKIP_BACK:
            convertedOption = .skip_back
        case .SKIP_FORWARD:
            convertedOption = .skip_forward
        case .VOICE_ASSISTANT:
            convertedOption = .voice_assistant
        }
        
        return convertedOption
    }
    
    func convertTapAndHoldActionToOption(action: TapAndHoldGestureActions) -> TapAndHoldOptions {
        if action.isNoiseControl {
            return .noise_control
        }
        switch action {
        case .VOICE_ASSISTANT:
            return .voice_assistant
        case .VOLUME_UP:
            return .volume_up
        case .VOLUME_DOWN:
            return .volume_down
        default:
            return .no_extra_action
        }
    }

    // MARK: - Double Tap

    func switchDoubleTapAction(device: DeviceType, action: DoubleTapOptions) {
        var convertedAction: DoubleTapGestureActions = .NO_EXTRA_ACTION

        switch action {
        case .play_pause:
            convertedAction = .PLAY_PAUSE
        case .skip_back:
            convertedAction = .SKIP_BACK
        case .skip_forward:
            convertedAction = .SKIP_FORWARD
        case .voice_assistant:
            convertedAction = .VOICE_ASSISTANT
        case .no_action:
            convertedAction = .NO_EXTRA_ACTION
        }

        switchControlsUseCase.switchGesture(device: device, gesture: .DOUBLE_TAP, action: convertedAction.rawValue)
    }

    func convertDoubleTapActionToOption(action: DoubleTapGestureActions) -> DoubleTapOptions {
        switch action {
        case .PLAY_PAUSE:
            return .play_pause
        case .SKIP_BACK:
            return .skip_back
        case .SKIP_FORWARD:
            return .skip_forward
        case .VOICE_ASSISTANT:
            return .voice_assistant
        case .NO_EXTRA_ACTION:
            return .no_action
        }
    }

    // MARK: - Double Tap & Hold

    func switchDoubleTapAndHoldAction(device: DeviceType, action: DoubleTapAndHoldOptions) {
        var convertedAction: DoubleTapAndHoldGestureActions = .NO_EXTRA_ACTION

        switch action {
        case .noise_control:
            convertedAction = .NOISE_CONTROL
        case .volume_up:
            convertedAction = .VOLUME_UP
        case .volume_down:
            convertedAction = .VOLUME_DOWN
        case .voice_assistant:
            convertedAction = .VOICE_ASSISTANT
        case .no_extra_action:
            convertedAction = .NO_EXTRA_ACTION
        }

        switchControlsUseCase.switchGesture(device: device, gesture: .DOUBLE_TAP_AND_HOLD, action: convertedAction.rawValue)
    }

    func convertDoubleTapAndHoldActionToOption(action: DoubleTapAndHoldGestureActions) -> DoubleTapAndHoldOptions {
        if action.isNoiseControl {
            return .noise_control
        }
        switch action {
        case .VOLUME_UP:
            return .volume_up
        case .VOLUME_DOWN:
            return .volume_down
        case .VOICE_ASSISTANT:
            return .voice_assistant
        default:
            return .no_extra_action
        }
    }

    func loadANCCycleState(from action: TapAndHoldGestureActions) {
        isUpdatingCycle = true
        let state = action.ancCycleState
        ancCycleANC = state.anc
        ancCycleTransparency = state.transparency
        ancCycleOff = state.off
        isUpdatingCycle = false
    }

    func updateANCCycle(device: DeviceType) {
        guard !isUpdatingCycle else { return }
        let selectedCount = [ancCycleANC, ancCycleTransparency, ancCycleOff].filter { $0 }.count
        guard selectedCount >= 2 else { return }

        let action = TapAndHoldGestureActions.fromCycleState(
            anc: ancCycleANC,
            transparency: ancCycleTransparency,
            off: ancCycleOff
        )
        switchControlsUseCase.switchGesture(device: .LEFT, gesture: .TAP_AND_HOLD, action: action.rawValue)
        switchControlsUseCase.switchGesture(device: .RIGHT, gesture: .TAP_AND_HOLD, action: action.rawValue)
    }

    // MARK: - Double Tap & Hold ANC Cycle

    func loadDTHANCCycleState(from action: DoubleTapAndHoldGestureActions) {
        isUpdatingDTHCycle = true
        let state = action.ancCycleState
        dthAncCycleANC = state.anc
        dthAncCycleTransparency = state.transparency
        dthAncCycleOff = state.off
        isUpdatingDTHCycle = false
    }

    func updateDTHANCCycle(device: DeviceType) {
        guard !isUpdatingDTHCycle else { return }
        let selectedCount = [dthAncCycleANC, dthAncCycleTransparency, dthAncCycleOff].filter { $0 }.count
        guard selectedCount >= 2 else { return }

        let action = DoubleTapAndHoldGestureActions.fromCycleState(
            anc: dthAncCycleANC,
            transparency: dthAncCycleTransparency,
            off: dthAncCycleOff
        )
        switchControlsUseCase.switchGesture(device: .LEFT, gesture: .DOUBLE_TAP_AND_HOLD, action: action.rawValue)
        switchControlsUseCase.switchGesture(device: .RIGHT, gesture: .DOUBLE_TAP_AND_HOLD, action: action.rawValue)
    }

}
