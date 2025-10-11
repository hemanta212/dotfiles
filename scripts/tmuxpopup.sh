if [ $# -eq 0 ]; then
  SESSIONS=("popup")
else
  SESSIONS=("$@")
fi

for SESSION in "${SESSIONS[@]}"; do
  if [ "$(tmux display-message -p -F "#{session_name}")" = "$SESSION" ]; then
    tmux detach-client
  else
    if [ "$SESSION" = "popup" ]; then
      WIDTH="90%"
      HEIGHT="90%"
    else
      WIDTH="60%"
      HEIGHT="70%"
    fi
    tmux popup -w $WIDTH -h $HEIGHT -E "tmux attach -t $SESSION || tmux new -s $SESSION"
  fi
done
