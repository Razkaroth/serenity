{ ... }: {
  services.logind = {
    settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
      IdleAction = "ignore";
      HandlePowerKey = "ignore";
      HandleSuspendKey = "ignore";
    };
  };
}
