//
//  ViewController.swift
//  Speech-Recognizer
//
//  Created by ShinokiRyosei on 2016/11/29.
//  Copyright © 2016年 ShinokiRyosei. All rights reserved.
//

import UIKit
import Speech


// MARK: ViewController

class ViewController: UIViewController {
    
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        speechRecognizer?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        self.request()
    }
    
    
    // MARK: Private
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask!
    
    @IBAction private func selectRecognize(sender: UIButton) {
        
        if audioEngine.isRunning {
            
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        else {
            
            do {
                
                try startRecording()
            }
            catch let error {
                
                print(error.localizedDescription)
            }
        }
    }
    
    private func request() {
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            
            OperationQueue.main.addOperation {
                
                switch status {
                    
                case .authorized: print("authorized")
                case .denied: print("denied")
                case .restricted: print("restricted")
                case .notDetermined: print("notDetermined")
                }
            }
        }
    }
    
    private func startRecording() throws {
        
        refreshTask()
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let inputNode = audioEngine.inputNode else {
            
            fatalError("Audio Engine has no inputNode")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            
            fatalError("Unable to create a SFSpeechAudioBufferRecognition object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] result, error in
            
            guard let `self` = self else { return }
            
            var isFinal = false
            if let result = result {
                
                print(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            
            self.recognitionRequest?.append(buffer)
        })
        
        try startAudioEngine()
    }
    
    private func refreshTask() {
        
        if let recognitionTask = recognitionTask {
            
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
    }
    
    private func startAudioEngine() throws {
        
        audioEngine.prepare()
        
        try audioEngine.start()
    }
}


// MARK: - SFSpeechRecognizerDelegate

extension ViewController: SFSpeechRecognizerDelegate {
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
    }
}
