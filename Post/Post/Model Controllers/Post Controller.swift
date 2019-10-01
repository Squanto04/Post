//
//  Post Controller.swift
//  Post
//
//  Created by Jordan Lamb on 9/30/19.
//  Copyright © 2019 Squanto Inc. All rights reserved.
//

import Foundation

class PostController {
    
    //Base URL
    let baseURL = URL(string: "https://devmtn-posts.firebaseio.com/posts")
    
    // Source Of Truth
    var posts: [Post] = []
    
    func fetchPosts(reset: Bool = true, completion: @escaping () -> Void) {
        let queryEndInterval = reset ? Date().timeIntervalSince1970 : posts.last?.timestamp ?? Date().timeIntervalSince1970
        guard let unwrappedURL = self.baseURL else { return }
        let urlParameters = [
            "orderBy": "\"timestamp\"",
            "endAt": "\(queryEndInterval)",
            "limitToLast": "15",
            ]
        let queryItems = urlParameters.compactMap( { URLQueryItem(name: $0.key, value: $0.value) } )
        var urlComponents = URLComponents(url: unwrappedURL, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = queryItems
        guard let finalURL = urlComponents?.url else { return }
        let getterEndpoint = finalURL.appendingPathExtension("json")
        var request = URLRequest(url: getterEndpoint)
        request.httpBody = nil
        request.httpMethod = "GET"
        let dataTask = URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                print("There was an error with the request: \(error.localizedDescription)")
                completion()
                return
            }
            guard let data = data else { return }
            let jsonDecoder = JSONDecoder()
            do {
                let postsDictionary = try jsonDecoder.decode([String:Post].self, from: data)
                var sortedposts = postsDictionary.compactMap({$0.value})
                sortedposts.sort(by: { $0.timestamp > $1.timestamp })
                if reset == true {
                    self.posts = sortedposts
                } else {
                    self.posts.append(contentsOf: sortedposts)
                }
                completion()
            } catch {
                print("There was an error retreiving the data: \(error.localizedDescription)")
                completion()
                return
            }
        }
        dataTask.resume()
    }
    
    func addNewPostWith(username: String, text: String, completion: @escaping () -> Void) {
        let post = Post(username: username, text: text)
        var postData: Data?
        do {
            let jsonEncoder = JSONEncoder()
            postData = try jsonEncoder.encode(post)
        } catch {
            print("Error endocing data: \(error.localizedDescription)")
        }
        guard let unwrappedURL = self.baseURL else { return }
        let postEndpoint = unwrappedURL.appendingPathExtension("json")
        var request = URLRequest(url: postEndpoint)
        request.httpBody = postData
        request.httpMethod = "POST"
        let dataTask = URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                print("There was an error encoding \(error.localizedDescription)")
            }
            guard let data = data else { return }
            let dataString = String(data: data, encoding: .utf8)
            print(dataString!)
            self.fetchPosts{
                completion()
            }
        }
        dataTask.resume()
    }
    
} // End of Class
