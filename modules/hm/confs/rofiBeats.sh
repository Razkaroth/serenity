#!/run/current-system/sw/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For Rofi Beats to play online Music or Locally save media files

# Directory local music folder
mDIR="$HOME/Music/"

# Directory for icons
iDIR="$HOME/.config/swaync/icons"

# Online Stations. Edit as required
declare -A online_music=(
  ["Radio - Lofi Girl 🎧🎶"]="https://play.streamafrica.net/lofiradio"
  ["Radio - Chillhop 🎧🎶"]="http://stream.zeno.fm/fyn8eh3h5f8uv"
  ["FM - Easy Rock 96.3 📻🎶"]="https://radio-stations-philippines.com/easy-rock"
  ["FM - Love Radio 90.7 📻🎶"]="https://radio-stations-philippines.com/love"
  ["FM - WRock - CEBU 96.3 📻🎶"]="https://onlineradio.ph/126-96-3-wrock.html"
  ["YT - Wish 107.5 YT Pinoy HipHop 📻🎶"]="https://youtube.com/playlist?list=PLkrzfEDjeYJnmgMYwCKid4XIFqUKBVWEs&si=vahW_noh4UDJ5d37"
  ["YT - Relaxing Music 📹🎶"]="https://youtube.com/playlist?list=PLMIbmfP_9vb8BCxRoraJpoo4q1yMFg4CE"
  ["YT - Relaxing Piano Jazz Music 🎹🎶"]="https://youtu.be/85UEqRat6E4?si=jXQL1Yp2VP_G6NSn"
  ["YT - CowbowBebop Lofi 🎹🎶"]="https://www.youtube.com/watch?v=xLgeRvykv1g&list=LL&index=2&pp=gAQBiAQB"
  ["YT - Souls Lofi - Prepare to chill 🔥⚔️🎶"]="https://www.youtube.com/playlist?list=PLK8il0yNGJfO4rSYm74ONTzg-usRynwUG"
  ["YT - Breathe in the ruins, Squire 🏰⚔️🎶"]="https://www.youtube.com/watch?v=Cs2BaMO7KnI"
  ["YT - Scholastum Provost 📖⚔️🎶"]="https://www.youtube.com/playlist?list=PLQsgB3CetZVZh1QEvnfdc59XNDx19YHlL"
  ["YT - Zelda Chillhop 🏰⚔️🎶"]="https://www.youtube.com/playlist?list=PLQsgB3CetZVZh1QEvnfdc59XNDx19YHlL"
  ["YT - Undertale Lofi 🏰⚔️🎶"]="https://www.youtube.com/playlist?list=PLb5uvAYH2QqAv4rbY7E5GaIdidZ_dNggt"
  ["YT - Nier 🏰⚔️🎶"]="https://www.youtube.com/playlist?list=PLIzhSrfqD8bgCsPuQeu_-V681TnuRLaar"
  ["YT - I dont remember Anymore 🔖⚔️🎶"]="https://www.youtube.com/watch?v=X6SN9eM--O4"
  ["YT - State of soul 🔖⚔️🎶"]="https://www.youtube.com/watch?v=_XrM4Y1wR88"

)

# Populate local_music array with files from music directory and subdirectories
populate_local_music() {
  local_music=()
  filenames=()
  while IFS= read -r file; do
    local_music+=("$file")
    filenames+=("$(basename "$file")")
  done < <(find "$mDIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.mp4" \))
}

# Function for displaying notifications
notification() {
  notify-send -u normal -i "$iDIR/music.png" "Playing: $@"
}

# Main function for playing local music
play_local_music() {
  populate_local_music

  # Prompt the user to select a song
  choice=$(printf "%s\n" "${filenames[@]}" | rofi -i -dmenu -config ~/.config/rofi/clipboard.rasi -p "Local Music")

  if [ -z "$choice" ]; then
    exit 1
  fi

  # Find the corresponding file path based on user's choice and set that to play the song then continue on the list
  for ((i = 0; i < "${#filenames[@]}"; ++i)); do
    if [ "${filenames[$i]}" = "$choice" ]; then

      notification "$choice"

      # Play the selected local music file using mpv
      mpv --playlist-start="$i" --loop-playlist --vid=no "${local_music[@]}"

      break
    fi
  done
}

# Main function for shuffling local music
shuffle_local_music() {
  notification "Shuffle local music"

  # Play music in $mDIR on shuffle
  mpv --shuffle --loop-playlist --vid=no "$mDIR"
}

# Main function for playing online music
play_online_music() {
  choice=$(printf "%s\n" "${!online_music[@]}" | rofi -i -dmenu -config ~/.config/rofi/clipboard.rasi -p "Online Music")

  if [ -z "$choice" ]; then
    exit 1
  fi

  link="${online_music[$choice]}"

  notification "$choice"

  # Play the selected online music using mpv
  mpv --shuffle --vid=no "$link"
}

nohup easyeffects --gapplication-service &

# Check if an online music process is running and send a notification, otherwise run the main function
pkill mpv && notify-send -u low -i "$iDIR/music.png" "Music stopped" || {

  # Prompt the user to choose between local and online music
  user_choice=$(printf "Play from Online Stations\nPlay from Music Folder\nShuffle Play from Music Folder" | rofi -dmenu -config ~/.config/rofi/clipboard.rasi -p "Select music source")

  case "$user_choice" in
  "Play from Music Folder")
    play_local_music
    ;;
  "Play from Online Stations")
    play_online_music
    ;;
  "Shuffle Play from Music Folder")
    shuffle_local_music
    ;;
  *)
    echo "Invalid choice"
    ;;
  esac
}
