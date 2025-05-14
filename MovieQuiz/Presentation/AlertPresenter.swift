//
//  AlertPresenter.swift
//  MovieQuiz
//
//  Created by Айлин Кызылай on 06.05.2025.
//

import Foundation
import UIKit


class AlertPresenter {
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func show(alertModel: AlertModel){
        let alert = UIAlertController(
            title: alertModel.title,
            message: alertModel.message,
            preferredStyle: .alert)
        
        let action = UIAlertAction (
            title: alertModel.buttonText,
            style: .default
        )
        { _ in alertModel.completion()
        }
          
        alert.addAction(action)
            viewController?.present(alert, animated: true, completion: nil)
    }
    
}
