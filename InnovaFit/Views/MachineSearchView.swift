import SwiftUI

struct MachineSearchView: View {
    let machines: [Machine]
    let gym: Gym
    let onSelectMachine: (Machine, Gym) -> Void
    var onBack: () -> Void

    @State private var searchText = ""
    @State private var selectedType = "Todos"

    private var machineTypes: [String] {
        let types = machines
            .map { $0.type.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let unique = Array(Set(types)).sorted()
        return ["Todos"] + unique
    }

    private var filteredMachines: [Machine] {
        machines.filter { machine in
            let trimmedType = machine.type.trimmingCharacters(in: .whitespaces)
            let matchesType = selectedType == "Todos" || trimmedType == selectedType
            let matchesSearch = searchText.isEmpty ||
                machine.name.localizedCaseInsensitiveContains(searchText) ||
                machine.description.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesSearch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar header
            HStack(spacing: 12) {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Buscar máquinas...", text: $searchText)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: "#F0F0F0"))
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(machineTypes, id: \.self) { type in
                        FilterChip(title: type, isSelected: selectedType == type) {
                            selectedType = type
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.white)

            Divider()

            // Results list
            if filteredMachines.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    if !searchText.isEmpty {
                        Text("Sin resultados para \"\(searchText)\"")
                            .font(.headline)
                            .foregroundColor(.gray)
                    } else {
                        Text("Sin máquinas en esta categoría")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredMachines) { machine in
                            Button {
                                onSelectMachine(machine, gym)
                            } label: {
                                SearchResultItem(machine: machine)
                            }
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(Color(hex: "#FBFCF8").ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .gray)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color(hex: "#F0F0F0"))
                .cornerRadius(20)
        }
    }
}

// MARK: - Search Result Item

private struct SearchResultItem: View {
    let machine: Machine

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: machine.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(hex: "#CACCD3")
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
            .frame(width: 52, height: 52)
            .clipped()
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(machine.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                Text(machine.description)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}
