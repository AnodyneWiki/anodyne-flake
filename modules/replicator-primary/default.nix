{
  pkgs,
  anodyneInputs,
  lib,
  config,
  ...
}:
let
  cfg = config.anodyne-wiki.replicator-primary;
in
{
  options.anodyne-wiki.replicator-primary = {
    enable = lib.mkEnableOption "";
    sshKey = lib.mkOption {
      type = lib.types.path;
      description = "ssh keyfile to use for the connection to the secondary machine";
    };
    target = lib.mkOption {
      type = lib.types.str;
      description = "FQDN of the target machine";
    };
  };
  config = lib.mkIf (config.anodyne-wiki.enable && cfg.enable) {
    systemd.tmpfiles.rules = [ "d /var/lib/anodyne/.snapshot 0750 anodyne anodyne -" ];
    systemd.services.anodyne-chrp.onSuccess = [ "anodyne-replicator-sync.service" ];
    systemd.services.anodyne-chrp-init.onSuccess = [ "anodyne-replicator-sync.service" ];

    systemd.services.anodyne-replicator-sync = {
      description = "anodyne wiki replicator";
      after = [
        "network-online.target"
      ];
      path = [
        pkgs.openssh
        pkgs.busybox
      ];
      wants = [ "network-online.target" ];
      requires = [ "anodyne-frontend-sync.service" ];
      serviceConfig = {
        User = "anodyne";
        Group = "anodyne";
        Type = "oneshot";
      };
      script = ''
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/anodyne/db.sqlite ".backup /var/lib/anodyne/.snapshot/db.sqlite"
          ${pkgs.rsync}/bin/rsync --archive --delete --delay-updates --compress --timeout=60 \
            --chmod=Dg+rwx,Fg+rw \
            --rsh="ssh -i ${cfg.sshKey} -o BatchMode=yes -o StrictHostKeyChecking=no" \
            /var/lib/anodyne/.snapshot/db.sqlite /var/lib/anodyne/frontend \
            anodyne-replicator@${cfg.target}:.
      '';
    };
  };
}
