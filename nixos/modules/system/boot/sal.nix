{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.sal;

in {
  sal.systemName = "nixos";
  sal.processManager.name = "systemd";
  sal.processManager.supports = {
    platforms = pkgs.systemd.meta.platforms;
    fork = true;
    syslog = true;
    users = true;
    privileged = true;
    socketTypes = ["inet" "inet6" "unix"];
    networkNamespaces = false;
  };
  sal.processManager.envNames = {
    mainPid = "MAINPID";
  };
  sal.processManager.extraPath = [ pkgs.su ];

  systemd.services = mapAttrs (n: s:
    let
      mkScript = cmd:
        if cmd != null then
          let c = if cmd.script != null then cmd.script else cmd.command;
          in if !cmd.privileged && s.user != "" && c != "" then ''
            su -s ${pkgs.stdenv.shell} ${s.user} <<'EOF'
            ${c}
            EOF
          '' else c
        else "";

    in mkMerge [
      {
        inherit (s) environment description path;

        wantedBy = [ "multi-user.target" ];
        after = mkMerge [
          (map (n: "${n}.socket") s.requires.sockets)
          (map (n: "${n}.service") s.requires.services)
          (mkIf s.requires.networking ["network.target"])
          (mkIf s.requires.displayManager ["display-manager.service"])
        ];
        requires = config.systemd.services.${n}.after;
        script = mkIf (s.start.script != null) s.start.script;
        preStart = mkIf (s.preStart != null) (mkScript s.preStart);
        postStart = mkIf (s.postStart != null) (mkScript s.postStart);
        preStop = mkIf (s.stop != null) (mkScript s.stop);
        reload = mkIf (s.reload != null) (mkScript s.reload);
        postStop = mkIf (s.postStop != null) (mkScript s.postStop);
        serviceConfig = {
          PIDFile = s.pidFile;
          Type = s.type;
          KillSignal = "SIG" + (toUpper s.stop.stopSignal);
          KillMode = s.stop.stopMode;
          PermissionsStartOnly = true;
          StartTimeout = s.start.timeout;
          StopTimeout = s.stop.timeout;
          User = s.user;
          Group = s.group;
          WorkingDirectory = s.workingDirectory;
          Restart = let
            restart = remove "changed" s.restart;
          in
            if length restart == 0 then "no" else
            if length restart == 1 then head restart else
            if contains "success" restart && contains "failure" restart
            then "allways" else "no";
          SuccessExitStatus =
            concatMapStringsSep " " (c: toString c) s.exitCodes;
        };

        restartIfChanged = contains "changed" s.restart;
      }
      (mkIf (s.start.command != "") {
        serviceConfig.ExecStart =
          if s.start.processName != "" then
            let cmd = head (splitString " " s.start.command);
            in "@${cmd}${s.start.processName}${removePrefix cmd s.start.command}"
          else s.start.command;
      })
      (mkIf (s.requires.dataContainers != []) {
        preStart = mkBefore (
          concatStrings (map (n:
          let
            dc = getAttr n config.sal.dataContainers;
          in ''
            mkdir -m ${dc.mode} -p ${dc.path}
            ${optionalString (dc.user != "") "chown -R ${dc.user} ${dc.path}"}
            ${optionalString (dc.group != "") "chgrp -R ${dc.group} ${dc.path}"}
          ''
          ) s.requires.dataContainers)
        );
      })
      (attrByPath ["systemd"] {} s.extra)
    ]
  ) config.sal.services;

  systemd.sockets = mapAttrs (n: s: {
    inherit (s) description;

    listenStreams = [ s.listen ];
  }) config.resources.sockets;

}
