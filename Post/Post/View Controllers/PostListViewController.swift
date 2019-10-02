//
//  PostListViewController.swift
//  Post
//
//  Created by Jordan Lamb on 9/30/19.
//  Copyright © 2019 Squanto Inc. All rights reserved.
//

import UIKit

class PostListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let postController = PostController()
    var refreshControl = UIRefreshControl()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 45
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshControlPulled), for: .valueChanged)
        postController.fetchPosts {
            self.reloadTableView()
        }
    }
    
    // MARK: - Actions
    @IBAction func addButtonTapped(_ sender: Any) {
        setUpAlertController()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postController.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath)
        let post = postController.posts[indexPath.row]
        cell.textLabel?.text = post.username
        cell.detailTextLabel?.text = post.text
        return cell
    }
    
    @objc func refreshControlPulled() {
        postController.fetchPosts {
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self.refreshControl.endRefreshing()
            }
            self.reloadTableView()
        }
    }
    
    func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    // MARK: - Alert Controller
    func setUpAlertController() {
        var usernameTextField: UITextField?
        var textBodyTextField: UITextField?
        let alert = UIAlertController(title: "Add New Post", message: "", preferredStyle: .alert)
        alert.addTextField { (unTextField) in
            unTextField.placeholder = "Username"
            usernameTextField = unTextField
        }
        alert.addTextField { (tbTextField) in
            tbTextField.placeholder = "New Post Text"
            textBodyTextField = tbTextField
        }
        
        let addPostAction = UIAlertAction(title: "Post", style: .default) { (_) in
            guard let newPostBody = textBodyTextField?.text,
                let newPostUsername = usernameTextField?.text
                else { return }
            if newPostBody.isEmpty || newPostUsername.isEmpty {
                presentErrorAlert()
            } else {
                print("Adding Post")
                self.postController.addNewPostWith(username: newPostUsername, text: newPostBody, completion: {
                    self.reloadTableView()
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        }
        
        alert.addAction(addPostAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        
        func presentErrorAlert() {
            let alertError = UIAlertController(title: "Error Adding Post", message: "Username & Body cannot be empty!", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "O.K.", style: .default, handler: { (_) in
                self.present(alert, animated: true, completion: nil)
            })
            alertError.addAction(okayAction)
            present(alertError, animated: true, completion: nil)
        }
    }
    
} // End of Class


extension PostListViewController {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= postController.posts.count - 1 {
            postController.fetchPosts(reset: false) {
                self.reloadTableView()
            }
        }
    }
}
