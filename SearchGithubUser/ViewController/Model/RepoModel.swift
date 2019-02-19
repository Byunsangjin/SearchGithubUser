//
//  Repo.swift
//  SearchGithubUser
//
//  Created by Byunsangjin on 16/02/2019.
//  Copyright © 2019 Byunsangjin. All rights reserved.
//

import Foundation

struct RepoModel {
    let avatarURL: String
    let name: String
    let url: String

    init?(object: [String: Any]) {
        guard let avatarURL = object["avatar_url"] as? String,
            let name = object["login"] as? String,
            let url = object["url"] as? String else {
                return nil
        }
        self.avatarURL = avatarURL
        self.name = name
        self.url = url
    }

    init(_ avatarURL: String, _ name: String, _ url: String) {
        self.avatarURL = avatarURL
        self.name = name
        self.url = url
    }
}
