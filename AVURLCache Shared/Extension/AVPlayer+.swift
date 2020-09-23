//
//  AVPlayer+.swift
//  AVURLCache
//
//  Created by Wayne Yeh on 2020/9/23.
//

import AVFoundation

extension AVPlayer {
    static var demo: AVPlayer {
        let url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
        let loader = URLCache[url]
        let asset = AVURLAsset(url: loader.url)
        asset.resourceLoader.setDelegate(loader, queue: .main)
        
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = true
        player.play()
        
        return player
    }
}
