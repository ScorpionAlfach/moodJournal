import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Today's mood card
                        todayMoodCard

                        // Statistics summary
                        if let stats = viewModel.statistics {
                            statisticsSummary(stats)
                        }

                        // Mood graph
                        moodGraphCard

                        // Quick actions
                        quickActionsCard
                    }
                    .padding(24)
                }

                if viewModel.isLoading && viewModel.statistics == nil {
                    LoadingOverlay()
                }
            }
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showMoodPicker) {
                MoodPickerSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    private var todayMoodCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Сегодня")
                    .font(.headline)
                    .foregroundColor(.appText)
                Spacer()
                Text(Date().formattedString(format: "d MMMM"))
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }

            if let mood = viewModel.todayMood {
                // Show today's mood
                HStack(spacing: 20) {
                    Text(mood.level.emoji)
                        .font(.system(size: 60))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mood.level.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.appText)

                        if let note = mood.note, !note.isEmpty {
                            Text(note)
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                                .lineLimit(2)
                        }

                        if !mood.factors.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(mood.factors.prefix(3), id: \.self) { factor in
                                    HStack(spacing: 4) {
                                        Image(systemName: factor.icon)
                                            .font(.caption)
                                        Text(factor.title)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.appTextSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.appBackground)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }

                    Spacer()
                }

                Button {
                    viewModel.showMoodPicker = true
                } label: {
                    Text("Изменить")
                        .font(.subheadline)
                        .foregroundColor(.appPrimary)
                }
            } else {
                // No mood recorded
                VStack(spacing: 16) {
                    Text("Как вы себя чувствуете?")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)

                    HStack(spacing: 12) {
                        ForEach(Mood.MoodLevel.allCases, id: \.self) { level in
                            Button {
                                viewModel.selectedMoodLevel = level
                                viewModel.showMoodPicker = true
                            } label: {
                                Text(level.emoji)
                                    .font(.system(size: 40))
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }

    private func statisticsSummary(_ stats: MoodService.StatisticsResponse) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Всего записей",
                value: "\(stats.totalMoods)",
                icon: "chart.bar.fill",
                color: .appPrimary
            )

            StatCard(
                title: "Средний уровень",
                value: String(format: "%.1f", stats.averageLevel),
                icon: "chart.line.uptrend.xyaxis",
                color: .appSuccess
            )

            StatCard(
                title: "Дней подряд",
                value: "\(stats.streakDays)",
                icon: "flame.fill",
                color: .appWarning
            )

            StatCard(
                title: "Главный фактор",
                value: stats.mostCommonFactors.first?.title ?? "-",
                icon: stats.mostCommonFactors.first?.icon ?? "star.fill",
                color: .appAccent
            )
        }
    }

    private var moodGraphCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("График настроения")
                    .font(.headline)
                    .foregroundColor(.appText)
                Spacer()

                Menu {
                    ForEach(StatisticsViewModel.Period.allCases, id: \.self) { period in
                        Button(period.title) {
                            viewModel.selectedPeriod = period
                            Task {
                                await viewModel.loadGraph()
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedPeriod.title)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.appPrimary)
                }
            }

            if let graphData = viewModel.graphData, !graphData.data.isEmpty {
                Chart(graphData.data) { point in
                    LineMark(
                        x: .value("Дата", point.date),
                        y: .value("Уровень", point.level)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                    AreaMark(
                        x: .value("Дата", point.date),
                        y: .value("Уровень", point.level)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "6366F1").opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    PointMark(
                        x: .value("Дата", point.date),
                        y: .value("Уровень", point.level)
                    )
                    .foregroundStyle(Color(hex: "6366F1"))
                    .symbolSize(50)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self),
                               let level = Mood.MoodLevel(rawValue: intValue) {
                                Text(level.emoji)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)

                // Average line info
                HStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.3))
                        .frame(width: 12, height: 12)
                    Text("Средний уровень: \(String(format: "%.1f", graphData.averageLevel))")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.appTextSecondary)
                    Text("Нет данных для отображения")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .cardStyle()
    }

    private var quickActionsCard: some View {
        VStack(spacing: 16) {
            Text("Быстрые действия")
                .font(.headline)
                .foregroundColor(.appText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                NavigationLink(destination: NotesView()) {
                    QuickActionButton(
                        icon: "note.text",
                        title: "Заметки",
                        color: .appSecondary
                    )
                }

                NavigationLink(destination: CalendarView()) {
                    QuickActionButton(
                        icon: "calendar",
                        title: "Календарь",
                        color: .appAccent
                    )
                }

                NavigationLink(destination: AIAssistantView()) {
                    QuickActionButton(
                        icon: "bubble.left.and.bubble.right",
                        title: "AI",
                        color: .appSuccess
                    )
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appText)

            Text(title)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
        }
        .padding(16)
        .cardStyle()
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    StatisticsView()
}
