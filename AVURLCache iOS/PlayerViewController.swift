//
//  GameViewController.swift
//  AVURLCache iOS
//
//  Created by Wayne Yeh on 2020/9/17.
//

import UIKit
import AVKit

// Our iOS specific view controller
class PlayerViewController: AVPlayerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.player = AVPlayer.demo
    }
}
