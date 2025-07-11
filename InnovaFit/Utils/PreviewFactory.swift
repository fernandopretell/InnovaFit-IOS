// MARK: - PreviewFactory Mock Inline
struct PreviewFactory {
    static var sampleMachine: Machine {
        Machine(
            id: "gym_001",
            name: "Prensa de Pierna",
            type: "Tren inferior",
            description: "Ideal para trabajar los cuádriceps y glúteos.",
            imageUrl: "",
            defaultVideos: [
                Video(
                    title: "Leg Press Estandar gffgjhjfjhjhgjhgjh",
                    urlVideo: "https://example.com/video.mp4",
                    cover: "https://smartgym.b-cdn.net/videos/leg_press/covers/leg_press_standar.webp",
                    musclesWorked: [
                        "Cuádriceps": Muscle(weight: 50, icon: "https://smartgym.b-cdn.net/icons/cuadriceps.svg"),
                        "Glúteos": Muscle(weight: 25, icon: "https://smartgym.b-cdn.net/icons/gluteos.svg"),
                        "Isquiotibiales": Muscle(weight: 25, icon: "https://smartgym.b-cdn.net/icons/isquiotibiales.svg")
                    ],
                    segments: []
                ),
                Video(
                    title: "Pies Abiertos",
                    urlVideo: "https://example.com/video.mp4",
                    cover: "https://smartgym.b-cdn.net/videos/leg_press/covers/leg_press_high_foots.webp",
                    musclesWorked: [
                        "Cuádriceps": Muscle(weight: 70, icon: "https://example.com/cuadriceps.png"),
                        "Glúteos": Muscle(weight: 60, icon: "https://example.com/gluteos.png")
                    ],
                    segments: []
                ),
                Video(
                    title: "Pies Bajos",
                    urlVideo: "https://example.com/video.mp4",
                    cover: "https://smartgym.b-cdn.net/videos/leg_press/covers/leg_press_down_foots.webp",
                    musclesWorked: [
                        "Cuádriceps": Muscle(weight: 70, icon: "https://example.com/cuadriceps.png"),
                        "Glúteos": Muscle(weight: 60,icon: "https://example.com/gluteos.png")
                    ],
                    segments: []
                )
                
            ]
        )
    }

    static var sampleGym: Gym {
        Gym(
            address: "Calle Falsa 123",
            color: "#FDD835",
            name: "InnovaFit Gym",
            owner: "Juan Pérez",
            phone: "123456789",
            isActive: true
        )
    }
}
