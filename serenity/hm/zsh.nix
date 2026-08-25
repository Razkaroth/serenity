{ lib, ... }:
{
  programs.zsh.initContent = lib.mkAfter ''
    alias ascend='~/ascension/rebuild.sh'
    alias sshA='ssh raz@ascension'

    enterAscension() {
      echo "Entering ascension..."
      sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 raz@ascension:/ /ascension/root
      sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 raz@ascension:/home/raz /ascension/home
    }

    exitAscension() {
      fusermount -u /ascension/root
      fusermount -u /ascension/home
      echo "Exiting ascension..."
    }
  '';
}
