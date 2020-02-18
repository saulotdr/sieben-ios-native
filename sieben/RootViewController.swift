//
//  RootViewController.swift
//  sieben
//
//  Created by Saulo Teodoro on 22/11/2019.
//  Copyright © 2019 docsystem.sieben.com. All rights reserved.
//

import UIKit
import WebKit

class RootViewController: UIViewController, UIPageViewControllerDelegate,
UISearchBarDelegate, WKNavigationDelegate {
    
    let USER_KEY = "user"	
    let PASSWORD_KEY = "password"
    let MAIN_PAGE = "Login"
    let TASKS_PAGE = "Tasks"
    
    var navigatedPage = ""
    var searchCount = -1
    var currentPosition = -1


    @IBOutlet weak var search: UISearchBar!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var findButton: UIBarButtonItem!
    @IBOutlet var refreshButton: UIBarButtonItem!
    
    @IBAction func save(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Salvar login",
                                              message: "Você deseja salvar suas credenciais?",
                                              preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: {(action) -> Void in
            print("save(): saving credentials")
            self.getCredentials()
        })
        
        let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
            print("save(): cancelling")
        }
        
        dialogMessage.addAction(ok)
        dialogMessage.addAction(cancel)
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    @IBAction func refresh(_ sender: Any) {
        webView.reload()
    }
    @IBAction func find(_ sender: Any) {
        search.isHidden = !search.isHidden
    }
    @IBAction func back(_ sender: Any) {
        if webView.canGoBack{
            webView.goBack()
        }
    }
    
    func injectCredentials(credentials: Credentials?) {
        print("injectCredentials(): user=" + credentials!.user)
        print("injectCredentials(): password=" + credentials!.password)
        if credentials!.user.count > 0 && credentials!.password.count > 0 {
            print("injectCredentials(): valid credentials found")
            if credentials!.user.contains("\\") {
                credentials!.user = credentials!.user.replacingOccurrences(of: "\\", with: "\\\\")
            }
            if credentials!.password.contains("\\") {
                credentials!.password = credentials!.password.replacingOccurrences(of: "\\", with: "\\\\")
            }
            let scriptSetUser = "document.getElementById('user').value='" + credentials!.user + "'"
            let scriptSetPassword = "document.getElementById('password').value='" + credentials!.password + "'"
            webView.evaluateJavaScript(scriptSetUser, completionHandler: nil)
            webView.evaluateJavaScript(scriptSetPassword, completionHandler: nil)
            print("injectCredentials(): credentials injected")
        }
    }
    
    func getCredentials() {
        let script = "document.getElementById('user').value + '#' + document.getElementById('password').value"
        webView.evaluateJavaScript(script) { (innerHtml, error) in
            let html = innerHtml as? String
            self.onGetCredentialsCompletionHandler(html: html!)
        }
    }
    
    func onGetCredentialsCompletionHandler(html: String) {
        let user = html.components(separatedBy: "#")[0]
        let password = html.components(separatedBy: "#")[1]
        print("onCompletionHandler(): user=" + user)
        print("onCompletionHandler: password=" + password)
        if user.count == 0 || password.count == 0 {
            print("onCompletionHandler: empty user or password")
            return;
        }
        let credentials = Credentials()
        credentials.user = user
        credentials.password = password
        saveToUserDefaults(credentials: credentials)
    }
    
    func onGetSearchResultCountCompletionHandler(searchCount: Int) {
        self.searchCount = searchCount
        self.currentPosition = self.searchCount + 1
    }

    func getFromUserDefaults() -> Credentials? {
        let preferences = UserDefaults.standard
        let credentials = Credentials()
        if let userKey = preferences.string(forKey: USER_KEY) {
            credentials.user = userKey
        }
        if let passwordKey = preferences.string(forKey: PASSWORD_KEY) {
            credentials.password = passwordKey
        }
        print("getFromUserDefaults() user=" + credentials.user)
        print("getFromUserDefaults() password=" + credentials.password)
        return credentials
    }
    
    func saveToUserDefaults(credentials : Credentials) {
        let preferences = UserDefaults.standard
        print("saveToUserDefaults(): user=" + credentials.user)
        print("saveToUserDefaults(): password=" + credentials.password)
        preferences.set(credentials.user, forKey: USER_KEY)
        preferences.set(credentials.password, forKey: PASSWORD_KEY)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchBarSearchButtonClicked(): clicked")
        searchBar.resignFirstResponder()
        let highlightAllOccurrences = "uiWebview_HighlightAllOccurencesOfString('" + searchBar.text! + "')"
        webView.evaluateJavaScript(highlightAllOccurrences, completionHandler: nil)
        let searchResultCount = "uiWebview_SearchResultCount"
        webView.evaluateJavaScript(searchResultCount) { (innerHtml, error) in
            let html = innerHtml as? Int
            self.onGetSearchResultCountCompletionHandler(searchCount: html!)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("searchBarCancelButtonClicked(): clicked")
        searchBar.resignFirstResponder()
        self.searchCount = -1; self.currentPosition = -1
        let removeAllHighlights = "uiWebview_RemoveAllHighlights()"
        webView.evaluateJavaScript(removeAllHighlights, completionHandler: nil)
    }
    
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        print("searchBarResultsListButtonClicked(): clicked")
        searchBar.resignFirstResponder()
        self.currentPosition -= 1
        if self.currentPosition <= 0 {
            //Maximum search results reached.
            self.currentPosition = self.searchCount + 1
        }
        print(String(format: "searchBarResultsListButtonClicked(): searchCount: %d, currentPosition : %d", self.searchCount, self.currentPosition))
        let jumpToNextScript = String(format: "a[%d].scrollIntoView()", self.currentPosition)
        webView.evaluateJavaScript(jumpToNextScript, completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.request.url!.absoluteString.contains(MAIN_PAGE) {
            print("webView(): Main page is loading")
            navigatedPage = MAIN_PAGE
            
        }
        if navigationAction.request.url!.absoluteString.contains(TASKS_PAGE) {
            print("webView(): Tasks page is loading")
            navigatedPage = TASKS_PAGE
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if (navigatedPage == MAIN_PAGE) {
            print("webView(): Main page finishes loading")
            injectCredentials(credentials: getFromUserDefaults())
            findButton.isEnabled = false
            saveButton.isEnabled = true
            search.isHidden = true
        }
        
        if (navigatedPage == TASKS_PAGE) {
            print("webView(): Tasks page finishes loading")
            initializeFindScript()
            findButton.isEnabled = true
            saveButton.isEnabled = false
            search.isHidden = true
        }
    }
    
    func initializeFindScript() {
        let path = Bundle.main.path(forResource: "UIWebViewSearch", ofType: "js")
        let script = try! String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        search.delegate = self
        webView.navigationDelegate = self
        
        let url = URL(string: "http://docsystem5.clouddoc.com.br/SimplePortalHomolog")
        let urlRequest = URLRequest(url: url!)
        
        webView.load(urlRequest)
        print("viewDidLoad(): web page loaded")
    }
}
