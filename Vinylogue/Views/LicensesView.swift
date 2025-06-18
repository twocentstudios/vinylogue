import SwiftUI

struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(acknowledgements())
                    .font(.f(.regular, .body))
                    .foregroundColor(.primaryText)
                    .padding()
            }
            .background(Color.primaryBackground)
            .navigationTitle("Licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Licenses")
                        .foregroundStyle(Color.vinylogueBlueDark)
                        .font(.f(.regular, .headline))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                }
            }
        }
    }
}

// $ brew install licenseplist
// $ cd ~/Code/vinylogue
// $ license-plist --markdown-path acknowledgements.md --single-page --force --output-path /tmp --suppress-opening-directory
private func acknowledgements() -> String {
    bundleMarkdown("acknowledgements")
}

private func bundleMarkdown(_ fileName: String) -> String {
    guard let path = Bundle.main.path(forResource: fileName, ofType: "md"),
          let string = try? String(contentsOfFile: path, encoding: .utf8)
    else {
        assertionFailure("\(fileName).md file is missing")
        return "Unable to load licenses information."
    }
    return string
}

#Preview {
    LicensesView()
}
