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
      type = str;
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
    system.activationScripts.hetrixtools-agent.text = ''
      #!/bin/sh
      mkdir -p /var/lib/hetrixtools-agent
    '';

    systemd.services.hetrixtools-agent = {
      environment = {
        SID = cfg.sid;
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
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.hetrixtools-agent}/bin/hetrixtools_agent.sh";
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
