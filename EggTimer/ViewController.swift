//
//  ViewController.swift
//  EggTimer
//

import UIKit
import AVFoundation
import UserNotifications

class ViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!

    // MARK: - Properties
    let eggTimes: [String: Int] = ["Soft": 300, "Medium": 450, "Hard": 700]
    var totalTime = 0
    var secondsPassed = 0
    var timer = Timer()
    var player: AVAudioPlayer?
    let defaultTitle = "How do you like your eggs?"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Başlık ayarla
        titleLabel.text = defaultTitle
        
        // Bildirim izni iste
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Bildirim izni verildi.")
            } else {
                print("Bildirim izni reddedildi.")
            }
        }
    }

    // MARK: - Button Action
    @IBAction func hardnessSelected(_ sender: UIButton) {
        // Zamanlayıcı ve alarmı sıfırla
        timer.invalidate()
        player?.stop()

        // Yeni süreyi ayarla
        let hardness = sender.currentTitle!
        totalTime = eggTimes[hardness]!
        secondsPassed = 0
        progressBar.progress = 0.0
        titleLabel.text = hardness

        // Yeni zamanlayıcı başlat
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }

    // MARK: - Timer Update
    @objc func updateCounter() {
        if secondsPassed < totalTime {
            secondsPassed += 1
            progressBar.progress = Float(secondsPassed) / Float(totalTime)
        } else {
            timer.invalidate()
            titleLabel.text = "DONE!"
            playSound()
            scheduleNotification()
        }
    }

    // MARK: - Ses Çalma
    func playSound() {
        player?.stop()
        guard let url = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else {
            print("Ses dosyası bulunamadı.")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            
            // 5 saniye sonra sesi durdur
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                self.player?.stop()
            }

        } catch {
            print("Ses çalınırken hata oluştu: \(error.localizedDescription)")
        }
    }

    // MARK: - Bildirim Gönderme
    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Your Egg is Ready!"
        content.body = "Time to enjoy your perfectly cooked egg 🥚"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "eggDoneNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim gönderilemedi: \(error.localizedDescription)")
            } else {
                print("Bildirim başarıyla gönderildi.")
            }
        }
    }

    // MARK: - Ekrana Dokununca Başlığı Geri Getir
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self.view)
        
        if let touchedView = self.view.hitTest(location, with: event) {
            if !(touchedView is UIButton) && titleLabel.text == "DONE!" {
                titleLabel.text = defaultTitle
            }
        }
    }
}
