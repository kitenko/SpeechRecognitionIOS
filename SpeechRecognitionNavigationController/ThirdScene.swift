import UIKit
import AVFoundation

class ThirdScene: UIViewController {

    private let dispatchGroup = DispatchGroup()
    private let synthesizer = AVSpeechSynthesizer()

    private var firstScene: FirstScene
    private var secondScene: SecondScene

    private var answerGame = " " {
        didSet {
            secondScene.stop()
            proccesingResults(textSynthes)
            print("ответ, ", answerGame)
        }
    }
    private var textSynthes = " "

    private var speechNow = false

    private let arrayWords = ["Камень", "Ножницы", "Бумага"]

    private let semaphore = DispatchSemaphore(value: 1)

    private var triggerGame = 1 {
        didSet {
            if triggerGame >= 3 {
                sythesisVoice(.continueGame)
            } else {
                getAnswer()
            }
        }
    }

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
        
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(gameButton)
        addConstain()
    }

    //MARK: - Constarins
    func addConstain() {
        var constrains = [NSLayoutConstraint]()

        constrains.append(NSLayoutConstraint(item: gameButton, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0))
        constrains.append(NSLayoutConstraint(item: gameButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))

        NSLayoutConstraint.activate(constrains)
    }

    @objc func startGame() {
        secondScene.initCobra()
        sythesisVoice(GameText.startGame)
    }

    private func sythesisVoice(_ textToSynthes: GameText) {

        semaphore.wait()
        
        
        let utterance = AVSpeechUtterance(string: textToSynthes.rawValue)

        // Configure the utterance.
        utterance.rate = 0.57
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0.2
        utterance.volume = 0.8

        // Retrieve the British English voice.
        let voice = AVSpeechSynthesisVoice(language: "ru-RU")

        // Assign the voice to the utterance.
        utterance.voice = voice

        // Tell the synthesizer to speak the utterance.
        speechNow = true
        synthesizer.speak(utterance)

    }

    private func getAnswer(){
        do {
            try secondScene.start()
        } catch {
            print("problev with micro")
        }
    }

    private func proccesingResults(_ textSynthes: String) {

        switch textSynthes {
        case GameText.startGame.rawValue:
            if answerGame == "Да" {
                sythesisVoice(.explanationRule)
            } else if answerGame == "Нет" {
                sythesisVoice(.noDesirePlay)
            }
        case GameText.explanationRule.rawValue:
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
                    sythesisVoice(.youWinn)
                } else {
                    sythesisVoice(.youLost)
                }
                triggerGame += 1
            } else {
                sythesisVoice(.unknowWord)
            }
        case GameText.youLost.rawValue:
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

        default:
            sythesisVoice(.unknowWord)
        }
    }
}

extension ThirdScene {
    enum GameText: String {
        case startGame = "Давай сыграем в камень, ножницы, бумага?"
        case explanationRule = "Супер! Мы играем так, ты произносишь либо камень, либо ножницы, либо бумага, я отвечаю выйграл ты или нет."
        case startRound = "Начинаем, произнеси слово."
        case youWinn = "Ты выйграл!"
        case youLost = "Я выйграла, ты проиграл!"
        case unknowWord = "Я не знаю этого слова!"
        case noDesirePlay = "Очень жаль что ты не хочешь играть"
        case stone = "Камень"
        case scissors = "Ножницы"
        case papper = "Бумага"
        case continueGame = "Хочешь продолжить игру или остановимся на этом?"
    }
}

extension ThirdScene: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {

        if utterance.speechString == GameText.explanationRule.rawValue {
            semaphore.signal()
            proccesingResults(GameText.explanationRule.rawValue)
        } else {
            if utterance.speechString == GameText.youWinn.rawValue || utterance.speechString == GameText.youLost.rawValue {
                textSynthes = GameText.startRound.rawValue
            } else {
                textSynthes = utterance.speechString
            }

            sleep(1)
            semaphore.signal()
            getAnswer()
        }
    }
}

extension ThirdScene: SendMessage {
    func receivedMessage(_ message: String) {
        answerGame = message
    }
}
