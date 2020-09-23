//
//  GameViewController.swift
//  AVURLCache macOS
//
//  Created by Wayne Yeh on 2020/9/17.
//

import Cocoa
import AVKit

// Our macOS specific view controller
class PlayerViewController: NSViewController {
    
    var player: AVPlayer? {
        set {
            let view = self.view as! AVPlayerView
            view.player = newValue
        }
        get {
            let view = self.view as! AVPlayerView
            return view.player
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.player = AVPlayer.demo
    }
}
