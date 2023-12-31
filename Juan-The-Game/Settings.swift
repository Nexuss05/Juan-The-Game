//
//  Settings.swift
//  Juan-The-Game
//

import SpriteKit

enum PhysicsCategories {
    static let none: UInt32 = 0
    static let ballCategory: UInt32 = 0x1
    static let platformCategory: UInt32 = 0x1 << 1
    static let dollarWithHoleCategory: UInt32 = 0x1 << 2
    static let tweet: UInt32 = 0x1 << 3
}

enum ZPositions {
    static let background: CGFloat = -1
    static let platform: CGFloat = 0
    static let ball: CGFloat = 1
    static let platform1: CGFloat = 2
    static let scoreLabel: CGFloat = 2
    static let logo: CGFloat = 2
    static let playButton: CGFloat = 2
}
