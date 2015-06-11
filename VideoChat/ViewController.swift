//
//  ViewController.swift
//  VideoChat
//
//  Created by Dmitry on 5/26/15.
//  Copyright (c) 2015 Dmitry. All rights reserved.
//

import UIKit

class ViewController: UIViewController, RTCPeerConnectionDelegate {
    
    var peerFactory = RTCPeerConnectionFactory()
    var iceServers = Array<RTCICEServer>()
    var peerConnections = [String:RTCPeerConnection]()
    var peerConnectionsSettings = [String:AnyObject]()
    
    @IBOutlet weak var someoneVideoView: UIView!
    @IBOutlet weak var myVideoView: UIView!
    
    func commonInit() {        
        self.iceServers.append(RTCICEServer(URI:NSURL(string: "stun:stun.l.google.com:19302"), username: "", password: ""))
        RTCPeerConnectionFactory.initializeSSL()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func localStreamMediaStreamConstraints() -> RTCMediaConstraints {
        return RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil);
    }
    
    func createLocalMediaStreamWithVideo(withVideo:Bool)-> RTCMediaStream {
        var localStream = self.peerFactory.mediaStreamWithLabel("ARDAMS")
        
        if UIDevice.currentDevice().model != "iPhone Simulator" && withVideo {
            var cameraID:String?
            for captureDevice in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
                if (captureDevice.position == AVCaptureDevicePosition.Front) {
                    cameraID = captureDevice.localizedName;
                    break
                }
            }
            
            assert(cameraID != nil, "Unable to get the front camera id")
        
            var capturer = RTCVideoCapturer(deviceName:cameraID)
            var mediaConstraints = localStreamMediaStreamConstraints()
            var videoSource = self.peerFactory.videoSourceWithCapturer(capturer, constraints: mediaConstraints)
            if let localVideoTrack = self.peerFactory.videoTrackWithID("ARDAMSv0", source:videoSource) {
                localStream.addVideoTrack(localVideoTrack)
            }
        }
        localStream.addAudioTrack(self.peerFactory.audioTrackWithID(NSUUID().UUIDString));
        return localStream;
    }
    
    func mediaConstraintsWithVideo(withVideo:Bool, sizeConstraints:Bool) -> RTCMediaConstraints {
        var mandatory:[RTCPair] = []
        var optional:[RTCPair] = []
        
        mandatory.append(RTCPair(key: "OfferToReceiveAudio", value:"true"))
        mandatory.append(RTCPair(key:"OfferToReceiveVideo", value:(withVideo ? "true" : "false")))
        optional.append(RTCPair(key:"internalSctpDataChannels", value:"true"))
        optional.append(RTCPair(key:"DtlsSrtpKeyAgreement", value:"true"))
        
        if (sizeConstraints) {
            optional.append(RTCPair(key:"MaxWidth", value:"320"))
            optional.append(RTCPair(key:"MinWidth", value:"320"))
            optional.append(RTCPair(key:"MaxHeight", value:"320"))
            optional.append(RTCPair(key:"MinHeight", value:"240"))
            optional.append(RTCPair(key:"MaxFramerate", value:"240"))
        }
        return RTCMediaConstraints(mandatoryConstraints: mandatory, optionalConstraints: optional)
    }
    
    func startCallImpl(withVideo:Bool) {
        var perrId:String = NSUUID().UUIDString
        var localStream = createLocalMediaStreamWithVideo(withVideo)
        var peer = self.peerFactory.peerConnectionWithICEServers(self.iceServers,
            constraints:mediaConstraintsWithVideo(withVideo, sizeConstraints:true),
            delegate:self)
        peer.addStream(localStream)
        self.peerConnections[perrId] = peer
        self.peerConnectionsSettings[perrId] = NSNumber(bool: withVideo)
    }

    @IBAction func startStopCallAction(sender: AnyObject) {
        startCallImpl(true)
    }
    
//MARK: - RTCPeerConnectionDelegate
    func peerConnection(peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
    }
    
    func peerConnectionOnRenegotiationNeeded(peerConnection: RTCPeerConnection!) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection, didOpenDataChannel dataChannel: RTCDataChannel) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection, gotICECandidate candidate: RTCICECandidate) {
    }

}

