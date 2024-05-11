import AVFoundation
import AudioToolbox

class SystemSound {
//    let soundID: SystemSoundID
    private let player: AVAudioPlayer

//    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&err];
//    [player prepareToPlay];
//    [player play];

    init(name: String) {
        let path = Bundle.main.path(forResource: name, ofType: "mp3")!
        let url = URL(filePath: path)
        player = try! AVAudioPlayer(contentsOf: url)
//        player.prepareToPlay()
//        var soundID: SystemSoundID = 0
//        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
//        self.soundID = soundID
    }

    func play() {

        player.play()
//        AudioServicesPlaySystemSound(soundID)
    }

    func stop() {
        player.stop()
        player.currentTime = 0
    }

    static let padFluteUp = SystemSound(name: "pad_flute_up")
    static let all: [SystemSound] = [.padFluteUp]

    static func preload() {
        DispatchQueue.global().async {
            _ = SystemSound.all
        }
    }
}

//var soundURL: NSURL?
//var soundID: SystemSoundID = 0
//
//@IBAction func playSoundButtonTapped(sender: AnyObject) {
//
//    let filePath = NSBundle.mainBundle().pathForResource("yourAudioFileName", ofType: "mp3")
//    soundURL = NSURL(fileURLWithPath: filePath!)
//    if let url = soundURL {
//        AudioServicesCreateSystemSoundID(url, &soundID)
//        AudioServicesPlaySystemSound(soundID)
//    }
//}
