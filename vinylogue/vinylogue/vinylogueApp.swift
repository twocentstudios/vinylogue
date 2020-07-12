import SwiftUI

@main
struct vinylogueApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    UINavigationBar.appearance().titleTextAttributes =
                        [
                            NSAttributedString.Key.font : UIFont(name: "AvenirNext-Regular", size: 20)!,
                        ]
                }
        }
    }
}
