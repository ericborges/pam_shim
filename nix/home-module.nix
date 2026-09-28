{ pkgs, lib, config, ... }: {
  options.pamShim = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable pam-shim and replace libpam with it.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./default.nix {};
      description = "The pam-shim package to use.";
    };
  };

  config = {
    assertions = lib.mkIf config.pamShim.enable [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "pam_shim is not available on non-Linux platforms.";
      }
    ];

    lib.pamShim.replacePam = drv:
      if config.pamShim.enable then
        let
          wrapped = pkgs.replaceDependencies {
            inherit drv;
            replacements = [
              {
                oldDependency = pkgs.linux-pam;
                newDependency = config.pamShim.package;
              }
            ];
          };
        in
        wrapped // {
          # replaceDependencies drops meta; restore it so consumers
          # (e.g. lib.getExe) can keep using meta.mainProgram.
          meta = (wrapped.meta or { }) // (drv.meta or { });
        }
      else drv;
  };
}
