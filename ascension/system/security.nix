{pkgs, ...}: {
  security.pam.services ={
    "raz" = {
      kwallet = {
        enable = true;
        package = pkgs.kdePackages.kwallet-pam;
      };
    };
  };
}
