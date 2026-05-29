import SwiftUI

struct LeaguesView: View {
    @ObservedObject var appState: AppStateManager
    @State private var showCreate = false; @State private var showJoin = false
    var body: some View {
        NavigationStack {
            List {
                if appState.leagues.isEmpty { EmptyState(icon: "trophy", title: "No Leagues", message: "Create or join a league.") }
                ForEach(appState.leagues) { l in
                    NavigationLink(destination: LeagueDetailView(league: l)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l.name).fontWeight(.semibold)
                            Text(l.code).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Leagues")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Menu { Button("Create") { showCreate = true }; Button("Join") { showJoin = true } } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $showCreate) { CreateLeagueView() }
            .sheet(isPresented: $showJoin) { JoinLeagueView() }
        }
    }
}

struct LeagueDetailView: View {
    let league: League; @State private var standings: [LeaderboardEntry] = []
    var body: some View {
        List { ForEach(standings) { e in LeaderboardRow(entry: e, isMe: false) } }
        .navigationTitle(league.name)
        .onAppear { Task { do { standings = try await APIService.shared.fetchLeagueStandings(leagueId: league.id) } catch {} } }
    }
}

struct CreateLeagueView: View {
    @Environment(\.dismiss) var dismiss; @State private var name = ""; @State private var isPrivate = false
    @State private var errMsg = ""; @State private var showAlert = false
    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("League Name", text: $name); Toggle("Private", isOn: $isPrivate) }
                Button(action: create) { Text("Create").frame(maxWidth: .infinity).foregroundStyle(name.isEmpty ? .gray : .green) }.disabled(name.isEmpty)
            }
            .navigationTitle("Create League").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
            .alert("Error", isPresented: $showAlert) { Button("OK") {} } message: { Text(errMsg) }
        }
    }
    func create() { Task { do { _ = try await APIService.shared.createLeague(name: name, isPrivate: isPrivate); dismiss() } catch { errMsg = error.localizedDescription; showAlert = true } } }
}

struct JoinLeagueView: View {
    @Environment(\.dismiss) var dismiss; @State private var code = ""
    @State private var errMsg = ""; @State private var showAlert = false
    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("League Code", text: $code).textInputAutocapitalization(.never) }
                Button(action: join) { Text("Join").frame(maxWidth: .infinity).foregroundStyle(code.isEmpty ? .gray : .green) }.disabled(code.isEmpty)
            }
            .navigationTitle("Join League").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
            .alert("Error", isPresented: $showAlert) { Button("OK") {} } message: { Text(errMsg) }
        }
    }
    func join() { Task { do { try await APIService.shared.joinLeague(code: code); dismiss() } catch { errMsg = error.localizedDescription; showAlert = true } } }
}
