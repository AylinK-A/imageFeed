//
//  AlertModel.swift
//  MovieQuiz
//
//  Created by Айлин Кызылай on 06.05.2025.
//

import Foundation

struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: () -> Void
}
