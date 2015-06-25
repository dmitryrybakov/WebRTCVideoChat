//
//  ViewController.swift
//  VideoChat
//
//  Created by Dmitry on 5/26/15.
//  Copyright (c) 2015 Dmitry. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TLKSocketIOSignalingDelegate, RTCEAGLVideoViewDelegate {
    
    var signaling:TLKSocketIOSignaling?;
    var localVideoTrack:RTCVideoTrack?;
    var remoteVideoTrack:RTCVideoTrack?;
    var peerId:String?;
    
    @IBOutlet weak var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet weak var localVideoView: RTCEAGLVideoView!
    
    func commonInit() {
        self.signaling = TLKSocketIOSignaling()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.localVideoView.delegate = self
        self.remoteVideoView.delegate = self
        self.signaling!.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startCallImpl(withVideo:Bool) {
        self.signaling?.connectToServer("signaling.simplewebrtc.com",
            port: 80,
            secure: false,
            success: { () -> Void in
                print("connect success")
                 self.signaling?.joinRoom("ios-demo",
                    success: { () -> Void in
                        print("join success")
                    },
                    failure: { () -> Void in
                        print("join failed")
                 })
            },
            failure: { (error:NSError!) -> Void in
                print("connect failed")
        })
    }

    @IBAction func startStopCallAction(sender: AnyObject) {
        startCallImpl(false)
    }
    
    // MARK: TLKSocketIOSignalingDelegate
    func socketIOSignaling(socketIOSignaling: TLKSocketIOSignaling!, addedStream stream: TLKMediaStream!) {
        self.peerId = stream.peerID;
        if stream.stream.videoTracks.count > 0 {
            if let videoTrack = stream.stream.videoTracks[0] as? RTCVideoTrack {
                self.localVideoTrack!.removeRenderer(self.localVideoView)
                self.localVideoTrack = nil
                self.localVideoTrack = videoTrack;
                videoTrack.addRenderer(self.localVideoView)
            }
        }
        print("addedStream")
    }
    
    func socketIOSignaling(socketIOSignaling: TLKSocketIOSignaling!, removedStream stream: TLKMediaStream!) {
        print("removedStream")
    }
    
    func socketIOSignalingRequiresServerPassword(socketIOSignaling: TLKSocketIOSignaling!) {
        print("serverRequiresPassword")
    }
    
    func socketIOSignaling(socketIOSignaling: TLKSocketIOSignaling!, didOpenChannel channel: RTCDataChannel!) {
    }

    @IBAction func sendTextAction(sender: AnyObject) {
        var dataChannel = self.signaling?.createDataChannelWithPeerId(self.peerId, label: "sample-channel", config: RTCDataChannelInit())
        var message : NSString = "hello"
        var messageData:NSData? = NSString(string:"hello").dataUsingEncoding(NSUTF8StringEncoding)
        var buffer : RTCDataBuffer = RTCDataBuffer(data: messageData, isBinary: true)
        dataChannel?.sendData(buffer)
    }
    
    // MARK: RTCEAGLVideoViewDelegate
    func videoView(videoView:RTCEAGLVideoView, didChangeVideoSize size:CGSize) {
    
    }
}

