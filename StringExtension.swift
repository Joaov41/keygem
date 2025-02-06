import Foundation

extension String {
    func replacingCharacters(in nsRange: NSRange, with replacement: String) -> String {
        guard let range = Range(nsRange, in: self) else {
            return self // Invalid range, return original string
        }
        return self.replacingCharacters(in: range, with: replacement)
    }
}
