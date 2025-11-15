{...}: 
{

fileSystems."/serenity" = {
    device = "sshfs#raz@serenity:/home/raz";
    fsType = "fuse";
    options = [
      "allow_other"
      "reconnect"
      "IdentityFile=/home/you/.ssh/id_ed25519"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
    ];
  };

 fileSystems."/c/beta" = {
    device = "sshfs#raz@serenity:/c/beta";
    fsType = "fuse";
    options = [
      "allow_other"
      "reconnect"
      "IdentityFile=/home/you/.ssh/id_ed25519"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
    ];
  };

}
