import SwiftUI

@main
struct vinylogueApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .accentColor(.blueDark)
                .onAppear {
                    UINavigationBar.appearance().titleTextAttributes =
                        [
                            NSAttributedString.Key.font : UIFont(name: "AvenirNext-Regular", size: 20)!,
                            NSAttributedString.Key.foregroundColor : UIColor(.blueDark)
                        ]
                    UINavigationBar.appearance().barTintColor = UIColor(.whiteSubtle)
                }
        }
    }
}
