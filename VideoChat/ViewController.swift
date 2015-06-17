//
//  ViewController.swift
//  VideoChat
//
//  Created by Dmitry on 5/26/15.
//  Copyright (c) 2015 Dmitry. All rights reserved.
//

import UIKit

class ViewController: UIViewController, RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate {
    
    var peerFactory = RTCPeerConnectionFactory()
    var iceServers = Array<RTCICEServer>()
    var peerConnections = [String:RTCPeerConnection]()
    var peerConnectionsSettings = [String:AnyObject]()
    var activePeerId:String?
    
    @IBOutlet weak var someoneVideoView: RTCEAGLVideoView!
    @IBOutlet weak var myVideoView: RTCEAGLVideoView!
    
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
        activePeerId = perrId
        self.peerConnectionsSettings[perrId] = NSNumber(bool: withVideo)
        peer.createOfferWithDelegate(self, constraints:mediaConstraintsWithVideo(withVideo, sizeConstraints:true));
    }

    @IBAction func startStopCallAction(sender: AnyObject) {
        startCallImpl(false)
    }
    
    func disconnect() {
        self.peerConnections.removeAll(keepCapacity: true);
        self.peerConnectionsSettings.removeAll(keepCapacity: true);
    }
    
//MARK: - RTCPeerConnectionDelegate
    func peerConnection(peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        stream.videoTracks.last?.addRenderer(self.myVideoView)
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
    }
    
    func peerConnectionOnRenegotiationNeeded(peerConnection: RTCPeerConnection!) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, didOpenDataChannel dataChannel: RTCDataChannel) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate) {
    }
//MARK: - RTCSessionDescriptionDelegate
    // Called when creating a session.
    func peerConnection(peerConnection:RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: NSError!) -> Void {
        dispatch_async(dispatch_get_main_queue()) {
            if (error != nil) {
                print("Failed to create session description. Error: \(error)")
                self.disconnect()
            }
        }
        peerConnection.setLocalDescriptionWithDelegate(self, sessionDescription:sdp)
    }
    
    // Called when setting a local or remote description.
    func peerConnection(peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error:NSError!) {
        if (peerConnection.signalingState == .HaveLocalOffer) {
            // Send offer through the signaling channel of our application
        }
        else if (peerConnection.signalingState == .HaveRemoteOffer) {
            // If we have a remote offer we should add it to the peer connection
            let withVideo:NSNumber = self.peerConnectionsSettings[activePeerId!] as! NSNumber
            peerConnection.createAnswerWithDelegate(self,
                constraints:mediaConstraintsWithVideo(withVideo.boolValue, sizeConstraints:true))
        }
    }

}

