import SwiftUI
import FirebaseFirestore

struct FeedbackDialogView: View {
    let gymId: String
    let gymColorHex: String
    var onDismiss: () -> Void
    var onFeedbackSent: () -> Void
    
    @State private var rating: Int = 3
    @State private var selectedOption: String = "Sí, me encanta"
    @State private var comment: String = ""
    
    private let options = [
        "Sí, me encanta",
        "Sí, pero más largos",
        "No lo necesito",
        "No entendí bien el video"
    ]
    
    var body: some View {
        VStack(spacing: 26) {
            headerSection
            ratingSection
            optionsSection
            commentSection
            submitButton
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        .padding()
        .preferredColorScheme(.light)
    }
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("¡Tú opinión nos importa!")
                .font(.title3)
                .fontWeight(.heavy)
                .foregroundColor(Color.textTitle)
            
            Text("Ayúdanos a mejorar Innovafit")
                .font(.subheadline)
                .foregroundColor(Color.textBody)
        }
        .padding(.top, 12)
    }
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("¿Qué tan claro fue el video?")
                .font(.subheadline)
                .fontWeight(.heavy)
                .foregroundColor(Color.textSubtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(index <= rating ? Color.accentColor : .gray)
                        .onTapGesture {
                            rating = index
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("¿Te gustaría ver más videos así?")
                .font(.subheadline)
                .fontWeight(.heavy)
                .foregroundColor(Color.textSubtitle)
            
            ForEach(options, id: \.self) { option in
                let isSelected = selectedOption == option
                
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                isSelected ? Color(hex: gymColorHex) : Color.gray,
                                lineWidth: 3
                            )
                            .frame(width: 20, height: 20)
                        
                        if isSelected {
                            Circle()
                                .fill(Color.textTitle)
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    Text(option)
                        .font(.body)
                        .fontWeight(isSelected ? .bold : .semibold)
                        .foregroundColor(isSelected ? .black : Color.black)
                    
                    Spacer()
                }
                .padding()
                .background(isSelected ? Color(hex: "#FFF8D6") : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color(hex: "#FFD600") : Color(hex: "#D9D9D9"), lineWidth: 1)
                )
                .cornerRadius(12)
                .onTapGesture {
                    selectedOption = option
                }
            }
        }
    }
    
    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("¿Qué mejorarías del video o del sistema?")
                .font(.subheadline)
                .fontWeight(.heavy)
                .foregroundColor(Color.textSubtitle)
            
            TextField("", text: $comment, prompt: Text("Escribe tu comentario aquí…")
                .foregroundColor(Color.textPlaceholder)
                .font(.body))
            .padding(12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            print("📤 Feedback enviado: \(rating) stars, option: \(selectedOption), comment: \(comment)")
            FeedbackRepository.saveFeedback(
                gymId: gymId,
                rating: rating,
                answer: selectedOption,
                comment: comment
            ) { result in
                switch result {
                case .success:
                    print("✅ Feedback guardado en Firestore")
                    onFeedbackSent()
                case .failure(let error):
                    print("⚠️ Error al guardar feedback: \(error)")
                    onFeedbackSent()
                }
            }
        }) {
            Text("Enviar")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(Color.textTitle)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: gymColorHex))
                .cornerRadius(28)
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


