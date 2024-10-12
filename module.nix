{ pkgs, lib, config, ... }:

let
  cfg = config.services.hetrixtools-agent;
in
{
  options.services.hetrixtools-agent = with lib.types; {
    enable = lib.mkEnableOption "hetrixtools-agent";

    package = lib.mkPackageOption pkgs "hetrixtools-agent" { };

    sid = lib.mkOption {
      description = "Server ID";
      type = nullOr str;
      default = null;
    };

    sidFile = lib.mkOption {
      description = "File containing server ID";
      type = nullOr str;
      default = null;
    };

    sidCommand = lib.mkOption {
      description = "Command to run to obtain server ID";
      type = nullOr str;
      default = null;
    };

    networkInterfaces = lib.mkOption {
      type = listOf str;
      default = [ ];
    };

    checkServices = lib.mkOption {
      type = listOf str;
      default = [ ];
    };

    checkSoftRAID = lib.mkOption {
      type = bool;
      default = false;
    };

    checkDriveHealth = lib.mkOption {
      type = bool;
      default = false;
    };

    runningProcesses = lib.mkOption {
      type = bool;
      default = false;
    };

    connectionPorts = lib.mkOption {
      type = listOf str;
      default = [ ];
    };

    # TODO: CustomVars

    securedConnection = lib.mkOption {
      type = bool;
      default = true;
    };

    collectEveryXSeconds = lib.mkOption {
      type = number;
      default = 3;
    };

    debug = lib.mkOption {
      type = bool;
      default = false;
    };

    onCalendar = lib.mkOption {
      type = str;
      default = "*-*-* *:*:00";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.count (x: x != null) [ cfg.sid cfg.sidFile cfg.sidCommand ] == 1;
        message = "Exactly one of services.hetrixtools-agent.{sid, sidFile, sidCommand} must be non-null.";
      }
    ];

    system.activationScripts.hetrixtools-agent.text = ''
      #!/bin/sh
      mkdir -p /var/lib/hetrixtools-agent
    '';

    systemd.services.hetrixtools-agent = {
      environment = {
        NetworkInterfaces = lib.strings.concatStringsSep "," cfg.networkInterfaces;
        CheckServices = lib.strings.concatStringsSep "," cfg.checkServices;
        CheckSoftRAID = if cfg.checkSoftRAID then "1" else "0";
        CheckDriveHealth = if cfg.checkDriveHealth then "1" else "0";
        RunningProcesses = if cfg.runningProcesses then "1" else "0";
        ConnectionPorts = lib.strings.concatStringsSep "," (builtins.map builtins.toString cfg.connectionPorts);
        # TODO: CustomVars
        SecuredConnection = if cfg.securedConnection then "1" else "0";
        CollectEveryXSeconds = builtins.toString cfg.collectEveryXSeconds;
        DEBUG = if cfg.debug then "1" else "0";
      } // (if cfg.sid != null then { SID = cfg.sid; } else { });

      serviceConfig =
        let
          script = pkgs.writeShellApplication {
            name = "hetrixtools-agent";
            text =
              if cfg.sidFile != null then ''
                SID="$(<'${cfg.sidFile}')"
                export SID
                exec "${pkgs.hetrixtools-agent}/bin/hetrixtools_agent.sh"
              '' else if cfg.sidCommand != null then ''
                SID="$(${cfg.sidCommand})"
                export SID
                exec "${pkgs.hetrixtools-agent}/bin/hetrixtools_agent.sh"
              '' else "${pkgs.hetrixtools-agent}/bin/hetrixtools_agent.sh";
          };
        in
        {
          Type = "oneshot";
          ExecStart = "${script}/bin/hetrixtools-agent";
        };
    };

    systemd.timers.hetrixtools-agent = {
      wantedBy = [ "multi-user.target" ];

      timerConfig = {
        Unit = "hetrixtools-agent.service";
        OnCalendar = cfg.onCalendar;
      };
    };
  };
}
