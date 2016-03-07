//
//  LX360SingerViewVC.swift
//  GitHub下载别人源码仅仅就一个播放本地视频简单代码所以改编下增加进度条拖拽播放时长等功能后给大家参考怎么做vr播放器 ps：不足的地方大家轻喷
//
//  Created by 罗欣 on 16/1/28.
//  Copyright © 2016年 Useus. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion
import SpriteKit
import AVFoundation
import Foundation
import Darwin
import CoreGraphics


// utility functions
func degreesToRadians(degrees: Float) -> Float {
    
    return (degrees * Float(M_PI)) / 180.0
}

//这个是单屏全屏播放视频界面

class LX360SingerViewVC: HorizontalScreenVC, SCNSceneRendererDelegate, UIGestureRecognizerDelegate {

    /** 视频URL(本地视频或者网络Url，在初始化后设置URL就大功告成) */
    var videoUrl: NSURL?
    
    //视频控制界面
    var showBtnView:Bool = true
    var btnView: UIView?
    var backBtn: UIButton?
    var playBtn: UIButton?
    
    
    var SceneView: SCNView!
    
    var scene : SCNScene?
    
    var videoNode : SCNNode?
    var videoSpriteKitNode : SKVideoNode?
    //增加变量avplayer控制视频长度
    var videoAvplayer : AVPlayer?
    var videoAvplayerItem : AVPlayerItem?
    var videoSlide : UISlider?
    var videoProgress : UIProgressView?
    var videoDuration:Float = 0
    var timeObserver:AnyObject?
    
    var camerasNode : SCNNode?
    var cameraRollNode : SCNNode?
    var cameraPitchNode : SCNNode?
    var cameraYawNode : SCNNode?
    
    var recognizer : UITapGestureRecognizer?
    var panRecognizer: UIPanGestureRecognizer?
    var motionManager : CMMotionManager?
    
    var playingVideo:Bool = false
    
    var currentAngleX:Float?
    var currentAngleY:Float?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        
        
        SceneView = SCNView(frame: CGRectMake(0, 0, ScreenHeight, ScreenWidth))
        
        SceneView?.opaque = true;
        
        SceneView.clearsContextBeforeDrawing = true;
        
        SceneView?.clipsToBounds = true;
        
        SceneView?.autoresizesSubviews = true;
        
        
        
        self.view.addSubview(SceneView)
        
        
        SceneView?.backgroundColor = UIColor.blackColor()
        
        // Create Scene
        scene = SCNScene()
        SceneView?.scene = scene
        
        // Create cameras
        let camX = 0.0 as Float
        let camY = 0.0 as Float
        let camZ = 0.0 as Float
        let zFar = 50.0
        
        let leftCamera = SCNCamera()
        let rightCamera = SCNCamera()
        
        leftCamera.zFar = zFar
        rightCamera.zFar = zFar
        
        
        let leftCameraNode = SCNNode()
        leftCameraNode.camera = leftCamera
        leftCameraNode.position = SCNVector3(x: camX - 0.5, y: camY, z: camZ)
        
        let rightCameraNode = SCNNode()
        rightCameraNode.camera = rightCamera
        rightCameraNode.position = SCNVector3(x: camX + 0.5, y: camY, z: camZ)
        
        
        camerasNode = SCNNode()
        camerasNode!.position = SCNVector3(x: camX, y:camY, z:camZ)
        camerasNode!.addChildNode(leftCameraNode)
        camerasNode!.addChildNode(rightCameraNode)
        
        camerasNode!.eulerAngles = SCNVector3Make(degreesToRadians(-90.0), 0, 0)
        
        //        NSLog("camerasNode.position = %@  %@  %@",camerasNode!.position.x,camerasNode!.position.y,camerasNode!.position.z);
        //        NSLog("eulerAngles = %@  %@  %@",camerasNode!.eulerAngles.x,camerasNode!.eulerAngles.y,camerasNode!.eulerAngles.z);
        
        cameraRollNode = SCNNode()
        cameraRollNode!.addChildNode(camerasNode!)
        
        cameraPitchNode = SCNNode()
        cameraPitchNode!.addChildNode(cameraRollNode!)
        
        cameraYawNode = SCNNode()
        cameraYawNode!.addChildNode(cameraPitchNode!)
        
        scene!.rootNode.addChildNode(cameraYawNode!)
        
        SceneView?.pointOfView = leftCameraNode
        
        // Respond to user head movement. Refreshes the position of the camera 60 times per second.
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager?.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryZVertical)
        
        SceneView?.delegate = self
        
        SceneView?.playing = true
        
        // Add gesture on screen
        recognizer = UITapGestureRecognizer(target: self, action:Selector("tapTheScreen"))
        recognizer!.delegate = self
        view.addGestureRecognizer(recognizer!)
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: "panGesture:")
        view.addGestureRecognizer(panRecognizer!)
        currentAngleX = 0
        currentAngleY = 0
        
        
        //添加退出暂停播放按钮
        btnView = UIView(frame:CGRectMake(0, ScreenWidth - 50, ScreenHeight, 50))
        
        btnView?.backgroundColor = UIColor.blackColor()
        btnView?.alpha = 0.6
        
        self.view.addSubview(btnView!)
        
        playBtn = UIButton(frame: CGRectMake(0, 0, 50, 50))
        playBtn!.setImage(UIImage(named: "playback_pause"), forState: .Normal)
        playBtn!.setImage(UIImage(named: "playback_play"), forState: .Selected)
        playBtn?.addTarget(self, action:Selector("stopPlay:"), forControlEvents: .TouchUpInside)
        
        btnView!.addSubview(playBtn!)
        
        backBtn = UIButton(frame: CGRectMake(CGRectGetWidth((btnView?.frame)!) - 50, 0, 50, 50))
        backBtn!.setImage(UIImage(named: "back"), forState: .Normal)
        backBtn!.setImage(UIImage(named: "back"), forState: .Selected)
        backBtn?.addTarget(self, action:Selector("backBtnAction:"), forControlEvents: .TouchUpInside)
        
        btnView!.addSubview(backBtn!)
        
        videoProgress = UIProgressView(frame: CGRectMake(CGRectGetMaxX((playBtn?.frame)!) + 15, 24, CGRectGetWidth((btnView?.frame)!) - 130, 2))
        
        
        videoProgress?.tintColor = UIColor.redColor()
        
        btnView?.addSubview(videoProgress!)
        
        
        videoSlide = UISlider(frame: CGRectMake(CGRectGetMaxX((playBtn?.frame)!) + 15, 10, CGRectGetWidth((btnView?.frame)!) - 130, 30))
        
        videoSlide?.backgroundColor = UIColor.clearColor()
        videoSlide?.minimumValue = 0
        videoSlide?.maximumValue = 1
        videoSlide?.enabled = false
        videoSlide?.addTarget(self, action: "movieProgressDragged:", forControlEvents: .ValueChanged)
        
        btnView?.addSubview(videoSlide!)
        
        
        play()
        
        self .performSelector("hideBtnViewAnimate", withObject: nil, afterDelay: 4.0)
        
    }
    
    func play(){
        
        //        let fileURL: NSURL? = NSURL(string: "www.baidu.com")
        //                let fileURL: NSURL? = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("vr2", ofType: "mp4")!)
        
        //        let fileURL: NSURL? = NSURL(string:videoUrl! as String)
        
        if (videoUrl != nil){
            
            //初始化播放器
            videoAvplayerItem = AVPlayerItem(URL: videoUrl!)
            videoAvplayerItem!.addObserver(self, forKeyPath: "status", options: .New, context: nil)
            videoAvplayerItem!.addObserver(self, forKeyPath:"loadedTimeRanges" , options: .New, context:nil) // 监听loadedTimeRanges属性
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "myMovieFinishedCallback:", name: AVPlayerItemDidPlayToEndTimeNotification, object: videoAvplayerItem)
            
            videoAvplayer = AVPlayer(playerItem: videoAvplayerItem!)
            
            
            //            videoSpriteKitNode =  SKVideoNode(AVPlayer: AVPlayer(URL: videoUrl!))
            //            videoSpriteKitNode =  SKVideoNode(AVPlayer: AVPlayer(playerItem: videoAvplayerItem!))
            
            videoSpriteKitNode = SKVideoNode(AVPlayer: videoAvplayer!)
            
            videoNode = SCNNode()
            videoNode!.geometry = SCNSphere(radius: 30)
            
            
            let spriteKitScene = SKScene(size: CGSize(width: 2500, height: 2500))
            spriteKitScene.scaleMode = .AspectFit
            
            videoSpriteKitNode!.position = CGPoint(x: spriteKitScene.size.width / 2.0, y: spriteKitScene.size.height / 2.0)
            videoSpriteKitNode!.size = spriteKitScene.size
            
            spriteKitScene.addChild(videoSpriteKitNode!)
            
            videoNode!.geometry?.firstMaterial?.diffuse.contents = spriteKitScene
            videoNode!.geometry?.firstMaterial?.doubleSided = true
            
            // Flip video upside down, so that it's shown in the right position
            var transform = SCNMatrix4MakeRotation(Float(M_PI), 0.0, 0.0, 1.0)
            transform = SCNMatrix4Translate(transform, 1.0, 1.0, 0.0)
            
            videoNode!.pivot = SCNMatrix4MakeRotation(Float(M_PI_2), 0.0, -1.0, 0.0)
            videoNode!.geometry?.firstMaterial?.diffuse.contentsTransform = transform
            videoNode!.position = SCNVector3(x: 0, y: 0, z: 0)
            
            scene!.rootNode.addChildNode(videoNode!)
            //            videoSpriteKitNode!.play()
            
            playingVideo = true
            
        }
        
    }
    
    
    
    func stopPlay(sender:UIButton){
        
        if (playingVideo){
            videoSpriteKitNode!.pause()
            playBtn?.selected = true
            
        }else{
            
            videoSpriteKitNode!.play()
            
            playBtn?.selected = false
            
        }
        
        playingVideo = !playingVideo
        
    }
    
    func tapTheScreen(){
        // Action when the screen is tapped
        
        //        stopPlay()
        if (showBtnView)
        {
            showBtnView = false
            hideBtnViewAnimate()
        }else
        {
            showBtnView = true
            showBtnViewAnimate()
            
        }
    }
    
    func panGesture(sender: UIPanGestureRecognizer){
        //getting the CGpoint at the end of the pan
        let translation = sender.translationInView(sender.view!)
        
        var newAngleX = Float(translation.x)
        
        //current angle is an instance variable so i am adding the newAngle to the newAngle to it
        newAngleX = newAngleX + currentAngleX!
        videoNode!.eulerAngles.y = -newAngleX/100
        
        //getting the end angle of the swipe put into the instance variable
        if(sender.state == UIGestureRecognizerState.Ended) {
            currentAngleX = newAngleX
        }
    }
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval){
        
        // Render the scene
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let mm = self.motionManager, let motion = mm.deviceMotion {
                let currentAttitude = motion.attitude
                
                var orientationMultiplier = 1.0
                if(UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.LandscapeRight){ orientationMultiplier = -1.0}
                
                
                self.cameraRollNode!.eulerAngles.x = Float(currentAttitude.roll * orientationMultiplier)
                self.cameraPitchNode!.eulerAngles.z = Float(currentAttitude.pitch)
                self.cameraYawNode!.eulerAngles.y = Float(currentAttitude.yaw)
                
            }
        }
    }
    /*
    *退出播放器事件
    */
    func backBtnAction(sender : UIButton) {
        
        //暂停播放
        videoSpriteKitNode!.pause()
        
        //移除监听
        videoAvplayerItem?.removeObserver(self, forKeyPath: "status")
        videoAvplayerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        videoAvplayer?.replaceCurrentItemWithPlayerItem(nil)
        
        videoAvplayerItem = nil
        videoAvplayer = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        SceneView.removeFromSuperview()
        
        removeTimeObserverFro_player()
        
        
        
        self .dismissViewControllerAnimated(true) { () -> Void in
            
        }
        
        
    }
    
    /*
    *隐藏按钮事件
    */
    func hideBtnViewAnimate() {
        
        
        UIView.animateWithDuration(1.0, delay: 0.0, options:  UIViewAnimationOptions.CurveEaseInOut , animations: {
            
            () -> Void in
            
            self.btnView?.alpha = 0
            
            }, completion: {
                
                (finish) -> Void in
                
                self.showBtnView = false
                
                self.btnView?.removeFromSuperview()
                
        })
        
    }
    
    func showBtnViewAnimate() {
        
        
        UIView.animateWithDuration(0.5, delay: 0.0, options:  UIViewAnimationOptions.CurveEaseInOut , animations: {
            
            () -> Void in
            
            self.view.addSubview(self.btnView!)
            
            self.btnView?.alpha = 0.6
            
            }, completion: {
                
                (finish) -> Void in
                
                self.showBtnView = true
                
                self .performSelector("hideBtnViewAnimate", withObject: nil, afterDelay: 3.0)
                
                
        })
        
    }
    
    
    func myMovieFinishedCallback(sender : AVPlayerItem)
    {
        
        videoAvplayer?.pause()
        
        
        playBtn?.selected = true
        videoAvplayerItem?.removeObserver(self, forKeyPath: "status")
        videoAvplayerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        videoAvplayer?.replaceCurrentItemWithPlayerItem(nil)
        
        videoAvplayerItem = nil
        videoAvplayer = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        SceneView.removeFromSuperview()
        
        
        
        removeTimeObserverFro_player()
        
        
        
        self .dismissViewControllerAnimated(true) { () -> Void in
            
        }
        
        
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        
        
        if (keyPath == "status")
        {
            
            let status = (change![NSKeyValueChangeNewKey] as! NSNumber).integerValue as AVPlayerStatus.RawValue
            
            
            
            switch (status) {
                
            case AVPlayerStatus.ReadyToPlay.rawValue:
                
                videoSpriteKitNode!.play()
                
                //                let duration:CMTime = self.videoAvplayerItem!.duration// 获取视频总长度
                let totalSecond:Float = Float(self.videoAvplayerItem!.duration.value) / Float(self.videoAvplayerItem!.duration.timescale)// 转换成秒
                //设置slider总长度跟视频长度一致
                videoSlide?.maximumValue = totalSecond
                
                NSLog("我准备播了")
                
                videoSlide?.enabled = true
                customVideoSlider()
                monitoringPlayback(videoAvplayerItem!)
                
                
            case AVPlayerStatus.Failed.rawValue:
                
                print("Failed to load video")
                
                
            default:
                
                true
                
            }
            
            
        }else if (keyPath == "loadedTimeRanges")
        {
            
            let timeInterval = availableDuration() // 计算缓冲进度
            
            let duration = videoAvplayerItem!.duration
            
            let totalDuration = CMTimeGetSeconds(duration)
            
            videoDuration = Float(timeInterval / totalDuration)
            //设置缓存条的缓存长度
            videoProgress?.setProgress(videoDuration, animated: true)
            
            
        }else
        {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            
        }
        
    }
    //自定义slider
    //    func customVideoSlider(duration:CMTime) {
    func customVideoSlider() {
        
        //    self.videoSlider.maximumValue = CMTimeGetSeconds(duration);
        //      UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1,height: 1), false, 0.0)
        let transparentImage:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        //    [self.videoSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
        videoSlide?.setMinimumTrackImage(transparentImage, forState: .Normal)
        //    [self.videoSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
        videoSlide?.setMaximumTrackImage(transparentImage, forState: .Normal)
        
    }
    
    func availableDuration() -> NSTimeInterval {
        
        let loadedTimeRanges = videoAvplayer!.currentItem!.loadedTimeRanges as NSArray
        let timeRange = loadedTimeRanges.firstObject!.CMTimeRangeValue as CMTimeRange// 获取缓冲区域
        let startSeconds = CMTimeGetSeconds(timeRange.start) as Double
        let durationSeconds = CMTimeGetSeconds(timeRange.duration) as Double
        let result = startSeconds + durationSeconds as NSTimeInterval // 计算缓冲总进度
        return result;
    }
    
    //实时滑动slider到播放的时间对齐
    func monitoringPlayback(playerItem:AVPlayerItem) {
        
        timeObserver = videoAvplayer?.addPeriodicTimeObserverForInterval(CMTimeMake(1, 1), queue:dispatch_get_main_queue(), usingBlock: { (time : CMTime) -> Void in
            
            let currentSecond = (Float(playerItem.currentTime().value)) / (Float(playerItem.currentTime().timescale))// 计算当前在第几秒
            //            let currentSecond2 = (Float(playerItem.currentTime().value))// 计算当前在第几秒
            
            //            NSLog("\n %f ----- %f --- %f",currentSecond,currentSecond2,Float(playerItem.currentTime().timescale))
            
            self.videoSlide?.value = currentSecond
            
        })
        
    }
    
    func movieProgressDragged(sender:UISlider) {
        
        //拖动改变视频播放进度
        //计算出拖动的当前秒数
        
        let dragedSeconds:Int64 = Int64(sender.value);
        
        NSLog("dragedSeconds:%d",dragedSeconds);
        
        //转换成CMTime才能给player来控制播放进度
        
        let dragedCMTime = CMTimeMake(dragedSeconds, 1);
        
        videoAvplayer?.pause()
        
        //        videoAvplayer.seekToTime:dragedCMTime completionHandler:^(BOOL finish){
        //
        //            [moviePlayeView.playerplay];
        //
        //            }
        
        videoAvplayer?.seekToTime(dragedCMTime, completionHandler: { (finish) -> Void in
            
            self.videoAvplayer?.play()
            
        })
        
        
    }
    
    //app前后台操作
    func applicationWillResignActive(notification:NSNotification) {
        
        stopPlay(playBtn!)
        
    }
    
    func applicationDidBecomeActive(notification:NSNotification) {
        
        //        playBtn.setImage:[UIImage imageNamed:[self isPlaying] ? @"playback_pause" : @"playback_play"]
        //            forState:UIControlStateNormal;
        
        playBtn!.setImage(UIImage(named: "playback_pause"), forState: .Normal)
        playBtn!.setImage(UIImage(named: "playback_play"), forState: .Selected)
        
        
        videoAvplayer?.seekToTime((videoAvplayer?.currentTime())!)
        
    }
    
    
    func removeTimeObserverFro_player() {
        if ((timeObserver) != nil) {
            videoAvplayer?.removeTimeObserver(timeObserver!)
            timeObserver = nil;
        }
    }
    
    
    //    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
    //
    //
    //
    //        switch (keyPath, context) {
    //
    //        case ("status", &myContext):
    //
    //            let status = (change[NSKeyValueChangeNewKey] as! NSNumber).integerValue as AVPlayerStatus.RawValue
    //
    //
    //
    //            switch (status) {
    //
    //            case AVPlayerStatus.ReadyToPlay.rawValue:
    //
    //                videoSpriteKitNode!.play()
    //
    //
    //
    //            case AVPlayerStatus.Failed.rawValue:
    //
    //                print("Failed to load video")
    //
    //
    //
    //            default:
    //
    //                true
    //                
    //            }
    //            
    //            
    //            
    //        case ("loadedTimeRanges", &myContext):
    //            
    //            let timeInterval = availableDuration() // 计算缓冲进度
    //            
    //            let duration = videoAvplayerItem!.duration
    //            
    //            let totalDuration = CMTimeGetSeconds(duration)
    //            
    //            println(timeInterval / totalDuration)
    //            
    //        default:
    //            
    //            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    //            
    //        }
    //        
    //    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
