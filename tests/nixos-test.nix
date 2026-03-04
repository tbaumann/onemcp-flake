{ self }:

pkgs: {
  name = "1mcp-nixos-test";
  nodes.machine =
    { pkgs, lib, ... }:
    {
      imports = [ self.nixosModules.onemcp ];

      services.onemcp-agent = {
        enable = true;
        servers = {
          "test-pkg" = {
            transport = "stdio";
            command = pkgs.hello;
            args = [
              "-g"
              "Hello from MCP"
            ];
            envFilter = [ "PATH" ];
            tags = [ "test" ];
          };
          "test-http" = {
            transport = "http";
            url = "http://localhost:8080/sse";
            enabled = true;
            tags = [ "remote" ];
          };
          "test-str" = {
            transport = "stdio";
            command = "${pkgs.coreutils}/bin/echo";
            args = [ "Raw string command" ];
          };
        };
      };
    };
  testScript = ''
    machine.wait_for_unit("onemcp-agent.service")

    # Find the config file path from systemd unit
    cmd = "systemctl cat onemcp-agent.service | grep 'ExecStart=' | sed 's/.*--config //' | awk '{print $1}'"
    config_path = machine.succeed(cmd).strip()

    # Verify that the config contains the absolute path to hello
    machine.succeed(f"grep '${pkgs.hello}/bin/hello' {config_path}")

    # Verify HTTP server URL is present
    machine.succeed(f"grep 'http://localhost:8080/sse' {config_path}")

    # Verify tags and envFilter are present in the JSON
    machine.succeed(f"grep 'envFilter' {config_path}")
    machine.succeed(f"grep 'tags' {config_path}")

    # Verify default values are NOT present
    machine.fail(f"grep 'restartOnExit' {config_path}")
    machine.fail(f"grep 'inheritParentEnv' {config_path}")
    machine.fail(f"grep '\"enabled\": true' {config_path}")
  '';
}
