//
//  URL.swift
//  SearchGithubUser
//
//  Created by Byunsangjin on 17/02/2019.
//  Copyright © 2019 Byunsangjin. All rights reserved.
//

import Foundation

struct UserModel: Codable {
    let publicRepos: Int
    
    private enum CodingKeys: String, CodingKey {
        case publicRepos = "public_repos"
    }
}
