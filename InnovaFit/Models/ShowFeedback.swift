import SwiftData

@Model
class ShowFeedback {
    var isShowFeedback: Bool
    init(isShowFeedback: Bool) {
        self.isShowFeedback = isShowFeedback
    }
}
