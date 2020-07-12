import ComposableArchitecture
import SwiftUI

@main
struct vinylogueApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(
                store: Store(
                    initialState: AppState(userState: UserState.uninitialized),
                    reducer: appReducer,
                    environment: mockUserEnvironment
                ))
                .onAppear {
                    UINavigationBar.appearance().titleTextAttributes =
                        [
                            NSAttributedString.Key.font: UIFont(name: "AvenirNext-Regular", size: 20)!,
                        ]
                }
        }
    }
}

