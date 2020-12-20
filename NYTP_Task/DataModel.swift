//
//  DataModel.swift
//  NYTP_Task
//
//  Created by Barath K on 19/12/20.
//

import UIKit

struct Photo: Codable {
    let format: String
    let width, height: Int
    let filename: String
    let id: Int
    let author: String
    let authorURL, postURL: String

    enum CodingKeys: String, CodingKey {
        case format, width, height, filename, id, author
        case authorURL = "author_url"
        case postURL = "post_url"
    }
}

