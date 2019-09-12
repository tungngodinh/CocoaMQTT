//
//  ViewController.swift
//  Example
//
//  Created by CrazyWisdom on 15/12/14.
//  Copyright © 2015年 emqtt.io. All rights reserved.
//

import UIKit
import CocoaMQTT
import RxCocoa
import RxSwift

/// https://github.com/emqx/CocoaMQTT

class ViewController: UIViewController {
   
    lazy var viewModel: ChatViewModel = {
        return ChatViewModel(with: animal ?? "unknow")
    }()

    var animal: String?
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var animalsImageView: UIImageView!
    @IBAction func connectToServer() {
        viewModel.connect()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        tabBarController?.delegate = self
        animal = tabBarController?.selectedViewController?.tabBarItem.title
        animalsImageView.clipsToBounds = true
        animalsImageView.layer.borderWidth = 1.0
        animalsImageView.layer.cornerRadius = animalsImageView.frame.width / 2.0
        
        viewModel.connectStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] connected in
            if connected, let controller = self?.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController  {
                controller.viewModel = self?.viewModel
                self?.show(controller, sender: nil)
            } else {
                print("Connect host failed")
            }
        }).disposed(by: viewModel.disposeBag)
        
    }
}
extension ViewController: UITabBarControllerDelegate {
    // Prevent automatic popToRootViewController on double-tap of UITabBarController
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return viewController != tabBarController.selectedViewController
    }
}
extension Optional {
    // Unwarp optional value for printing log only
    var description: String {
        if let warped = self {
            return "\(warped)"
        }
        return ""
    }
}
