{
  config,
  lib,
  ...
}:
let
  cfg = config.anodyne-wiki;
in
{
  imports = [
    ./caddy
    ./frontend
    ./pkgs
    ./api
    ./chrp
    ./replicator-primary
    ./replicator-secondary
  ];
  options.anodyne-wiki = {
    enable = lib.mkEnableOption "";
  };
  config = lib.mkIf cfg.enable {
    users.users.anodyne = {
      isSystemUser = true;
      group = "anodyne";
    };
    users.groups.anodyne = { };

    systemd.tmpfiles.rules = lib.mkIf (!config.anodyne-wiki.replicator-secondary.enable) [
      "d /var/lib/anodyne 0755 anodyne anodyne -"
    ];
  };
}
