import SwiftUI

struct Homepage: View {

    @EnvironmentObject var session: SessionViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Homepage")
                .font(.title)

            Button {
                session.signOut()
            } label: {
                Text("Çıkış Yap")
                    .foregroundColor(.white)
                    .padding()
                    .background(.red)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}
