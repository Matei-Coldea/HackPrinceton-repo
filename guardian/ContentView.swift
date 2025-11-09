import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack{
            Color.theme.primary.edgesIgnoringSafeArea(.all)
            VStack{
                HStack{
                    Text("Guardian")
                        .font(.system(size: 40, design: .serif))
                        .bold()
                        .foregroundStyle(Color.white)
                        .hAlign(.center)
                        .vAlign(.center)
                    Spacer()
                }
                Text("Your personal financial advisor")
                    .foregroundStyle(Color.white)
                    .font(Font.system(size: 20, weight: .light))
                .padding()
                Spacer()
            }
        }}
}

#Preview {
    ContentView()
}


extension View {
    func disableWithOpacity(_ condition: Bool) -> some View {
        self.disabled(condition).opacity(condition ? 0.5 : 1)
    }
    func hAlign(_ alignment: Alignment) -> some View {
        self.frame(maxWidth: .infinity, alignment: alignment)
    }
    func vAlign(_ alignment: Alignment) -> some View {
        self.frame(maxHeight: .infinity, alignment: alignment)
    }
    func border(_ width: CGFloat, _ color: Color) -> some View {
        self
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(color, lineWidth: width)
            }
    }
    func fillView(_ color: Color) -> some View {
        self
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color)
            }
    }
}
