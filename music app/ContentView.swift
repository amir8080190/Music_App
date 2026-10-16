
import SwiftUI
import AVFoundation
import Combine

// MARK: - Song Model

struct Song: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let url: String
    let symbol: String
    let colors: [Color]
}

// MARK: - Sample Songs

let songs: [Song] = [
    Song(
        title: "Summer Vibes",
        artist: "Artist One",
        url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
        symbol: "sunset.fill",
        colors: [.pink, .orange, .purple]
    ),
    Song(
        title: "Night Drive",
        artist: "Artist Two",
        url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
        symbol: "moon.stars.fill",
        colors: [.indigo, .purple, .black]
    ),
    Song(
        title: "Dreams",
        artist: "Artist Three",
        url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
        symbol: "cloud.fill",
        colors: [.cyan, .blue, .indigo]
    ),
    Song(
        title: "Lost in You",
        artist: "Artist Four",
        url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
        symbol: "heart.fill",
        colors: [.red, .pink, .purple]
    ),
    Song(
        title: "Better Days",
        artist: "Artist Five",
        url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3",
        symbol: "sun.max.fill",
        colors: [.orange, .red, .purple]
    )
]

// MARK: - Music Player


@MainActor
final class MusicPlayer: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false

    private var player: AVPlayer?

    func play(_ song: Song) {
        guard let url = URL(string: song.url) else {
            return
        }

        player?.pause()
        player = AVPlayer(url: url)
        currentSong = song
        isPlaying = true
        player?.play()
    }

    func togglePlayback() {
        guard let player else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func nextSong() {
        guard let currentSong,
              let index = songs.firstIndex(
                where: { $0.id == currentSong.id }
              ) else {
            play(songs[0])
            return
        }

        play(songs[(index + 1) % songs.count])
    }

    func previousSong() {
        guard let currentSong,
              let index = songs.firstIndex(
                where: { $0.id == currentSong.id }
              ) else {
            play(songs[0])
            return
        }

        play(songs[(index - 1 + songs.count) % songs.count])
    }
}

// MARK: - Album Artwork

struct AlbumArt: View {
    let song: Song
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            LinearGradient(
                colors: song.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: song.symbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.9))
                .padding(size * 0.25)
        }
        .frame(width: size, height: size)
        .clipShape(
            RoundedRectangle(cornerRadius: size * 0.18)
        )
    }
}

// MARK: - Main Screen

struct ContentView: View {
    @StateObject private var player = MusicPlayer()
    @State private var selectedTab = 0
    @State private var searchText = ""

    private var filteredSongs: [Song] {
        if searchText.isEmpty {
            return songs
        }

        return songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
            || $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.04, blue: 0.055)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("hello")
                Group {
                    switch selectedTab {
                    case 1:
                        searchScreen
                    case 2:
                        libraryScreen
                    default:
                        homeScreen
                    }
                }

                Spacer(minLength: 12)

                if let song = player.currentSong {
                    miniPlayer(song)
                }

                tabBar
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Home

    private var homeScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                Text("Recently Played")
                    .font(.title2.bold())

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(songs) { song in
                            Button {
                                player.play(song)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    AlbumArt(song: song, size: 125)

                                    Text(song.title)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    Text(song.artist)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                .frame(width: 125, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("All Songs")
                    .font(.title2.bold())

                songList(filteredSongs)

                Text("Made for You")
                    .font(.title2.bold())

                HStack {
                    Image(systemName: "heart.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.pink)

                    VStack(alignment: .leading) {
                        Text("Your Favorites")
                            .font(.headline)
                        Text("Your personal soundtrack")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Good music.")
                    .font(.subheadline)
                    .foregroundStyle(.purple)

                Text("My Music")
                    .font(.largeTitle.bold())
            }

            Spacer()

            Image(systemName: "waveform")
                .font(.title)
                .foregroundStyle(.purple)
                .padding()
                .background(.purple.opacity(0.15))
                .clipShape(Circle())
        }
    }

    // MARK: Search

    private var searchScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Search")
                .font(.largeTitle.bold())

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)

                TextField("Songs or artists", text: $searchText)
                    .tint(.purple)
            }
            .padding()
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Search Results")
                .font(.title2.bold())

            songList(filteredSongs)

            Spacer()
        }
        .padding()
    }

    // MARK: Library

    private var libraryScreen: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Your Library")
                .font(.largeTitle.bold())

            libraryItem(
                title: "Liked Songs",
                subtitle: "Your favorite tracks",
                symbol: "heart.fill",
                color: .pink
            )

            libraryItem(
                title: "Playlists",
                subtitle: "Your music collections",
                symbol: "music.note.list",
                color: .purple
            )

            libraryItem(
                title: "Recently Played",
                subtitle: "Listen again",
                symbol: "clock.fill",
                color: .orange
            )

            Spacer()
        }
        .padding()
    }

    private func libraryItem(
        title: String,
        subtitle: String,
        symbol: String,
        color: Color
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .padding()
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Song List

    private func songList(_ items: [Song]) -> some View {
        VStack(spacing: 14) {
            ForEach(items) { song in
                HStack(spacing: 13) {
                    AlbumArt(song: song, size: 55)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(song.title)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    Button {
                        if player.currentSong?.id == song.id {
                            player.togglePlayback()
                        } else {
                            player.play(song)
                        }
                    } label: {
                        Image(
                            systemName:
                                player.currentSong?.id == song.id
                                && player.isPlaying
                                ? "pause.fill" : "play.fill"
                        )
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Mini Player

    private func miniPlayer(_ song: Song) -> some View {
        HStack(spacing: 12) {
            AlbumArt(song: song, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)

                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Button {
                player.previousSong()
            } label: {
                Image(systemName: "backward.end.fill")
                    .foregroundStyle(.white)
            }

            Button {
                player.togglePlayback()
            } label: {
                Image(
                    systemName: player.isPlaying
                    ? "pause.fill" : "play.fill"
                )
                .font(.title2)
                .foregroundStyle(.white)
            }

            Button {
                player.nextSong()
            } label: {
                Image(systemName: "forward.end.fill")
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
        .background(.white.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: Bottom Navigation

    private var tabBar: some View {
        HStack {
            tabButton("Home", icon: "house.fill", index: 0)
            Spacer()
            tabButton("Search", icon: "magnifyingglass", index: 1)
            Spacer()
            tabButton("Library", icon: "music.note.list", index: 2)
        }
        .padding(.horizontal, 35)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.black.opacity(0.5))
    }

    private func tabButton(
        _ title: String,
        icon: String,
        index: Int
    ) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(
                selectedTab == index ? .purple : .gray
            )
        }
        .buttonStyle(.plain)
    }
}

