import SwiftUI
import SDWebImageSwiftUI

struct MachineScreenContent: View {
    let machine: Machine
    let gym: Gym

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                machineHeader
                VideoCarouselView(videos: machine.defaultVideos, gymColor: gym.safeColor)
                muscleTitle
                MuscleListView(
                    musclesWorked: machine.defaultVideos.first?.musclesWorked ?? [:],
                    gymColor: Color(hex: gym.safeColor)
                )
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .center) {
            Color.black
                .clipShape(RoundedBottomShape(radius: 30))
                .frame(height: 55)
            
            Image("AppLogo1")
                .resizable()
                .scaledToFit()
                .frame(height: 25)
            
        }
        .background(Color(hex: gym.safeColor))
    }

    private var machineHeader: some View {
        VStack(spacing: 0) {
            Text(machine.name.uppercased())
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(Color.black)

            Text("Con esta máquina puedes trabajar")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.black)
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
        .background(Color(hex: gym.safeColor))
    }

    private var muscleTitle: some View {
        VStack(spacing: 0) {
            Text("Realizando este ejercicio")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(Color.black)

            Text("Estarás trabajando los siguientes músculos...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.black)
        }
    }
}

struct MachineScreenContent_Previews: PreviewProvider {
    static var previews: some View {
        let machine = Machine(
            name: "LEG PRESS",
            description: "Ideal para trabajar los cuádriceps y glúteos.",
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

struct RoundedBottomShape: Shape {
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

