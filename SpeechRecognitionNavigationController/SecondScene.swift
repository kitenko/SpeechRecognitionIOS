import UIKit
import CoreML
import AVFoundation
import Foundation
import Speech

import Cobra
import ios_voice_processor

class SecondScene: UIViewController {

    private let ACCESS_KEY = "VOkKPMPXOLpS2TJQsMV+nnGf7479KVvLIw8Ol7DzUO2VX/hdLJDgjQ=="

//    private let ACCESS_KEY = "YpfSvOCAXffIM0gA5h2qEolSILk+9whwnijU0iJAeqDGlYFn7CNfUg=="


    private let ALPHA: Float = 0.5

    private var trigger = 0

    private var cobra: Cobra!
    private var isListening = false

    private var arrayAudio = [[Float]]()

    private var timer: Timer?

    private var errorMessage = ""
    private var recordToggleButtonText:String = "Start"
    private var voiceProbability: Float = 0.0
    private var THRESHOLD: Float = 0.8
    private var detectedText = ""

    private var firstScene: FirstScene

    private var addArrayNum = 0

    private var arrayNoiseOne = [[Float]]()
    private var arrayNoiseTwo = [[Float]]()

    private var bombSoundEffect: AVAudioPlayer?

    var audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()

    private var newArray = [Double]()

    private let audioEngine = AVAudioEngine()
    // specify the audio samples format the CoreML model
    private let desiredAudioFormatPrediction: AVAudioFormat = {
        let avAudioChannelLayout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono)!
        return AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double( 16000 ), // as specified when creating the Pytorch model
            interleaved: true,
            channelLayout: avAudioChannelLayout
        )
    }()

    private let desiredAudioFormatCobra: AVAudioFormat = {
        let avAudioChannelLayout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono)!
        return AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Double( 16000 ), // as specified when creating the Pytorch model
            interleaved: true,
            channelLayout: avAudioChannelLayout
        )
    }()

    private var arrayToPlay = [Float]()

    weak var reloadFirstConstrane: ReloadConstrains?


    //MARK: - init

    init(_ firstScene: FirstScene) {
        self.firstScene = firstScene
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - create Button

    private let startButton: UIButton = {
        let startButton = UIButton()
        startButton.setTitle("Start", for: .normal)
        startButton.titleLabel?.font = .preferredFont(forTextStyle: .title1)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .lightGray
        startButton.titleLabel?.adjustsFontSizeToFitWidth = true
        startButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        startButton.layer.cornerRadius = 12
        startButton.clipsToBounds = true
        startButton.layer.shadowColor = UIColor.gray.cgColor
        startButton.layer.shadowOffset = CGSize(width: 2, height: 5)
        startButton.layer.masksToBounds = false
        startButton.layer.shadowRadius = 5
        startButton.layer.shadowOpacity = 2.0
        return startButton
    }()

    //MARK: - Lables
    private let voiceInfo: UILabel = {
        let label = UILabel()
        label.text = "Hello "
        label.font = .boldSystemFont(ofSize: 30)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    //MARK: - StackViews

    private let stackMain: UIStackView = {
        let stackMain = UIStackView()
        stackMain.spacing = 15
        stackMain.translatesAutoresizingMaskIntoConstraints = false
        stackMain.distribution = .fill
        stackMain.alignment = .fill
        stackMain.axis = .vertical
        return stackMain
    }()

    //MARK: - function interface

    override func viewDidLoad() {
        super.viewDidLoad()
        initCobra()
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        self.title = "Auto Recognize"

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(perfAdd))

        stackMain.addArrangedSubview(voiceInfo)
        stackMain.addArrangedSubview(firstScene.collectionView)
        stackMain.addArrangedSubview(startButton)
        view.addSubview(stackMain)
        view.addSubview(firstScene.stackAnimation)
        addConstrains()
    }

    private func addConstrains() {
        var constrains = [NSLayoutConstraint]()

        constrains.append(stackMain.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
        constrains.append(stackMain.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
        constrains.append(stackMain.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        constrains.append(stackMain.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))

        constrains.append(firstScene.stackLabels.leadingAnchor.constraint(equalTo: firstScene.resalutEffectView.leadingAnchor))
        constrains.append(firstScene.stackLabels.trailingAnchor.constraint(equalTo: firstScene.resalutEffectView.trailingAnchor))
        constrains.append(firstScene.stackLabels.bottomAnchor.constraint(equalTo: firstScene.resalutEffectView.bottomAnchor))
        constrains.append(firstScene.stackLabels.topAnchor.constraint(equalTo: firstScene.resalutEffectView.topAnchor))

//        constrains.append(NSLayoutConstraint(item: firstScene.stackAnimation, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.3, constant: 0))

        constrains.append(firstScene.stackAnimation.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10))
        constrains.append(firstScene.stackAnimation.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10))
        constrains.append(firstScene.stackAnimation.topAnchor.constraint(equalTo: firstScene.collectionView.topAnchor, constant: 16))


        NSLayoutConstraint.activate(constrains)
    }

    //MARK: - init and deinit Cobra

//    @objc func banButtonBack () {
//        print("Go back")
//    }

    func initCobra() {
        do {
            try cobra = Cobra(accessKey: ACCESS_KEY)
        } catch is CobraInvalidArgumentError {
            errorMessage = "ACCESS_KEY '\(ACCESS_KEY)' is invalid."
        } catch is CobraActivationError {
            errorMessage = "ACCESS_KEY activation error."
        } catch is CobraActivationRefusedError {
            errorMessage = "ACCESS_KEY activation refused."
        } catch is CobraActivationLimitError {
            errorMessage = "ACCESS_KEY reached its limit."
        } catch is CobraActivationThrottledError  {
            errorMessage = "ACCESS_KEY is throttled."
        } catch {
            errorMessage = "\(error)"
        }
    }

    func deinitCobra () {
        stop()
        cobra.delete()
    }

    //MARK: - Cobra functions

    @objc func toggleRecording(){

        do {
            if isListening {
                stop()
                startButton.setTitle("Start", for: .normal)
                startButton.backgroundColor = .lightGray

            } else {
                do {
                    try start()
                } catch {
                    print("Error record audio")
                }
                startButton.backgroundColor = UIColor(named: "ButtonStop")
                startButton.setTitle("Stop", for: .normal)
                recordToggleButtonText = "Stop"
            }
        } catch {
            self.errorMessage = "Failed to start audio session."
        }
    }

    public func start() throws {

        guard !isListening else {
            return
        }

        guard try VoiceProcessor.shared.hasPermissions() else {
            print("Permissions denied.")
            return
        }
        isListening = true

        firstScene.showResultsView()

        //        try VoiceProcessor.shared.start(
        //            frameLength: Cobra.frameLength,
        //            sampleRate: 16000,
        //            audioCallback: self.audioCallback)

        arrayAudio.removeAll()
        arrayNoiseOne.removeAll()
        arrayNoiseTwo.removeAll()
//        arrayToPlay.removeAll()

        startAudioEngine()
    }

    public func stop() {
        guard isListening else {
            return
        }

//        VoiceProcessor.shared.stop()
        isListening = false

        DispatchQueue.main.async {
            self.voiceProbability = 0
            self.timer?.invalidate()
            self.detectedText = ""
        }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        prepareToPlay(arrayToPlay)

    }

    private func setProbability(value: Float32) -> Bool {
        self.voiceProbability = (self.ALPHA * value) + ((1 - self.ALPHA) * self.voiceProbability)
        if self.voiceProbability >= self.THRESHOLD {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) {timer in
                self.voiceInfo.text = ""
            }
            DispatchQueue.main.async {
                self.voiceInfo.text = "Voice Detected!"
            }
            return true
        }
        DispatchQueue.main.async {
            self.voiceInfo.text = "no Voice"
        }
        return false
    }

    private func prepareConda(pcm: [Int16], classification: [Float]) {
        let pcm1 = Array(pcm[0..<512])
        let pcm2 = Array(pcm[512..<1024])
        let pcm3 = Array(pcm[1024..<1536])
        let pcm4 = Array(pcm[1536..<2048])

        let classificationArr1 = Array(classification[0..<512])
        let classificationArr2 = Array(classification[512..<1024])
        let classificationArr3 = Array(classification[1024..<1536])
        let classificationArr4 = Array(classification[1536..<2048])

        DispatchQueue.global(qos: .userInitiated).sync {
            self.audioCallback(pcm: pcm1, classification: classificationArr1)
            self.audioCallback(pcm: pcm2, classification: classificationArr2)
            self.audioCallback(pcm: pcm3, classification: classificationArr3)
            self.audioCallback(pcm: pcm4, classification: classificationArr4)
        }

    }

    private func audioCallback(pcm: [Int16], classification: [Float]) -> Void {

        do {
            let result:Float32 = try self.cobra!.process(pcm: pcm)

            let resultBool = self.setProbability(value: result)
            if resultBool {
                arrayAudio.append(classification)
                trigger=0
            } else if trigger <= 10 && arrayAudio.count > 2{
                trigger += 1
                arrayAudio.append(classification)
            } else {
                trigger += 1
                if arrayNoiseOne.count < 20 {
                    arrayNoiseOne.append(classification)
                } else {
                    arrayNoiseOne.append(classification)
                    arrayNoiseOne.removeFirst()
                }
            }


            if trigger > 10 && arrayAudio.count > 15 {
                //                addArrayNum = 0
                prepareData(arrayNoiseOne, arrayAudio)
                print("Len audio \((Double(arrayAudio.count) * 512.0) / 16000.0)")
                arrayAudio.removeAll()
//                arrayNoiseOne.removeAll()
//            } else if trigger < 15 {
//                if arrayAudio.count > 1{
//                    arrayAudio.append(classification)
//                }
            } else if trigger > 15 {
                trigger = 0
            }

        } catch {
            self.errorMessage = "Failed to process pcm frames."
            self.stop()
        }
    }

    //MARK: - another functions
    @objc func perfAdd() {
        reloadFirstConstrane?.reloadConstrains()
        self.navigationController?.popViewController(animated: true)
    }


    //MARK: - prepare data

    private func playAudio(){

        let url = firstScene.getWhistleURL(false)

        do {
            bombSoundEffect = try AVAudioPlayer(contentsOf: url)
            bombSoundEffect?.play()
        } catch {
            // couldn't load file :(
        }
    }

    private func recognizeAppla(_ audioArrayPlay: [Float]){
        let bufferFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(16000), channels: 1, interleaved: true)
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: bufferFormat!, frameCapacity: AVAudioFrameCount(audioArrayPlay.count))

        // i had my samples in doubles, so convert then write

        for i in 0..<audioArrayPlay.count {
            outputBuffer?.floatChannelData!.pointee[i] = audioArrayPlay[i]
        }
        outputBuffer?.frameLength = AVAudioFrameCount( audioArrayPlay.count )


        firstScene.requesApple.append(outputBuffer!)
        firstScene.recognizeApple()
        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
            self.firstScene.bestAnswerApple()
        }

    }

    private func prepareToPlay(_ audioArrayPlay: [Float]) {
        let bufferFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(16000), channels: 1, interleaved: true)
//        guard let bufferFormat = AVAudioFormat(settings: outputFormatSettings) else { return }

        let outputBuffer = AVAudioPCMBuffer(pcmFormat: bufferFormat!, frameCapacity: AVAudioFrameCount(audioArrayPlay.count))

        // i had my samples in doubles, so convert then write

        for i in 0..<audioArrayPlay.count {
            outputBuffer?.floatChannelData!.pointee[i] = audioArrayPlay[i]
        }
        outputBuffer?.frameLength = AVAudioFrameCount( audioArrayPlay.count )

        print("stop")


        let mainMixer = audioEngine.mainMixerNode
        audioEngine.attach(audioFilePlayer)
        audioEngine.connect(audioFilePlayer, to:mainMixer, format: outputBuffer?.format)
        do {
            try audioEngine.start()
        } catch {
            print("probleb audio Engine")
        }

        audioFilePlayer.play()
        audioFilePlayer.scheduleBuffer(outputBuffer!)

        //        var mainMixer = audioEngine.mainMixerNode
        //        audioEngine.attach(audioFilePlayer)
        //        audioEngine.connect(audioFilePlayer, to:mainMixer, format: outputBuffer?.format)
        //        do {
        //        try audioEngine.start()
        //        } catch {
        //            print("probleb audio Engine")
        //        }
        //
        //        audioFilePlayer.play()
        //        audioFilePlayer.scheduleBuffer(outputBuffer!)
    }


    func normAmplitude(_ arrayAudio: [Double], _ maxValue: Double) -> [Double] {
        let value = 1.0 / maxValue
        return arrayAudio.map {$0 * value}

    }


    private func prepareData(_ noiseArray: [[Float]], _ inputArray: [[Float]]) {


        newArray.removeAll()
        arrayAudio.removeAll()

        for arrayNoiseInt32 in noiseArray {
            for valueNoise in arrayNoiseInt32{
                newArray.append(Double(valueNoise))
            }
        }

        for arrayAudioInt32 in inputArray {
            for valueAudio in arrayAudioInt32{
                newArray.append(Double(valueAudio))
            }
        }

//        let maxValueAudio = newArray.max()!
//        let minValueAudio = abs(newArray.min()!)
//
//        if maxValueAudio > minValueAudio {
//            newArray = normAmplitude(newArray, maxValueAudio)
//        } else {
//            newArray = normAmplitude(newArray, minValueAudio)
//        }

//        stop()
//        prepareToPlay(newArray.map {Float($0)})

        firstScene.requesApple = SFSpeechAudioBufferRecognitionRequest()

        recognizeAppla(newArray.map {Float($0)})

        newArray = firstScene.normLen(inputArray: newArray)


        let audioData = try! MLMultiArray( shape: [1, 65280], dataType: .double )
        let ptr = UnsafeMutablePointer<Double>(OpaquePointer(audioData.dataPointer))

        let firstDem = audioData.strides[0].intValue
        let secondDem = audioData.strides[1].intValue


        for i in 0..<65280 {
            ptr[0*firstDem + i*secondDem] = newArray[i]
        }

        let inputs: [String: Any] = [
            "input": audioData,
        ]

        let provider = try! MLDictionaryFeatureProvider(dictionary: inputs)

        firstScene.predictProviderSmall(provider: provider)
        firstScene.predictProviderBig(provider: provider)
    }

}


//MARK: - Test

extension SecondScene {
    private func startAudioEngine() {

        let inputNode = audioEngine.inputNode

        let originalAudioFormat: AVAudioFormat = inputNode.inputFormat(forBus: 0)

        let downSampleRate: Double = desiredAudioFormatPrediction.sampleRate

        let ratio: Float = Float(originalAudioFormat.sampleRate)/Float(downSampleRate)

        guard let formatConverterFloat =  AVAudioConverter(from:originalAudioFormat, to: desiredAudioFormatPrediction) else {
            fatalError( "unable to create formatConverter! float" )
        }

        guard let formatConverterInt =  AVAudioConverter(from:originalAudioFormat, to: desiredAudioFormatCobra) else {
            fatalError( "unable to create formatConverter! int" )
        }

        // start audio capture by installing a Tap
        inputNode.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(Int(2048 * ratio) + 1),
            format: originalAudioFormat
        ) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) in
            // closure to process the captured audio, buffer size dictated by AudioEngine/device
            let capacity = UInt32(Float(buffer.frameCapacity)/ratio)

            guard let pcmBufferFloat = AVAudioPCMBuffer(
                pcmFormat: self.desiredAudioFormatPrediction,
                frameCapacity: capacity) else {
                print("Failed to create pcm buffer float")
                return
            }

            guard let pcmBufferInt16 = AVAudioPCMBuffer(
                pcmFormat: self.desiredAudioFormatCobra, frameCapacity: capacity) else {
                print("Failed to create pcm buffer int16")
                return
            }

            let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return buffer
            }

            // convert input samples into the one our model needs
            var error: NSError?
            let status: AVAudioConverterOutputStatus = formatConverterFloat.convert(
                to: pcmBufferFloat,
                error: &error,
                withInputFrom: inputBlock)

            let statusInt: AVAudioConverterOutputStatus = formatConverterInt.convert(
                to: pcmBufferInt16,
                error: &error,
                withInputFrom: inputBlock)

            if status == .error {
                if let unwrappedError: NSError = error {
                    print("Error \(unwrappedError)")
                }
                return
            }

            let channelDataFloat = pcmBufferFloat.floatChannelData
            let channelDataPointerFloat = channelDataFloat!.pointee
            let channelDataValueArrayFloat = stride(from: 0,
                                               to: Int(pcmBufferFloat.frameLength),
                                               by: pcmBufferFloat.stride).map{ channelDataPointerFloat[$0] }

            let channelDataInt = pcmBufferInt16.int16ChannelData
            let channelDataPoiterInter = channelDataInt!.pointee
            let channelDataValueArrayInt = stride(from: 0,
                                                  to: Int(pcmBufferInt16.frameLength),
                                                  by: pcmBufferInt16.stride).map{ channelDataPoiterInter[$0]}

            DispatchQueue.global(qos: .userInitiated).async {
                self.prepareConda(pcm: channelDataValueArrayInt, classification: channelDataValueArrayFloat)
            }

        } // installTap

        // ready to start the actual audio capture
        audioEngine.prepare()
        do {
            try audioEngine.start()
        }
        catch {
            print(error.localizedDescription)
        }
    } // end startAudioEngine
}

protocol ReloadConstrains: AnyObject {
    func reloadConstrains()
}
