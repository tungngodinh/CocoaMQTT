//
//  ChatViewModel.swift
//  Example
//
//  Created by tungnd on 9/11/19.
//  Copyright © 2019 emqtt.io. All rights reserved.
//

import UIKit
import CocoaMQTT
import RxSwift
import RxCocoa

class ChatViewModel {
    
    let defaultHost = "127.0.0.1"
    
    let disposeBag = DisposeBag()
    let animal: String
    let connectStatus = PublishSubject<Bool>()
    let recevedMessage = PublishSubject<ChatMessage>()
    let sendMessage = PublishSubject<String>()
    let dissconect = PublishSubject<Bool>()
    
    lazy var animalImage: BehaviorRelay<UIImage?> = {
        return BehaviorRelay<UIImage?>(value: UIImage(named: animal))
    }()
    
    lazy var animalSlogan: BehaviorRelay<String?> = {
        var text = ""
        switch animal {
        case "Sheep":
            text = "Four legs good, two legs bad."
        case "Pig":
            text = "All animals are equal."
        case "Horse":
            text = "I will work harder."
        default:
            break
        }
        return BehaviorRelay<String?>(value: text)
    }()
    
    init(with animal: String) {
        self.animal = animal
        
        sendMessage.subscribe(onNext: {[weak self] text in
            guard let weakSelf = self else { return }
            weakSelf.mqttClient.publish("chat/room/animals/client/" + weakSelf.animal, withString: text, qos: .qos1)
        }).disposed(by: disposeBag)
        
        dissconect.subscribe(onNext: {[weak self] _ in
            self?.mqttClient.disconnect()
        }).disposed(by: disposeBag)
    }
    
    lazy var mqttClient: CocoaMQTT = {
        let clientID = "CocoaMQTT-\(animal)-" + String(ProcessInfo().processIdentifier)
        let mqtt = CocoaMQTT(clientID: clientID, host: defaultHost, port: 1883)
        mqtt.username = ""
        mqtt.password = ""
        mqtt.keepAlive = 60
        mqtt.delegate = self
        return mqtt
    }()
    
    func connect() {
        connectStatus.onNext(mqttClient.connect())
    }
}

extension ChatViewModel: CocoaMQTTDelegate {
    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            mqtt.subscribe("chat/room/animals/client/+", qos: CocoaMQTTQOS.qos1)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        
        if let text = message.string {
            recevedMessage.onNext(ChatMessage(sender: message.topic.replacingOccurrences(of: "chat/room/animals/client/", with: ""), content: text))
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
    
    }
}

