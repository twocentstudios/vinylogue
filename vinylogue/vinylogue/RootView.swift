import SwiftUI

struct RootView: View {
    var body: some View {
        LoginView(userName: .constant(""))
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
