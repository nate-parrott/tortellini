import Foundation
import Speech
import AVFoundation

#if os(iOS)
import UIKit
#endif

// Starts when initialized; runs once
@MainActor
class SpeechRecognizer {
    enum Status: Equatable {
        case none
        case starting
        case errored
        case recognizedText(String)
        case finalizedText(String)

        var text: String? {
            switch self {
            case .none, .errored, .starting: return nil
            case .recognizedText(let string): return string
            case .finalizedText(let string): return string
            }
        }
    }

    enum Errors: Error {
        case notAvailable
        case noChannels
        case inBackground
    }

    @Published var status = Status.none {
        didSet {
            if let text = status.text, text != oldValue.text {
                lastTextUpdateDate = Date()
            }
        }
    }
    var lastTextUpdateDate: Date?

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    let managesAudioSession: Bool

    init(managesAudioSession: Bool = true) {
        self.managesAudioSession = managesAudioSession
    }

    func start() async {
        if status != .none {
            fatalError("Cannot reuse a SpeechRecognizer!")
        }
        do {
            self.status = .starting
            // Check to see if we have the necessary permissions, or request tjem
#if os(iOS)
            guard (await SFSpeechRecognizer.requestAuthorization()) == .authorized,
                  await AVAudioSession.sharedInstance().requestRecordPermissionAsync(),
                  recognizer.isAvailable else {
                throw Errors.notAvailable
            }

            if UIApplication.shared.applicationState == .background {
                throw Errors.inBackground
            }
#endif

#if os(macOS)
            guard (await SFSpeechRecognizer.requestAuthorization()) == .authorized,
                  recognizer.isAvailable else {
                throw SpeechRecError.recognizerNotAvailable
            }
#endif
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = true
//            request.taskHint = .dictation
            request.contextualStrings = [
                "Hey Chef",
                "Hey Tommy",
                "Hey Tortellini",
            ]
            //            request.taskHint = .search
            // TODO: Add contextual strings using text from the current page
            recognitionRequest = request

            let inputNode = self.audioEngine.inputNode
            recognitionTask = recognizer.recognitionTask(with: request, resultHandler: { [weak self] res, err in
                guard let self else { return }
                Task {
                    if let res {
                        self.recognized(res)
                    } else if let err {
                        print("[SpeechRecognizer] Recognition error: \(err)")
                        self.encounteredError()
                    }
                }
            })
#if os(iOS)
            if managesAudioSession {
                try AVAudioSession.sharedInstance().setCategory(.record, mode: .default, options: .duckOthers)
                try AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            }
#endif

            let recFmt = inputNode.outputFormat(forBus: 0)
            if recFmt.channelCount == 0 {
                throw Errors.noChannels
            }

            lazy var sendOK: () = {
                Task { [weak self] in
                    guard let self else { return }
                    self.becameReady()
                    //        await self.delegate?.speechRecognizerStarted(self)
                }
            }()
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recFmt) { buffer, _ in
                _ = sendOK
                request.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

        } catch {
            print("[SpeechRecognizer] Error: \(error)")
            self.status = .errored
        }
    }

    private func becameReady() {
        if status == .starting {
            self.status = .recognizedText("")
        }
    }

    private func recognized(_ res: SFSpeechRecognitionResult) {
        switch status {
        case .starting, .recognizedText:
            if res.isFinal {
                self.status = .finalizedText(res.bestTranscription.formattedString)
            } else {
                self.status = .recognizedText(res.bestTranscription.formattedString)
            }
        case .errored, .none, .finalizedText: ()
        }
    }

    private func encounteredError() {
        self.status = .errored
    }


    public func cancel() {
        recognitionTask?.cancel()
        stopAudioInput()
    }

    // Called after final transcription
    // TODO: Can't this be called immediately after _stop_?
    private func stopAudioInput() {
        #if os(iOS)
        if managesAudioSession {
            try? AVAudioSession.sharedInstance().setActive(false)
        }
        #endif
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask = nil
    }

    public func stop() {
        recognitionTask?.finish()
    }

    // MARK: - Permissions helpers

    func hasPermissions() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized && SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    @discardableResult
    func requestPermissions() async -> Bool {
        let mic = await AVCaptureDevice.requestAccess(for: .audio)
        let speech = await SFSpeechRecognizer.requestAuthorization() == .authorized
        return mic && speech
    }
}

extension SFSpeechRecognizer {
    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        if authorizationStatus() == .authorized {
            return .authorized
        }
        return await withCheckedContinuation { cont in
            DispatchQueue.main.async {
                SFSpeechRecognizer.requestAuthorization { status in
                    cont.resume(returning: status)
                }
            }
        }
    }
}

#if os(iOS)
extension AVAudioSession {
    func requestRecordPermissionAsync() async -> Bool {
        await withCheckedContinuation { cont in
            requestRecordPermission { resp in
                cont.resume(returning: resp)
            }
        }
    }
}
#endif
