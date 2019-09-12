//
//  ChatViewController.swift
//  Example
//
//  Created by CrazyWisdom on 15/12/24.
//  Copyright © 2015年 emqtt.io. All rights reserved.
//

import UIKit
import CocoaMQTT
import RxSwift
import RxCocoa
import RxDataSources

class ChatViewController: UIViewController {

    weak var viewModel: ChatViewModel!
    
    
    var messages: [ChatMessage] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var animalAvatarImageView: UIImageView!
    @IBOutlet weak var sloganLabel: UILabel!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendMessageButton: UIButton!
    
    lazy var dataSource: RxTableViewSectionedReloadDataSource<SectionModel<String, ChatMessage>> = {
        return RxTableViewSectionedReloadDataSource<SectionModel<String, ChatMessage>>(configureCell: {section, tableView, indexPath, message -> UITableViewCell in
            if message.sender == self.viewModel.animal {
                let cell = tableView.dequeueReusableCell(withIdentifier: "rightMessageCell", for: indexPath) as! ChatRightMessageCell
                cell.contentLabel.text = message.content
                cell.avatarImageView.image = UIImage(named: self.viewModel.animal)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "leftMessageCell", for: indexPath) as! ChatLeftMessageCell
                cell.contentLabel.text = message.content
                cell.avatarImageView.image = UIImage(named: message.sender)
                return cell
            }
        })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configUI()
        setupBinding()
    }
    
    @IBAction func disconnect() {
        viewModel.dissconect.onNext(true)
        _ = navigationController?.popViewController(animated: true)
    }
    
    func configUI() {
        navigationController?.navigationBar.isHidden = true
        automaticallyAdjustsScrollViewInsets = false
        messageTextView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        messageTextView.layer.cornerRadius = 5

    }
    
    func setupBinding() {
        messageTextView
            .rx.text
            .map({!($0?.isEmpty ?? true)})
            .bind(to: sendMessageButton.rx.isEnabled)
            .disposed(by: viewModel.disposeBag)
        
        sendMessageButton
            .rx.controlEvent(.touchUpInside)
            .subscribe(onNext: {[weak self] _ in
            guard let weakSelf = self else { return }
                weakSelf.viewModel.sendMessage.onNext(weakSelf.messageTextView.text)
                weakSelf.messageTextView.rx.text.onNext(nil)
            })
            .disposed(by: viewModel.disposeBag)
        
        viewModel
            .animalImage
            .bind(to: animalAvatarImageView.rx.image)
            .disposed(by: viewModel.disposeBag)
        
        viewModel
            .animalSlogan
            .bind(to: sloganLabel.rx.text)
            .disposed(by: viewModel.disposeBag)
        
        viewModel
            .recevedMessage
            .scan(messages) { (ms, item) -> [ChatMessage] in
                return ms + [item]
            }.map({[SectionModel<String, ChatMessage>(model: "", items: $0)]})
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: viewModel.disposeBag)
    }
    
    @objc func keyboardChanged(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let keyboardValue = userInfo["UIKeyboardFrameEndUserInfoKey"]
        let bottomDistance = UIScreen.main.bounds.size.height - (navigationController?.navigationBar.frame.height)! - keyboardValue!.cgRectValue.origin.y
        
        if bottomDistance > 0 {
            inputViewBottomConstraint.constant = bottomDistance
        } else {
            inputViewBottomConstraint.constant = 0
        }
        view.layoutIfNeeded()
    }
    
    func scrollToBottom() {
        let count = messages.count
        if count > 3 {
            let indexPath = IndexPath(row: count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}


extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.contentSize.height != textView.frame.size.height {
            let textViewHeight = textView.contentSize.height
            if textViewHeight < 100 {
                messageTextViewHeightConstraint.constant = textViewHeight
                textView.layoutIfNeeded()
            }
        }
    }
}
