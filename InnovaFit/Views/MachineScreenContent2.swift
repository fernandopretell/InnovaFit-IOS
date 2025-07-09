import SwiftUI
import _SwiftData_SwiftUI
import SDWebImageSwiftUI

struct MachineScreenContent2: View {
    let machine: Machine
    let gym: Gym

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Imagen principal con overlay y título
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: machine.imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 240)
                            .clipped()
                            .cornerRadius(12)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                            .frame(height: 240)
                            .cornerRadius(12)
                    }

                    // Capa oscura
                    Rectangle()
                        .foregroundColor(.black)
                        .opacity(0.4)
                        .cornerRadius(12)
                        .frame(height: 240)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(machine.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text("Tren inferior")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding()
                }
                .padding(.horizontal)

                // Descripción
                VStack(alignment: .leading, spacing: 8) {
                    Text(machine.description)
                        .font(.body)
                        .foregroundColor(.black)
                        .lineLimit(nil)
                }
                .padding(.horizontal)

                // Lista de videos sugeridos
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(machine.defaultVideos, id: \.id) { video in
                        VideoRowView(video: video)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(machine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }
        }
    }
}

struct VideoRowView: View {
    let video: Video

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .center) {
                AsyncImage(url: URL(string: video.cover)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 80)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    Color.gray.opacity(0.1)
                        .frame(width: 100, height: 80)
                        .cornerRadius(8)
                }

                // Icono Play gris claro
                Image(systemName: "play.fill")
                    .foregroundColor(Color.accentColor.opacity(0.4))
                    .padding(6)
                    .background(.gray.opacity(0.4))
                    .clipShape(Circle())
                    .padding(6)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                ForEach(video.musclesWorked.sorted(by: { $0.value.weight > $1.value.weight }), id: \.key) { key, value in
                    HStack {
                        Text(key)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Spacer()

                        Text("\(value.weight)%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.clear)
        .cornerRadius(10)
    }
}



struct RoundedBottomShape2: Shape {
    var radius: CGFloat = 30

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - radius),
            control: CGPoint(x: rect.width / 2, y: rect.height + radius)
        )
        path.closeSubpath()

        return path
    }
}

struct ToastView2: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
            .shadow(radius: 4)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .zIndex(1)
    }
}


struct MachineScreenContent_Previews2: PreviewProvider {
    static var previews: some View {
        let machine = Machine(
            id: "gym_001",
            name: "LEG PRESS",
            description: "Ideal para trabajar los cuádriceps y glúteos.",
            imageUrl: "",
            defaultVideos: [
                Video(
                    title: "Prensa de Pierna",
                    urlVideo: "https://www.youtube.com/watch?v=example",
                    cover: "https://example.com/cover.jpg",
                    musclesWorked: [
                        "Cuádriceps": Muscle(weight: 50, icon: "https://smartgym.b-cdn.net/icons/cuadriceps.svg"),
                        "Glúteos": Muscle(weight: 25, icon: "https://smartgym.b-cdn.net/icons/gluteos.svg"),
                        "Isquiotibiales": Muscle(weight: 25, icon: "https://smartgym.b-cdn.net/icons/isquiotibiales.svg")
                    ],
                    segments: []
                )
            ]
        )

        let gym = Gym(
            address: "Calle Falsa 123",
            color: "#FDD835",
            name: "InnovaFit Gym",
            owner: "Juan Pérez",
            phone: "123456789",
            isActive: true
        )

        MachineScreenContent(machine: machine, gym: gym)
    }
}

