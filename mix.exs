defmodule SipHash.Mixfile do
  use Mix.Project

  @url_docs "http://hexdocs.pm/siphash"
  @url_github "https://github.com/whitfin/siphash-elixir"

  def project do
    [
      app: :siphash,
      name: "SipHash",
      description: "Elixir implementation of the SipHash hash family",
      compilers: [ :make, :elixir, :app ],
      package: %{
        files: [
          "c_src",
          "lib",
          "mix.exs",
          "LICENSE",
          "Makefile",
          "README.md"
        ],
        licenses: [ "MIT" ],
        links: %{
          "Docs" => @url_docs,
          "GitHub" => @url_github
        },
        maintainers: [ "Isaac Whitfield" ]
      },
      version: "3.2.0",
      elixir: "~> 1.1",
      aliases: [
        clean: [ "clean", "clean.make" ]
      ],
      deps: deps(),
      docs: [
        extras: [ "README.md" ],
        source_ref: "master",
        source_url: @url_github
      ],
      test_coverage: [
        tool: ExCoveralls
      ],
      preferred_cli_env: [
        docs: :docs,
        bench: :test,
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.travis": :test
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      # development dependencies
      { :benchfella,  "~> 0.3",  optional: true, only: [ :dev, :test ] },
      { :excoveralls, "~> 0.7",  optional: true, only: [ :dev, :test ] },
      { :exprof,      "~> 0.2",  optional: true, only: [ :dev, :test ] },

      # documentation dependencies
      { :ex_doc, "~> 0.18", optional: true, only: [ :docs ] }
    ]
  end

  # https://github.com/whitfin/siphash-elixir/pull/5/files
  # Basically the same code, just with my spin on it
  def determine_host_make do
    make_cmd =
      case System.get_env("MAKE") do
        nil ->
          # nil is nil
          nil

        "" ->
          # we don't want accidental empty variables
          nil

        cmd when is_binary(cmd) ->
          cmd
      end

    case make_cmd do
      nil ->
        # if all else fails, let's check the OS
        case :os.type() do
          {:unix, bsd_like} when bsd_like in [:dragonfly, :freebsd, :netbsd, :openbsd] ->
            "gmake"

          _ ->
            "make"
        end

      cmd ->
        cmd
    end
  end
end

defmodule Mix.Tasks.Clean.Make do
  def run(_) do
    make_cmd = SipHash.Mixfile.determine_host_make()
    {_result, 0} = System.cmd(make_cmd, ["clean"], stderr_to_stdout: true)
    :ok
  end
end

defmodule Mix.Tasks.Compile.Make do
  def run(_) do
    make_cmd = SipHash.Mixfile.determine_host_make()
    if !Application.get_env(:siphash, :disable_nifs, false)  do
      {_result, 0} = System.cmd(make_cmd, ["priv/siphash.so"], stderr_to_stdout: true)
      Mix.Project.build_structure()
    end
    :ok
  end
end
