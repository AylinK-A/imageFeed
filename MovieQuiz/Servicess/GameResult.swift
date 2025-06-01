import Foundation

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date
    
    func bestRecord(_ oneOf: GameResult) -> Bool{
        correct > oneOf.correct
    }
}
