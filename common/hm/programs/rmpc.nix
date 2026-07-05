{ ... }:
{
  xdg.configFile."rmpc/config.ron".text = ''
    #![enable(implicit_some)]
    #![enable(unwrap_newtypes)]
    #![enable(unwrap_variant_newtypes)]
    (
      address: "127.0.0.1:6600",
      password: None,
    )
  '';
}
