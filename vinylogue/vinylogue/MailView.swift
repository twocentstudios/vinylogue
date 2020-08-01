import MessageUI
import SwiftUI
import UIKit

struct MailView: UIViewControllerRepresentable {
    struct Input: Equatable {
        let toRecipients: [String]
        let subject: String
        let messageBody: String
    }

    let input: Input
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Environment(\.presentationMode) var presentation

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(presentation: Binding<PresentationMode>,
             result: Binding<Result<MFMailComposeResult, Error>?>) {
            _presentation = presentation
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer { $presentation.wrappedValue.dismiss() }
            if let error = error {
                self.result = .failure(error)
            } else {
                self.result = .success(result)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation,
                           result: $result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.setToRecipients(input.toRecipients)
        viewController.setSubject(input.subject)
        viewController.setMessageBody(input.messageBody, isHTML: false)
        viewController.mailComposeDelegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {}
}
