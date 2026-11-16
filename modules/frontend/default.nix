{
  pkgs,
  anodyneInputs,
  lib,
  config,
  ...
}:
let
  cfg = config.anodyne-wiki.frontend;
  chrpEnabled = config.anodyne-wiki.chrp.enable;
  stateRoot = "/var/lib/anodyne/frontend";
in
{
  options.anodyne-wiki.frontend = {
    enable = lib.mkEnableOption "";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { src = anodyneInputs.anodyne-frontend; };
    };
    root = lib.mkOption {
      type = lib.types.str;
      default =
        if chrpEnabled || config.anodyne-wiki.replicator-secondary.enable then
          stateRoot
        else
          "${cfg.package}";
      defaultText = lib.literalExpression ''
        if config.anodyne-wiki.chrp.enable then "/var/lib/anodyne/frontend" else "''${package}"
      '';
      description = ''
        Directory the frontend is served from. chrp writes its results into
        the frontend, so a writable copy of the package is used when chrp is
        enabled.
      '';
    };
  };

  config = lib.mkIf config.anodyne-wiki.frontend.enable {
    systemd.services.anodyne-frontend-sync = {
      description = "copy the anodyne frontend to a writable directory";
      wantedBy = [ "multi-user.target" ];
      before = [ "caddy.service" ];
      serviceConfig = {
        User = "anodyne";
        Group = "anodyne";
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/cp -rfT --no-preserve=mode,ownership ${cfg.package} ${stateRoot}";
      };
    };
  };
}
