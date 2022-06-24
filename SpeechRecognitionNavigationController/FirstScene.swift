import UIKit
import AVFoundation
import CoreML
import Speech

class FirstScene: UIViewController, AVAudioRecorderDelegate,
                  UICollectionViewDelegate, SFSpeechRecognizerDelegate {


    var recordingSession: AVAudioSession!
    var whistleRecorder: AVAudioRecorder!
    var bombSoundEffect: AVAudioPlayer?
    var player: AVAudioPlayer?

    var bigModel: mobilenetSpeechSpeBig? = nil
    typealias NetworkInputBig = mobilenetSpeechSpeBigInput
    typealias NetworkOutputBig = mobilenetSpeechSpeBigOutput

    var smallModel: mobilenetSpeechSpeSmall? = nil
    typealias NetworkInputSmall = mobilenetSpeechSpeSmallInput
    typealias NetworkOutputSmall = mobilenetSpeechSpeSmallOutput

    var class_labels: NSArray?
    var arrayAnwserApple = [String]()

    var firstTime = true

    var resultConstraint: CGFloat = -10
    //    var constrainResult: NSLayoutConstraint!

    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier: "ru-RU"))
    var requesApple = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    let sampleRate: Float = 16000

    var labelChange: String = " " {
        didSet {
            sendTo?.receivedMessage(labelChange)
        }
    }

    weak var sendTo: SendMessage?

    private var secondScene: SecondScene?

    //MARK: - VOSK
    var processingQueue: DispatchQueue!


    //MARK: - resultsView

    let resalutEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let resultEffectView = UIVisualEffectView(effect: blurEffect)
        resultEffectView.translatesAutoresizingMaskIntoConstraints = false
        resultEffectView.alpha = 0
        resultEffectView.layer.cornerRadius = 30
        resultEffectView.clipsToBounds = true
        return resultEffectView
    }()

    let resultLabel: UILabel = {
        let resultLabel = UILabel()
        return resultLabel
    }()


    // MARK: - init Button

    private let recordButton: UIButton = {
        let recordButton = UIButton()
        recordButton.setTitle("Tap ro Record", for: .normal)
        recordButton.titleLabel?.font = .preferredFont(forTextStyle: .title1)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.backgroundColor = .lightGray
        recordButton.titleLabel?.adjustsFontSizeToFitWidth = true
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        recordButton.layer.cornerRadius = 12
        recordButton.clipsToBounds = true
        recordButton.layer.shadowColor = UIColor.gray.cgColor
        recordButton.layer.shadowOffset = CGSize(width: 2, height: 5)
        recordButton.layer.masksToBounds = false
        recordButton.layer.shadowRadius = 5
        recordButton.layer.shadowOpacity = 2.0
        return recordButton
    }()

    private let autoRecognition: UIButton = {
        let autoRecognition = UIButton()
        autoRecognition.setTitle("Go to auto mode", for: .normal)
        autoRecognition.titleLabel?.font = .preferredFont(forTextStyle: .title1)
        autoRecognition.translatesAutoresizingMaskIntoConstraints = false
        autoRecognition.backgroundColor = .lightGray
        autoRecognition.titleLabel?.adjustsFontSizeToFitWidth = true
        autoRecognition.layer.cornerRadius = 12
        autoRecognition.clipsToBounds = true
        autoRecognition.layer.shadowColor = UIColor.gray.cgColor
        autoRecognition.layer.shadowOffset = CGSize(width: 2, height: 5)
        autoRecognition.layer.masksToBounds = false
        autoRecognition.layer.shadowRadius = 5
        autoRecognition.layer.shadowOpacity = 2.0
        autoRecognition.addTarget(self, action: #selector(showSecondScene), for: .touchUpInside)
        return autoRecognition
    }()

    private let gameButton: UIButton = {
        let button = UIButton()
        button.setTitle("Game", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .title1)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .lightGray
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOffset = CGSize(width: 2, height: 5)
        button.layer.masksToBounds = false
        button.layer.shadowRadius = 5
        button.layer.shadowOpacity = 2.0
        button.addTarget(self, action: #selector(showThirdScene), for: .touchUpInside)
        return button
    }()



    // MARK: - init Answer

    private let firstAnswer: UILabel = {
        let firstAnswer = UILabel()
        firstAnswer.text = "1) First Answer"
        firstAnswer.font = .boldSystemFont(ofSize: 30)
        firstAnswer.translatesAutoresizingMaskIntoConstraints = false
        firstAnswer.textColor = .white
        firstAnswer.textAlignment = .left
        firstAnswer.adjustsFontSizeToFitWidth = true

        return firstAnswer
    }()

    private let secondAnswer: UILabel = {
        let secondAnswer = UILabel()
        secondAnswer.text = "2) Second Answer"
        secondAnswer.font = .boldSystemFont(ofSize: 30)
        secondAnswer.translatesAutoresizingMaskIntoConstraints = false
        secondAnswer.textColor = .white
        secondAnswer.textAlignment = .left
        secondAnswer.adjustsFontSizeToFitWidth = true
        return secondAnswer
    }()

    private let thirdAnswer: UILabel = {
        let thirdAnswer = UILabel()
        thirdAnswer.text = "3) Third Answer"
        thirdAnswer.font = .boldSystemFont(ofSize: 30)
        thirdAnswer.translatesAutoresizingMaskIntoConstraints = false
        thirdAnswer.textColor = .white
        thirdAnswer.textAlignment = .left
        thirdAnswer.adjustsFontSizeToFitWidth = true
        return thirdAnswer
    }()

    // MARK: - init Stacks
    private let stackMain: UIStackView = {
        let stackMain = UIStackView()
        stackMain.spacing = 15
        stackMain.translatesAutoresizingMaskIntoConstraints = false
        stackMain.distribution = .fill
        stackMain.alignment = .fill
        stackMain.axis = .vertical
        return stackMain
    }()

    private let stackButton: UIStackView = {
        let stackButton = UIStackView()
        stackButton.spacing = 20
        stackButton.translatesAutoresizingMaskIntoConstraints = false
        stackButton.distribution = .fillEqually
        stackButton.alignment = .center
        stackButton.axis = .horizontal
        stackButton.isLayoutMarginsRelativeArrangement = true
        stackButton.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20)
        return stackButton
    }()

    let stackAnimation: UIStackView = {
        let stackAnimation = UIStackView()
        stackAnimation.spacing = 10
        stackAnimation.translatesAutoresizingMaskIntoConstraints = false
        stackAnimation.distribution = .fillEqually
        stackAnimation.alignment = .fill
        stackAnimation.axis = .vertical
        stackAnimation.isLayoutMarginsRelativeArrangement = true
        stackAnimation.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        return stackAnimation
    }()


    let stackLabels: UIStackView = {
        let stackLabels = UIStackView()
        stackLabels.translatesAutoresizingMaskIntoConstraints = false
        stackLabels.spacing = 10
        stackLabels.distribution = .fillEqually
        stackLabels.alignment = .fill
        stackLabels.axis = .vertical
        stackLabels.isLayoutMarginsRelativeArrangement = true
        stackLabels.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        return stackLabels
    }()

    private let stackTable: UIStackView = {
        let stackTable = UIStackView()
        stackTable.translatesAutoresizingMaskIntoConstraints = false
        stackTable.distribution = .fill
        stackTable.alignment = .fill
        stackTable.axis = .vertical
        return stackTable
    }()

    // MARK: - tableView

    //    private let tableView = UITableView()

    let collectionView: UICollectionView = {
        let viewLayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: viewLayout)
        collectionView.backgroundColor = .white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    // MARK: - main funktions
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Recognition by button"

        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("yes")
                    } else {
                        self.loadFailUI()
                    }
                }
            }
        } catch {
            self.loadFailUI()
        }


        secondScene = SecondScene(self)
        secondScene?.reloadFirstConstrane = self

        load_model()
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white

        stackButton.addArrangedSubview(recordButton)
        stackButton.addArrangedSubview(autoRecognition)
        stackButton.addArrangedSubview(gameButton)

        stackAnimation.addArrangedSubview(resalutEffectView)
        stackTable.addArrangedSubview(collectionView)
        stackLabels.addArrangedSubview(firstAnswer)
        stackLabels.addArrangedSubview(secondAnswer)
        stackLabels.addArrangedSubview(thirdAnswer)
        resalutEffectView.contentView.addSubview(stackLabels)


        stackMain.addArrangedSubview(stackTable)
        stackMain.addArrangedSubview(stackButton)

        view.addSubview(stackMain)
        view.addSubview(stackAnimation)

        prepareTable()
        addConstrains()


    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        hideResultsView()
    }

    // MARK: - additional functions interface
    func addConstrains(){
        var constrains = [NSLayoutConstraint]()
        // Add
        constrains.append(stackMain.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
        constrains.append(stackMain.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
        constrains.append(stackMain.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
        constrains.append(stackMain.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))

        constrains.append(stackLabels.leadingAnchor.constraint(equalTo: resalutEffectView.leadingAnchor))
        constrains.append(stackLabels.trailingAnchor.constraint(equalTo: resalutEffectView.trailingAnchor))
        constrains.append(stackLabels.bottomAnchor.constraint(equalTo: resalutEffectView.bottomAnchor))
        constrains.append(stackLabels.topAnchor.constraint(equalTo: resalutEffectView.topAnchor))

        constrains.append(collectionView.leadingAnchor.constraint(equalTo: stackTable.leadingAnchor))
        constrains.append(collectionView.trailingAnchor.constraint(equalTo: stackTable.trailingAnchor))
        constrains.append(collectionView.bottomAnchor.constraint(equalTo: stackTable.bottomAnchor))
        constrains.append(collectionView.topAnchor.constraint(equalTo: stackTable.topAnchor))

        constrains.append(stackAnimation.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: 16))
        constrains.append(stackAnimation.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10))
        constrains.append(stackAnimation.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10))

        //Activate
        NSLayoutConstraint.activate(constrains)
    }

    func loadFailUI() {
        let failLabel = UILabel()
        failLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        failLabel.text = "Recording failed: please ensure the app has access to your microphone."
        failLabel.numberOfLines = 0

        view.addSubview(failLabel)
    }

    func showResultsView(delay: TimeInterval = 0.1) {
        DispatchQueue.main.async {
            self.view.layoutIfNeeded()
        }

        UIView.animate(withDuration: 0.5,
                       delay: delay,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.6,
                       options: .beginFromCurrentState,
                       animations: {
            DispatchQueue.main.async {
                self.resalutEffectView.alpha = 1
            }
            //            self.constrainResult.constant = -10
            DispatchQueue.main.async {
                self.view.layoutIfNeeded()
            }
        },
                       completion: nil)
    }

    func hideResultsView() {
        UIView.animate(withDuration: 0.3) {
            self.resalutEffectView.alpha = 0
        }
    }

    func prepareTable() {
        collectionView.register(Cell.self, forCellWithReuseIdentifier: Cell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    func sendAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @objc func showSecondScene(){
        self.navigationController?.pushViewController(secondScene!, animated: true)
    }

    @objc func showThirdScene(){
        let thirdScene = ThirdScene(self)
        self.navigationController?.pushViewController(thirdScene, animated: true)
    }


    // MARK: - additional functions

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func getWhistleURL(_ firstScene: Bool = true) -> URL {
        if firstScene {
            return getDocumentsDirectory().appendingPathComponent("whistle.waw")
        } else {
            return getDocumentsDirectory().appendingPathComponent("outFileCobra.waw")
        }
    }

    func startRecording() {
        requesApple = SFSpeechAudioBufferRecognitionRequest()
        // 1
        recordButton.backgroundColor = UIColor(named: "ButtonStop")

        // 2
        recordButton.setTitle("Tap to Stop", for: .normal)

        // 3
        let audioURL = getWhistleURL()
        print(audioURL.absoluteString)

        // 4
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            // 5
            whistleRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            whistleRecorder.delegate = self
            whistleRecorder.record()
        } catch {
            finishRecording(success: false)
        }
    }

    @objc func nextTapped() {

    }

    func finishRecording(success: Bool) {
        recordButton.backgroundColor = .lightGray

        whistleRecorder.stop()
        whistleRecorder = nil

        if success {
            recordButton.setTitle("Tap to Re-record", for: .normal)
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextTapped))
            prepareSound()
            recognizeApple()
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                self.bestAnswerApple()
            }
            showResultsView()
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
            let ac = UIAlertController(title: "Record failed", message: "There was a problem recording your whistle; please try again.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }

    @objc func recordTapped() {
        if whistleRecorder == nil {
            hideResultsView()
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }

    func prepareSound() {
        let audioURL = getWhistleURL()

        if FileManager.default.fileExists(atPath: audioURL.path) {
            print("FILE AVAILABLE")
        } else {
            print("FILE NOT AVAILABLE")
        }

        if let file = try? AVAudioFile(forReading: audioURL) {
            if let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false) {
                let audioFrameCount = UInt32(file.length)
                if let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: audioFrameCount) {
                    do {
                        try file.read(into: buf)
                    } catch {
                        print("problem with read")
                    }
                    self.requesApple.append(buf)

                    // this makes a copy, you might not want that
                    var audioArray = Array(UnsafeBufferPointer(start: buf.floatChannelData![0], count:Int(buf.frameLength))).map { Double($0) }



                    audioArray = normLen(inputArray: audioArray)


                    let audioData = try! MLMultiArray( shape: [1, 65280], dataType: .double )
                    let ptr = UnsafeMutablePointer<Double>(OpaquePointer(audioData.dataPointer))

                    let firstDem = audioData.strides[0].intValue
                    let secondDem = audioData.strides[1].intValue


                    for i in 0..<65280 {
                        ptr[0*firstDem + i*secondDem] = audioArray[i]
                    }

                    let inputs: [String: Any] = [
                        "input": audioData,
                    ]

                    let provider = try! MLDictionaryFeatureProvider(dictionary: inputs)

                    self.predictProviderBig(provider: provider)

                    self.predictProviderSmall(provider: provider)
                }
            }
        }  else {
            print("error read")
        }
    }


    func recognizeApple() {
        DispatchQueue.main.async {
            self.thirdAnswer.text = "Apple: "
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not currently available. Check back at a later time.")
            // Recognizer is not available right now
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: requesApple) { result, error in
            if let result = result {

                self.arrayAnwserApple.append(result.bestTranscription.formattedString)

            } else if let error = error {
                //                self.sendAlert(title: "Speech Recognizer Error", message: "There has been a speech recognition error.")
                //                self.sendAlert(title: "Speech Recognizer Error", message: error.localizedDescription)
                                print(error.localizedDescription)
            }
        }
    }

    func bestAnswerApple() {
        DispatchQueue.main.async {
            self.thirdAnswer.text = "Apple: \(self.arrayAnwserApple.last ?? "no answer")"
        }
        recognitionTask?.finish()
    }

    func normLen(inputArray: [Double]) -> [Double] {
        let lenAudio = inputArray.count
        let maxLen = 65280

        if lenAudio > maxLen {
            let padBegin = Int.random(in: 0...lenAudio - maxLen)
            let newAudio = Array(inputArray[padBegin..<padBegin+maxLen])

            return newAudio

        } else if lenAudio < maxLen {
            let padBegin = Int.random(in: 0...maxLen - lenAudio)
            let padEnd = maxLen - lenAudio - padBegin
            let padFirst = (0..<padBegin).map({_ in Double.random(in: -0.001...0.001)})
            let padSecond = (0..<padEnd).map({_ in Double.random(in: -0.001...0.001)})
            let newAudio = padFirst + inputArray + padSecond

            return newAudio

        } else {
            return inputArray
        }
    }

    private func load_model() {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        do {
            self.bigModel = try mobilenetSpeechSpeBig(configuration: config )
        } catch {
            fatalError("unable to load ML model!")
        }

        do {
            self.smallModel = try mobilenetSpeechSpeSmall(configuration: config)
        } catch {
            fatalError("unable to load ML model!")
        }

        guard let path = Bundle.main.path(forResource:"label", ofType: "json") else {
            return
        }


        if let JSONData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            self.class_labels = try! JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as? NSArray
        }

    }

    func predictProviderBig(provider: MLDictionaryFeatureProvider ) {

        if let outFeatures = try? self.bigModel?.model.prediction(from: provider) {
            // release the semaphore as soon as the model is done

            let outputs = NetworkOutputBig(features: outFeatures)

            let output_clipwise: MLMultiArray = outputs._558

            let pointer = UnsafeMutablePointer<Float32>(OpaquePointer(output_clipwise.dataPointer))

            let num_classes = self.class_labels!.count
            var max_class: Int = -1
            var max_class_prob: Float32 = 0.0
            for i in 0..<num_classes {
                let val = Float32( pointer[i] )
                if val > max_class_prob {
                    max_class_prob = val
                    max_class = i
                }
            }

            let answer1 = class_labels![max_class] as! String
            DispatchQueue.main.async {
                self.firstAnswer.text = "Big: " + answer1 + ":" + String(format: "%.3f", max_class_prob)
            }


            //            var max_class_2: Int = -1
            //            var max_class_prob_2: Float32 = 0.0
            //            for i in 0..<num_classes {
            //                if i == max_class {
            //                    continue
            //                }
            //                let val = Float32( pointer[i] )
            //                if val > max_class_prob_2 {
            //                    max_class_prob_2 = val
            //                    max_class_2 = i
            //                }
            //            }
            //
            //            let answer2 = class_labels![max_class_2] as! String
            //            secondAnswer.text = "2) " + answer2 + ": \(max_class_prob_2)"

            //            var max_class_3: Int = -1
            //            var max_class_prob_3: Float32 = 0.0
            //            for i in 0..<num_classes {
            //                if i == max_class || i == max_class_2 {
            //                    continue
            //                }
            //                let val = Float32( pointer[i] )
            //                if val > max_class_prob_3 {
            //                    max_class_prob_3 = val
            //                    max_class_3 = i
            //                }
            //            }
            //
            //            let answer3 = class_labels![max_class_3] as! String
            //            thirdAnswer.text = "3) " + answer3 + ": \(max_class_prob_3)"


        } else {
            print("not")
        }
    }

    func predictProviderSmall(provider: MLDictionaryFeatureProvider ) {

        if let outFeatures = try? self.smallModel?.model.prediction(from: provider) {
            // release the semaphore as soon as the model is done

            let outputs = NetworkOutputSmall(features: outFeatures)

            let output_clipwise: MLMultiArray = outputs._453

            let pointer = UnsafeMutablePointer<Float32>(OpaquePointer(output_clipwise.dataPointer))

            let num_classes = self.class_labels!.count - 3
            var max_class: Int = -1
            var max_class_prob: Float32 = 0.0
            for i in 0..<num_classes {
                let val = Float32( pointer[i] )
                if val > max_class_prob {
                    max_class_prob = val
                    max_class = i
                }
            }

            let answer1 = class_labels![max_class] as! String
            DispatchQueue.main.async {
                self.secondAnswer.text = "Small: " + answer1 + ": " + String(format: "%.3f", max_class_prob)
                self.labelChange = answer1
            }
        } else {
            print("not")
        }
    }
}

// MARK: - Extension

extension FirstScene: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return class_labels?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.identifier, for: indexPath) as! Cell

        let text = "\(indexPath.item + 1)) \(class_labels?[indexPath.row] as! String)"
        cell.newText(new: text)
        return cell
    }

}

extension FirstScene: UICollectionViewDelegateFlowLayout {

    private enum LayoutConstant {
        static let spacing: CGFloat = 16.0
        static let itemHeight: CGFloat = 70.0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = itemWidth(for: view.frame.width, spacing: LayoutConstant.spacing)

        return CGSize(width: width, height: LayoutConstant.itemHeight)
    }

    func itemWidth(for width: CGFloat, spacing: CGFloat) -> CGFloat {
        let itemsInRow: CGFloat = 1

        let totalSpacing: CGFloat = 2 * spacing + (itemsInRow - 1) * spacing
        let finalWidth = (width - totalSpacing) / itemsInRow

        return floor(finalWidth)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: LayoutConstant.spacing, left: LayoutConstant.spacing, bottom: LayoutConstant.spacing, right: LayoutConstant.spacing)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return LayoutConstant.spacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return LayoutConstant.spacing
    }

}

extension FirstScene: ReloadConstrains {

    func reloadConstrains() {
        self.loadView()
        self.viewDidLoad()
    }
}


protocol SendMessage: AnyObject {
    func receivedMessage(_ message: String)
}
