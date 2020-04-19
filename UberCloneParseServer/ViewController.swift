//
//  ViewController.swift
//  UberCloneParseServer
//
//  Created by Manjot S Sandhu on 17/4/20.
//  Copyright © 2020 Manjot S Sandhu. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController {

    func displayAlert(title: String, message: String){
        let alertCtrl = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertCtrl.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertCtrl, animated: true, completion: nil)
    }
    
    var signupMode = true
    
    @IBOutlet weak var usernameTextField: UITextField!

    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var isDriverSwitch: UISwitch!
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    
    @IBAction func signupOrLogin(_ sender: Any) {
        
        if usernameTextField.text == "" || passwordTextField.text == "" {
            displayAlert(title: "Error", message: "Username and password are required")
        }else{
        
            if signupMode {
                let user = PFUser()
                user.username = usernameTextField.text
                user.password = passwordTextField.text
                
                user["isDriver"] = isDriverSwitch.isOn
                
                user.signUpInBackground {
                    (success, error) in
                    if let error = error {
                        self.displayAlert(title: "Sign Up Failed", message: error.localizedDescription)
                    }else{
                        print("sign up successful")
                        
                        if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                            
                            if isDriver {
                                self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                                
                            }else{
                                self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                            }
                            
                        }
                        
                    }
                }
                
            } else{ // log in
                
                PFUser.logInWithUsername(inBackground: usernameTextField.text!, password: passwordTextField.text!) {
                    (user, error) in
                    if let error = error {
                        self.displayAlert(title: "Log In failed", message: error.localizedDescription)
                    }else{
                        print("Log In successful")
                        
                        if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                            
                            if isDriver {
                                self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                            }else{
                                self.performSegue(withIdentifier: "showRiderViewController", sender: nil)
                            }
                            
                        }
                        
                    }
                }
                
            }
            
        }
        
    }
    
    @IBOutlet weak var signupOrLogin: UIButton!
    
    @IBOutlet weak var signupSwitchButton: UIButton!
    
    @IBAction func switchSignUpMode(_ sender: Any) {
        
        if signupMode {
            signupOrLogin.setTitle("Log In", for: [])
            signupSwitchButton.setTitle("Switch to Sign Up", for: [])
            signupMode = false
            isDriverSwitch.isHidden = true
            riderLabel.isHidden = true
            driverLabel.isHidden = true
        }else{
            signupOrLogin.setTitle("Sign up", for: [])
            signupSwitchButton.setTitle("Switch to Log In", for: [])
            signupMode = true
            isDriverSwitch.isHidden = false
            riderLabel.isHidden = false
            driverLabel.isHidden = false
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    
    override func viewDidAppear(_ animated: Bool) {
            if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                
                if isDriver {
                    self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                }else{
                    self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                }
                
            }
    }

}

