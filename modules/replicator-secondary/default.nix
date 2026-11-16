{
  pkgs,
  anodyneInputs,
  lib,
  config,
  ...
}:
let
  cfg = config.anodyne-wiki.replicator-secondary;
in
{
  options.anodyne-wiki.replicator-secondary = {
    enable = lib.mkEnableOption "";
    primaryKey = lib.mkOption {
      type = lib.types.str;
    };
  };
  config = lib.mkIf (config.anodyne-wiki.enable && cfg.enable) {
    systemd.tmpfiles.rules = [
      "d /var/lib/anodyne 2775 anodyne anodyne -"
    ];
    users.users = {
      anodyne-replicator = {
        useDefaultShell = true;
        isSystemUser = true;
        group = "anodyne";
        openssh.authorizedKeys.keys = [
          ''command="${pkgs.rrsync}/bin/rrsync -wo /var/lib/anodyne",restrict ${cfg.primaryKey}''
        ];
      };
    };
  };
}
