{ self, home-manager }:

pkgs: {
  name = "1mcp-home-manager-test";
  nodes.machine =
    { pkgs, lib, ... }:
    {
      imports = [ home-manager.nixosModules.home-manager ];

      users.users.testuser = {
        isNormalUser = true;
        uid = 1000;
        linger = true;
      };

      home-manager.users.testuser = {
        imports = [ self.homeModules.onemcp ];
        home.stateVersion = "24.11";

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
    };
  testScript = ''
    machine.wait_for_unit("user@1000.service")
    machine.wait_until_succeeds("su - testuser -c 'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user is-active onemcp-agent.service'")

    # Find the config file path from systemd unit
    cmd = "su - testuser -c \"XDG_RUNTIME_DIR=/run/user/1000 systemctl --user cat onemcp-agent.service | grep 'ExecStart=' | sed 's/.*--config //'\""
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
