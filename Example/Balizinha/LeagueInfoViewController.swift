//
//  LeagueEditViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/9/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import AsyncImageView
import RxSwift
import FirebaseCommunity
import Balizinha

protocol LeagueViewDelegate {
    func didUpdate()
}

class LeagueEditViewController: UIViewController {
    
    @IBOutlet weak var inputName: UITextField!
    @IBOutlet weak var inputCity: UITextField!
    @IBOutlet weak var inputDescription: UITextField!
    @IBOutlet weak var inputTags: UITextField!
    @IBOutlet weak var togglePrivate: UISwitch!

    weak var currentInput: UITextField?
    var keyboardHeight: CGFloat = 0
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!

    @IBOutlet weak var photoView: AsyncImageView!
    @IBOutlet weak var constraintPhotoWidth: NSLayoutConstraint!
    @IBOutlet weak var buttonPhoto: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var containerOwner: UIView!
    @IBOutlet weak var labelOwnerName: UILabel!
    @IBOutlet weak var photoOwner: AsyncImageView!
    @IBOutlet weak var constraintOwnerHeight: NSLayoutConstraint!
    
    @IBOutlet weak var labelPlayerCount: UILabel!
    
    @IBOutlet weak var containerPlayers: UIView!
    weak var playersController: PlayersScrollViewController?
    @IBOutlet weak var constraintPlayersHeight: NSLayoutConstraint!
    @IBOutlet weak var buttonOrganizers: UIButton!

    var selectedPhoto: UIImage?

    var league: League? {
        didSet {
            observeUsers()
        }
    }
    var delegate: LeagueViewDelegate?
    var roster: [Membership] = []
    
    let disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        refresh()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        containerPlayers.addGestureRecognizer(gesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didClickSave(_:)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        constraintPhotoWidth.constant = view.frame.size.width
    }
    
    func observeUsers() {
        guard let league = self.league else { return }
        LeagueService.shared.observeUsers(for: league) { [weak self] (results, error) in
            guard let newRoster = results else { return }
            self?.roster.removeAll()
            for member in newRoster {
                guard member.isActive else { continue }
                self?.roster.append(member)
                PlayerService.shared.withId(id: member.playerId, completion: {[weak self] (player) in
                    if let player = player {
                        DispatchQueue.main.async {
                            self?.playersController?.addPlayer(player: player)
                        }
                    }
                })
            }
        }
    }
    fileprivate func refresh() {
        if let image = selectedPhoto {
            buttonPhoto.setTitle(nil, for: .normal)
            buttonPhoto.backgroundColor = .clear
            photoView.image = image
        } else if let url = league?.photoUrl, let URL = URL(string: url) {
            buttonPhoto.backgroundColor = .clear
            buttonPhoto.setTitle(nil, for: .normal)
            photoView.imageURL = URL
        } else {
            buttonPhoto.backgroundColor = UIColor(red: 88.0/255.0, green: 122.0/255.0, blue: 103.0/255.0, alpha: 1)
            photoView.image = nil
            photoView.imageURL = nil
            buttonPhoto.setTitle("Add photo", for: .normal)
        }

        guard let league = league else {
            constraintOwnerHeight.constant = 0
            constraintPlayersHeight.constant = 0
            togglePrivate.isOn = false
            return
        }
        
        inputName.text = league.name
        inputCity.text = league.city
        inputDescription.text = league.info
        inputTags.text = league.tagString
        togglePrivate.isOn = league.isPrivate
        
        league.playerCount.asObservable().subscribe(onNext: { [weak self] (count) in
            self?.labelPlayerCount.text = "\(count)"
        }).disposed(by: disposeBag)
        league.countPlayers()
        
        if let owner = league.owner {
            PlayerService.shared.withId(id: owner) { [weak self] (player) in
                DispatchQueue.main.async {
                    self?.labelOwnerName.text = player?.name ?? player?.email ?? player?.id
                    if let url = player?.photoUrl, let URL = URL(string: url) {
                        self?.photoOwner.image = nil
                        self?.photoOwner.imageURL = URL
                    } else {
                        self?.photoOwner.imageURL = nil
                        self?.photoOwner.image = UIImage(named: "profile-img")
                    }
                }
            }
            constraintOwnerHeight.constant = 40
        } else {
            constraintOwnerHeight.constant = 0
        }
    }

    @objc func didTap(_ gesture: UITapGestureRecognizer?) {
        performSegue(withIdentifier: "toPlayers", sender: nil)
    }
    
    @IBAction func didClickOrganizers(_ sender: Any?) {
        performSegue(withIdentifier: "toPlayers", sender: sender)
    }
    
    @IBAction func didClickSave(_ sender: Any?) {
        if let league = league {
            league.name = inputName.text
            league.city = inputCity.text
            league.info = inputDescription.text ?? ""
            
            if let text = inputTags.text {
                let tags = League.tags(from: text)
                league.tags = tags
            }
            league.isPrivate = togglePrivate.isOn

            if let photo = selectedPhoto {
                showLoadingIndicator()
                uploadPhoto(photo, id: league.id) {[weak self] url in
                    league.photoUrl = url
                    self?.delegate?.didUpdate()
                    self?.hideLoadingIndicator()
                }
            } else {
                delegate?.didUpdate()
            }
        } else {
            // create a league
            guard let name = inputName.text else {
                print("Invalid name")
                return
            }
            guard let city = inputCity.text else {
                print("Invalid city")
                return
            }
            guard let info = inputDescription.text else {
                print("Invalid description")
                return
            }
            
            showLoadingIndicator()
            LeagueService.shared.create(name: name, city: city, info: info, completion: { [weak self] (result, error) in
                // print something
                guard let result = result as? [String: Any], let leagueId = result["league"] as? String else {
                    // error?
                    var message = "There was an error creating a league."
                    if let error = error {
                        message = message + " Error: \(error)"
                    }
                    let alert = UIAlertController(title: "League creation error", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
                    })
                    DispatchQueue.main.async {
                        self?.hideLoadingIndicator()
                        self?.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                LeagueService.shared.withId(id: leagueId, completion: { [weak self] (league) in
                    guard let league = league else {
                        DispatchQueue.main.async {
                            self?.hideLoadingIndicator()
                        }
                        return
                    }
                    
                    // update tags
                    if let text = self?.inputTags.text {
                        let tags = League.tags(from: text)
                        league.tags = tags
                    }
                    
                    // update privacy
                    if let weakself = self {
                        league.isPrivate = weakself.togglePrivate.isOn
                    }
                    
                    if let photo = self?.selectedPhoto {
                        self?.uploadPhoto(photo, id: league.id) { url in
                            league.photoUrl = url
                            DispatchQueue.main.async {
                                self?.delegate?.didUpdate()
                                self?.hideLoadingIndicator()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.delegate?.didUpdate()
                            self?.hideLoadingIndicator()
                        }
                    }
                })
            })
        }
    }
    
    @IBAction func didClickPhoto(_ sender: Any?) {
        // TODO
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
                self.selectPhoto(camera: true)
            }))
        }
        alert.addAction(UIAlertAction(title: "Photo album", style: .default, handler: { (action) in
            self.selectPhoto(camera: false)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        })
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedPlayers", let controller = segue.destination as? PlayersScrollViewController {
            playersController = controller
            playersController?.delegate = self
        } else if segue.identifier == "toPlayers", let controller = segue.destination as? LeaguePlayersViewController {
            controller.roster = roster
            controller.league = league
            controller.delegate = self
            
            if sender as? UIButton == buttonOrganizers {
                controller.isEditOrganizerMode = true
            }
        }
    }
}

// MARK: Camera
extension LeagueEditViewController {
    func selectPhoto(camera: Bool) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        picker.view.backgroundColor = .blue
        UIApplication.shared.isStatusBarHidden = false
        
        if camera, UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.showsCameraControls = true
        } else {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                picker.sourceType = .photoLibrary
            }
            else {
                picker.sourceType = .savedPhotosAlbum
            }
            picker.navigationBar.isTranslucent = false
        }
        
        present(picker, animated: true)
    }
    
    func didTakePhoto(image: UIImage) {
        selectedPhoto = image
        dismissCamera {
            // nothing
            self.refresh()
        }
    }
    
    func dismissCamera(completion: (()->Void)? = nil) {
        dismiss(animated: true, completion: completion)
    }
    
    fileprivate func uploadPhoto(_ photo: UIImage, id: String, completion: @escaping ((_ url: String?)->Void)) {
        activityIndicator.startAnimating()
        DispatchQueue.global().async {
            FirebaseImageService.uploadImage(image: photo, type: "league", uid: id, completion: { [weak self] (url) in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                }
                completion(url)
            })
        }
    }
}

extension LeagueEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let img = info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]
        guard let photo = img as? UIImage else { return }
        didTakePhoto(image: photo)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismissCamera()
    }
}

extension LeagueEditViewController: PlayersScrollViewDelegate {
    func componentHeightChanged(controller: UIViewController, newHeight: CGFloat) {
        constraintPlayersHeight.constant = newHeight
    }
}

extension LeagueEditViewController: LeaguePlayersDelegate {
    func didUpdateRoster() {
        observeUsers()
    }
}

extension LeagueEditViewController: UITextFieldDelegate {
    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        keyboardHeight = keyboardRectangle.height
        
        let lastPosition = containerPlayers.frame.origin.y + containerPlayers.frame.size.height
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: lastPosition + keyboardHeight)
        if let currentInput = currentInput {
            var frame = currentInput.frame
            frame.origin.y += keyboardHeight
            scrollView.scrollRectToVisible(frame, animated: true)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        let lastPosition = containerPlayers.frame.origin.y + containerPlayers.frame.size.height
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: lastPosition)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentInput = textField
        
//        adjustOffset()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch currentInput {
        case inputName:
            inputCity.becomeFirstResponder()
        case inputCity:
            inputDescription.becomeFirstResponder()
        case inputDescription:
            inputTags.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
