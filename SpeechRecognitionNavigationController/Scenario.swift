import Foundation

class ScenarioTest {
    private var thirdScene: ThirdScene

    private var start = true

    let semaphoreScenario = DispatchSemaphore(value: 1)
    let semaphoreMobile = DispatchSemaphore(value: 1)

    init(_ thirdScene: ThirdScene) {
        self.thirdScene = thirdScene
    }

    private var event = ["ничего не происходит", "обнаружена сонливость", "обнаружен непристегнутый ремень",
                         "обнаружен телефон", "обнаружен напиток", "обнаружена еда"]

    func startScenario() {
        DispatchQueue.global().async {
            self.scenarioEvent()
        }

    }

    func scenarioEvent() {
        while start {

            sleep(5)

            if thirdScene.answerGame == "Выйти" {
                break
            }
            semaphoreScenario.wait()
            let randomEvent = event.randomElement()

            if "обнаружен непристегнутый ремень" == randomEvent! {
                thirdScene.sythesisVoice(.detectSeatBelt)
            } else if "обнаружена сонливость" == randomEvent {
                thirdScene.sythesisVoice(.detectDrowsiness)
            } else if "обнаружен напиток" == randomEvent {
                thirdScene.sythesisVoice(.detectDrink)
            } else if "обнаружена еда" == randomEvent {
                thirdScene.sythesisVoice(.detectFood)
            } else if "обнаружен телефон" == randomEvent {
                
                thirdScene.getAnswer()

                while thirdScene.answerGame != "Отключить повтор" {
                    sleep(3)
                    semaphoreMobile.wait()
                    thirdScene.sythesisVoice(.detectPhone)
                }

                thirdScene.secondScene.stop()
                semaphoreScenario.signal()

            }
        }
    }
}
