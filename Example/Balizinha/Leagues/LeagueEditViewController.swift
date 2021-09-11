//
//  LeagueEditViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/9/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseCore
import Balizinha
import RenderCloud
import RenderPay

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

    @IBOutlet weak var photoView: RAImageView!
    @IBOutlet weak var constraintPhotoWidth: NSLayoutConstraint!
    @IBOutlet weak var buttonPhoto: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var containerOwner: UIView!
    @IBOutlet weak var labelOwnerName: UILabel!
    @IBOutlet weak var photoOwner: RAImageView!
    @IBOutlet weak var constraintOwnerHeight: NSLayoutConstraint!

    @IBOutlet weak var labelPlayerCount: UILabel!
    
    @IBOutlet weak var playersScrollView: PlayersScrollView!
    @IBOutlet weak var constraintPlayersHeight: NSLayoutConstraint!
    @IBOutlet weak var buttonOrganizers: UIButton!
    
    @IBOutlet weak var buttonShareLink: UIButton!

    var selectedPhoto: UIImage?

    var league: League?
    var delegate: LeagueViewDelegate?
    var roster: [String: Membership] = [:]
    fileprivate var players: [Player] = []
    
    let disposeBag: DisposeBag = DisposeBag()
    let apiService = Globals.apiService
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        refresh()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didClickSave(_:)))
        
        loadRoster()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        constraintPhotoWidth.constant = view.frame.size.width
    }
    
    func loadRoster() {
        guard !AIRPLANE_MODE else {
            roster = ["1": Membership(id: "1", status: "organizer")]
            observePlayers()
            return
        }
        roster.removeAll()
        
        guard let league = league else { return }
        LeagueService.shared.memberships(for: league) { [weak self] (results) in
            self?.roster.removeAll()
            for membership in results ?? [] {
                self?.roster[membership.playerId] = membership
            }
            self?.playersScrollView.delegate = self
            self?.observePlayers()
        }
    }
    
    fileprivate func refresh() {
        if let image = selectedPhoto {
            buttonPhoto.setTitle(nil, for: .normal)
            buttonPhoto.backgroundColor = .clear
            photoView.image = image
        } else if league?.photoUrl != nil { // league has a photo
            buttonPhoto.backgroundColor = .clear
            buttonPhoto.setTitle(nil, for: .normal)
            FirebaseImageService().leaguePhotoUrl(with: league?.id) {[weak self] (url) in
                print("URL \(String(describing: url?.absoluteString))")
                DispatchQueue.main.async {
                    if let url = url {
                        self?.photoView.imageUrl = url.absoluteString
                    } else {
                        self?.photoView.imageUrl = nil
                        self?.photoView.image = UIImage(named: "crest30")?.withRenderingMode(.alwaysTemplate)
                        self?.photoView.tintColor = UIColor.white
                    }
                }
            }
        } else {
            buttonPhoto.backgroundColor = UIColor(red: 88.0/255.0, green: 122.0/255.0, blue: 103.0/255.0, alpha: 1)
            photoView.image = nil
            photoView.imageUrl = nil
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
        
        // player count
        labelPlayerCount?.text = "\(league.playerCount)"
        
        if let owner = league.ownerId {
            PlayerService.shared.withId(id: owner) { [weak self] (player) in
                DispatchQueue.main.async {
                    let player = player as? Player
                    self?.labelOwnerName.text = player?.name ?? player?.email ?? player?.id
                }
            }
            FirebaseImageService().profileUrl(with: owner) { [weak self] (url) in
                DispatchQueue.main.async {
                    if let url = url {
                        self?.photoOwner.image = nil
                        self?.photoOwner.imageUrl = url.absoluteString
                    } else {
                        self?.photoOwner.imageUrl = nil
                        self?.photoOwner.image = UIImage(named: "profile-img")
                    }
                }
            }
            constraintOwnerHeight.constant = 40
        } else {
            constraintOwnerHeight.constant = 0
        }
        
        if let shareLink = league.shareLink {
            buttonShareLink.setTitle(shareLink, for: .normal)
        } else {
            buttonShareLink.setTitle("Generate a share link", for: .normal)
        }
    }
    
    func observePlayers() {
        guard !AIRPLANE_MODE else {
            let players = [MockService.mockPlayerOrganizer()]
            self.players = players
            playersScrollView.reset()
            for player in players {
                playersScrollView.addPlayer(player: player)
            }
            // player count
            labelPlayerCount?.text = "\(players.count)"
            playersScrollView.refresh()
            return
        }
        players.removeAll()
        let dispatchGroup = DispatchGroup()
        for (playerId, membership) in roster {
            guard membership.isActive else { continue }
            dispatchGroup.enter()
            print("Loading player id \(playerId)")
            PlayerService.shared.withId(id: playerId, completion: {[weak self] (player) in
                if let player = player as? Player {
                    print("Finished player id \(playerId)")
                    self?.players.append(player)
                }
                dispatchGroup.leave()
            })
        }
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.playersScrollView.reset()
            guard let players = self?.players else { return }
            for player in players {
                self?.playersScrollView.addPlayer(player: player)
            }
            
            // player count
            self?.labelPlayerCount?.text = "\(players.count)"
            self?.playersScrollView.refresh()
        }
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
                    guard let league = league as? League else {
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
        if segue.identifier == "toPlayers", let controller = segue.destination as? LeaguePlayersListViewController {
            controller.roster = roster
            controller.league = league
            controller.delegate = self
            
            if sender as? UIButton == buttonOrganizers {
                controller.isEditOrganizerMode = true
            }
        }
    }
    
    @IBAction func didClickShareLink(_ sender: Any?) {
        guard let id = league?.id else { return }
        if let shareLink = league?.shareLink, let url = URL(string: shareLink) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else {
            showLoadingIndicator()
            let name = league?.name ?? "Panna Social Leagues"
            let info = league?.info ?? "Join a league on Panna and play pickup."
            apiService.cloudFunction(functionName: "generateShareLink", method: "POST", params: ["type": "leagues", "id": id, "socialTitle": name, "socialDescription": info]) { [weak self] (result, error) in
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    print("Result \(String(describing: result)) error \(String(describing: error))")
                    if let result = result as? [String: Any], let link = result["shareLink"] as? String {
                        self?.league?.dict["shareLink"] = link // temporary
                        self?.refresh()
                    } else {
                        self?.simpleAlert("Generate link failed", defaultMessage: "Could not generate share link", error: error as NSError?)
                    }
                }
            }
        }
    }
}

// MARK: Camera
extension LeagueEditViewController {
    override var prefersStatusBarHidden: Bool {
        return false
    }

    func selectPhoto(camera: Bool) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        picker.view.backgroundColor = .blue
        
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
        FirebaseImageService.uploadImage(image: photo, type: FirebaseImageService.ImageType.league, uid: id, completion: { [weak self] (url) in
            self?.activityIndicator.stopAnimating()
            completion(url)
        })
    }
}

extension LeagueEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        let img = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] ?? info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)]
        guard let photo = img as? UIImage else { return }
        didTakePhoto(image: photo)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismissCamera()
    }
}

extension LeagueEditViewController: PlayersScrollViewDelegate {
    func didSelectPlayer(player: Player) {
        performSegue(withIdentifier: "toPlayers", sender: nil)
    }
}

extension LeagueEditViewController: LeagueListDelegate {
    func didUpdateRoster() {
        loadRoster()
    }
}

extension LeagueEditViewController: UITextFieldDelegate {
    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        keyboardHeight = keyboardRectangle.height
        
        let lastPosition = playersScrollView.frame.origin.y + playersScrollView.frame.size.height
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: lastPosition + keyboardHeight)
        if let currentInput = currentInput {
            var frame = currentInput.frame
            frame.origin.y += keyboardHeight
            scrollView.scrollRectToVisible(frame, animated: true)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        let lastPosition = playersScrollView.frame.origin.y + playersScrollView.frame.size.height
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
