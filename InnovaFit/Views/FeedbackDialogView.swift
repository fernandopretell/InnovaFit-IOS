import SwiftUI
import FirebaseFirestore

struct FeedbackDialogView: View {
    let gymId: String
    let gymColorHex: String
    var onDismiss: () -> Void
    var onFeedbackSent: () -> Void

    @State private var rating = 3
    @State private var selectedOption = "Sí, me encanta"
    @State private var comment = ""

    let options = [
        "Sí, me encanta",
        "Sí, pero más largos",
        "No lo necesito",
        "No entendí bien el video"
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8){
                Text("¡Tu opinión importa!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Ayúdanos a mejorar InnovaFit")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }

            Text("1. ¿Qué tan claro fue el video?")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            StarRatingView(rating: $rating)

            Text("2. ¿Te gustaría ver más ejercicios así?")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            OptionsSelectorView(options: options, selectedOption: $selectedOption)

            Text("3. ¿Qué mejorarías del video o del sistema?")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextEditor(text: $comment)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )

            Button(action: submitFeedback) {
                Text("Enviar")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, minHeight: 48) // ancho completo y alto mínimo fijo
                    .background(Color(hex: gymColorHex))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .padding(.top, 8)
            }

            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .padding()
    }

    func submitFeedback() {
        let db = Firestore.firestore()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current // o TimeZone(abbreviation: "UTC") si lo preferís
        let readableTimestamp = formatter.string(from: Date())
        
        let data: [String: Any] = [
            "timestamp": readableTimestamp,
            "rating": rating,
            "answer": selectedOption,
            "comment": comment,
            "gymId": gymId,
            "os": "IOS"
        ]
        
        db.collection("feedback").addDocument(data: data) { error in
            if error == nil {
                onFeedbackSent()
                onDismiss()
            }
        }
    }
}


struct StarRatingView: View {
    @Binding var rating: Int

    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        rating = star
                    }
            }
        }
    }
}

struct OptionsSelectorView: View {
    let options: [String]
    @Binding var selectedOption: String

    var body: some View {
        ForEach(options, id: \.self) { option in
            HStack {
                Image(systemName: selectedOption == option ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(.black)
                Text(option)
            }
            .onTapGesture {
                selectedOption = option
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FeedbackDialogView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackDialogView(
            gymId: "gym123",
            gymColorHex: "#FDD535",
            onDismiss: { print("Dismiss called") },
            onFeedbackSent: { print("Feedback sent") }
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}


