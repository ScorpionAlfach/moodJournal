import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()

    private let weekDays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Month navigation
                    monthHeader

                    // Filters
                    filtersSection

                    // Calendar grid
                    calendarGrid

                    // Legend
                    legendSection
                }
                .padding(24)
            }

            if viewModel.isLoading && viewModel.calendarData == nil {
                LoadingOverlay()
            }
        }
        .navigationTitle("Календарь")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .sheet(isPresented: $viewModel.showDayDetail) {
            if let detail = viewModel.selectedDayDetail {
                DayDetailSheet(detail: detail)
            }
        }
        .sheet(isPresented: $viewModel.showFilters) {
            CalendarFiltersSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.loadCalendarData()
            await viewModel.loadFilters()
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.appPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.appPrimary.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appText)

            Spacer()

            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.appPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.appPrimary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    private var filtersSection: some View {
        Group {
            if !viewModel.selectedFilters.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.filters.filter { viewModel.selectedFilters.contains($0.value) }) { filter in
                            HStack(spacing: 4) {
                                Image(systemName: filter.icon)
                                    .font(.caption)
                                Text(filter.label)
                                    .font(.caption)
                                Button {
                                    viewModel.toggleFilter(filter.value)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.appPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.appPrimary.opacity(0.1))
                            .cornerRadius(16)
                        }

                        Button {
                            viewModel.clearFilters()
                        } label: {
                            Text("Сбросить")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
            }
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Week day headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appTextSecondary)
                        .frame(height: 32)
                }
            }

            // Days
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(viewModel.filteredDays.enumerated()), id: \.offset) { index, day in
                    if let day = day {
                        CalendarDayCell(day: day) {
                            Task {
                                await viewModel.loadDayDetail(date: day.date)
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 56)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Уровни настроения")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appText)

            HStack(spacing: 16) {
                ForEach(Mood.MoodLevel.allCases, id: \.self) { level in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(level.color)
                            .frame(width: 12, height: 12)
                        Text(level.title)
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct CalendarDayCell: View {
    let day: CalendarDay
    let onTap: () -> Void

    private var isToday: Bool {
        guard let date = day.dateObject else { return false }
        return Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(day.dayNumber ?? 0)")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isToday ? .white : .appText)
                    .frame(width: 32, height: 32)
                    .background(
                        isToday ?
                        AnyView(Circle().fill(Color.appPrimary)) :
                        AnyView(Color.clear)
                    )

                // Mood indicator
                if let moodLevel = day.moodLevel {
                    Circle()
                        .fill(moodColor(for: moodLevel))
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                }

                // Note indicator
                if day.hasNotes {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(Color.appBackground.opacity(0.5))
            .cornerRadius(8)
        }
    }

    private func moodColor(for level: Double) -> Color {
        let intLevel = Int(level.rounded())
        return Mood.MoodLevel(rawValue: intLevel)?.color ?? .appTextSecondary
    }
}

struct DayDetailSheet: View {
    let detail: CalendarDayDetail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date header
                    if let date = parseDate(detail.date) {
                        Text(date.formattedString(format: "d MMMM yyyy"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                    }

                    // Average mood
                    if let avgMood = detail.averageMoodLevel {
                        VStack(spacing: 8) {
                            if let level = Mood.MoodLevel(rawValue: Int(avgMood.rounded())) {
                                Text(level.emoji)
                                    .font(.system(size: 60))
                                Text("Среднее настроение: \(level.title)")
                                    .font(.subheadline)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .cardStyle()
                    }

                    // Factors
                    if !detail.factors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Факторы")
                                .font(.headline)
                                .foregroundColor(.appText)

                            FlowLayout(spacing: 8) {
                                ForEach(detail.factors, id: \.self) { factor in
                                    HStack(spacing: 4) {
                                        Image(systemName: factor.icon)
                                        Text(factor.title)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.appPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.appPrimary.opacity(0.1))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Moods list
                    if !detail.moods.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Записи настроения")
                                .font(.headline)
                                .foregroundColor(.appText)

                            ForEach(detail.moods) { mood in
                                HStack(spacing: 12) {
                                    Text(mood.level.emoji)
                                        .font(.title2)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mood.level.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appText)

                                        if let note = mood.note {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                                .lineLimit(2)
                                        }
                                    }

                                    Spacer()

                                    Text(mood.createdAt.formattedString(format: "HH:mm"))
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                .padding()
                                .background(Color.appBackground)
                                .cornerRadius(12)
                            }
                        }
                    }

                    // Notes preview
                    if !detail.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Заметки")
                                    .font(.headline)
                                    .foregroundColor(.appText)

                                Spacer()

                                NavigationLink(destination: NotesView()) {
                                    Text("Все заметки")
                                        .font(.subheadline)
                                        .foregroundColor(.appPrimary)
                                }
                            }

                            ForEach(detail.notes.prefix(3)) { note in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        if let moodLevel = note.moodLevel {
                                            Text(moodLevel.emoji)
                                        }
                                        Text(note.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appText)
                                        Spacer()
                                    }

                                    Text(note.shortContent)
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                        .lineLimit(2)
                                }
                                .padding()
                                .background(Color.appBackground)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}

struct CalendarFiltersSheet: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.filters) { filter in
                        Button {
                            viewModel.toggleFilter(filter.value)
                        } label: {
                            HStack {
                                Image(systemName: filter.icon)
                                    .foregroundColor(.appPrimary)
                                    .frame(width: 24)

                                Text(filter.label)
                                    .foregroundColor(.appText)

                                Spacer()

                                if viewModel.selectedFilters.contains(filter.value) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.appPrimary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.appBorder)
                                }
                            }
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Сбросить") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(.appTextSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
