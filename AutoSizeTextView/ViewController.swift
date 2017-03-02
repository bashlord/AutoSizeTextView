//
//  ViewController.swift
//  AutoSizeTextView
//
//  Created by John Jin Woong Kim on 3/2/17.
//  Copyright © 2017 John Jin Woong Kim. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {
    // Array of textViews, just to keep a reference of them
    var textViews = [UITextView]()
    // UITextView var used as a pointer when involved in non UITextViewDelegate functions
    var selectedTextView: UITextView?
    // Simple array of CGFloats that represent font sizes of textViews by index
    var fonts = [CGFloat]()
    // The text views used
    let smallTextView = UITextView()
    let mediumTextView = UITextView()
    let largeTextView = UITextView()
    // Limits on font size, adjust for preference, but maintain the relationship->  1.0 < fontMin < fontMax
    var fontMax:CGFloat = 100.0
    var fontMin:CGFloat = 5.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Gesture recognizer that dismisses keyboard when the view is tapped
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        textViews.append(smallTextView)
        textViews.append(mediumTextView)
        textViews.append(largeTextView)
        // Populate fonts with a default size, in this case size 40, set the textView delegates to 
        //  the current viewController so they delegate to the implemented UITextView functions below
        for i in 0...2{
            fonts.append(40.0)
            textViews[i].delegate = self
            textViews[i].translatesAutoresizingMaskIntoConstraints = false
            textViews[i].backgroundColor = UIColor(white: 0, alpha: 0.1)
            view.addSubview(textViews[i])
        }
        
        view.addConstraintsWithFormat("V:|-75-[v0(100)]-16-[v1(200)]-16-[v2(300)]-16-|", views: smallTextView, mediumTextView,largeTextView)
        view.addConstraintsWithFormat("H:|-100-[v0(220)]", views: smallTextView)
        view.addConstraintsWithFormat("H:|-50-[v0(320)]", views: mediumTextView)
        view.addConstraintsWithFormat("H:|-25-[v0(360)]", views: largeTextView)
        
        subscribeToKeyboardNotification()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubsribeToKeyboardNotification()
    }
}

extension ViewController{
    // Extension of ViewController containing all the implemented UITextView functions

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        // Set a pointer to the textView being used
        selectedTextView = textView
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Determine the index of the currentTextView and its fontSize
        var index = -1
        for i in 0..<textViews.count{
            if textViews[i] == textView{
                index = i
                break
            }
        }
        
        // Because textViews auto resize their contentSize depending on how large the content is (basically if
        //  there are a lot of characters, the textView will become a scroll view to make space).  In order to
        //  maintain/contain the content size to the frame size of the textView, iterativly increment/decrement
        //  the font size of the textView's text until the content size's height <= frame's height
        while textView.contentSize.height < textView.frame.size.height && fonts[index] < fontMax{
            textView.attributedText = resizeFont(str: textView.text,fontSize: CGFloat(fonts[index]))
            textView.textAlignment = .center
            textView.autocapitalizationType = UITextAutocapitalizationType.allCharacters
            fonts[index] += 1
        }
        while textView.contentSize.height > textView.frame.size.height && fonts[index] > fontMin{
            textView.attributedText = resizeFont(str: textView.text,fontSize: CGFloat(fonts[index]))
            textView.textAlignment = .center
            textView.autocapitalizationType = UITextAutocapitalizationType.allCharacters
            fonts[index] -= 1
        }
        // Once a respectable font size has been found, set the textView's attributed text with the new
        //  font size and set the typing attribute for the textView to the newly found font size as well!
        textView.attributedText = resizeFont(str: textView.text,fontSize: fonts[index])
        textView.typingAttributes = resizeTyping(fontSize: fonts[index])
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            // If the return key is pressed on the keyboard, dismiss the keyboard rather than a newline char.
            //  If you want the return key to add a newline char, then remove this if case
            textView.resignFirstResponder()
            return true
        }else{
            var index = -1
            for i in 0..<textViews.count{
                if textViews[i] == textView{
                    index = i
                    break
                }
            }
            if fonts[index] <= 1{
                return false
            }else{
                return true
            }
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        // Dereference the pointer now that the textView is done
        selectedTextView = nil
        textView.resignFirstResponder()
    }
    
    func resizeFont(str:String, fontSize: CGFloat) -> NSAttributedString{
        // Returns a NSAttributedString, which is a string with a bunch of attributes that describes something.
        //  In this case, it is describing a font's stroke color, foreground color, font type/size, and stroke width
        let memeTextAttributes = [
            NSStrokeColorAttributeName: UIColor.black,
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "HelveticaNeue-CondensedBlack", size: fontSize)!,
            NSStrokeWidthAttributeName : -4.0
            ] as [String : Any]
        // This takes the attributes and combines it with a string that the attributes will be applied to
        let newAttr = NSAttributedString(string: str, attributes: memeTextAttributes)
        return newAttr
    }
    
    func resizeTyping(fontSize: CGFloat) -> [String:Any]{
        // Returns font attributes as a (key,value) array
        let memeTextAttributes = [
            NSStrokeColorAttributeName: UIColor.black,
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "HelveticaNeue-CondensedBlack", size: fontSize)!,
            NSStrokeWidthAttributeName : -4.0
            ] as [String : Any]
        return memeTextAttributes
    }
    
    /* Suscribe the view controller to the UIKeyboardWillShowNotification */
    func subscribeToKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /* Unsubscribe the view controller to the UIKeyboardWillShowNotification */
    func unsubsribeToKeyboardNotification(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(_ notification: Notification) {
        let keyboardHeight = getKeyboardHeight(notification)
        let keyWindow = UIApplication.shared.keyWindow
        /* (only if you have multiple textViews on your view, otherwise this is not an issue)
            Disable all other textViews from user interaction, because interacting (touching, tapping, etc) another
             textView calls the NotificationCenter Listener to check for keyboard functions.  Essentially, this is
             a semaphore that blocks all other textViews from keyboard functions because it is now in use by selectedTextView.
         */
        for textView in textViews{
            if textView != selectedTextView{
                textView.isUserInteractionEnabled = false
            }
        }

        //if the current textView's bottom (its y origin + its height) is less
        //  than the y origin of the keyboard (height of the screen - height
        //  of the keyboard), then the view needs to be shifted up
        //    The shift needs to be the top of the current textView aligning with
        //    the top of the keyWindow ( textView's y origin )
        if ((selectedTextView?.frame.origin.y)!+(selectedTextView?.frame.size.height)!) > (keyWindow?.frame.size.height)!-keyboardHeight{
            view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    /* Reset view origin when keyboard hides */
    func keyboardWillHide(_ notification: Notification) {
        for textView in textViews{
            if textView != selectedTextView{
                textView.isUserInteractionEnabled = true
            }
        }
        if view.frame.origin.y < 0{
            view.frame.origin.y = 0
        }
    }
    
    /* Get the height of the keyboard from the user info dictionary */
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}

extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
}
