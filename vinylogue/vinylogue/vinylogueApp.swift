import ComposableArchitecture
import SwiftUI

@main
struct vinylogueApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(
                store: Store(
                    initialState: AppState(userState: UserState.uninitialized, viewState: .startup),
                    reducer: appReducer.debug(),
                    environment: .mockUser
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

