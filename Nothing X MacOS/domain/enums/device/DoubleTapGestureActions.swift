//
//  DoubleTapGestureActions.swift
//  Nothing X MacOS
//

import Foundation

enum DoubleTapGestureActions: UInt8, Codable {
    case PLAY_PAUSE = 2
    case SKIP_BACK = 8
    case SKIP_FORWARD = 9
    case VOICE_ASSISTANT = 11
    case NO_EXTRA_ACTION = 1
}
