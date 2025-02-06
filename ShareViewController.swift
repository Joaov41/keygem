import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {
    override func isContentValid() -> Bool {
        return !contentText.isEmpty
    }

    override func didSelectPost() {
        guard let sharedText = self.contentText else {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        // Minimal example: just log the shared text
        print("Shared text: \(sharedText)")

        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}
