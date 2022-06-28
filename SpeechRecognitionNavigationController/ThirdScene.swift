import UIKit
import AVFoundation

class ThirdScene: UIViewController {

    private let dispatchGroup = DispatchGroup()
    private let synthesizer = AVSpeechSynthesizer()

    private var firstScene: FirstScene
    var secondScene: SecondScene

    private var scenario: ScenarioTest?

    var answerGame = " " {
        didSet {
            if textSynthes != GameText.detectPhone.rawValue {
            secondScene.stop()
            semaphore.signal()
            }
            if answerGame == "Выйти" {
                print("ответ, ", answerGame)
                scenario?.semaphoreScenario.signal()
            } else {
                proccesingResults(textSynthes)
                print("ответ, ", answerGame)
            }
        }
    }
    private var textSynthes = " "

    private var speechNow = false

    private let arrayWords = ["Камень", "Ножницы", "Бумага"]

    private let semaphore = DispatchSemaphore(value: 1)

    private let maxTrigger = 3

    private var triggerGame = 0

    //MARK: - Button

    private let gameButton: UIButton = {
        let button = UIButton()
        button.setTitle("Start Game", for: .normal)
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
        button.addTarget(self, action: #selector(startGame), for: .touchUpInside)
        return button
    }()

    private let scenarioButton: UIButton = {
        let button = UIButton()
        button.setTitle("Start Scenario", for: .normal)
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
        button.addTarget(self, action: #selector(startScenario), for: .touchUpInside)
        return button
    }()


    //MARK: - init

    init(_ firstScene: FirstScene) {
        self.firstScene = firstScene
        self.secondScene = SecondScene(firstScene)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        synthesizer.delegate = self
        firstScene.sendTo = self
        scenario = ScenarioTest(self)
        secondScene.initCobra()
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }

    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(gameButton)
        view.addSubview(scenarioButton)
        addConstain()
    }

    //MARK: - Constarins
    func addConstain() {
        var constrains = [NSLayoutConstraint]()

        constrains.append(NSLayoutConstraint(item: gameButton, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0))
        constrains.append(NSLayoutConstraint(item: gameButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))

        constrains.append(scenarioButton.topAnchor.constraint(equalTo: gameButton.bottomAnchor, constant: 20))
        constrains.append(NSLayoutConstraint(item: scenarioButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))

        NSLayoutConstraint.activate(constrains)
    }

    @objc func startGame() {
        sythesisVoice(GameText.startGame)
    }

    func sythesisVoice(_ textToSynthes: GameText) {

        let utterance = AVSpeechUtterance(string: textToSynthes.rawValue)

        // Configure the utterance.
        utterance.rate = 0.57
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0.2
        utterance.volume = 0.8

        let  voiceIdentifier = "com.apple.ttsbundle.Milena-premium"

        // Retrieve the British English voice.
        let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)


        // Assign the voice to the utterance.
        utterance.voice = voice

        // Tell the synthesizer to speak the utterance.
        speechNow = true
        synthesizer.speak(utterance)

    }

    func getAnswer(){

        DispatchQueue.global().async {
            self.semaphore.wait()
            do {
                try self.secondScene.start()
            } catch {
                print("problev with micro")
            }
        }
    }

    private func proccesingResults(_ textSynthes: String) {

        switch textSynthes {
        case GameText.startGame.rawValue:
            if answerGame == "Да" {
                sythesisVoice(.explanationRule)
            } else if answerGame == "Нет" {
                sythesisVoice(.noDesirePlay)
            } else {
                sythesisVoice(.dontUnderstand)
            }

        case GameText.explanationRule.rawValue:
            triggerGame = 0
            sythesisVoice(.startRound)

        case GameText.startRound.rawValue:
            if arrayWords.contains(answerGame) {
                if arrayWords.randomElement() == answerGame {
                    sythesisVoice(.youWinn)
                } else {
                    sythesisVoice(.youLost)
                }
                triggerGame += 1
            } else {
                sythesisVoice(.unknowWord)
            }

        case GameText.youWinn.rawValue:
            if arrayWords.contains(answerGame) {
                if arrayWords.randomElement() == answerGame {
                    if triggerGame + 1 == maxTrigger {
                        sythesisVoice(.youWinnCool)
                    } else {
                    sythesisVoice(.youWinn)
                    }
                } else {
                    if triggerGame + 1 == maxTrigger {
                        sythesisVoice(.youLostNo)
                    } else {
                    sythesisVoice(.youLost)
                    }
                }
                triggerGame += 1
            } else {
                sythesisVoice(.unknowWord)
            }
        case GameText.youLost.rawValue:
            if arrayWords.contains(answerGame) {
                if arrayWords.randomElement() == answerGame {
                    if triggerGame + 1 == maxTrigger {
                        sythesisVoice(.youWinnCool)
                    } else {
                    sythesisVoice(.youWinn)
                    }
                } else {
                    if triggerGame + 1 == maxTrigger {
                        sythesisVoice(.youLostNo)
                    } else {
                    sythesisVoice(.youLost)
                    }
                }
                triggerGame += 1
            } else {
                sythesisVoice(.unknowWord)
            }
        case GameText.unknowWord.rawValue:
            sythesisVoice(.continueGame)

        case GameText.continueGame.rawValue:
            if answerGame == "Да" {
                sythesisVoice(.coolContinue)
            } else if answerGame == "Нет" {
                sythesisVoice(.coolGetStop)
            } else {
                sythesisVoice(.continue222)
            }

        case GameText.detectPhone.rawValue:
            print("я тут ")
            if answerGame == "Отключить повтор" {
                print(answerGame)
            }

        default:
            sythesisVoice(.unknowWord)
        }
    }


    @objc func startScenario() {
        scenario?.startScenario()
    }
}

extension ThirdScene {
    enum GameText: String {
        case startGame = "Давай сыграем в камень, ножницы, бумага?"
        case explanationRule = "Супер! Мы играем так, ты произносишь либо камень, либо ножницы, либо бумага, я отвечаю выйграл ты или нет."
        case startRound = "Начинаем, произнеси слово."
        case youWinn = "Ты выйграл!, загадай ещё"
        case youLost = "Я выйграла, ты проиграл!, давай ещё попробуешь!"
        case unknowWord = "Я не знаю этого слова!"
        case noDesirePlay = "Очень жаль что ты не хочешь играть"
        case stone = "Камень"
        case scissors = "Ножницы"
        case papper = "Бумага"
        case continueGame = "Хочешь продолжить игру или остановимся на этом?"
        case dontUnderstand = "Я не поняла, хочешь ли ты играть или нет?"
        case coolContinue = "Классно!, продолжаем"
        case coolGetStop = "Хорошо, ты молодец, пока пока!"
        case continue222 = "Продолжаем?"
        case youWinnCool = "Круто!, ты выйграл"
        case youLostNo = "В этот раз ты проиграл"

        case detectDrowsiness = "Мне кажется ты начинаешь засыпать."
        case detectSeatBelt = "Ты прёстегнул ремень безопасности?"
        case detectDrink = "Если ты хочешь попить что-то, то это следует делать во время остановки а не за рулём автомобиля!"
        case detectFood = "Я надеюсь это очень вкусно, но держать руль нужно двумя руками!"
        case detectPhone = "Обнаружено использование телефона"
    }
}

extension ThirdScene: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {

        print("out -- \(utterance.speechString)")

        if utterance.speechString == GameText.explanationRule.rawValue {
            proccesingResults(GameText.explanationRule.rawValue)
        } else if utterance.speechString == GameText.startRound.rawValue {
            textSynthes = utterance.speechString
            getAnswer()
        } else if utterance.speechString == GameText.youWinn.rawValue || utterance.speechString == GameText.youLost.rawValue {
                    textSynthes = utterance.speechString
                    getAnswer()
                } else if utterance.speechString == GameText.youWinnCool.rawValue || utterance.speechString == GameText.youLostNo.rawValue {
                    secondScene.stop()
                    semaphore.signal()
                    sythesisVoice(.continueGame)
        } else if utterance.speechString == GameText.coolContinue.rawValue {
            proccesingResults(GameText.explanationRule.rawValue)
        } else if utterance.speechString == GameText.coolGetStop.rawValue {
            secondScene.stop()
            semaphore.signal()
            scenario?.semaphoreScenario.signal()
        } else if utterance.speechString == GameText.continueGame.rawValue {
            textSynthes = GameText.continueGame.rawValue
            getAnswer()
        } else if utterance.speechString == GameText.unknowWord.rawValue {
            semaphore.signal()
            proccesingResults(GameText.unknowWord.rawValue)
        } else if utterance.speechString == GameText.dontUnderstand.rawValue {
            textSynthes = GameText.startGame.rawValue
            getAnswer()
        } else if utterance.speechString == GameText.startGame.rawValue {
            textSynthes = GameText.startGame.rawValue
            getAnswer()
        } else if utterance.speechString == GameText.noDesirePlay.rawValue {
            secondScene.stop()
            semaphore.signal()
            scenario?.semaphoreScenario.signal()
        } else if utterance.speechString == GameText.continue222.rawValue {
            textSynthes = GameText.continueGame.rawValue
            getAnswer()
        } else if utterance.speechString == GameText.detectDrowsiness.rawValue {
            sythesisVoice(.startGame)
        } else if utterance.speechString == GameText.detectFood.rawValue {
            scenario?.semaphoreScenario.signal()
        } else if utterance.speechString == GameText.detectDrink.rawValue {
            scenario?.semaphoreScenario.signal()
        } else if utterance.speechString == GameText.detectSeatBelt.rawValue {
            scenario?.semaphoreScenario.signal()
        } else if utterance.speechString == GameText.detectPhone.rawValue {
            textSynthes = GameText.detectPhone.rawValue
            scenario?.semaphoreMobile.signal()
        }
    }
}

extension ThirdScene: SendMessage {
    func receivedMessage(_ message: String) {
        answerGame = message
    }
}
