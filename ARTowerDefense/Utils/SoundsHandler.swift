//
//  SoundsHandler.swift
//  ARTowerDefense
//
//  Created by Johnny Ramos on 5/23/21.
//

import Foundation
import AVFoundation

enum AudioSource: String, CaseIterable {
    case bomb,missile,sword,creep_spawn,tower_building,creep_finish
    var key: String {
        return self.rawValue
    }
}

//class SoundsHandler {
//    static var shared = SoundsHandler()
//    var player: AVAudioPlayer?
//
//    init() {
//
//    }
//
//    func playSound(_ type: AudioSource) {
//        guard UserDefaults.standard.bool(forKey:SettingsPreferences.sound.key) else {return}
//        guard let url = Bundle.main.url(forResource: type.key , withExtension: "wav") else {return}
//
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
//            try AVAudioSession.sharedInstance().setActive(true)
//
//            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
//
//            guard let player = player else {return}
//            player.play()
//        } catch let error {
//            print(error.localizedDescription)
//        }
//    }
//}

class SoundsHandler: NSObject, AVAudioPlayerDelegate {
    static var shared = SoundsHandler()

    private override init() {}

    var players: [URL: AVAudioPlayer] = [:]
    var duplicatePlayers: [AVAudioPlayer] = []

    func playSound(_ type: AudioSource) {
        guard UserDefaults.standard.bool(forKey: SettingsPreferences.sound.key) else {return}
        guard let bundle = Bundle.main.path(forResource: type.key, ofType: "wav") else {return}
        let soundFileNameUrl = URL(fileURLWithPath: bundle)

        if let player = players[soundFileNameUrl] {
            if !player.isPlaying {
                player.prepareToPlay()
                player.play()
            } else {
                do {
                    let duplicatePlayer = try AVAudioPlayer(contentsOf: soundFileNameUrl )
                    duplicatePlayer.delegate = self
                    duplicatePlayers.append(duplicatePlayer)

                    duplicatePlayer.prepareToPlay()
                    duplicatePlayer.play()
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        } else {
            do {
                let player = try AVAudioPlayer(contentsOf: soundFileNameUrl)
                players[soundFileNameUrl] = player
                player.prepareToPlay()
                player.play()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
}
