{ lib, ... }:
{
  programs.zsh.initContent = lib.mkAfter ''
    alias ascension='cd /home/raz/ascension && n'
    alias ascend='~/ascension/rebuild-ascension.sh'
    alias sshS='ssh raz@serenity'

    enterSerenity() {
      echo "Entering serenity..."
      sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 raz@serenity:/ /serenity/root
      sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 raz@serenity:/home/raz /serenity/home
    }

    exitSerenity() {
      fusermount -u /serenity/root
      fusermount -u /serenity/home
      echo "Exiting serenity..."
    }
  '';
}
